// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

// The tables of the game: what everything costs, how strong it is, and how long
// it takes. The simulation, the interface and the computer player all read these
// values, so they live here. They are first estimates, to be tuned by play;
// every duration is in ticks (see `Tick`).

/// How a person attacks.
public struct Attack: Hashable, Codable, Sendable {
    /// Harm per blow, before armour.
    public var damage: Int
    /// Reach in tiles; 1 or less is a melee attack.
    public var range: Double
    /// Ticks between blows.
    public var interval: Int

    public init(damage: Int, range: Double, interval: Int) {
        self.damage = damage; self.range = range; self.interval = interval
    }
}

public struct UnitStats: Hashable, Codable, Sendable {
    public var kind: UnitKind
    /// The age in which the kind can first be trained.
    public var age: Age
    public var cost: ResourceAmounts
    public var trainTime: Int
    public var health: Int
    public var armour: Int
    /// Tiles per second.
    public var speed: Double
    /// Tiles within which it sees.
    public var sight: Double
    public var attack: Attack?
    /// The building kinds at which it is trained.
    public var trainedAt: [BuildingKind]
    /// How many places it takes under the population limit.
    public var population: Int

    public init(kind: UnitKind, age: Age, cost: ResourceAmounts, trainTime: Int, health: Int, armour: Int,
                speed: Double, sight: Double, attack: Attack?, trainedAt: [BuildingKind], population: Int = 1) {
        self.kind = kind; self.age = age; self.cost = cost; self.trainTime = trainTime; self.health = health
        self.armour = armour; self.speed = speed; self.sight = sight; self.attack = attack
        self.trainedAt = trainedAt; self.population = population
    }
}

public struct BuildingStats: Hashable, Codable, Sendable {
    public var kind: BuildingKind
    public var age: Age
    public var cost: ResourceAmounts
    /// Ticks of one engineer's work to construct it; more engineers finish sooner.
    public var buildTime: Int
    public var health: Int
    public var armour: Int
    /// The tiles it covers, from its origin tile toward +x and +y.
    public var footprint: GridPoint
    public var sight: Double
    /// Towers and the town centre shoot at opponents in range.
    public var attack: Attack?
    /// Population places it provides.
    public var housing: Int
    /// Resources that workers may deliver here.
    public var accepts: [Resource]
    /// What may be trained here.
    public var trains: [UnitKind]
    /// What may be researched here.
    public var researches: [Improvement]

    public init(kind: BuildingKind, age: Age, cost: ResourceAmounts, buildTime: Int, health: Int, armour: Int,
                footprint: GridPoint, sight: Double, attack: Attack? = nil, housing: Int = 0,
                accepts: [Resource] = [], trains: [UnitKind] = [], researches: [Improvement] = []) {
        self.kind = kind; self.age = age; self.cost = cost; self.buildTime = buildTime; self.health = health
        self.armour = armour; self.footprint = footprint; self.sight = sight; self.attack = attack
        self.housing = housing; self.accepts = accepts; self.trains = trains; self.researches = researches
    }
}

public struct ImprovementStats: Hashable, Codable, Sendable {
    public var improvement: Improvement
    public var age: Age
    public var cost: ResourceAmounts
    /// Scholar-ticks of work: one scholar takes this many ticks, two take half.
    public var work: Int

    public init(improvement: Improvement, age: Age, cost: ResourceAmounts, work: Int) {
        self.improvement = improvement; self.age = age; self.cost = cost; self.work = work
    }
}

/// What it takes to leave an age for the next (requirement 16).
public struct AdvanceStats: Hashable, Codable, Sendable {
    public var from: Age
    /// Paid when the advance is completed.
    public var cost: ResourceAmounts
    /// Scholar-ticks of study needed: progress accumulates whilst scholars work at
    /// a town centre, one point per scholar per tick.
    public var study: Int

    public init(from: Age, cost: ResourceAmounts, study: Int) {
        self.from = from; self.cost = cost; self.study = study
    }
}

/// Gathering rates and loads.
public struct GatheringStats: Hashable, Codable, Sendable {
    /// Units of the resource a worker takes from a site per second.
    public var perSecond: [SiteKind: Double]
    /// Food per second a worker earns tending a stock pen (herds, Bronze age).
    public var herdingPerSecond: Double
    /// How much a worker carries before returning to deliver it.
    public var load: Int
    /// What each kind of site holds when the map is made.
    public var siteAmount: [SiteKind: Int]

    public init(perSecond: [SiteKind: Double], herdingPerSecond: Double, load: Int, siteAmount: [SiteKind: Int]) {
        self.perSecond = perSecond; self.herdingPerSecond = herdingPerSecond; self.load = load; self.siteAmount = siteAmount
    }
}

/// All the tables of the game.
public struct Catalogue: Hashable, Codable, Sendable {
    public var units: [UnitStats]
    public var buildings: [BuildingStats]
    public var improvements: [ImprovementStats]
    public var advances: [AdvanceStats]
    public var gathering: GatheringStats
    /// Damage multipliers: `bonuses[attacker]?[defender]`, 1 where absent.
    public var bonuses: [UnitKind: [UnitKind: Double]]
    /// What every player holds at the start of a match.
    public var startingResources: ResourceAmounts
    /// Workers each player begins with, beside the town centre.
    public var startingWorkers: Int
    /// The population limit can never exceed this, however many houses stand.
    public var populationMaximum: Int

    public init(units: [UnitStats], buildings: [BuildingStats], improvements: [ImprovementStats],
                advances: [AdvanceStats], gathering: GatheringStats, bonuses: [UnitKind: [UnitKind: Double]],
                startingResources: ResourceAmounts, startingWorkers: Int, populationMaximum: Int) {
        self.units = units; self.buildings = buildings; self.improvements = improvements; self.advances = advances
        self.gathering = gathering; self.bonuses = bonuses; self.startingResources = startingResources
        self.startingWorkers = startingWorkers; self.populationMaximum = populationMaximum
    }

    public func stats(_ kind: UnitKind) -> UnitStats { units.first { $0.kind == kind }! }
    public func stats(_ kind: BuildingKind) -> BuildingStats { buildings.first { $0.kind == kind }! }
    public func stats(_ improvement: Improvement) -> ImprovementStats { improvements.first { $0.improvement == improvement }! }
    public func advance(from age: Age) -> AdvanceStats? { advances.first { $0.from == age } }

    /// The damage multiplier when `attacker` strikes `defender`.
    public func bonus(_ attacker: UnitKind, against defender: UnitKind) -> Double {
        bonuses[attacker]?[defender] ?? 1
    }

    /// The tables of the first milestone: the Stone and Bronze ages.
    public static let standard: Catalogue = {
        func cost(_ pairs: [Resource: Int]) -> ResourceAmounts { ResourceAmounts(pairs) }
        let s = Tick.seconds
        let units: [UnitStats] = [
            UnitStats(kind: .worker, age: .stone, cost: cost([.food: 50]), trainTime: s(12), health: 25, armour: 0,
                      speed: 1.0, sight: 4, attack: Attack(damage: 3, range: 1, interval: s(1.5)), trainedAt: [.townCentre]),
            UnitStats(kind: .scholar, age: .stone, cost: cost([.food: 60]), trainTime: s(15), health: 20, armour: 0,
                      speed: 0.9, sight: 4, attack: nil, trainedAt: [.townCentre]),
            UnitStats(kind: .engineer, age: .stone, cost: cost([.food: 50, .wood: 10]), trainTime: s(12), health: 25, armour: 0,
                      speed: 1.0, sight: 4, attack: Attack(damage: 2, range: 1, interval: s(1.5)), trainedAt: [.townCentre]),
            UnitStats(kind: .merchant, age: .bronze, cost: cost([.food: 50, .gold: 20]), trainTime: s(15), health: 30, armour: 0,
                      speed: 1.3, sight: 5, attack: nil, trainedAt: [.townCentre]),
            UnitStats(kind: .founder, age: .stone, cost: cost([:]), trainTime: 0, health: 1, armour: 0,
                      speed: 1.2, sight: 5, attack: nil, trainedAt: [], population: 0),
            UnitStats(kind: .clubman, age: .stone, cost: cost([.food: 50, .wood: 10]), trainTime: s(12), health: 40, armour: 0,
                      speed: 1.1, sight: 5, attack: Attack(damage: 4, range: 1, interval: s(1.5)), trainedAt: [.townCentre, .barracks]),
            UnitStats(kind: .slinger, age: .stone, cost: cost([.food: 40, .stone: 15]), trainTime: s(12), health: 28, armour: 0,
                      speed: 1.1, sight: 6, attack: Attack(damage: 3, range: 4, interval: s(2)), trainedAt: [.townCentre, .barracks]),
            UnitStats(kind: .spearman, age: .bronze, cost: cost([.food: 60, .bronze: 20]), trainTime: s(14), health: 55, armour: 1,
                      speed: 1.0, sight: 5, attack: Attack(damage: 5, range: 1, interval: s(1.5)), trainedAt: [.barracks]),
            UnitStats(kind: .archer, age: .bronze, cost: cost([.wood: 40, .gold: 20]), trainTime: s(14), health: 35, armour: 0,
                      speed: 1.1, sight: 7, attack: Attack(damage: 4, range: 6, interval: s(2)), trainedAt: [.barracks]),
            UnitStats(kind: .chariot, age: .bronze, cost: cost([.food: 60, .wood: 60, .bronze: 20]), trainTime: s(20), health: 100,
                      armour: 1, speed: 2.0, sight: 6, attack: Attack(damage: 6, range: 1, interval: s(1.5)), trainedAt: [.barracks],
                      population: 2),
        ]
        let allStone: [Resource] = [.food, .wood, .stone, .bronze, .gold, .iron]
        let buildings: [BuildingStats] = [
            BuildingStats(kind: .townCentre, age: .stone, cost: cost([.wood: 200, .stone: 100]), buildTime: s(120), health: 1200,
                          armour: 2, footprint: GridPoint(3, 3), sight: 8, attack: Attack(damage: 3, range: 6, interval: s(2)),
                          housing: 5, accepts: allStone, trains: [.worker, .scholar, .engineer, .merchant, .clubman, .slinger],
                          researches: [.betterTools]),
            BuildingStats(kind: .house, age: .stone, cost: cost([.wood: 30]), buildTime: s(20), health: 200, armour: 0,
                          footprint: GridPoint(2, 2), sight: 3, housing: 5),
            BuildingStats(kind: .storagePit, age: .stone, cost: cost([.wood: 50]), buildTime: s(25), health: 300, armour: 0,
                          footprint: GridPoint(2, 2), sight: 3, accepts: [.wood, .stone, .bronze, .gold, .iron]),
            BuildingStats(kind: .stockPen, age: .bronze, cost: cost([.wood: 60]), buildTime: s(25), health: 250, armour: 0,
                          footprint: GridPoint(3, 3), sight: 3, accepts: [.food]),
            BuildingStats(kind: .barracks, age: .bronze, cost: cost([.wood: 100]), buildTime: s(40), health: 500, armour: 1,
                          footprint: GridPoint(3, 3), sight: 4, trains: [.clubman, .slinger, .spearman, .archer, .chariot],
                          researches: [.bronzeWeapons, .shields]),
            BuildingStats(kind: .watchTower, age: .bronze, cost: cost([.stone: 80, .wood: 20]), buildTime: s(40), health: 400,
                          armour: 2, footprint: GridPoint(1, 1), sight: 9, attack: Attack(damage: 4, range: 7, interval: s(2))),
            BuildingStats(kind: .palisade, age: .bronze, cost: cost([.wood: 3]), buildTime: s(4), health: 150, armour: 1,
                          footprint: GridPoint(1, 1), sight: 1),
        ]
        let improvements: [ImprovementStats] = [
            ImprovementStats(improvement: .betterTools, age: .stone, cost: cost([.food: 80, .wood: 60]), work: s(40)),
            ImprovementStats(improvement: .bronzeWeapons, age: .bronze, cost: cost([.food: 100, .bronze: 60]), work: s(60)),
            ImprovementStats(improvement: .shields, age: .bronze, cost: cost([.wood: 80, .bronze: 40]), work: s(60)),
        ]
        let advances: [AdvanceStats] = [
            AdvanceStats(from: .stone, cost: cost([.food: 300, .wood: 100]), study: s(4 * 90)),
        ]
        let gathering = GatheringStats(
            perSecond: [.tree: 0.6, .prey: 0.8, .stone: 0.5, .copper: 0.4, .tin: 0.4, .gold: 0.4, .iron: 0.4, .oilField: 0],
            herdingPerSecond: 0.7,
            load: 10,
            siteAmount: [.tree: 100, .prey: 150, .stone: 300, .copper: 400, .tin: 250, .gold: 400, .iron: 500, .oilField: 2000]
        )
        let bonuses: [UnitKind: [UnitKind: Double]] = [
            .spearman: [.chariot: 3],
            .chariot: [.archer: 2, .slinger: 2],
            .archer: [.spearman: 1.5, .clubman: 1.5],
            .clubman: [.slinger: 1.5],
        ]
        return Catalogue(units: units, buildings: buildings, improvements: improvements, advances: advances,
                         gathering: gathering, bonuses: bonuses,
                         startingResources: cost([.food: 200, .wood: 200, .stone: 50]),
                         startingWorkers: 3, populationMaximum: 100)
    }()
}
