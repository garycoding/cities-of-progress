// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore
import Testing
@testable import GameSimulation

/// The setting "What you see" (ruled 2026-11-20): what the people in a match
/// see of the map; computer players always explore.
@Suite struct MapSightSetting {
    /// A duel in which player 0 is a person and player 1 a computer, with a
    /// gold deposit far from both, under the given setting.
    private func match(_ sight: MapSight) -> Simulation {
        var s = setup(openMap(starts: [GridPoint(2, 2), GridPoint(34, 34)], sites: [(.gold, 20, 20)]), teams: [0, 1])
        s.sight = sight == .explore ? nil : sight
        var sim = Simulation(setup: s)
        sim.players[0].age = .bronze
        sim.players[1].age = .bronze
        return sim
    }

    private func theirCentre(_ view: PlayerView) -> Bool {
        view.entities.contains { $0.owner == them && $0.kind == .building(.townCentre) }
    }

    @Test func exploringShowsOnlyWhatHasBeenSeen() {
        var sim = match(.explore)
        let view = sim.view(for: me)
        #expect(view.visibility(at: GridPoint(30, 30)) == .unexplored)
        #expect(!view.sites.contains { $0.kind == .gold })
        #expect(!theirCentre(view))
    }

    @Test func theMapShownRevealsTheGroundAndDepositsButNotWhatIsHappening() {
        var sim = match(.mapShown)
        let view = sim.view(for: me)
        #expect(view.visibility(at: GridPoint(30, 30)) == .explored)
        #expect(view.visibility(at: GridPoint(3, 3)) == .visible)
        #expect(view.sites.contains { $0.kind == .gold })
        #expect(!theirCentre(view))
    }

    @Test func everythingInViewShowsTheWholeMapAsItIs() {
        var sim = match(.everything)
        let view = sim.view(for: me)
        #expect(view.visibility.allSatisfy { $0 == .visible })
        #expect(view.sites.contains { $0.kind == .gold })
        #expect(theirCentre(view))
    }

    @Test func computerPlayersAlwaysExplore() {
        var sim = match(.everything)
        // The computer's own seat.
        let theirs = sim.view(for: them)
        #expect(theirs.visibility(at: GridPoint(3, 3)) == .unexplored)
        #expect(!theirs.entities.contains { $0.owner == me })
        // A person's seat played by a computer.
        let handed = sim.computerView(for: me)
        #expect(handed.visibility(at: GridPoint(30, 30)) == .unexplored)
        #expect(!theirCentre(handed))
    }

    @Test func theSettingIsSavedWithTheMatchAndOlderSavesExplore() throws {
        let sim = match(.mapShown)
        let reopened = try JSONDecoder().decode(Simulation.self, from: JSONEncoder().encode(sim))
        #expect(reopened.sight == .mapShown)
        // A save from before the setting has no value, which is `.explore`.
        let older = try JSONDecoder().decode(Simulation.self, from: JSONEncoder().encode(match(.explore)))
        #expect(older.sight == nil)
        var view = older
        #expect(view.view(for: me).visibility(at: GridPoint(30, 30)) == .unexplored)
    }
}
