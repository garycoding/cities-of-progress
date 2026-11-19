// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import Testing
@testable import GameCore

private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
    try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
}

@Test func valuesEncodeAndDecodeToThemselves() throws {
    #expect(try roundTrip(Samples.map()) == Samples.map())
    #expect(try roundTrip(Samples.stoneAgeOpening()) == Samples.stoneAgeOpening())
    #expect(try roundTrip(Samples.bronzeAgeSkirmish()) == Samples.bronzeAgeSkirmish())
    #expect(try roundTrip(Samples.twoPlayerSetup()) == Samples.twoPlayerSetup())
    #expect(try roundTrip(Catalogue.standard) == Catalogue.standard)
    let orders: [Order] = [
        .move(units: [EntityID(1)], to: MapPosition(x: 1, y: 2)), .gather(units: [EntityID(2)], site: SiteID(3)),
        .work(units: [EntityID(4)], at: EntityID(1)), .construct(engineers: [EntityID(5)], building: .house, at: GridPoint(3, 4)),
        .attack(units: [EntityID(6)], target: EntityID(9)), .train(at: EntityID(1), unit: .worker),
        .cancelTraining(at: EntityID(1)), .research(at: EntityID(1), improvement: .betterTools), .advanceAge,
        .found(founder: EntityID(7), at: GridPoint(1, 1)), .stop(units: [EntityID(1)]),
    ]
    #expect(try roundTrip(orders) == orders)
    #expect(try roundTrip(OrderResult.refused(.notEnough(ResourceAmounts([.wood: 20])))) == .refused(.notEnough(ResourceAmounts([.wood: 20]))))
}

@Test func catalogueHoldsEveryKindOfTheFirstMilestone() {
    let c = Catalogue.standard
    for kind in UnitKind.allCases { #expect(c.units.filter { $0.kind == kind }.count == 1, "\(kind)") }
    for kind in BuildingKind.allCases { #expect(c.buildings.filter { $0.kind == kind }.count == 1, "\(kind)") }
    for i in Improvement.allCases { #expect(c.improvements.filter { $0.improvement == i }.count == 1, "\(i)") }
    #expect(c.advance(from: .stone) != nil)
    // The requirements' table for the two ages.
    #expect(c.stats(.clubman).age == .stone && c.stats(.slinger).age == .stone)
    #expect([UnitKind.spearman, .archer, .chariot].allSatisfy { c.stats($0).age == .bronze })
    #expect([BuildingKind.townCentre, .house, .storagePit].allSatisfy { c.stats($0).age == .stone })
    #expect([BuildingKind.stockPen, .barracks, .watchTower, .palisade].allSatisfy { c.stats($0).age == .bronze })
    #expect(c.stats(.merchant).age == .bronze)
    #expect(c.stats(.founder).attack == nil && c.stats(.founder).trainedAt.isEmpty)
    // Everything trainable is trained somewhere that trains it.
    for stats in c.units where !stats.trainedAt.isEmpty {
        for building in stats.trainedAt { #expect(c.stats(building).trains.contains(stats.kind), "\(stats.kind) at \(building)") }
    }
    // Nothing costs a resource before that resource's age.
    for stats in c.units { for r in Resource.allCases where stats.cost[r] > 0 { #expect(r.firstAge <= stats.age, "\(stats.kind)") } }
    for stats in c.buildings { for r in Resource.allCases where stats.cost[r] > 0 { #expect(r.firstAge <= stats.age, "\(stats.kind)") } }
}

@Test func resourcesAndSitesAppearInTheirAges() {
    #expect(Resource.allCases.filter { $0.firstAge == .stone } == [.food, .wood, .stone])
    #expect(Resource.allCases.filter { $0.firstAge == .bronze } == [.bronze, .gold])
    #expect(SiteKind.copper.yield == .bronze && SiteKind.tin.yield == .bronze)
    #expect(SiteKind.copper.firstAge == .bronze && SiteKind.oilField.firstAge == .industrial)
    #expect(Samples.stoneAgeOpening().shownResources == [.food, .wood, .stone])
    #expect(Samples.stoneAgeOpening().sites.allSatisfy { $0.kind.firstAge == .stone })
}

@Test func generatorIsSeededAndStable() {
    var a = SeededGenerator(seed: 42), b = SeededGenerator(seed: 42), c = SeededGenerator(seed: 43)
    let xs = (0..<5).map { _ in a.next() }
    #expect(xs == (0..<5).map { _ in b.next() })
    #expect(xs != (0..<5).map { _ in c.next() })
    // A fixed value, so that a change of algorithm is noticed: saved matches depend on it.
    var d = SeededGenerator(seed: 1)
    #expect(d.next() == 0xB3F2_AF6D_0FC7_10C5)
    var sum = StableChecksum(); sum.add("cities")
    #expect(sum.value == 0x3F72_BDA1_17A8_8752)
}

@Test func projectionRoundTrips() {
    for p in [MapPosition(x: 0, y: 0), MapPosition(x: 3.5, y: 7.25), MapPosition(x: 31, y: 2)] {
        let back = Projection.map(Projection.screen(p))
        #expect(abs(back.x - p.x) < 1e-9 && abs(back.y - p.y) < 1e-9)
    }
    #expect(Projection.screen(MapPosition(x: 1, y: 0)).x > 0)   // +x toward the lower right
    #expect(Projection.screen(MapPosition(x: 0, y: 1)).x < 0)   // +y toward the lower left
    #expect(Projection.screen(MapPosition(x: 1, y: 1)).y < 0)   // both downward
}

@Test func spriteChecklistCoversTheFirstMilestone() {
    let keys = SpriteKey.required(through: .bronze)
    #expect(Set(keys).count == keys.count)
    for kind in BuildingKind.allCases { #expect(keys.contains(SpriteKey(.building(kind, .bronze), .complete))) }
    #expect(keys.contains(SpriteKey(.unit(.worker, .stone), .working)))
    #expect(keys.contains(SpriteKey(.unit(.worker, .bronze), .working)))
    #expect(!keys.contains(SpriteKey(.unit(.scholar, .stone), .fighting)))
    #expect(keys.contains(SpriteKey(.site(.copper), .complete)))
    #expect(!keys.contains(SpriteKey(.site(.iron), .complete)))
}

@MainActor @Test func sessionKeepsRefusalsAndDropsVanishedSelection() {
    let session = PlayerSession(view: Samples.bronzeAgeSkirmish(), catalogue: .standard,
                                camera: Camera(centre: MapPosition(x: 10, y: 10))) { _ in .refused(.populationLimit) }
    session.selection = [EntityID(1), EntityID(999)]
    session.update(Samples.bronzeAgeSkirmish())
    #expect(session.selection == [EntityID(1)])
    #expect(session.issue(.advanceAge) == .refused(.populationLimit))
    #expect(session.lastRefusal == .populationLimit)
}

@Test func samplesAreConsistent() {
    for view in [Samples.stoneAgeOpening(), Samples.bronzeAgeSkirmish()] {
        #expect(view.terrain.count == view.mapWidth * view.mapHeight)
        #expect(view.visibility.count == view.terrain.count)
        #expect(view.entities.map(\.id) == view.entities.map(\.id).sorted())
        #expect(Set(view.entities.map(\.id)).count == view.entities.count)
        #expect(view.sites.allSatisfy { $0.kind.firstAge <= view.age })
    }
    let map = Samples.map()
    #expect(map.starts.count == 2)
    #expect(map.sites.map(\.id) == map.sites.map(\.id).sorted())
}
