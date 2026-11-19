// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore

/// What a click, a box or a right-click means, as pure functions of the view, so
/// that they are tested without a scene. Orders are returned, never issued here.
public enum MapCommands {
    /// The selection after a click on `hit` (`nil` for empty ground). With `additive`
    /// (shift) the entity is added to the selection, or removed if already in it,
    /// and a click on empty ground changes nothing.
    public static func selection(afterClickOn hit: EntityID?, current: [EntityID], additive: Bool) -> [EntityID] {
        guard let hit else { return additive ? current : [] }
        if !additive { return [hit] }
        if let index = current.firstIndex(of: hit) {
            var out = current
            out.remove(at: index)
            return out
        }
        return current + [hit]
    }

    /// The selection after a box that holds `boxed` (the player's own people).
    /// With `additive` they are added to the selection; otherwise they replace it.
    public static func selection(afterBoxHolding boxed: [EntityID], current: [EntityID], additive: Bool) -> [EntityID] {
        guard additive else { return boxed }
        return current + boxed.filter { !current.contains($0) }
    }

    /// The order a right-click gives to the player's selected people, or `nil` if
    /// none of the selection is a person of the player's.
    ///
    /// - Ground: move. A site: workers gather there (others move to it). An own
    ///   building that is unfinished or damaged: engineers work there. An own town
    ///   centre or stock pen: workers, scholars and engineers work there. Another
    ///   of the player's or an ally's: move to it. An opponent: attack.
    public static func contextualOrder(on target: MapTarget, view: PlayerView, selection: [EntityID]) -> Order? {
        let people = selection.compactMap { view.entity($0) }.filter {
            if case .unit = $0.kind { return $0.owner == view.player } else { return false }
        }
        guard !people.isEmpty else { return nil }
        func ids(_ matching: (UnitKind) -> Bool) -> [EntityID] {
            people.filter { if case .unit(let k) = $0.kind { return matching(k) } else { return false } }.map(\.id)
        }
        let everyone = people.map(\.id)

        switch target {
        case .ground(let position):
            return .move(units: everyone, to: position)
        case .site(let site):
            let workers = ids { $0 == .worker }
            return workers.isEmpty ? .move(units: everyone, to: site.tile.centre) : .gather(units: workers, site: site.id)
        case .entity(let entity):
            if entity.owner == view.player, case .building(let kind) = entity.kind {
                var unfinished = false
                if case .underConstruction = entity.activity { unfinished = true }
                let engineers = ids { $0 == .engineer }
                if (unfinished || entity.health < entity.maxHealth), !engineers.isEmpty {
                    return .work(units: engineers, at: entity.id)
                }
                if kind == .townCentre || kind == .stockPen {
                    let hands = ids { $0 == .worker || $0 == .scholar || $0 == .engineer }
                    if !hands.isEmpty { return .work(units: hands, at: entity.id) }
                }
                // A complete farm takes a farmer, a complete alchemist's workshop its craftsmen.
                if (kind == .farm || kind == .alchemistsWorkshop) && !unfinished {
                    let workers = ids { $0 == .worker }
                    if !workers.isEmpty { return .work(units: workers, at: entity.id) }
                }
                return .move(units: everyone, to: entity.position)
            }
            if view.isAlly(entity.owner) { return .move(units: everyone, to: entity.position) }
            return .attack(units: everyone, target: entity.id)
        }
    }
}
