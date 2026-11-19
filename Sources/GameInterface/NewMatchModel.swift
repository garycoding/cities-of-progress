// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore

/// What the new-match screen hands back: the players, ready to join a map and a
/// seed into a `MatchSetup`. The map comes from elsewhere.
public struct NewMatchChoice: Hashable, Sendable {
    public var players: [PlayerSetup]

    public init(players: [PlayerSetup]) { self.players = players }

    public func setup(map: GameMap, seed: UInt64, catalogue: Catalogue = .standard) -> MatchSetup {
        MatchSetup(map: map, players: players, seed: seed, catalogue: catalogue)
    }
}

/// The new-match screen's state: one seat for each player, each with a
/// civilization, a controller and a team. The first milestone is one human
/// against one computer player (`maxPlayers` 2); a match of four or six, with
/// more human seats and shared teams, adds seats to the same list.
public struct NewMatchModel: Hashable, Sendable {
    public struct Seat: Identifiable, Hashable, Sendable {
        public var id: Int
        public var civilization: Civilization
        public var controller: Controller
        public var team: Int

        public var isHuman: Bool { controller == .human }
        public var difficulty: Difficulty? {
            if case .computer(let d) = controller { return d }
            return nil
        }
    }

    public private(set) var seats: [Seat]
    public var maxPlayers: Int
    private var nextID: Int

    public init(maxPlayers: Int = 2, civilization: Civilization = .sumer, opponent: Civilization = .egypt,
                difficulty: Difficulty = .standard) {
        self.maxPlayers = maxPlayers
        seats = [
            Seat(id: 0, civilization: civilization, controller: .human, team: 0),
            Seat(id: 1, civilization: opponent == civilization ? Self.firstUnused([civilization]) : opponent,
                 controller: .computer(difficulty), team: 1),
        ]
        nextID = 2
    }

    private static func firstUnused(_ taken: [Civilization]) -> Civilization {
        Civilization.allCases.first { !taken.contains($0) } ?? .sumer
    }

    /// Choose a civilization for a seat. Each player has a different one
    /// (requirement 10), so a civilization another seat holds changes places.
    public mutating func setCivilization(_ civilization: Civilization, forSeat id: Int) {
        guard let i = seats.firstIndex(where: { $0.id == id }) else { return }
        let previous = seats[i].civilization
        if let j = seats.firstIndex(where: { $0.civilization == civilization && $0.id != id }) {
            seats[j].civilization = previous
        }
        seats[i].civilization = civilization
    }

    public mutating func setDifficulty(_ difficulty: Difficulty, forSeat id: Int) {
        guard let i = seats.firstIndex(where: { $0.id == id }), !seats[i].isHuman else { return }
        seats[i].controller = .computer(difficulty)
    }

    public mutating func setTeam(_ team: Int, forSeat id: Int) {
        guard let i = seats.firstIndex(where: { $0.id == id }) else { return }
        seats[i].team = team
    }

    public var canAddComputerPlayer: Bool { seats.count < maxPlayers && seats.count < Civilization.allCases.count }

    /// Add a computer player on a team of its own, with the first civilization not yet taken.
    @discardableResult
    public mutating func addComputerPlayer(difficulty: Difficulty = .standard) -> Bool {
        guard canAddComputerPlayer else { return false }
        let team = (seats.map(\.team).max() ?? -1) + 1
        seats.append(Seat(id: nextID, civilization: Self.firstUnused(seats.map(\.civilization)),
                          controller: .computer(difficulty), team: team))
        nextID += 1
        return true
    }

    /// Remove a computer player's seat; the human seat stays.
    public mutating func removeSeat(_ id: Int) {
        seats.removeAll { $0.id == id && !$0.isHuman }
    }

    /// Why the match cannot start, or `nil` if it can (requirements 4, 5 and 10).
    public var problem: String? {
        if ![2, 4, 6].contains(seats.count) { return "A match has two, four or six players." }
        if Set(seats.map(\.team)).count < 2 { return "A match needs at least two teams." }
        if Set(seats.map(\.civilization)).count != seats.count { return "Each player needs a different civilization." }
        if seats.filter(\.isHuman).contains(where: { $0.team != seats[0].team }) { return "All the human players are on one team." }
        return nil
    }

    public var canStart: Bool { problem == nil }

    /// The players in seat order, numbered from 0; teams are numbered by first appearance.
    public var choice: NewMatchChoice {
        var teams: [Int: Int] = [:]
        var players: [PlayerSetup] = []
        for (i, seat) in seats.enumerated() {
            let team = teams[seat.team] ?? teams.count
            teams[seat.team] = team
            players.append(PlayerSetup(id: PlayerID(i), civilization: seat.civilization, team: TeamID(team),
                                       controller: seat.controller))
        }
        return NewMatchChoice(players: players)
    }
}
