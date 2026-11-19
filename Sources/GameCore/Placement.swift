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

    /// Whether a building of `kind` may be placed with its origin at `origin`.
    /// `explored` answers whether the placing player has explored a tile.
    public static func canPlace(_ kind: BuildingKind, at origin: GridPoint, width: Int, height: Int,
                                terrain: [Terrain], occupied: Set<GridPoint>,
                                explored: (GridPoint) -> Bool, catalogue: Catalogue = .standard) -> Bool {
        footprint(kind, at: origin, catalogue: catalogue).allSatisfy { t in
            t.x >= 0 && t.y >= 0 && t.x < width && t.y < height
                && terrain[t.y * width + t.x].isBuildable && !occupied.contains(t) && explored(t)
        }
    }

    /// The same rule as the player sees it: for the drawing's outline and the
    /// computer player. The simulation applies it to its full state.
    public static func canPlace(_ kind: BuildingKind, at origin: GridPoint, in view: PlayerView,
                                catalogue: Catalogue = .standard) -> Bool {
        let buildings: [(kind: BuildingKind, origin: GridPoint)] = view.entities.compactMap {
            if case .building(let k) = $0.kind { return (k, $0.tile) } else { return nil }
        }
        let occupied = occupied(buildings: buildings, sites: view.sites, catalogue: catalogue)
        return canPlace(kind, at: origin, width: view.mapWidth, height: view.mapHeight, terrain: view.terrain,
                        occupied: occupied, explored: { view.visibility(at: $0) != .unexplored }, catalogue: catalogue)
    }
}
