// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore

/// The match as the Mac that runs it holds it: the simulation and the computer
/// players, advanced one tick at a time (docs/architecture.md). The app drives
/// it from a timer and the match tests drive it in a loop, so both run the same
/// code.
///
/// It is a value and `Codable`, so encoding it saves the whole match,
/// computer players included (requirement 23).
public struct MatchHost<Simulation: GameSimulating, Computer: ComputerPlaying>: Codable, Sendable {
    /// Ticks between two decisions of one computer player: four a second.
    public static var decisionInterval: Int { Tick.rate / 4 }

    public private(set) var simulation: Simulation
    public private(set) var computers: [Computer]
    /// The player each computer controls, in the order of `computers`.
    public let computerPlayers: [PlayerID]
    public let catalogue: Catalogue

    /// Starts a match: one computer player for each player the setup gives to a computer.
    public init(setup: MatchSetup) {
        simulation = Simulation(setup: setup)
        catalogue = setup.catalogue
        var computers: [Computer] = []
        var players: [PlayerID] = []
        for (i, p) in setup.players.enumerated() {
            guard case .computer(let difficulty) = p.controller else { continue }
            // Each computer player draws from its own stream, derived from the match's seed.
            computers.append(Computer(player: p.id, difficulty: difficulty,
                                      seed: setup.seed &* 0x9E37_79B9_7F4A_7C15 &+ UInt64(i + 1)))
            players.append(p.id)
        }
        self.computers = computers
        computerPlayers = players
    }

    public var tick: Int { simulation.tick }
    public var outcome: MatchOutcome? { simulation.outcome }
    public var isPaused: Bool { simulation.isPaused }

    /// An order from a person at this Mac (or, in a later milestone, another Mac).
    @discardableResult
    public mutating func apply(_ order: Order, from player: PlayerID) -> OrderResult {
        simulation.apply(order, from: player)
    }

    /// One tick: each computer player whose turn it is decides from its own view,
    /// its orders are applied, and the simulation steps. The computer players'
    /// turns are spread across the interval so that no tick carries them all.
    public mutating func advance() {
        guard outcome == nil, !isPaused else { return }
        let interval = Self.decisionInterval
        for k in computers.indices where (simulation.tick + k) % interval == 0 {
            let player = computerPlayers[k]
            let view = simulation.view(for: player)
            for order in computers[k].decide(view: view, catalogue: catalogue) {
                simulation.apply(order, from: player)
            }
        }
        simulation.step()
    }

    /// What a person may know now. It takes the events since that player's last
    /// view, so call it once per update for each person.
    public mutating func view(for player: PlayerID) -> PlayerView {
        simulation.view(for: player)
    }

    public func checksum() -> UInt64 { simulation.checksum() }
}
