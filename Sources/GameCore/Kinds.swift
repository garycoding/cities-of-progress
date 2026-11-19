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

    public var sector: Sector? {
        switch self {
        case .worker: .workers
        case .scholar: .scholars
        case .engineer: .engineers
        case .merchant: .merchants
        case .founder: nil
        case .clubman, .slinger, .spearman, .archer, .chariot, .swordsman, .horseman, .catapult: .warfighters
        }
    }

    public var isWarfighter: Bool { sector == .warfighters }

    /// The name of this kind at the owner's age, for the interface.
    public func stageName(at age: Age) -> String {
        switch self {
        case .worker: age >= .iron ? "Farmer" : age >= .bronze ? "Herder" : "Hunter"
        case .scholar: age >= .iron ? "Philosopher" : age >= .bronze ? "Scribe" : "Elder"
        case .engineer: age >= .iron ? "Siege engineer" : age >= .bronze ? "Mason" : "Builder"
        case .merchant: age >= .iron ? "Caravan trader" : "Trader"
        case .founder: "Founder"
        case .clubman: "Clubman"
        case .slinger: "Slinger"
        case .spearman: "Spearman"
        case .archer: "Archer"
        case .chariot: "Chariot"
        case .swordsman: "Swordsman"
        case .horseman: "Horseman"
        case .catapult: "Catapult"
        }
    }
}

/// The kinds of building of the Stone and Bronze ages (docs/requirements.md,
/// "Buildings and ages"). Later milestones add cases.
public enum BuildingKind: Int, CaseIterable, Codable, Sendable, Hashable {
    case townCentre, house, storagePit
    case stockPen, barracks, watchTower, palisade
    case farm, stable, siegeWorkshop, stoneWall

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
}

/// Which way a person faces on the screen. Artwork is drawn facing right; the
/// drawing mirrors it for left (docs/architecture.md, "Sprites").
public enum Facing: Int, Codable, Sendable, Hashable {
    case right, left
}
