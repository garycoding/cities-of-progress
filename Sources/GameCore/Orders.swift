// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Everything a player, human or computer, can tell the game to do. A human's
/// clicks and a computer player's decisions become the same orders, so that
/// both play by the same rules (requirement 22). Orders cross the network
/// unchanged in a later milestone, so they are Codable.
public enum Order: Hashable, Codable, Sendable {
    /// Walk to a point.
    case move(units: [EntityID], to: MapPosition)
    /// Workers gather at a site: fell a tree, hunt prey, or mine a deposit.
    case gather(units: [EntityID], site: SiteID)
    /// Work at a building: workers tend a stock pen; scholars study at a town
    /// centre (progress toward the next age) or research where research is under
    /// way; engineers finish or repair it.
    case work(units: [EntityID], at: EntityID)
    /// Engineers construct a new building with its footprint's origin at `at`.
    case construct(engineers: [EntityID], building: BuildingKind, at: GridPoint)
    /// Attack a person or building that is not an ally's.
    case attack(units: [EntityID], target: EntityID)
    /// Queue a person for training at a building.
    case train(at: EntityID, unit: UnitKind)
    /// Remove the last person from a building's queue, refunding its cost.
    case cancelTraining(at: EntityID)
    /// Begin researching an improvement at a building; scholars working there
    /// carry it out.
    case research(at: EntityID, improvement: Improvement)
    /// Advance to the next age, once the scholars' study is complete; this pays
    /// the advance's cost (requirement 16).
    case advanceAge
    /// A founder builds a new town centre, free of cost, at `at` (requirement 26).
    case found(founder: EntityID, at: GridPoint)
    /// Stop whatever the units are doing.
    case stop(units: [EntityID])
}

/// Why an order was refused. The interface shows it to the player.
public enum OrderRefusal: Hashable, Codable, Sendable, CustomStringConvertible {
    /// The player lacks these resources.
    case notEnough(ResourceAmounts)
    /// The player has not reached the age the order needs.
    case ageNotReached(Age)
    /// The population limit is reached.
    case populationLimit
    /// Not every entity named belongs to the player, or none of them can carry it out.
    case notYours
    /// The target cannot be acted on in this way.
    case invalidTarget
    /// The building cannot stand there.
    case placementBlocked
    /// Allies cannot attack one another (requirement 6), and founders cannot attack.
    case cannotAttack
    /// The scholars' study is not yet complete.
    case studyIncomplete
    /// The match is over or paused.
    case notNow

    public var description: String {
        switch self {
        case .notEnough(let short): "Not enough: \(short)"
        case .ageNotReached(let age): "Needs the \(age.name) age"
        case .populationLimit: "Population limit reached; build a house"
        case .notYours: "Not yours to order"
        case .invalidTarget: "Cannot do that there"
        case .placementBlocked: "Cannot build there"
        case .cannotAttack: "Cannot attack that"
        case .studyIncomplete: "The scholars have not finished their study"
        case .notNow: "Not now"
        }
    }
}

public enum OrderResult: Hashable, Codable, Sendable {
    case accepted
    case refused(OrderRefusal)

    public var isAccepted: Bool { self == .accepted }
}
