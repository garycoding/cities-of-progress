// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore
import Network
import Observation

/// The Mac that hosts a match. It listens for the Macs that join, admits them
/// to the open people's seats of its `Lobby`, and once the match has started
/// relays their orders to the match and sends them their views and every
/// notice. How the app drives it is described at the top of `GameNetwork.swift`.
@MainActor
@Observable
public final class HostServer {
    /// How often each person is sent a view: about 20 times a second.
    public static let viewInterval: Duration = .milliseconds(50)
    /// A view is sent in a frame at least this long after the last one, so that
    /// frames of 60 Hz or 120 Hz give 20 views a second.
    static let viewDue: Duration = .milliseconds(45)
    /// Views handed to a connection but not yet taken by the network, beyond
    /// which a person's views wait; their events wait in the match meanwhile.
    static let viewsInFlight = 2

    public enum Phase: Hashable, Sendable {
        case lobby, playing, closed
    }

    /// The match being set up, as every Mac in it sees it.
    public private(set) var lobby: Lobby
    public private(set) var phase: Phase = .lobby
    /// The port on which the server listens, once it does.
    public private(set) var port: UInt16?
    /// Why the match cannot be offered on the network, if it cannot.
    public private(set) var problem: String?
    /// Every notice of the match so far, the oldest first, including those
    /// about the host's own person.
    public private(set) var notices: [Notice] = []
    /// How many times the normal rate the match runs.
    public private(set) var speed: Double
    /// The seats of people whose Macs have left and which are not yet handed
    /// to a computer player; the match holds still while any remain.
    public private(set) var dropped: [PlayerID] = []
    /// Called with each notice, after it has been added to `notices`.
    @ObservationIgnored public var onNotice: (@MainActor (Notice) -> Void)?

    /// The build stamp a joining Mac must match.
    public let build: String
    /// The speeds anyone may choose; a request outside them is brought within.
    public let speeds: ClosedRange<Double>
    /// A joining Mac from which nothing arrives for this long is taken to have
    /// left. A client pings every second.
    @ObservationIgnored public var silenceLimit: Duration = .seconds(6)

    @ObservationIgnored private weak var match: (any HostedMatch)?
    @ObservationIgnored private var listener: NWListener?
    @ObservationIgnored private var guests: [Guest] = []
    @ObservationIgnored private var nextGuest = 0
    /// Events of views that never went out, for the seat's next view.
    @ObservationIgnored private var carried: [PlayerID: [GameEvent]] = [:]
    @ObservationIgnored private var flushScheduled = false
    @ObservationIgnored private var housekeeping: Task<Void, Never>?

    /// - Parameters:
    ///   - lobby: the match as the host set it up, with seats open for people.
    ///   - build: the host's build stamp, which a joining Mac must match.
    ///   - speed: the speed at which the match starts (a saved match's own, when resuming one).
    ///   - speeds: the speeds anyone may choose (the app's Speed menu runs from 1× to 4×).
    public init(lobby: Lobby, build: String, speed: Double = 1, speeds: ClosedRange<Double> = 1...4) {
        self.lobby = lobby
        self.build = build
        self.speeds = speeds
        self.speed = min(max(speed, speeds.lowerBound), speeds.upperBound)
    }

    /// The seat of the person at this Mac.
    public var hostSeat: PlayerID? { lobby.seats.first { $0.kind == .host }?.player }

    private var hostName: String { lobby.seats.first { $0.kind == .host }?.holder ?? "The host" }

    // MARK: Listening

    /// Starts listening: on every interface, with the match announced on the
    /// LAN under the lobby's name, or, for tests, on this Mac's loopback
    /// interface only and unannounced. `port` is set once it listens.
    public func open(loopbackOnly: Bool = false) throws {
        guard listener == nil, phase != .closed else { return }
        let parameters = Framing.parameters()
        if loopbackOnly { parameters.requiredInterfaceType = .loopback }
        let listener = try NWListener(using: parameters)
        if !loopbackOnly {
            listener.service = NWListener.Service(name: Self.serviceName(for: lobby.name), type: NetService.type)
        }
        listener.stateUpdateHandler = { [weak self, weak listener] state in
            let port = listener?.port?.rawValue
            let problem: String? = switch state {
            case .failed(let error), .waiting(let error): error.localizedDescription
            default: nil
            }
            let ready = if case .ready = state { true } else { false }
            DispatchQueue.main.async { MainActor.assumeIsolated { self?.listening(ready: ready, port: port, problem: problem) } }
        }
        listener.newConnectionHandler = { [weak self] connection in
            DispatchQueue.main.async { MainActor.assumeIsolated { self?.accept(connection) } }
        }
        listener.start(queue: DispatchQueue(label: "GameNetwork.HostServer", qos: .userInteractive))
        self.listener = listener
        housekeeping = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                tidy()
            }
        }
    }

    deinit {
        listener?.cancel()
        housekeeping?.cancel()
    }

    /// The lobby's name as a Bonjour service name, which holds at most 63 bytes.
    nonisolated static func serviceName(for name: String) -> String {
        var out = ""
        for character in name {
            guard out.utf8.count + String(character).utf8.count <= 63 else { break }
            out.append(character)
        }
        return out.isEmpty ? "Cities of Progress" : out
    }

    private func listening(ready: Bool, port: UInt16?, problem: String?) {
        guard phase != .closed else { return }
        if ready { self.port = port }
        if let problem { self.problem = "The match cannot be offered on the network: \(problem)" } else if ready { self.problem = nil }
    }

    private func accept(_ connection: NWConnection) {
        guard phase != .closed else { return connection.cancel() }
        let id = nextGuest
        nextGuest += 1
        let link = Link(connection: connection, handlers: Link.Handlers(
            message: { [weak self] message in self?.received(message, from: id) },
            ended: { [weak self] _ in self?.ended(id) }))
        guests.append(Guest(id: id, link: link))
        link.start()
    }

    // MARK: The lobby

    /// The host chooses the civilization of its own seat or of a computer's; a
    /// person's seat is chosen by that person. Refused when another seat has
    /// it or the seat's civilization is fixed.
    @discardableResult
    public func chooseCivilization(_ civilization: Civilization, for seat: PlayerID) -> Bool {
        guard lobby.seats.contains(where: { $0.player == seat && $0.kind != .person }) else { return false }
        return choose(civilization, for: seat)
    }

    private func choose(_ civilization: Civilization, for seat: PlayerID) -> Bool {
        guard phase == .lobby, let i = lobby.seats.firstIndex(where: { $0.player == seat }),
              !lobby.seats[i].civilizationFixed,
              !lobby.seats.contains(where: { $0.player != seat && $0.civilization == civilization }) else { return false }
        if lobby.seats[i].civilization != civilization {
            lobby.seats[i].civilization = civilization
            sendLobby()
        }
        return true
    }

    /// Starts the match, once every seat is held and has a civilization.
    /// `match` is the app's match, made from `lobby.setup(map:seed:)` or opened
    /// from a save; each person is sent the match's start, then views.
    @discardableResult
    public func start(_ match: any HostedMatch) -> Bool {
        guard phase == .lobby, lobby.isReady else { return false }
        self.match = match
        match.speed = speed
        phase = .playing
        for guest in guests where guest.seat != nil { sendStart(to: guest) }
        return true
    }

    // MARK: The match

    /// Sends each person who joined their view when it is due, about 20 times
    /// a second. Call it once a frame, after the frame's ticks.
    public func frame() {
        guard phase == .playing else { return }
        let now = ContinuousClock.now
        for guest in guests where guest.started {
            if let last = guest.lastView, last.duration(to: now) < Self.viewDue { continue }
            sendView(to: guest)
        }
    }

    /// An order from the person at this Mac (the session's sink, when hosting).
    @discardableResult
    public func issue(_ order: Order) -> OrderResult {
        guard phase == .playing, let seat = hostSeat else { return .refused(.notNow) }
        return apply(order, from: seat, by: hostName)
    }

    /// The person at this Mac changes the speed; everyone is told.
    public func setSpeed(_ speed: Double) { changeSpeed(to: speed, by: hostName) }

    /// "Continue with a computer player": a computer player at `difficulty`
    /// plays the seat of a person who is not connected, until they return.
    @discardableResult
    public func handToComputer(_ seat: PlayerID, difficulty: Difficulty) -> Bool {
        guard phase == .playing, let match, holder(of: seat) == nil,
              lobby.seats.contains(where: { $0.player == seat && $0.kind == .person }) else { return false }
        match.handToComputer(seat, difficulty: difficulty)
        dropped.removeAll { $0 == seat }
        publish(.handedToComputer(player: seat, difficulty: difficulty))
        return true
    }

    /// Closes the match: everyone is told that the host is leaving, and the
    /// match is no longer offered.
    public func close() {
        guard phase != .closed else { return }
        phase = .closed
        notices.append(.hostLeaving)
        onNotice?(.hostLeaving)
        for guest in guests {
            if guest.seat != nil { guest.link.send(.notice(.hostLeaving), final: true) } else { guest.link.close() }
        }
        stop()
    }

    /// Stops at once, as if the host's Mac had gone: no notice, and every
    /// connection broken (for tests).
    func vanish() {
        guard phase != .closed else { return }
        phase = .closed
        for guest in guests { guest.link.breakOff() }
        stop()
    }

    private func stop() {
        guests.removeAll()
        listener?.cancel()
        listener = nil
        port = nil
        housekeeping?.cancel()
        housekeeping = nil
    }

    // MARK: Messages

    private func received(_ message: NetMessage, from id: Int) {
        guard let guest = guests.first(where: { $0.id == id }) else { return }
        guest.heard = .now
        switch message {
        case .hello(let version, let build, let name, let rejoining):
            hello(guest, version: version, build: build, name: name, rejoining: rejoining)
        case .chooseCivilization(let civilization):
            guard let seat = guest.seat else { return }
            // A refusal changes nothing, so the person is sent the lobby as it stands.
            if !choose(civilization, for: seat) { guest.link.send(.lobby(lobby)) }
        case .order(let order):
            guard phase == .playing, let seat = guest.seat, let name = guest.name else { return }
            apply(order, from: seat, by: name)
            guest.wantsView = true
            scheduleFlush()
        case .setSpeed(let speed):
            guard let name = guest.name else { return }
            changeSpeed(to: speed, by: name)
        case .ping(let n):
            guest.link.send(.pong(n))
        case .welcome, .turnedAway, .lobby, .start, .view, .notice, .pong:
            break
        }
    }

    private func hello(_ guest: Guest, version: Int, build: String, name: String, rejoining: PlayerID?) {
        guard guest.seat == nil else { return }
        guard version == NetMessage.protocolVersion, build == self.build else {
            return turnAway(guest, "This Mac runs build \(build) (protocol \(version)) and the host runs build "
                                + "\(self.build) (protocol \(NetMessage.protocolVersion)); both must run the same build.")
        }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return turnAway(guest, "A name is needed to join a match.") }
        guard lobby.seats.first(where: { $0.kind == .host })?.holder != name else {
            return turnAway(guest, "The person hosting is also called \(name); each person in a match needs a name of their own.")
        }
        switch phase {
        case .lobby: admit(guest, name: name, asking: rejoining)
        case .playing: readmit(guest, name: name)
        case .closed: turnAway(guest, "The match has closed.")
        }
    }

    /// A person joins the match being set up: the seat already held under their
    /// name (they joined again before their old connection was seen to close),
    /// else the seat they ask for if it is open, else the first open seat.
    private func admit(_ guest: Guest, name: String, asking: PlayerID?) {
        let seats = lobby.seats.indices.filter { lobby.seats[$0].kind == .person }
        var index = seats.first { lobby.seats[$0].holder == name }
        if let index, let old = holder(of: lobby.seats[index].player) { replace(old) }
        if index == nil, let asking {
            index = seats.first { lobby.seats[$0].player == asking && lobby.seats[$0].holder == nil }
        }
        if index == nil { index = seats.first { lobby.seats[$0].holder == nil } }
        guard let index else { return turnAway(guest, "The match \(lobby.name) has no open seat.") }
        lobby.seats[index].holder = name
        seat(guest, at: lobby.seats[index].player, name: name)
        sendLobby()
    }

    /// A person comes back to the match in play: they are given the seat held
    /// under their name, whether their Mac dropped out or a computer player
    /// took the seat meanwhile.
    private func readmit(_ guest: Guest, name: String) {
        guard let seat = lobby.seats.first(where: { $0.kind == .person && $0.holder == name })?.player else {
            return turnAway(guest, "The match \(lobby.name) has started; only the people playing it can rejoin it.")
        }
        if let old = holder(of: seat) {
            replace(old)
            drop(seat, name: name)
        }
        self.seat(guest, at: seat, name: name)
        guest.link.send(.lobby(lobby))
        match?.rejoin(seat)
        dropped.removeAll { $0 == seat }
        sendStart(to: guest)
        publish(.rejoined(player: seat, name: name))
    }

    private func seat(_ guest: Guest, at seat: PlayerID, name: String) {
        guest.seat = seat
        guest.name = name
        guest.link.send(.welcome(seat: seat))
    }

    /// Another connection has come under the same name. The old one, whose
    /// loss may not have been noticed yet, is turned away rather than left to
    /// take the seat back, so that two Macs cannot take it from each other in turn.
    private func replace(_ old: Guest) {
        turnAway(old, "Another connection has taken this seat under the name \(old.name ?? "").")
    }

    private func turnAway(_ guest: Guest, _ reason: String) {
        guests.removeAll { $0 === guest }
        guest.link.send(.turnedAway(reason: reason), final: true)
    }

    /// The person's connection ended or fell silent: in the lobby their seat
    /// opens again; in play the match holds for them.
    private func ended(_ id: Int) {
        guard let guest = guests.first(where: { $0.id == id }) else { return }
        lose(guest)
    }

    private func lose(_ guest: Guest) {
        guests.removeAll { $0 === guest }
        guest.link.close()
        guard let seat = guest.seat, let name = guest.name else { return }
        switch phase {
        case .lobby:
            guard let i = lobby.seats.firstIndex(where: { $0.player == seat }) else { return }
            lobby.seats[i].holder = nil
            if !lobby.seats[i].civilizationFixed { lobby.seats[i].civilization = nil }
            sendLobby()
        case .playing:
            drop(seat, name: name)
        case .closed:
            break
        }
    }

    private func drop(_ seat: PlayerID, name: String) {
        match?.drop(seat)
        if !dropped.contains(seat) { dropped.append(seat) }
        publish(.dropped(player: seat, name: name))
    }

    private func holder(of seat: PlayerID) -> Guest? { guests.first { $0.seat == seat } }

    private func tidy() {
        let now = ContinuousClock.now
        for guest in guests where guest.heard.duration(to: now) > silenceLimit { lose(guest) }
    }

    // MARK: Orders, speed and notices

    @discardableResult
    private func apply(_ order: Order, from seat: PlayerID, by name: String) -> OrderResult {
        guard let match else { return .refused(.notNow) }
        let held = !dropped.isEmpty
        let result = match.apply(order, from: seat)
        guard case .setPaused(let paused) = order else { return result }
        if result == .accepted {
            publish(paused ? .paused(by: name) : .resumed(by: name))
        } else if !paused, held, result == .refused(.notNow), seat != hostSeat {
            // `MatchHost` refuses a resume while it holds for a dropped person
            // without the simulation's knowing, so no event reports it; the
            // person's next view does.
            carried[seat, default: []].append(.refused(.notNow))
        }
        return result
    }

    private func changeSpeed(to requested: Double, by name: String) {
        guard requested.isFinite else { return }
        let new = min(max(requested, speeds.lowerBound), speeds.upperBound)
        guard new != speed else { return }
        speed = new
        match?.speed = new
        publish(.speedChanged(to: new, by: name))
    }

    private func publish(_ notice: Notice) {
        notices.append(notice)
        onNotice?(notice)
        for guest in guests where guest.seat != nil { guest.link.send(.notice(notice)) }
    }

    private func sendLobby() {
        for guest in guests where guest.seat != nil { guest.link.send(.lobby(lobby)) }
    }

    // MARK: Views

    /// The match's start, from the terrain of the first view, which follows it.
    private func sendStart(to guest: Guest) {
        guard let match, let seat = guest.seat else { return }
        let view = takeView(for: seat, from: match)
        guest.link.send(.start(MatchStart(player: seat, mapWidth: view.mapWidth, mapHeight: view.mapHeight,
                                          terrain: view.terrain, catalogue: match.catalogue, speed: speed)))
        guest.started = true
        send(view, to: guest)
    }

    private func sendView(to guest: Guest) {
        guard let match, let seat = guest.seat, guest.started, guest.inFlight < Self.viewsInFlight else { return }
        send(takeView(for: seat, from: match), to: guest)
    }

    /// A view is taken only to be sent, so that the events of a view never
    /// taken stay in the match; the events of a view that never went out are
    /// carried into the next.
    private func takeView(for seat: PlayerID, from match: any HostedMatch) -> PlayerView {
        var view = match.view(for: seat)
        if let earlier = carried.removeValue(forKey: seat) { view.events = earlier + view.events }
        return view
    }

    private func send(_ view: PlayerView, to guest: Guest) {
        guard let seat = guest.seat else { return }
        let sent = view.withoutTerrain
        guest.inFlight += 1
        guest.lastView = .now
        guest.wantsView = false
        guest.link.send(.view(sent)) { [weak self, weak guest] wentOut in
            guest?.inFlight -= 1
            if !wentOut, !sent.events.isEmpty { self?.carried[seat, default: []].append(contentsOf: sent.events) }
        }
    }

    /// A person who gave orders is sent a view once the orders that arrived
    /// together have been applied.
    private func scheduleFlush() {
        guard !flushScheduled else { return }
        flushScheduled = true
        DispatchQueue.main.async { [weak self] in MainActor.assumeIsolated { self?.flush() } }
    }

    private func flush() {
        flushScheduled = false
        for guest in guests where guest.wantsView { sendView(to: guest) }
    }
}

/// A Mac connected to the server, before its hello and then in a seat.
@MainActor
private final class Guest {
    let id: Int
    let link: Link
    var name: String?
    var seat: PlayerID?
    var heard = ContinuousClock.now
    /// Sent the match's start, after which it is sent views.
    var started = false
    var lastView: ContinuousClock.Instant?
    var inFlight = 0
    var wantsView = false

    init(id: Int, link: Link) {
        self.id = id
        self.link = link
    }
}
