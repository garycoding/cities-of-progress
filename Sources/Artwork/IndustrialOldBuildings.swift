// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore
import Synchronization

/// The buildings of the earlier ages in the look of the Industrial age,
/// complete and under construction (the boat house among them, ruled
/// 2026-11-21): red brick with dressed-stone trim, slate
/// roofs with chimney pots, sash windows, cast-iron columns and railings, and
/// gas lamps, in the style of docs/art-style.md. A building takes the look of
/// its owner's age (`SpriteSubject.of`), so these replace the Alchemy looks
/// once a player reaches the Industrial age. The Industrial age's own
/// buildings (the factory, the railway depot and the oil well) are drawn by
/// another batch; every key but this batch's gives nil.
public struct IndustrialOldBuildingSprites: SpriteSource {
    private let store = Store()

    public init() {}

    public func sprite(_ key: SpriteKey) -> SpriteImage? {
        guard let subject = IndustrialOldBuildingsArt.subject(of: key) else { return nil }
        if let known = store.made.withLock({ $0[key] }) { return known }
        guard let made = IndustrialOldBuildingsArt.render(subject.kind, complete: subject.complete) else { return nil }
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
enum IndustrialOldBuildingsArt {
    /// The buildings this batch draws: those of the Stone, Bronze, Iron and Alchemy ages.
    static let kinds: [BuildingKind] = [.townCentre, .house, .storagePit, .stockPen, .barracks, .watchTower, .palisade,
                                        .farm, .stable, .siegeWorkshop, .stoneWall, .castle, .alchemistsWorkshop, .boatHouse]

    /// The buildings drawn with the kit of the larger works (`IndustrialOldBuildingsLatePainter`).
    static let late: [BuildingKind] = [.castle, .alchemistsWorkshop]

    /// The building and pose a key names, if it is one of this batch's: a
    /// building of an earlier age in the Industrial age's look, complete or
    /// under construction, at frame 0.
    static func subject(of key: SpriteKey) -> (kind: BuildingKind, complete: Bool)? {
        guard case .building(let kind, .industrial) = key.subject, key.frame == 0, kinds.contains(kind) else { return nil }
        if key.pose == .complete { return (kind, true) }
        if key.pose == .underConstruction { return (kind, false) }
        return nil
    }

    /// The canvas of the Alchemy look of the same building, so that a
    /// building keeps its size and anchor from one age to the next. The boat
    /// house keeps the canvas of its Stone look (ruled 2026-11-21: one canvas
    /// for the boat house in every age).
    static func canvas(_ kind: BuildingKind) -> Canvas {
        if kind == .boatHouse { return boatHouseCanvas }
        return late.contains(kind) ? AlchemyNewBuildingsArt.canvas(kind) : AlchemyOldBuildingsArt.canvas(kind)
    }

    /// The boat house's canvas, the Stone age's (`StoneBuildingsPiece.canvas`).
    static let boatHouseCanvas = Canvas(minX: -68, minY: -108, width: 136, height: 144, pixelsPerUnit: 2)

    /// A building drawn at `pixelsPerUnit` (two for the game): its picture and its mask, grained alike.
    static func draw(_ kind: BuildingKind, complete: Bool, pixelsPerUnit: Double = 2) -> Rendered? {
        let canvas = canvas(kind).scaled(to: pixelsPerUnit)
        return Raster.render(on: canvas) { svg in
            if late.contains(kind) {
                var painter = IndustrialOldBuildingsLatePainter(layer: svg.layer)
                painter.building(kind, complete: complete)
                svg = painter.svg
            } else {
                var painter = IndustrialOldBuildingsPainter(layer: svg.layer)
                painter.building(kind, complete: complete)
                svg = painter.svg
            }
        }
    }

    /// A building drawn as a sprite.
    static func render(_ kind: BuildingKind, complete: Bool) -> SpriteImage? {
        draw(kind, complete: complete)?.sprite(anchor: canvas(kind).anchor)
    }
}

extension IndustrialOldBuildingsPainter {
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
        case .boatHouse: boatHouse(complete: complete)
        // Drawn with the kit of the larger works, or by another batch.
        case .castle, .alchemistsWorkshop, .factory, .railwayDepot, .oilWell, .bridge: break
        }
    }
}

extension IndustrialOldBuildingsLatePainter {
    /// The drawing of a building, complete or under construction.
    mutating func building(_ kind: BuildingKind, complete: Bool) {
        switch kind {
        case .castle: castle(complete: complete)
        case .alchemistsWorkshop: workshop(complete: complete)
        default: break
        }
    }
}
