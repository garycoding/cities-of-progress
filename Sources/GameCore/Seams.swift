// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

// The protocols at the seams between modules. Each module implements or uses
// these and nothing of another module's internals (docs/architecture.md).

/// Who controls a player.
public enum Controller: Hashable, Codable, Sendable {
    case human
    case computer(Difficulty)
}

public struct PlayerSetup: Hashable, Codable, Sendable {
    public var id: PlayerID
    public var civilization: Civilization
    public var team: TeamID
    public var controller: Controller

    public init(id: PlayerID, civilization: Civilization, team: TeamID, controller: Controller) {
        self.id = id; self.civilization = civilization; self.team = team; self.controller = controller
    }
}

/// Everything needed to start a match.
public struct MatchSetup: Hashable, Codable, Sendable {
    public var map: GameMap
    /// In player order; `map.starts[i]` is the start of `players[i]`.
    public var players: [PlayerSetup]
    public var seed: UInt64
    public var catalogue: Catalogue

    public init(map: GameMap, players: [PlayerSetup], seed: UInt64, catalogue: Catalogue = .standard) {
        self.map = map; self.players = players; self.seed = seed; self.catalogue = catalogue
    }
}

/// The rules of the game (module `GameSimulation`).
///
/// It is a value: copying it copies the match, and encoding it saves the match,
/// random generator included, so that a saved match resumes exactly. It uses no
/// Apple frameworks and no unseeded randomness, and it never lets the order of a
/// `Dictionary` or `Set` decide an outcome, so that the same setup and the same
/// orders at the same ticks give the same result in any process.
public protocol GameSimulating: Codable, Sendable {
    init(setup: MatchSetup)
    var tick: Int { get }
    var outcome: MatchOutcome? { get }
    var isPaused: Bool { get set }
    /// Apply an order from a player at the current tick. A refusal is also
    /// reported as `GameEvent.refused` in that player's next view.
    mutating func apply(_ order: Order, from player: PlayerID) -> OrderResult
    /// Advance one tick (1 / `Tick.rate` seconds), unless paused.
    mutating func step()
    /// What the player may know now, with the events since the player's last view.
    mutating func view(for player: PlayerID) -> PlayerView
    /// A checksum of the whole state, the same in every process for the same
    /// state. Computed field by field from the simulation's own ordered arrays,
    /// never by hashing an encoding that contains a dictionary.
    func checksum() -> UInt64
}

/// The map generator (module `MapGeneration`). The same request gives the same map.
public protocol MapGenerating: Sendable {
    func generate(_ request: MapRequest) -> GameMap
}

/// A computer player (module `ComputerPlayer`). It sees only what its player's
/// view shows and acts only through orders, as a person does (requirement 22).
public protocol ComputerPlaying: Codable, Sendable {
    init(player: PlayerID, difficulty: Difficulty, seed: UInt64)
    /// Called a few times a second, never more than once a tick.
    mutating func decide(view: PlayerView, catalogue: Catalogue) -> [Order]
}
