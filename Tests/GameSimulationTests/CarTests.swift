// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore
import Testing
@testable import GameSimulation

/// A person's car (ruled 2026-11-21).
@Suite struct Car {
    @Test func aPersonSummonsOneCarBesideATownCentreAndAComputerNone() {
        var sim = duel()
        #expect(sim.apply(.summonCar, from: them) == .refused(.notYours))   // a computer player
        #expect(sim.apply(.summonCar, from: me) == .accepted)
        let cars = sim.people(me, .car)
        #expect(cars.count == 1)
        let centre = sim.living(sim.townCentre(me))
        #expect(sim.living(cars[0]).position.distance(to: centre.position) < 4)
        #expect(sim.apply(.summonCar, from: me) == .refused(.notNow))      // one each
        #expect(sim.people(me, .car).count == 1)
        // Free, and outside the population.
        #expect(sim.view(for: me).population == sim.people(me, .worker).count + sim.people(me, .engineer).count)
    }

    @Test func withoutATownCentreThereIsNoCar() {
        var sim = duel()
        sim.kill(sim.index(of: sim.townCentre(me))!)
        sim.removeDead()
        #expect(sim.apply(.summonCar, from: me) == .refused(.invalidTarget))
    }

    @Test func itDrivesAtTwiceAWorkersSpeed() {
        #expect(Catalogue.standard.stats(.car).speed == 2 * Catalogue.standard.stats(.worker).speed)
    }

    @Test func everyOpponentsUnitWithinElevenTilesDiesAndTheCarCannotBeHarmed() {
        var sim = duel()
        #expect(sim.apply(.summonCar, from: me) == .accepted)
        let car = sim.people(me, .car)[0]
        let at = sim.living(car).position
        let near = sim.add(.cannon, them, at.x + 10.5, at.y)          // inside 11 tiles
        let far = sim.add(.clubman, them, at.x + 14, at.y)            // outside
        let mine = sim.add(.clubman, me, at.x + 2, at.y)              // the player's own
        let archer = sim.add(.archer, them, at.x + 12.5, at.y)
        sim.step()
        #expect(sim.entity(near) == nil)
        #expect(sim.entity(far) != nil && sim.entity(mine) != nil)
        // The archer may not target the car, nor harm it.
        #expect(sim.apply(.attack(units: [archer], target: car), from: them) != .accepted)
        #expect(!sim.canStrike(them, sim.index(of: car)!))
        #expect(sim.view(for: me).events.contains(.destroyed(near)))
    }

    @Test func theCarKeepsNobodyInTheMatch() {
        var sim = Simulation(setup: setup(openMap(starts: [GridPoint(2, 2), GridPoint(34, 34), GridPoint(2, 34)]),
                                          teams: [0, 1, 0]))
        #expect(sim.apply(.summonCar, from: me) == .accepted)
        let car = sim.people(me, .car)[0]
        // Everything else of the player's is destroyed: a founder comes, the car stays.
        for i in sim.entities.indices where sim.entities[i].owner == me && sim.entities[i].id != car { sim.kill(i) }
        sim.step()
        #expect(sim.entity(car) != nil)
        #expect(sim.people(me, .founder).count == 1)
    }
}
