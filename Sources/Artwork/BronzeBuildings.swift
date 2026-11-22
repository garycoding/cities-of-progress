// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore
import Synchronization

/// Every building in the look of the Bronze age, complete and under
/// construction: mud brick, plaster, timber, bronze fittings and painted bands,
/// in the style of docs/art-style.md. A building takes the look of its owner's
/// age (`SpriteSubject.of`), so a Stone-age town centre is drawn from here once
/// its owner reaches the Bronze age. Every other key gives nil.
public struct BronzeBuildingSprites: SpriteSource {
    private let store = Store()

    public init() {}

    public func sprite(_ key: SpriteKey) -> SpriteImage? {
        guard let subject = BronzeBuildingsArt.subject(of: key) else { return nil }
        if let known = store.made.withLock({ $0[key] }) { return known }
        guard let made = BronzeBuildingsArt.render(subject.kind, complete: subject.complete) else { return nil }
        store.made.withLock { $0[key] = made }
        return made
    }
}

/// The sprites drawn so far, so that each is drawn once.
private final class Store: Sendable {
    let made = Mutex<[SpriteKey: SpriteImage]>([:])
}

/// What this batch draws, on what canvas, and the drawing of it.
enum BronzeBuildingsArt {
    /// The building and pose a key names, if it is one of this batch's: a
    /// building of the standard catalogue in the Bronze age's look, complete or
    /// under construction, at frame 0.
    static func subject(of key: SpriteKey) -> (kind: BuildingKind, complete: Bool)? {
        guard case .building(let kind, .bronze) = key.subject, key.frame == 0,
              Catalogue.standard.buildings.contains(where: { $0.kind == kind }) else { return nil }
        if key.pose == .complete { return (kind, true) }
        if key.pose == .underConstruction { return (kind, false) }
        return nil
    }

    /// The area a building's sprite covers, in points with the origin on the
    /// ground at the centre of its footprint, drawn at two pixels a point (twice
    /// its size in points). The footprint's diamond fills the width, with a small
    /// margin; above it there is room for the building's height.
    static func canvas(_ kind: BuildingKind) -> Canvas {
        let footprint = Catalogue.standard.stats(kind).footprint
        let halfWidth = Double(footprint.x + footprint.y) * 16, halfHeight = Double(footprint.x + footprint.y) * 8
        let margin = 4.0
        let top = Self.height(kind)
        return Canvas(minX: -(halfWidth + margin), minY: -top, width: 2 * (halfWidth + margin),
                      height: top + halfHeight + margin, pixelsPerUnit: 2)
    }

    /// How far above the footprint's centre a building's drawing may reach, in points.
    static func height(_ kind: BuildingKind) -> Double {
        switch kind {
        case .townCentre: 118
        case .house: 78
        case .storagePit: 62
        case .stockPen: 76
        case .barracks: 96
        case .watchTower: 120
        case .palisade: 58
        // Iron-age buildings are drawn by their own batch; the boat house fits in their height too.
        case .farm, .stable, .siegeWorkshop, .stoneWall, .castle, .alchemistsWorkshop, .factory, .railwayDepot, .oilWell, .bridge, .boatHouse: 80
        }
    }

    /// A building drawn as a sprite: its picture and its team-colour mask, grained alike.
    static func render(_ kind: BuildingKind, complete: Bool) -> SpriteImage? {
        let canvas = canvas(kind)
        let rendered = Raster.render(on: canvas) { svg in
            var painter = BronzeBuildingsPainter(layer: svg.layer)
            painter.building(kind, complete: complete)
            svg = painter.svg
        }
        return rendered?.sprite(anchor: canvas.anchor)
    }
}

extension BronzeBuildingsPainter {
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
        case .boatHouse: boatHouse(complete: complete)
        // Iron-age buildings are drawn by their own batch.
        case .farm, .stable, .siegeWorkshop, .stoneWall, .castle, .alchemistsWorkshop, .factory, .railwayDepot, .oilWell, .bridge: break
        }
    }
}
