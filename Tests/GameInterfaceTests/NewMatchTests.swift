// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore
import Testing
@testable import GameInterface

@Test func theDefaultMatchIsOneHumanAgainstOneComputerAndCanStart() {
    let m = NewMatchModel()
    #expect(m.canStart && m.problem == nil)
    let c = m.choice
    #expect(c.players == [
        PlayerSetup(id: PlayerID(0), civilization: .sumer, team: TeamID(0), controller: .human),
        PlayerSetup(id: PlayerID(1), civilization: .egypt, team: TeamID(1), controller: .computer(.standard)),
    ])
}

@Test func anyOfTheElevenCivilizationsMayBeChosenForEitherSeat() {
    #expect(Civilization.allCases.count == 11)
    for civ in Civilization.allCases {
        var m = NewMatchModel()
        m.setCivilization(civ, forSeat: 0)
        #expect(m.seats[0].civilization == civ)
        #expect(m.canStart)
        var n = NewMatchModel()
        n.setCivilization(civ, forSeat: 1)
        #expect(n.seats[1].civilization == civ)
        #expect(n.canStart)
    }
}

@Test func choosingTheOpponentsCivilizationSwapsThem() {
    var m = NewMatchModel()   // Sumer, Egypt
    m.setCivilization(.egypt, forSeat: 0)
    #expect(m.seats[0].civilization == .egypt && m.seats[1].civilization == .sumer)
    #expect(m.canStart)
}

@Test func theDifficultyIsChosenForTheComputerSeatOnly() {
    var m = NewMatchModel()
    m.setDifficulty(.hard, forSeat: 1)
    #expect(m.choice.players[1].controller == .computer(.hard))
    m.setDifficulty(.easy, forSeat: 0)
    #expect(m.choice.players[0].controller == .human)
}

@Test func theChoiceBecomesAMatchSetup() {
    var m = NewMatchModel()
    m.setDifficulty(.easy, forSeat: 1)
    let setup = m.choice.setup(map: Samples.map(), seed: 7)
    #expect(setup.players.count == 2 && setup.seed == 7 && setup.map == Samples.map())
    #expect(setup.players[1].controller == .computer(.easy))
}

@Test func seatsBeyondTheFirstMilestoneAreAddedToTheSameList() {
    var m = NewMatchModel(maxPlayers: 6)
    #expect(m.canAddComputerPlayer)
    let added = m.addComputerPlayer()
    #expect(added)
    #expect(!m.canStart)   // three players
    #expect(m.problem == "A match has two, four or six players.")
    let addedAgain = m.addComputerPlayer()
    #expect(addedAgain)
    #expect(m.canStart && m.seats.count == 4)
    // Each seat has its own civilization; computer players are on teams of their own until grouped.
    #expect(Set(m.seats.map(\.civilization)).count == 4)
    #expect(Set(m.choice.players.map(\.team)).count == 4)
    // Computer players may be grouped, or placed on the human team.
    m.setTeam(0, forSeat: 2)
    m.setTeam(1, forSeat: 3)
    #expect(m.canStart)
    #expect(m.choice.players.map(\.team) == [TeamID(0), TeamID(1), TeamID(0), TeamID(1)])
}

@Test func aSingleTeamCannotStart() {
    var m = NewMatchModel()
    m.setTeam(0, forSeat: 1)
    #expect(!m.canStart && m.problem == "A match needs at least two teams.")
}

@Test func theFirstMilestoneHoldsTwoPlayersAndTheHumanSeatStays() {
    var m = NewMatchModel()
    let added = m.addComputerPlayer()
    #expect(!m.canAddComputerPlayer && !added)
    m.removeSeat(0)
    #expect(m.seats.count == 2)
    m.removeSeat(1)
    #expect(m.seats.count == 1 && m.seats[0].isHuman && !m.canStart)
}
