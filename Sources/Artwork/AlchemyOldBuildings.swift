// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore
import Synchronization

/// The buildings of the earlier ages in the look of the Alchemy age, complete
/// and under construction: half-timbering over stone, steep roofs of slate,
/// glazed windows, and gilt finials and weathervanes, in the style of
/// docs/art-style.md. A building takes the look of its owner's age
/// (`SpriteSubject.of`), so these replace the Iron looks once a player
/// reaches the Alchemy age. The castle and the alchemist's workshop are drawn
/// by another batch; every key but this batch's gives nil.
public struct AlchemyOldBuildingSprites: SpriteSource {
    private let store = Store()

    public init() {}

    public func sprite(_ key: SpriteKey) -> SpriteImage? {
        guard let subject = AlchemyOldBuildingsArt.subject(of: key) else { return nil }
        if let known = store.made.withLock({ $0[key] }) { return known }
        guard let made = AlchemyOldBuildingsArt.render(subject.kind, complete: subject.complete) else { return nil }
        return store.made.withLock { cache in
            if let first = cache[key] { return first }
            cache[key] = made
            return made
        }
    }
}

/// The sprites drawn so far, so that each is drawn once.
private final class Store: Sendable {
    let made = Mutex<[SpriteKey: SpriteImage]>([:])
}

/// What this batch draws, on what canvas, and the drawing of it.
enum AlchemyOldBuildingsArt {
    /// The buildings this batch draws: those of the Stone, Bronze and Iron ages.
    static let kinds: [BuildingKind] = [.townCentre, .house, .storagePit, .stockPen, .barracks, .watchTower, .palisade,
                                        .farm, .stable, .siegeWorkshop, .stoneWall]

    /// The building and pose a key names, if it is one of this batch's: a
    /// building of an earlier age in the Alchemy age's look, complete or under
    /// construction, at frame 0.
    static func subject(of key: SpriteKey) -> (kind: BuildingKind, complete: Bool)? {
        guard case .building(let kind, .alchemy) = key.subject, key.frame == 0, kinds.contains(kind) else { return nil }
        if key.pose == .complete { return (kind, true) }
        if key.pose == .underConstruction { return (kind, false) }
        return nil
    }

    /// The canvas of the Iron look of the same building, so that a building
    /// keeps its size and anchor from one age to the next.
    static func canvas(_ kind: BuildingKind) -> Canvas {
        IronNewBuildingsArt.kinds.contains(kind) ? IronNewBuildingsArt.canvas(kind) : IronOldBuildingsArt.canvas(kind)
    }

    /// A building drawn as a sprite: its picture and its team-colour mask, grained alike.
    static func render(_ kind: BuildingKind, complete: Bool) -> SpriteImage? {
        let canvas = canvas(kind)
        let rendered = Raster.render(on: canvas) { svg in
            var painter = AlchemyOldBuildingsPainter(layer: svg.layer)
            painter.building(kind, complete: complete)
            svg = painter.svg
        }
        return rendered?.sprite(anchor: canvas.anchor)
    }
}

extension AlchemyOldBuildingsPainter {
    /// The drawing of a building, complete or under construction.
    mutating func building(_ kind: BuildingKind, complete: Bool) {
        switch kind {
        case .townCentre: townCentre(complete: complete)
        case .house: house(complete: complete)
        case .storagePit: storagePit(complete: complete)
        case .stockPen: stockPen(complete: complete)
        case .barracks: barracks(complete: complete)
        case .watchTower: watchTower(complete: complete)
        case .palisade: palisade(complete: complete)
        case .farm: farm(complete: complete)
        case .stable: stable(complete: complete)
        case .siegeWorkshop: siegeWorkshop(complete: complete)
        case .stoneWall: stoneWall(complete: complete)
        // The Alchemy age's own buildings are drawn by their own batch.
        case .castle, .alchemistsWorkshop: break
        }
    }
}
