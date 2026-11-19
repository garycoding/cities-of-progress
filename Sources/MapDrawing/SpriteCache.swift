// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Artwork
import CoreGraphics
import GameCore
import SpriteKit

/// A sprite ready for a node: textures, size in points, and the anchor point.
struct ResolvedSprite {
    var texture: SKTexture
    /// White where the team colour goes; `nil` for artwork without a mask and for placeholders.
    var mask: SKTexture?
    var size: CGSize
    var anchor: CGPoint
    var isPlaceholder: Bool
}

/// Turns the `SpriteSource`'s images into textures once, remembers what the
/// source did not supply (so that it is not asked again), and falls back as
/// docs/architecture.md, "Sprites", describes: the same pose at frame 0, then
/// `standing` (people) or `complete` (buildings), then a placeholder.
@MainActor
final class SpriteCache {
    let source: any SpriteSource
    let catalogue: Catalogue

    private enum Entry { case missing, found(ResolvedSprite) }
    private var artwork: [SpriteKey: Entry] = [:]

    private struct PersonKey: Hashable { var kind: UnitKind; var civilization: Civilization; var pose: String; var frame: Int }
    private struct BuildingKey: Hashable { var kind: BuildingKind; var civilization: Civilization; var constructing: Bool }
    private struct TerrainKey: Hashable { var terrain: Terrain; var variant: Int; var dimmed: Bool }
    private var people: [PersonKey: ResolvedSprite] = [:]
    private var buildings: [BuildingKey: ResolvedSprite] = [:]
    private var sites: [SiteKind: ResolvedSprite] = [:]
    private var outcrop: ResolvedSprite?
    private var terrainTextures: [TerrainKey: (texture: SKTexture, size: CGSize)] = [:]
    private var variantCounts: [Terrain: Int] = [:]
    private var footprints: [BuildingKind: GridPoint] = [:]

    init(source: any SpriteSource, catalogue: Catalogue) {
        self.source = source
        self.catalogue = catalogue
    }

    func footprint(_ kind: BuildingKind) -> GridPoint {
        if let known = footprints[kind] { return known }
        let size = catalogue.stats(kind).footprint
        footprints[kind] = size
        return size
    }

    // MARK: Artwork

    private func supplied(_ key: SpriteKey) -> ResolvedSprite? {
        if let entry = artwork[key] {
            if case .found(let sprite) = entry { return sprite }
            return nil
        }
        guard let image = source.sprite(key) else { artwork[key] = .missing; return nil }
        let size = CGSize(width: Double(image.base.width) / 2, height: Double(image.base.height) / 2)
        let sprite = ResolvedSprite(texture: SKTexture(cgImage: image.base),
                                    mask: image.teamMask.map { SKTexture(cgImage: $0) },
                                    size: size, anchor: CGPoint(x: image.anchor.x, y: image.anchor.y), isPlaceholder: false)
        artwork[key] = .found(sprite)
        return sprite
    }

    private func suppliedWithFallback(_ subject: SpriteSubject, pose: SpritePose, frame: Int, fallback: SpritePose) -> ResolvedSprite? {
        supplied(SpriteKey(subject, pose, frame: frame))
            ?? supplied(SpriteKey(subject, pose, frame: 0))
            ?? supplied(SpriteKey(subject, fallback, frame: frame))
            ?? supplied(SpriteKey(subject, fallback, frame: 0))
    }

    // MARK: Entities and sites

    /// The sprite of a person or building: the source's, else a placeholder.
    func sprite(for kind: EntityKind, subject: SpriteSubject, civilization: Civilization,
                pose: SpritePose, frame: Int) -> ResolvedSprite {
        switch kind {
        case .unit(let unit):
            if let found = suppliedWithFallback(subject, pose: pose, frame: frame, fallback: .standing) { return found }
            let key = PersonKey(kind: unit, civilization: civilization, pose: pose.rawValue, frame: frame % 2)
            if let known = people[key] { return known }
            let drawn = Placeholders.person(unit, civilization: civilization, pose: Placeholders.figurePose(pose), frame: frame)
            let sprite = Self.placeholder(drawn)
            people[key] = sprite
            return sprite
        case .building(let building):
            if let found = suppliedWithFallback(subject, pose: pose, frame: frame, fallback: .complete) { return found }
            let constructing = pose == .underConstruction
            let key = BuildingKey(kind: building, civilization: civilization, constructing: constructing)
            if let known = buildings[key] { return known }
            let drawn = Placeholders.building(building, civilization: civilization, constructing: constructing,
                                              footprint: footprint(building))
            let sprite = Self.placeholder(drawn)
            buildings[key] = sprite
            return sprite
        }
    }

    func sprite(forSite kind: SiteKind) -> ResolvedSprite {
        if let known = sites[kind] { return known }
        let sprite = supplied(SpriteKey(.site(kind), .complete)) ?? Self.placeholder(Placeholders.site(kind))
        sites[kind] = sprite
        return sprite
    }

    func spriteForOutcrop() -> ResolvedSprite {
        if let known = outcrop { return known }
        let sprite = supplied(SpriteKey(.outcrop, .complete)) ?? Self.placeholder(Placeholders.outcrop())
        outcrop = sprite
        return sprite
    }

    private static func placeholder(_ drawn: DrawnImage) -> ResolvedSprite {
        ResolvedSprite(texture: SKTexture(cgImage: drawn.image), mask: nil, size: drawn.size, anchor: drawn.anchor, isPlaceholder: true)
    }

    // MARK: Terrain

    /// How many variants of a terrain there are to choose between: those the source
    /// supplies from 0 on, else the placeholder's two.
    func variantCount(_ terrain: Terrain) -> Int {
        if let known = variantCounts[terrain] { return known }
        var count = 0
        while count < 8, supplied(SpriteKey(.terrain(terrain, variant: count), .complete)) != nil { count += 1 }
        let result = max(count, count == 0 ? 2 : 1)
        variantCounts[terrain] = result
        return result
    }

    /// The tile texture of a terrain: the source's, else a placeholder diamond; and
    /// the same darkened, for ground explored but not in sight.
    func terrainTexture(_ terrain: Terrain, variant: Int, dimmed: Bool) -> (texture: SKTexture, size: CGSize) {
        let key = TerrainKey(terrain: terrain, variant: variant, dimmed: dimmed)
        if let known = terrainTextures[key] { return known }
        let made: (SKTexture, CGSize)
        if let found = supplied(SpriteKey(.terrain(terrain, variant: variant), .complete)) {
            let size = found.size
            if dimmed, let image = source.sprite(SpriteKey(.terrain(terrain, variant: variant), .complete))?.base {
                made = (SKTexture(cgImage: Placeholders.darkened(image)), size)
            } else {
                made = (found.texture, size)
            }
        } else {
            made = (SKTexture(cgImage: Placeholders.terrain(terrain, variant: variant, dimmed: dimmed)), Placeholders.terrainSize)
        }
        terrainTextures[key] = made
        return made
    }
}
