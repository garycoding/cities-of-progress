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
    /// The radius in tiles within which a blow also harms the target's
    /// neighbours (the catapult's stone); `nil` for a blow that harms the target
    /// alone. Optional so that saves made before it existed still open.
    public var area: Double?

    public init(damage: Int, range: Double, interval: Int, area: Double? = nil) {
        self.damage = damage; self.range = range; self.interval = interval; self.area = area
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
    /// Workers take this many times as much from a site in the same time
    /// (herding excepted); the effects of several improvements multiply.
    public var gatheringMultiplier: Double
    /// Added to the damage of each blow a warfighter strikes.
    public var warfighterDamage: Int
    /// Added to the armour of each warfighter.
    public var warfighterArmour: Int
    /// A farm yields this many times as much; optional so that older saves open.
    public var farmingMultiplier: Double?

    public init(improvement: Improvement, age: Age, cost: ResourceAmounts, work: Int,
                gatheringMultiplier: Double = 1, warfighterDamage: Int = 0, warfighterArmour: Int = 0,
                farmingMultiplier: Double? = nil) {
        self.improvement = improvement; self.age = age; self.cost = cost; self.work = work
        self.gatheringMultiplier = gatheringMultiplier; self.warfighterDamage = warfighterDamage
        self.warfighterArmour = warfighterArmour; self.farmingMultiplier = farmingMultiplier
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

/// Gathering rates and loads. Tables are arrays indexed by `SiteKind.rawValue`,
/// not dictionaries, so that they encode identically in every process.
public struct GatheringStats: Hashable, Codable, Sendable {
    /// Units of the resource a worker takes from a site per second, by site kind.
    public var perSecondBySite: [Double]
    /// Food per second a worker earns tending a stock pen (herds, Bronze age).
    public var herdingPerSecond: Double
    /// Food per second a worker earns tending a farm (Iron age), before the
    /// plough; optional so that older saves open, and then no farm yields.
    public var farmingPerSecond: Double?
    /// How much a worker carries before returning to deliver it.
    public var load: Int
    /// What each kind of site holds when the map is made, by site kind.
    public var amountBySite: [Int]

    public init(perSecond: [SiteKind: Double], herdingPerSecond: Double, farmingPerSecond: Double? = nil, load: Int,
                siteAmount: [SiteKind: Int]) {
        perSecondBySite = SiteKind.allCases.map { perSecond[$0] ?? 0 }
        amountBySite = SiteKind.allCases.map { siteAmount[$0] ?? 0 }
        self.herdingPerSecond = herdingPerSecond; self.farmingPerSecond = farmingPerSecond; self.load = load
    }

    public func perSecond(_ kind: SiteKind) -> Double { perSecondBySite[kind.rawValue] }
    public func amount(_ kind: SiteKind) -> Int { amountBySite[kind.rawValue] }
}

/// A damage multiplier when one kind strikes another.
public struct Bonus: Hashable, Codable, Sendable {
    public var attacker: UnitKind
    public var defender: UnitKind
    public var multiplier: Double
    public init(_ attacker: UnitKind, against defender: UnitKind, _ multiplier: Double) {
        self.attacker = attacker; self.defender = defender; self.multiplier = multiplier
    }
}

/// Paying to turn warfighters of one kind into the kind a later age brings
/// (requirement 17). Done at a building that trains the new kind.
public struct UpgradeStats: Hashable, Codable, Sendable {
    public var from: UnitKind
    public var to: UnitKind
    /// Per warfighter upgraded.
    public var cost: ResourceAmounts
    public var time: Int
    public init(from: UnitKind, to: UnitKind, cost: ResourceAmounts, time: Int) {
        self.from = from; self.to = to; self.cost = cost; self.time = time
    }
}

/// All the tables of the game.
public struct Catalogue: Hashable, Codable, Sendable {
    public var units: [UnitStats]
    public var buildings: [BuildingStats]
    public var improvements: [ImprovementStats]
    public var advances: [AdvanceStats]
    public var gathering: GatheringStats
    /// Damage multipliers; 1 where none is listed.
    public var bonuses: [Bonus]
    public var upgrades: [UpgradeStats]
    /// What every player holds at the start of a match.
    public var startingResources: ResourceAmounts
    /// People each player begins with, beside the town centre: one engineer,
    /// so that a house can always be built, and the rest workers.
    public var startingPeople: Int
    /// The population limit can never exceed this, however many houses stand.
    public var populationMaximum: Int
    /// People that come with a town centre built by a founder: one engineer,
    /// so that a house can be built, and the rest workers (requirement 26).
    public var founderPeople: Int

    public init(units: [UnitStats], buildings: [BuildingStats], improvements: [ImprovementStats],
                advances: [AdvanceStats], gathering: GatheringStats, bonuses: [Bonus], upgrades: [UpgradeStats],
                startingResources: ResourceAmounts, startingPeople: Int, populationMaximum: Int, founderPeople: Int) {
        self.units = units; self.buildings = buildings; self.improvements = improvements; self.advances = advances
        self.gathering = gathering; self.bonuses = bonuses; self.upgrades = upgrades
        self.startingResources = startingResources; self.startingPeople = startingPeople
        self.populationMaximum = populationMaximum; self.founderPeople = founderPeople
    }

    public func stats(_ kind: UnitKind) -> UnitStats { units.first { $0.kind == kind }! }
    public func stats(_ kind: BuildingKind) -> BuildingStats { buildings.first { $0.kind == kind }! }
    public func stats(_ improvement: Improvement) -> ImprovementStats { improvements.first { $0.improvement == improvement }! }
    public func advance(from age: Age) -> AdvanceStats? { advances.first { $0.from == age } }

    /// The last age a player can reach with these tables: the interface offers
    /// nothing of a later age, whose units and buildings may be listed before
    /// the rules that bring them are built.
    public var lastAge: Age {
        var age = Age.stone
        while advance(from: age) != nil, let next = Age(rawValue: age.rawValue + 1) { age = next }
        return age
    }

    /// The damage multiplier when `attacker` strikes `defender`.
    public func bonus(_ attacker: UnitKind, against defender: UnitKind) -> Double {
        bonuses.first { $0.attacker == attacker && $0.defender == defender }?.multiplier ?? 1
    }

    /// The upgrade available for a kind, if any.
    public func upgrade(from kind: UnitKind) -> UpgradeStats? { upgrades.first { $0.from == kind } }

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
            // The Iron age's warfighters. Their figures are provisional until the Iron age's rules are built.
            UnitStats(kind: .swordsman, age: .iron, cost: cost([.food: 60, .iron: 25]), trainTime: s(14), health: 70, armour: 2,
                      speed: 1.0, sight: 5, attack: Attack(damage: 7, range: 1, interval: s(1.5)), trainedAt: [.barracks]),
            UnitStats(kind: .horseman, age: .iron, cost: cost([.food: 80, .iron: 20]), trainTime: s(18), health: 90, armour: 1,
                      speed: 2.2, sight: 7, attack: Attack(damage: 7, range: 1, interval: s(1.4)), trainedAt: [.stable],
                      population: 2),
            UnitStats(kind: .catapult, age: .iron, cost: cost([.wood: 150, .iron: 40]), trainTime: s(30), health: 120, armour: 1,
                      speed: 0.6, sight: 8, attack: Attack(damage: 20, range: 9, interval: s(5), area: 1.5), trainedAt: [.siegeWorkshop],
                      population: 3),
        ]
        let allStone: [Resource] = [.food, .wood, .stone, .bronze, .gold, .iron]
        let buildings: [BuildingStats] = [
            BuildingStats(kind: .townCentre, age: .stone, cost: cost([.wood: 200, .stone: 100]), buildTime: s(120), health: 1200,
                          armour: 2, footprint: GridPoint(3, 3), sight: 8, attack: Attack(damage: 3, range: 6, interval: s(2)),
                          housing: 5, accepts: allStone, trains: [.worker, .scholar, .engineer, .merchant, .clubman, .slinger],
                          researches: [.betterTools, .ironTools]),
            BuildingStats(kind: .house, age: .stone, cost: cost([.wood: 30]), buildTime: s(20), health: 200, armour: 0,
                          footprint: GridPoint(2, 2), sight: 3, housing: 5),
            BuildingStats(kind: .storagePit, age: .stone, cost: cost([.wood: 50]), buildTime: s(25), health: 300, armour: 0,
                          footprint: GridPoint(2, 2), sight: 3, accepts: [.wood, .stone, .bronze, .gold, .iron]),
            BuildingStats(kind: .stockPen, age: .bronze, cost: cost([.wood: 60]), buildTime: s(25), health: 250, armour: 0,
                          footprint: GridPoint(3, 3), sight: 3, accepts: [.food]),
            BuildingStats(kind: .barracks, age: .bronze, cost: cost([.wood: 100]), buildTime: s(40), health: 500, armour: 1,
                          footprint: GridPoint(3, 3), sight: 4, trains: [.clubman, .slinger, .spearman, .archer, .chariot, .swordsman],
                          researches: [.bronzeWeapons, .shields, .ironWeapons, .mail]),
            BuildingStats(kind: .watchTower, age: .bronze, cost: cost([.stone: 80, .wood: 20]), buildTime: s(40), health: 400,
                          armour: 2, footprint: GridPoint(1, 1), sight: 9, attack: Attack(damage: 4, range: 7, interval: s(2))),
            BuildingStats(kind: .palisade, age: .bronze, cost: cost([.wood: 3]), buildTime: s(4), health: 150, armour: 1,
                          footprint: GridPoint(1, 1), sight: 1),
            // The Iron age's buildings. Their figures are provisional until the Iron age's rules are built.
            BuildingStats(kind: .farm, age: .iron, cost: cost([.wood: 60]), buildTime: s(20), health: 150, armour: 0,
                          footprint: GridPoint(3, 3), sight: 2, researches: [.plough]),
            BuildingStats(kind: .stable, age: .iron, cost: cost([.wood: 120]), buildTime: s(45), health: 500, armour: 1,
                          footprint: GridPoint(3, 3), sight: 4, trains: [.horseman]),
            BuildingStats(kind: .siegeWorkshop, age: .iron, cost: cost([.wood: 150, .stone: 50]), buildTime: s(50), health: 600,
                          armour: 1, footprint: GridPoint(3, 3), sight: 4, trains: [.catapult]),
            BuildingStats(kind: .stoneWall, age: .iron, cost: cost([.stone: 5]), buildTime: s(6), health: 400, armour: 3,
                          footprint: GridPoint(1, 1), sight: 1),
        ]
        let improvements: [ImprovementStats] = [
            ImprovementStats(improvement: .betterTools, age: .stone, cost: cost([.food: 80, .wood: 60]), work: s(40),
                             gatheringMultiplier: 1.2),
            ImprovementStats(improvement: .bronzeWeapons, age: .bronze, cost: cost([.food: 100, .bronze: 60]), work: s(60),
                             warfighterDamage: 1),
            ImprovementStats(improvement: .shields, age: .bronze, cost: cost([.wood: 80, .bronze: 40]), work: s(60),
                             warfighterArmour: 1),
            ImprovementStats(improvement: .ironTools, age: .iron, cost: cost([.food: 150, .iron: 80]), work: s(70),
                             gatheringMultiplier: 1.2),
            ImprovementStats(improvement: .ironWeapons, age: .iron, cost: cost([.food: 150, .iron: 100]), work: s(80),
                             warfighterDamage: 2),
            ImprovementStats(improvement: .mail, age: .iron, cost: cost([.gold: 60, .iron: 100]), work: s(80),
                             warfighterArmour: 1),
            ImprovementStats(improvement: .plough, age: .iron, cost: cost([.wood: 120, .iron: 60]), work: s(60),
                             farmingMultiplier: 1.25),
        ]
        let advances: [AdvanceStats] = [
            AdvanceStats(from: .stone, cost: cost([.food: 300, .wood: 100]), study: s(4 * 90)),
            AdvanceStats(from: .bronze, cost: cost([.food: 500, .bronze: 150, .gold: 100]), study: s(4 * 150)),
        ]
        let gathering = GatheringStats(
            perSecond: [.tree: 0.6, .prey: 0.8, .stone: 0.5, .copper: 0.4, .tin: 0.4, .gold: 0.4, .iron: 0.4, .oilField: 0],
            herdingPerSecond: 0.7,
            farmingPerSecond: 0.9,
            load: 10,
            siteAmount: [.tree: 100, .prey: 150, .stone: 300, .copper: 400, .tin: 250, .gold: 400, .iron: 500, .oilField: 2000]
        )
        let bonuses: [Bonus] = [
            Bonus(.spearman, against: .chariot, 3),
            Bonus(.chariot, against: .archer, 2), Bonus(.chariot, against: .slinger, 2),
            Bonus(.archer, against: .spearman, 1.5), Bonus(.archer, against: .clubman, 1.5),
            Bonus(.clubman, against: .slinger, 1.5),
            Bonus(.swordsman, against: .spearman, 1.5), Bonus(.swordsman, against: .clubman, 1.5),
            Bonus(.horseman, against: .archer, 2), Bonus(.horseman, against: .slinger, 2), Bonus(.horseman, against: .catapult, 3),
            Bonus(.spearman, against: .horseman, 3),
            Bonus(.archer, against: .swordsman, 1.5),
        ]
        let upgrades: [UpgradeStats] = [
            UpgradeStats(from: .clubman, to: .spearman, cost: cost([.food: 20, .bronze: 15]), time: s(6)),
            UpgradeStats(from: .slinger, to: .archer, cost: cost([.wood: 20, .gold: 15]), time: s(6)),
            UpgradeStats(from: .spearman, to: .swordsman, cost: cost([.food: 20, .iron: 20]), time: s(6)),
            UpgradeStats(from: .chariot, to: .horseman, cost: cost([.food: 30, .iron: 15]), time: s(8)),
        ]
        return Catalogue(units: units, buildings: buildings, improvements: improvements, advances: advances,
                         gathering: gathering, bonuses: bonuses, upgrades: upgrades,
                         startingResources: cost([.food: 200, .wood: 200, .stone: 50]),
                         startingPeople: 3, populationMaximum: 200, founderPeople: 6)
    }()
}
