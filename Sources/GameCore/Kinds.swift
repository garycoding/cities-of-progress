// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The kinds of person. The four peaceful sectors have one kind each, whose
/// stage (hunter, herder and so on) follows the owner's age and changes at once
/// when the age changes (docs/requirements.md, "Sectors"). Each warfighter is a
/// kind of its own. The first milestone holds the Stone and Bronze ages; later
/// milestones add cases.
public enum UnitKind: Int, CaseIterable, Codable, Sendable, Hashable {
    case worker, scholar, engineer, merchant
    /// Received by a player who has lost everything whilst an ally lives
    /// (requirements 26 and 27). It cannot attack and cannot be killed.
    case founder
    case clubman, slinger
    case spearman, archer, chariot
    case swordsman, horseman, catapult
    case knight, musketeer, cannon
    case rifleman, fieldGun, armouredCar

    public var sector: Sector? {
        switch self {
        case .worker: .workers
        case .scholar: .scholars
        case .engineer: .engineers
        case .merchant: .merchants
        case .founder: nil
        case .clubman, .slinger, .spearman, .archer, .chariot, .swordsman, .horseman, .catapult, .knight, .musketeer, .cannon,
             .rifleman, .fieldGun, .armouredCar:
            .warfighters
        }
    }

    public var isWarfighter: Bool { sector == .warfighters }

    /// The name of this kind at the owner's age, for the interface.
    public func stageName(at age: Age) -> String {
        switch self {
        case .worker: age >= .industrial ? "Factory hand" : age >= .alchemy ? "Craftsman" : age >= .iron ? "Farmer" : age >= .bronze ? "Herder" : "Hunter"
        case .scholar: age >= .industrial ? "Scientist" : age >= .alchemy ? "Alchemist" : age >= .iron ? "Philosopher" : age >= .bronze ? "Scribe" : "Elder"
        case .engineer: age >= .industrial ? "Mechanic" : age >= .alchemy ? "Gunsmith" : age >= .iron ? "Siege engineer" : age >= .bronze ? "Mason" : "Builder"
        case .merchant: age >= .industrial ? "Industrialist" : age >= .alchemy ? "Banker" : age >= .iron ? "Caravan trader" : "Trader"
        case .founder: "Founder"
        case .clubman: "Clubman"
        case .slinger: "Slinger"
        case .spearman: "Spearman"
        case .archer: "Archer"
        case .chariot: "Chariot"
        case .swordsman: "Swordsman"
        case .horseman: "Horseman"
        case .catapult: "Catapult"
        case .knight: "Knight"
        case .musketeer: "Musketeer"
        case .cannon: "Cannon"
        case .rifleman: "Rifleman"
        case .fieldGun: "Field gun"
        case .armouredCar: "Armoured car"
        }
    }
}

/// The kinds of building of the Stone and Bronze ages (docs/requirements.md,
/// "Buildings and ages"). Later milestones add cases.
public enum BuildingKind: Int, CaseIterable, Codable, Sendable, Hashable {
    case townCentre, house, storagePit
    case stockPen, barracks, watchTower, palisade
    case farm, stable, siegeWorkshop, stoneWall
    case castle, alchemistsWorkshop
    case factory, railwayDepot, oilWell

    public var name: String {
        switch self {
        case .townCentre: "Town centre"
        case .house: "House"
        case .storagePit: "Storage pit"
        case .stockPen: "Stock pen"
        case .barracks: "Barracks"
        case .watchTower: "Watch tower"
        case .palisade: "Palisade"
        case .farm: "Farm"
        case .stable: "Stable"
        case .siegeWorkshop: "Siege workshop"
        case .stoneWall: "Stone wall"
        case .castle: "Castle"
        case .alchemistsWorkshop: "Alchemist's workshop"
        case .factory: "Factory"
        case .railwayDepot: "Railway depot"
        case .oilWell: "Oil well"
        }
    }
}

/// Either kind of thing a player owns on the map.
public enum EntityKind: Hashable, Codable, Sendable {
    case unit(UnitKind)
    case building(BuildingKind)
}

/// Improvements that scholars research at buildings. Later milestones add cases.
public enum Improvement: Int, CaseIterable, Codable, Sendable, Hashable {
    /// Workers gather faster.
    case betterTools
    /// Warfighters strike harder.
    case bronzeWeapons
    /// Warfighters take less harm.
    case shields
    /// Workers gather faster again (Iron age).
    case ironTools
    /// Warfighters strike harder again.
    case ironWeapons
    /// Warfighters take less harm again.
    case mail
    /// Farms yield more.
    case plough
    /// Warfighters strike harder (Alchemy age).
    case betterPowder
    /// Warfighters take less harm.
    case plateArmour
    /// Workers gather faster and workshops make more gunpowder.
    case guilds
    /// Merchants' exchanges give more.
    case banking
    /// Workers gather faster and workshops make more (Industrial age).
    case machineTools
    /// Warfighters strike harder.
    case rifling
    /// Warfighters take less harm.
    case steelPlate
    /// Oil wells pump more.
    case refining
}

/// Which way a person faces on the screen. Artwork is drawn facing right; the
/// drawing mirrors it for left (docs/architecture.md, "Sprites").
public enum Facing: Int, Codable, Sendable, Hashable {
    case right, left
}
