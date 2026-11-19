// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore

/// Why a button cannot act now: the refusal the game would give, and a line
/// that says it in particular ("Short of 20 Wood").
public struct Unavailability: Hashable, Sendable {
    public var refusal: OrderRefusal
    public var explanation: String

    public init(_ refusal: OrderRefusal, _ explanation: String) {
        self.refusal = refusal; self.explanation = explanation
    }
}

/// One button of the panels: what it does, what it costs, and whether it can act now.
/// A button that cannot act stays enabled: pressing it shows its refusal
/// (`perform(in:)`), and its tooltip and refusal line say why.
public struct ActionOffer: Identifiable, Hashable, Sendable {
    public enum Section: Int, Hashable, Sendable {
        case train, research, build, upgrade, age

        public var heading: String {
            switch self {
            case .train: "Train"
            case .research: "Research"
            case .build: "Build"
            case .upgrade: "Upgrade"
            case .age: "Advance"
            }
        }
    }

    public enum Action: Hashable, Sendable {
        case train(at: EntityID, unit: UnitKind)
        case place(BuildingKind)
        case research(at: EntityID, improvement: Improvement)
        /// `at` is nil when no building of the player's trains the new kind.
        case upgrade(units: [EntityID], to: UnitKind, at: EntityID?)
        case advanceAge
    }

    public var id: String
    public var section: Section
    public var title: String
    /// A second line: what it is or does.
    public var detail: String
    public var cost: ResourceAmounts
    public var action: Action
    public var unavailable: Unavailability?
    /// The key that does it, without modifiers.
    public var shortcut: Character?
    /// What the button's icon shows, if anything.
    public var icon: EntityKind?
    public var iconSubject: SpriteSubject?

    public var isAvailable: Bool { unavailable == nil }

    /// The order this button issues, or `nil` where it issues none (placing a
    /// building sets `PlayerSession.placing`; an upgrade without a building).
    public var order: Order? {
        switch action {
        case .train(let building, let unit): .train(at: building, unit: unit)
        case .place: nil
        case .research(let building, let improvement): .research(at: building, improvement: improvement)
        case .upgrade(let units, let kind, let building): building.map { .upgrade(units: units, to: kind, at: $0) }
        case .advanceAge: .advanceAge
        }
    }

    public var tooltip: String {
        var text = "\(section.heading) \(title): \(detail.isEmpty ? "" : detail + " ")Cost: \(InterfaceText.cost(cost))."
        if let unavailable { text += " Not now: \(unavailable.explanation)." }
        if let shortcut { text += " Key: \(String(shortcut).uppercased())." }
        return text
    }

    /// Press the button. A button that cannot act sets the session's refusal
    /// and issues nothing; one that places a building chooses it (a second
    /// press chooses nothing again); the rest issue their order.
    @MainActor
    public func perform(in session: PlayerSession) {
        if let unavailable {
            session.lastRefusal = unavailable.refusal
            return
        }
        switch action {
        case .place(let kind): session.placing = (session.placing == kind) ? nil : kind
        default: if let order { session.issue(order) }
        }
    }
}

/// A selected entity, in words.
public struct EntityDetail: Hashable, Sendable {
    public var id: EntityID
    public var kind: EntityKind
    public var name: String
    /// "Sumer, yours", "Egypt, ally" or "Egypt, opponent".
    public var ownerLine: String
    public var health: Int
    public var maxHealth: Int
    public var activity: String
    /// From 0 to 1, for construction, training and research.
    public var progress: Double?

    public var healthFraction: Double { maxHealth > 0 ? InterfaceText.clamp(Double(health) / Double(maxHealth)) : 0 }
}

public struct KindCount: Hashable, Sendable {
    public var kind: EntityKind
    public var name: String
    public var count: Int
}

/// What the selection panel shows for the session's selection, and which
/// actions it offers, each with the reason it is or is not available. Computed
/// from the view and the catalogue alone, so that it is testable without a screen.
public struct PanelModel: Sendable {
    public enum Content: Hashable, Sendable {
        case nothing
        case single(EntityDetail)
        case several(total: Int, counts: [KindCount])
    }

    public var content: Content
    public var train: [ActionOffer] = []
    public var research: [ActionOffer] = []
    public var build: [ActionOffer] = []
    public var upgrade: [ActionOffer] = []
    /// A building the player is placing, for the panel's hint.
    public var placing: BuildingKind?

    public var actions: [ActionOffer] { train + research + build + upgrade }
    public var sections: [(section: ActionOffer.Section, offers: [ActionOffer])] {
        [(.train, train), (.research, research), (.build, build), (.upgrade, upgrade)].filter { !$0.1.isEmpty }
    }

    /// The offer that a key press does, if any.
    public func offer(forKey key: Character) -> ActionOffer? {
        let lower = Character(key.lowercased())
        return actions.first { $0.shortcut == lower }
    }

    @MainActor
    public init(session: PlayerSession) {
        self.init(view: session.view, catalogue: session.catalogue, selection: session.selection, placing: session.placing)
    }

    public init(view: PlayerView, catalogue: Catalogue, selection: [EntityID], placing: BuildingKind? = nil) {
        self.placing = placing
        let selected = selection.compactMap { view.entity($0) }
        func age(of owner: PlayerID) -> Age { view.players.first { $0.id == owner }?.age ?? view.age }

        // The content.
        switch selected.count {
        case 0:
            content = .nothing
        case 1:
            let e = selected[0]
            let ownerAge = age(of: e.owner)
            let (text, progress) = InterfaceText.describe(e.activity, of: e.kind, age: ownerAge)
            let civ = view.players.first { $0.id == e.owner }?.civilization.name ?? "Unknown"
            let relation = e.owner == view.player ? "yours" : (view.isAlly(e.owner) ? "ally" : "opponent")
            content = .single(EntityDetail(id: e.id, kind: e.kind, name: InterfaceText.name(of: e.kind, at: ownerAge),
                                           ownerLine: "\(civ), \(relation)", health: e.health, maxHealth: e.maxHealth,
                                           activity: text, progress: progress))
        default:
            var counts: [EntityKind: Int] = [:]
            for e in selected { counts[e.kind, default: 0] += 1 }
            let ordered = counts.keys.sorted { Self.rank($0) < Self.rank($1) }
            content = .several(total: selected.count, counts: ordered.map {
                KindCount(kind: $0, name: InterfaceText.name(of: $0, at: view.age), count: counts[$0] ?? 0)
            })
        }

        // What the match allows at all.
        let gate: Unavailability?
        if view.outcome != nil {
            gate = Unavailability(.notNow, "The match is over")
        } else if view.isPaused {
            gate = Unavailability(.notNow, "The match is paused")
        } else {
            gate = nil
        }

        let planner = Planner(view: view, catalogue: catalogue, gate: gate)
        let own = selected.filter { $0.owner == view.player }

        // Train and research at a single own building that stands complete.
        if selected.count == 1, let b = own.first, case .building(let kind) = b.kind, !Self.isUnderConstruction(b) {
            let stats = catalogue.stats(kind)
            train = stats.trains.filter { $0 != .founder }.map { unit in
                let u = catalogue.stats(unit)
                let name = unit.stageName(at: view.age)
                return ActionOffer(
                    id: "train-\(unit)", section: .train, title: name, detail: "Trains one \(name).", cost: u.cost,
                    action: .train(at: b.id, unit: unit),
                    unavailable: planner.check(cost: u.cost, age: u.age, population: u.population),
                    shortcut: Self.trainKey(unit), icon: .unit(unit),
                    iconSubject: planner.subject(.unit(unit)))
            }
            var researching = false
            if case .researching = b.activity { researching = true }
            research = stats.researches.filter { !view.improvements.contains($0) }.map { improvement in
                let r = catalogue.stats(improvement)
                var why = planner.check(cost: r.cost, age: r.age)
                if why == nil && researching { why = Unavailability(.notNow, "Research is already under way here") }
                return ActionOffer(
                    id: "research-\(improvement)", section: .research, title: InterfaceText.name(of: improvement),
                    detail: InterfaceText.effect(of: improvement), cost: r.cost,
                    action: .research(at: b.id, improvement: improvement), unavailable: why,
                    shortcut: Self.researchKey(improvement), icon: nil, iconSubject: nil)
            }
        }

        // Buildings for engineers, of the ages reached.
        if own.contains(where: { $0.kind == .unit(.engineer) }) {
            build = catalogue.buildings.filter { $0.age <= view.age }.map { b in
                ActionOffer(
                    id: "build-\(b.kind)", section: .build, title: b.kind.name, detail: "Engineers construct it where you click.",
                    cost: b.cost, action: .place(b.kind), unavailable: planner.check(cost: b.cost, age: b.age),
                    shortcut: Self.buildKey(b.kind), icon: .building(b.kind), iconSubject: planner.subject(.building(b.kind)))
            }
        }

        // Upgrades for warfighters where the catalogue has one.
        var keyGiven = false
        let warfighters = Dictionary(grouping: own.filter { $0.kind.isWarfighterKind }, by: { $0.kind })
        for kind in warfighters.keys.sorted(by: { Self.rank($0) < Self.rank($1) }) {
            guard case .unit(let from) = kind, let up = catalogue.upgrade(from: from), let group = warfighters[kind] else { continue }
            let ids = group.map(\.id).sorted()
            var total = ResourceAmounts()
            for _ in ids { total = total + up.cost }
            let target = up.to.stageName(at: view.age)
            let host = view.entities
                .filter { $0.owner == view.player && !Self.isUnderConstruction($0) }
                .first { if case .building(let k) = $0.kind { return catalogue.stats(k).trains.contains(up.to) } else { return false } }
            var why = planner.check(cost: total, age: catalogue.stats(up.to).age)
            if why == nil && host == nil {
                let names = catalogue.stats(up.to).trainedAt.map(\.name).joined(separator: " or ").lowercased()
                why = Unavailability(.invalidTarget, "Needs a \(names) to train the \(target)")
            }
            upgrade.append(ActionOffer(
                id: "upgrade-\(from)", section: .upgrade, title: "\(ids.count) \(from.stageName(at: view.age)) to \(target)",
                detail: "Turns \(ids.count) into \(target).", cost: total,
                action: .upgrade(units: ids, to: up.to, at: host?.id), unavailable: why,
                shortcut: keyGiven ? nil : "u", icon: .unit(up.to), iconSubject: planner.subject(.unit(up.to))))
            keyGiven = true
        }
    }

    // MARK: Shortcuts

    /// Keys for the actions that are not tied to the selection.
    public static let pauseKey: Character = " "
    public static let advanceKey: Character = "n"

    static func trainKey(_ unit: UnitKind) -> Character? {
        switch unit {
        case .worker: "w"
        case .scholar: "s"
        case .engineer: "e"
        case .merchant: "m"
        case .clubman: "c"
        case .slinger: "l"
        case .spearman: "p"
        case .archer: "a"
        case .chariot: "h"
        case .founder: nil
        }
    }

    static func buildKey(_ kind: BuildingKind) -> Character? {
        switch kind {
        case .townCentre: "t"
        case .house: "h"
        case .storagePit: "s"
        case .stockPen: "k"
        case .barracks: "b"
        case .watchTower: "w"
        case .palisade: "p"
        }
    }

    static func researchKey(_ improvement: Improvement) -> Character? {
        switch improvement {
        case .betterTools: "t"
        case .bronzeWeapons: "b"
        case .shields: "d"
        }
    }

    // MARK: Helpers

    static func rank(_ kind: EntityKind) -> Int {
        switch kind {
        case .unit(let u): u.rawValue
        case .building(let b): 100 + b.rawValue
        }
    }

    static func isUnderConstruction(_ e: EntityView) -> Bool {
        if case .underConstruction = e.activity { return true }
        return false
    }

    /// The common reasoning behind every offer.
    struct Planner {
        let view: PlayerView
        let catalogue: Catalogue
        let gate: Unavailability?

        /// The first reason an action cannot act: the match first, then the age,
        /// the resources and the population limit.
        func check(cost: ResourceAmounts, age: Age, population places: Int? = nil) -> Unavailability? {
            if let gate { return gate }
            if age > view.age {
                return Unavailability(.ageNotReached(age), "Needs the \(age.name) age")
            }
            if !view.resources.covers(cost) {
                let short = view.resources.shortfall(for: cost)
                return Unavailability(.notEnough(short), "Short of \(InterfaceText.cost(short))")
            }
            if let places, view.population + places > view.populationLimit {
                let advice = view.populationLimit >= catalogue.populationMaximum ? "" : "; build a house"
                return Unavailability(.populationLimit, "Population limit reached (\(view.population) of \(view.populationLimit))\(advice)")
            }
            return nil
        }

        /// The sprite subject of an icon, chosen as `SpriteSubject.of` does for an entity.
        func subject(_ kind: EntityKind) -> SpriteSubject {
            switch kind {
            case .unit(let u):
                let own = catalogue.stats(u).age
                return .unit(u, (u.isWarfighter || u == .founder) ? own : max(own, view.age))
            case .building(let b):
                return .building(b, max(catalogue.stats(b).age, view.age))
            }
        }
    }
}

extension EntityKind {
    var isWarfighterKind: Bool {
        if case .unit(let u) = self { return u.isWarfighter }
        return false
    }
}
