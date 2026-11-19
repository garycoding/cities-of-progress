// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import AppKit
import Artwork
import ComputerPlayer
import Foundation
import GameCore
import GameInterface
import GameNetwork
import GameSimulation
import MapGeneration
import Observation

typealias Host = MatchHost<Simulation, ComputerPlayer>

/// Carries the person's orders from the session to the match, which is made
/// after the session it feeds.
@MainActor
private final class OrderRelay {
    weak var match: Match?
}

/// A match being played on this Mac: the host that runs it, the person's
/// session, and the clock that advances it twenty ticks a second.
@MainActor
final class Match {
    private(set) var host: Host
    let player: PlayerID
    let session: PlayerSession
    private var clock: Timer?
    private var lastTime: TimeInterval?
    private var owed = 0.0

    /// At most this many frames' worth of ticks are run at once, so that a stall
    /// (the Mac asleep, a window being dragged) does not make the match race.
    static let catchUpFrames = 5.0

    /// The speeds the person may choose: how many times the normal rate the match runs.
    static let speeds: [Double] = [1, 1.5, 2, 3, 4]

    /// How many times the normal rate the match runs. It changes only the clock,
    /// so the rules and the computer players are the same at every speed.
    var speed = 1.0

    init(host: Host, player: PlayerID, camera: Camera? = nil) {
        var host = host
        let view = host.view(for: player)
        let relay = OrderRelay()
        self.host = host
        self.player = player
        session = PlayerSession(view: view, catalogue: host.catalogue,
                                camera: camera ?? Camera(centre: Self.home(in: view)),
                                sink: { order in relay.match?.apply(order) })
        relay.match = self
    }

    /// The person's town centre, or else the middle of the map.
    static func home(in view: PlayerView) -> MapPosition {
        view.entities.first { $0.owner == view.player && $0.kind == .building(.townCentre) }?.position
            ?? MapPosition(x: Double(view.mapWidth) / 2, y: Double(view.mapHeight) / 2)
    }

    func start() {
        guard clock == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.frame() }
        }
        RunLoop.main.add(timer, forMode: .common)
        clock = timer
    }

    func stop() {
        clock?.invalidate()
        clock = nil
        // The time stopped is not owed: the match resumes where it stood.
        lastTime = nil
    }

    var isOver: Bool { host.outcome != nil }

    fileprivate func apply(_ order: Order) {
        host.apply(order, from: player)
    }

    /// One frame: run the ticks owed since the last frame, then give the
    /// session the person's view.
    private func frame() {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = lastTime.map { now - $0 } ?? 0
        lastTime = now
        owed = min(owed + elapsed * Double(Tick.rate) * speed, Self.catchUpFrames * speed)
        while owed >= 1 {
            host.advance()
            owed -= 1
        }
        session.update(host.view(for: player))
    }

    /// What a save file holds: the match, whose player this Mac is, and where it was looking.
    struct Saved: Codable {
        var host: Host
        var player: PlayerID
        var camera: Camera
        /// Absent in saves made before speeds existed.
        var speed: Double?
    }

    var saved: Saved { Saved(host: host, player: player, camera: session.camera, speed: speed) }
}

/// The app's state: the match in play, if any, and the artwork every match shares.
@MainActor
@Observable
final class GameController {
    private(set) var match: Match?
    let sprites = GameSprites()
    var problem: String?

    /// The match's speed, shown in the Speed menu.
    var speed = 1.0 {
        didSet { match?.speed = speed }
    }

    /// One step faster or slower among `Match.speeds`, or back to normal.
    func changeSpeed(by steps: Int) {
        let speeds = Match.speeds
        let current = speeds.firstIndex(of: speed) ?? 0
        speed = speeds[min(max(current + steps, 0), speeds.count - 1)]
    }

    func start(_ choice: NewMatchChoice) {
        let seed = UInt64.random(in: 1...UInt64.max)
        let map = MapGenerator().generate(MapRequest(playerCount: choice.players.count, seed: seed))
        let setup = choice.setup(map: map, seed: seed)
        guard let person = setup.players.first(where: { $0.controller == .human }) else { return }
        let new = Match(host: Host(setup: setup), player: person.id)
        new.speed = speed
        begin(new)
    }

    private func begin(_ new: Match) {
        match?.stop()
        match = new
        new.start()
    }

    /// Leave the match and show the new-match screen.
    func endMatch() {
        guard mayLeaveMatch(to: "start a new match") else { return }
        match?.stop()
        match = nil
    }

    /// Whether the person agrees to leave a match still in play; the match is
    /// stopped while the question is open.
    private func mayLeaveMatch(to what: String) -> Bool {
        guard let match, !match.isOver else { return true }
        match.stop()
        let alert = NSAlert()
        alert.messageText = "Leave this match?"
        alert.informativeText = "To \(what), this match will be closed. Save it first if you want to come back to it."
        alert.addButton(withTitle: "Leave Match")
        alert.addButton(withTitle: "Keep Playing")
        let leave = alert.runModal() == .alertFirstButtonReturn
        if !leave { match.start() }
        return leave
    }

    func save() {
        guard let match else { return }
        // The match is saved as it stood when the person asked, and waits while they name the file.
        let snapshot = match.saved
        match.stop()
        defer { match.start() }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Match.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
        } catch {
            problem = "The match could not be saved: \(error.localizedDescription)"
        }
    }

    func open() {
        guard mayLeaveMatch(to: "open a saved match") else { return }
        match?.stop()
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { match?.start(); return }
        do {
            let saved = try JSONDecoder().decode(Match.Saved.self, from: Data(contentsOf: url))
            let opened = Match(host: saved.host, player: saved.player, camera: saved.camera)
            opened.speed = saved.speed ?? 1
            speed = opened.speed
            begin(opened)
        } catch {
            problem = "That file is not a saved match."
            match?.start()
        }
    }
}
