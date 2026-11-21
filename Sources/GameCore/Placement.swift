// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The one rule for where things may stand, so that the simulation, the
/// drawing's placement outline and the computer player agree.
///
/// - A tile is passable when its terrain is passable, no building's footprint
///   covers it, and no site that `blocksTile` remains on it. People do not
///   block one another or buildings.
/// - A building may be placed when every tile of its footprint is inside the
///   map, buildable, free of footprints and blocking sites, and explored by the
///   placing player.
public enum Placement {
    /// The tiles a building covers, from its origin toward +x and +y.
    public static func footprint(_ kind: BuildingKind, at origin: GridPoint, catalogue: Catalogue = .standard) -> [GridPoint] {
        let size = catalogue.stats(kind).footprint
        var tiles: [GridPoint] = []
        for dy in 0..<size.y { for dx in 0..<size.x { tiles.append(GridPoint(origin.x + dx, origin.y + dy)) } }
        return tiles
    }

    /// The origin tile of a building whose footprint is centred on `centre`.
    public static func origin(_ kind: BuildingKind, centre: MapPosition, catalogue: Catalogue = .standard) -> GridPoint {
        let size = catalogue.stats(kind).footprint
        return GridPoint(Int((centre.x - Double(size.x) / 2).rounded()), Int((centre.y - Double(size.y) / 2).rounded()))
    }

    /// The centre of a building's footprint, which is its `EntityView.position`.
    public static func centre(_ kind: BuildingKind, origin: GridPoint, catalogue: Catalogue = .standard) -> MapPosition {
        let size = catalogue.stats(kind).footprint
        return MapPosition(x: Double(origin.x) + Double(size.x) / 2, y: Double(origin.y) + Double(size.y) / 2)
    }

    /// The occupied tiles of a map: building footprints and blocking sites.
    public static func occupied(buildings: [(kind: BuildingKind, origin: GridPoint)], sites: [ResourceSite],
                                catalogue: Catalogue = .standard) -> Set<GridPoint> {
        var out = Set<GridPoint>()
        for b in buildings { for t in footprint(b.kind, at: b.origin, catalogue: catalogue) { out.insert(t) } }
        for s in sites where s.kind.blocksTile && s.remaining > 0 { out.insert(s.tile) }
        return out
    }

    /// The kind of site a building must stand on: an oil well on an oil field
    /// (ruled 2026-11-19); nil for every other building. Nothing else may be
    /// built over an oil field.
    public static func site(for kind: BuildingKind) -> SiteKind? { kind == .oilWell ? .oilField : nil }

    /// Whether a bridge may be built from `a` to `b` as the player sees the map:
    /// the line of `bridgeWater`, every tile of it explored, and no building on
    /// its water.
    public static func canBridge(from a: GridPoint, to b: GridPoint, in view: PlayerView) -> Bool {
        guard let water = bridgeWater(from: a, to: b, width: view.mapWidth, height: view.mapHeight, terrain: view.terrain)
        else { return false }
        let built = Set(view.entities.compactMap { e -> GridPoint? in if case .building = e.kind { e.tile } else { nil } })
        return ([a, b] + water).allSatisfy { view.visibility(at: $0) != .unexplored } && !water.contains(where: built.contains)
    }

    /// The end of a bridge dragged from `start` toward `pointer`: the pointer's
    /// tile, brought onto the straight line along the axis it is nearer.
    public static func bridgeEnd(from start: GridPoint, toward pointer: GridPoint) -> GridPoint {
        abs(pointer.x - start.x) >= abs(pointer.y - start.y) ? GridPoint(pointer.x, start.y) : GridPoint(start.x, pointer.y)
    }

    /// The water tiles a bridge from the land tile `a` to the land tile `b`
    /// would cross, in order from `a`, or nil if no bridge may run there: the
    /// line must be straight, both ends on passable ground, every tile between
    /// them water, and at least one and at most `BridgeRule.maxWater` of them.
    public static func bridgeWater(from a: GridPoint, to b: GridPoint, width: Int, height: Int,
                                   terrain: [Terrain]) -> [GridPoint]? {
        guard let run = BridgeRun.of(from: a, to: b) else { return nil }
        func inside(_ t: GridPoint) -> Bool { t.x >= 0 && t.y >= 0 && t.x < width && t.y < height }
        guard inside(a), inside(b), terrain[a.y * width + a.x].isPassable, terrain[b.y * width + b.x].isPassable
        else { return nil }
        let step = run == .alongX ? GridPoint(b.x > a.x ? 1 : -1, 0) : GridPoint(0, b.y > a.y ? 1 : -1)
        var tiles: [GridPoint] = []
        var t = GridPoint(a.x + step.x, a.y + step.y)
        while t != b {
            guard !terrain[t.y * width + t.x].isPassable, tiles.count < BridgeRule.maxWater else { return nil }
            tiles.append(t)
            t = GridPoint(t.x + step.x, t.y + step.y)
        }
        return tiles.isEmpty ? nil : tiles
    }

    /// Whether a building of `kind` may be placed with its origin at `origin`.
    /// `explored` answers whether the placing player has explored a tile.
    /// `wanted` holds the tiles of the sites of `site(for: kind)` with
    /// something left: the footprint must cover one, and they do not count as
    /// occupied for it.
    public static func canPlace(_ kind: BuildingKind, at origin: GridPoint, width: Int, height: Int,
                                terrain: [Terrain], occupied: Set<GridPoint>,
                                explored: (GridPoint) -> Bool, catalogue: Catalogue = .standard,
                                wanted: Set<GridPoint> = []) -> Bool {
        let tiles = footprint(kind, at: origin, catalogue: catalogue)
        let needs = site(for: kind) != nil
        if needs && !tiles.contains(where: wanted.contains) { return false }
        return tiles.allSatisfy { t in
            t.x >= 0 && t.y >= 0 && t.x < width && t.y < height
                && terrain[t.y * width + t.x].isBuildable && (!occupied.contains(t) || needs && wanted.contains(t)) && explored(t)
        }
    }

    /// The same rule as the player sees it: for the drawing's outline and the
    /// computer player. The simulation applies it to its full state. An
    /// outcrop (`PlayerView.outcrops`) is a deposit not yet revealed, and
    /// blocks its tile as the deposit does.
    public static func canPlace(_ kind: BuildingKind, at origin: GridPoint, in view: PlayerView,
                                catalogue: Catalogue = .standard) -> Bool {
        let buildings: [(kind: BuildingKind, origin: GridPoint)] = view.entities.compactMap {
            if case .building(let k) = $0.kind { return (k, $0.tile) } else { return nil }
        }
        var occupied = occupied(buildings: buildings, sites: view.sites, catalogue: catalogue)
        for t in view.outcrops { occupied.insert(t) }
        // An oil field holds nothing but a well, and one well at that.
        let fields = view.sites.filter { $0.kind == .oilField && $0.remaining > 0 }.map(\.tile)
        let built = Set(buildings.flatMap { footprint($0.kind, at: $0.origin, catalogue: catalogue) })
        for t in fields { occupied.insert(t) }
        let wanted = site(for: kind) == .oilField ? Set(fields.filter { !built.contains($0) }) : []
        return canPlace(kind, at: origin, width: view.mapWidth, height: view.mapHeight, terrain: view.terrain,
                        occupied: occupied, explored: { view.visibility(at: $0) != .unexplored }, catalogue: catalogue,
                        wanted: wanted)
    }
}
