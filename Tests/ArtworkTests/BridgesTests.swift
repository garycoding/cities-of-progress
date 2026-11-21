// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import AppKit
import CoreGraphics
import Foundation
import GameCore
import Testing
@testable import Artwork

/// The bridge (`BridgeSprites`): every key of the batch has a sprite anchored
/// at the centre of its tile with a mask, every other key has none, pieces
/// laid side by side make one deck, a key always gives the same pixels, and
/// the batch is drawn quickly.
@Suite(.serialized) struct BridgesTests {
    private static let source = BridgeSprites()

    /// The batch's keys, as the milestone's checklist names them.
    private static let batch: [SpriteKey] = SpriteKey.required(through: .industrial).filter {
        if case .building(.bridge, _) = $0.subject { return true }
        return false
    }

    @Test func theBatchIsEveryAgesBridgeAlongBothRuns() {
        #expect(Self.batch.count == 5 * 4)
        #expect(Set(Self.batch) == Set(BridgesPiece.keys))
    }

    @Test func everyKeyHasASpriteWithAMask() throws {
        for key in Self.batch {
            let sprite = try #require(Self.source.sprite(key), "\(key)")
            let mask = try #require(sprite.teamMask, "\(key) has no team colour")
            #expect(mask.width == sprite.base.width && mask.height == sprite.base.height, "\(key)")
            #expect(BridgesPixels(mask).bounds(alphaAbove: 128) != nil, "\(key): the mask is empty")
            let drawn = try #require(BridgesPixels(sprite.base).bounds(alphaAbove: 128), "\(key) is empty")
            let pixels = BridgesPixels(sprite.base)
            #expect(drawn.minX > 0 && drawn.minY > 0 && drawn.maxX < pixels.width - 1 && drawn.maxY < pixels.height - 1,
                    "\(key) reaches the edge of its picture")
        }
    }

    /// The anchor is the centre of the tile's diamond: along the run, the deck
    /// reaches the tile's two edges, half a tile on either side of the anchor
    /// at the deck's height, and not past the far one.
    @Test func theAnchorIsTheCentreOfTheTile() throws {
        for key in Self.batch where Self.isComplete(key) {
            let sprite = try #require(Self.source.sprite(key))
            let pixels = BridgesPixels(sprite.base)
            let (x, y) = pixels.place(sprite.anchor)
            // Two pixels a point: half a tile along x is 32 by 16 pixels on the screen.
            let dx = Self.run(key) == .alongX ? 32.0 : -32.0
            let deck = 2 * BridgesPiece(key)!.look.deckHeight
            func opaque(_ t: Double) -> Bool {
                pixels.alpha(Int((x + dx * t).rounded()), Int((y - deck + 16 * t).rounded())) > 200
            }
            for t in stride(from: -0.95, through: 0.95, by: 0.05) { #expect(opaque(t), "\(key): no deck at \(t)") }
            // Past the far edge there is nothing. (Past the near edge, the supports
            // of the near end stand under the deck's line on the screen; the next
            // test shows that a piece laid there joins this one.)
            #expect(!opaque(-1.25), "\(key): the deck runs past the tile")
        }
    }

    /// Three pieces laid side by side along their run show one deck: no
    /// pixel along its middle is less than opaque, across either joint.
    @Test func piecesSideBySideMakeOneDeck() throws {
        for key in Self.batch where Self.isComplete(key) {
            let sprite = try #require(Self.source.sprite(key))
            let w = sprite.base.width, h = sprite.base.height
            let width = w + 160, height = h + 80
            let context = try #require(Raster.bitmap(width: width, height: height))
            let step = Self.run(key) == .alongX ? 64.0 : -64.0
            let centre = CGPoint(x: Double(width) / 2, y: Double(height) / 2)
            // The farthest piece first; the canvas's y runs up, so the next piece along is 32 pixels lower.
            for k in -1...1 {
                let ax = centre.x + Double(k) * step - sprite.anchor.x * Double(w)
                let ay = centre.y - Double(k) * 32 - sprite.anchor.y * Double(h)
                context.draw(sprite.base, in: CGRect(x: ax, y: ay, width: Double(w), height: Double(h)))
            }
            let pixels = BridgesPixels(try #require(context.makeImage()))
            let deck = 2 * BridgesPiece(key)!.look.deckHeight
            for t in stride(from: -1.4, through: 1.4, by: 0.02) {
                let px = Int((centre.x + step * t).rounded()), py = Int((Double(height) - centre.y - deck + 32 * t).rounded())
                #expect(pixels.alpha(px, py) == 255, "\(key): a gap in the deck at \(t)")
            }
        }
    }

    @Test func everyOtherKeyHasNone() {
        let batch = Set(Self.batch)
        var others: [SpriteKey] = []
        let poses: [SpritePose] = [.complete, .underConstruction, .standing, "bridge-along-z"]
            + BridgeRun.allCases.flatMap { [$0.pose(complete: true), $0.pose(complete: false)] }
        for kind in BuildingKind.allCases {
            for age in Age.allCases {
                for pose in poses {
                    for frame in [-1, 0, 1, 11] { others.append(SpriteKey(.building(kind, age), pose, frame: frame)) }
                }
            }
        }
        for kind in UnitKind.allCases {
            for age in Age.allCases { others.append(SpriteKey(.unit(kind, age), .standing)) }
        }
        for kind in SiteKind.allCases { others.append(SpriteKey(.site(kind), .complete)) }
        others.append(SpriteKey(.outcrop, .complete))
        for terrain in Terrain.allCases { others.append(SpriteKey(.terrain(terrain, variant: 0), .complete)) }
        let outside = others.filter { !batch.contains($0) }
        #expect(outside.count > 1000)
        for key in outside { #expect(Self.source.sprite(key) == nil, "\(key)") }
        for age in [Age.silicon, .ai] {
            #expect(Self.source.sprite(SpriteKey(.building(.bridge, age), BridgeRun.alongX.pose(complete: true))) == nil)
        }
    }

    @Test func theSameKeyGivesTheSamePixels() throws {
        let first = BridgeSprites(), second = BridgeSprites()
        for key in Self.batch {
            let a = try #require(first.sprite(key)), b = try #require(second.sprite(key))
            #expect(BridgesPixels(a.base).bytes == BridgesPixels(b.base).bytes, "\(key)")
            let maskA = try #require(a.teamMask), maskB = try #require(b.teamMask)
            #expect(BridgesPixels(maskA).bytes == BridgesPixels(maskB).bytes, "\(key)")
            #expect(a.anchor == b.anchor, "\(key)")
        }
    }

    @Test func theBatchRendersInUnderThreeSeconds() {
        let fresh = BridgeSprites()
        let elapsed = ContinuousClock().measure {
            for key in Self.batch { _ = fresh.sprite(key) }
        }
        #expect(elapsed < .seconds(3), "the batch took \(elapsed)")
    }

    private static func isComplete(_ key: SpriteKey) -> Bool { !key.pose.rawValue.hasSuffix("under-construction") }

    private static func run(_ key: SpriteKey) -> BridgeRun { key.pose.rawValue.contains("along-x") ? .alongX : .alongY }
}

/// An image's pixels, premultiplied RGBA, the top row first.
private struct BridgesPixels {
    let width: Int, height: Int
    let bytes: [UInt8]

    init(_ image: CGImage) {
        width = image.width
        height = image.height
        let context = Raster.bitmap(width: width, height: height)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let data = context.data!.bindMemory(to: UInt8.self, capacity: context.bytesPerRow * height)
        bytes = Array(UnsafeBufferPointer(start: data, count: context.bytesPerRow * height))
    }

    func alpha(_ x: Int, _ y: Int) -> UInt8 {
        guard x >= 0, y >= 0, x < width, y < height else { return 0 }
        return bytes[(y * width + x) * 4 + 3]
    }

    /// The anchor as a column and a row from the top.
    func place(_ anchor: SpriteAnchor) -> (x: Double, y: Double) {
        (anchor.x * Double(width), (1 - anchor.y) * Double(height))
    }

    /// The smallest box holding every pixel more opaque than `alphaAbove`.
    func bounds(alphaAbove threshold: UInt8) -> (minX: Int, minY: Int, maxX: Int, maxY: Int)? {
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where alpha(x, y) > threshold {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        return maxX < 0 ? nil : (minX, minY, maxX, maxY)
    }
}

/// The pictures for the person's ruling, written to the directory named by the
/// environment variable `BRIDGES_RENDERS`, each file's name ending with
/// `BRIDGES_RENDERS_SUFFIX` where it is set; skipped when `BRIDGES_RENDERS` is
/// not set: a contact sheet of every drawing in two civilizations' colours,
/// with rows of pieces joined along each run, the same enlarged, and a scene
/// at game size for each age of a river crossed by two bridges.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["BRIDGES_RENDERS"] != nil))
struct BridgesRenders {
    private let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["BRIDGES_RENDERS"] ?? "/",
                                isDirectory: true)
    private let suffix = ProcessInfo.processInfo.environment["BRIDGES_RENDERS_SUFFIX"] ?? ""
    private let colours: [(String, TeamColour)] = [("Sumer", .of(.sumer)), ("Egypt", .of(.egypt))]

    @Test func contactSheets() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for scale in [2.0, 4.0] { try sheet(scale: scale) }
    }

    /// Every drawing at `scale` pixels a point (2 is game size), complete and
    /// under construction along each run, in two colours, and four complete
    /// pieces joined along each run.
    private func sheet(scale: Double) throws {
        let k = scale / 2
        let column = 170.0 * k, row = 190.0 * k, left = 30.0 * k, top = 110.0 * k
        let joined = 360.0 * k
        let width = Int(left * 2 + column * 8 + joined * 2), height = Int(top + row * Double(BridgesPiece.ages.count) + 30 * k)
        let context = Raster.bitmap(width: width, height: height)!
        context.draw(Preview.ground(width: width, height: height, tile: 128 * k), in: CGRect(x: 0, y: 0, width: width, height: height))
        Preview.label("The bridge, \(scale == 2 ? "at game size" : "at twice game size"): along x and along y, complete and under construction, in Sumer's and Egypt's colours, and four pieces joined along each run",
                      in: context, at: CGPoint(x: left, y: Double(height) - 48 * k), size: 20 * k)
        var headings: [String] = []
        for (name, _) in colours { headings += ["\(name): x", "\(name): y", "\(name): x, building", "\(name): y, building"] }
        headings += ["joined along x", "joined along y"]
        for (i, heading) in headings.enumerated() {
            let x = i < 8 ? left + Double(i) * column : left + 8 * column + Double(i - 8) * joined
            Preview.label(heading, in: context, at: CGPoint(x: x + 8 * k, y: Double(height) - 84 * k), size: 14 * k)
        }
        for (r, age) in BridgesPiece.ages.enumerated() {
            let ground = Double(height) - top - Double(r) * row - row * 0.62
            Preview.label("\(age)", in: context, at: CGPoint(x: left, y: ground + row * 0.45), size: 16 * k)
            var i = 0
            for (_, colour) in colours {
                for complete in [true, false] {
                    for run in BridgeRun.allCases {
                        let piece = BridgesPiece(age: age, run: run, complete: complete)
                        let image = try picture(piece, colour: colour, scale: scale)
                        let x = left + Double(i) * column + column / 2
                        water(context, at: CGPoint(x: x, y: ground), tiles: [(0, 0)], run: run, scale: scale)
                        Preview.place(image.0, anchor: image.1, at: CGPoint(x: x, y: ground), in: context)
                        i += 1
                    }
                }
            }
            for (j, run) in BridgeRun.allCases.enumerated() {
                let piece = BridgesPiece(age: age, run: run, complete: true)
                let image = try picture(piece, colour: colours[j].1, scale: scale)
                let centre = CGPoint(x: left + 8 * column + Double(j) * joined + joined / 2, y: ground - 10 * k)
                let dx = (run == .alongX ? 64.0 : -64.0) * k
                let tiles = (-2...1).map { (Double($0) + 0.5, 0.0) }
                water(context, at: centre, tiles: tiles, run: run, scale: scale)
                for n in -2...1 {
                    let t = Double(n) + 0.5
                    Preview.place(image.0, anchor: image.1, at: CGPoint(x: centre.x + dx * t, y: centre.y - 32 * k * t), in: context)
                }
            }
        }
        let name = scale == 2 ? "bridges-sheet" : "bridges-sheet-large"
        try Preview.writePNG(context.makeImage()!, to: directory.appendingPathComponent("\(name)\(suffix).png"))
    }

    /// A piece drawn at `scale` pixels a point and tinted, with its anchor.
    private func picture(_ piece: BridgesPiece, colour: TeamColour, scale: Double) throws -> (CGImage, SpriteAnchor) {
        let canvas = BridgesPiece.canvas.scaled(to: scale)
        let drawn = try #require(piece.render(on: canvas))
        return (Preview.tinted(base: drawn.base, mask: drawn.mask, colour: colour), canvas.anchor)
    }

    /// Faint diamonds of shallow water under the pieces drawn at `centre`,
    /// at (`u`, `v`) along and across the run, so that a sheet shows them on water.
    private func water(_ context: CGContext, at centre: CGPoint, tiles: [(Double, Double)], run: BridgeRun, scale: Double) {
        let k = scale / 2
        context.saveGState()
        context.setFillColor(NSColor(srgbRed: 0x93 / 255.0, green: 0xa5 / 255.0, blue: 0xc4 / 255.0, alpha: 1).cgColor)
        for (u, v) in tiles {
            let (x, y) = run == .alongX ? (u, v) : (v, u)
            let c = CGPoint(x: centre.x + (x - y) * 64 * k, y: centre.y - (x + y) * 32 * k)
            context.move(to: CGPoint(x: c.x, y: c.y + 32 * k))
            context.addLine(to: CGPoint(x: c.x + 64 * k, y: c.y))
            context.addLine(to: CGPoint(x: c.x, y: c.y - 32 * k))
            context.addLine(to: CGPoint(x: c.x - 64 * k, y: c.y))
            context.closePath()
        }
        context.fillPath()
        context.restoreGState()
    }

    /// A river at game size for each age: grass banks, shallow water at its
    /// edges and deep water in its middle, bending from a reach that runs along
    /// y to one that runs along x, crossed by a bridge of six pieces along x
    /// and one of five along y, with people of the age on each. Everything
    /// standing is drawn by depth, as the drawing draws it, except the
    /// bridges, which the drawing lays beneath whoever crosses them.
    @Test func riverScenes() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let others = GameSprites(), bridges = BridgeSprites()
        let mapWidth = 19, mapHeight = 17
        // The river: x from 4 to 9 for y below 11, then y from 10 to 14 for x from 4 to 18.
        func isWater(_ x: Int, _ y: Int) -> Bool { x >= 4 && ((x <= 9 && y <= 14) || (y >= 10 && y <= 14)) }
        /// Water by a bank is shallow; the rest is deep.
        func terrain(_ x: Int, _ y: Int) -> Terrain {
            guard isWater(x, y) else { return .grass }
            let bank = !isWater(x - 1, y) || !isWater(x + 1, y) || !isWater(x, y - 1) || !isWater(x, y + 1)
            return bank ? .shallowWater : .deepWater
        }
        let terrains = (0..<mapHeight).flatMap { y in (0..<mapWidth).map { x in terrain(x, y) } }
        let alongX = try #require(Placement.bridgeWater(from: GridPoint(3, 4), to: GridPoint(10, 4), width: mapWidth,
                                                         height: mapHeight, terrain: terrains))
        let alongY = try #require(Placement.bridgeWater(from: GridPoint(14, 9), to: GridPoint(14, 15), width: mapWidth,
                                                         height: mapHeight, terrain: terrains))
        #expect(alongX.count == 6 && alongY.count == 5)
        for age in BridgesPiece.ages {
            let width = 2100, height = 1150
            let context = Raster.bitmap(width: width, height: height)!
            let origin = CGPoint(x: 1000, y: -60)
            func screen(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: origin.x + (x - y) * 64, y: Double(height) - (origin.y + (x + y) * 32))
            }
            for y in -12..<(mapHeight + 12) {
                for x in -12..<(mapWidth + 12) {
                    let t = (0..<mapWidth).contains(x) && (0..<mapHeight).contains(y) ? terrain(x, y) : .grass
                    let variant = (x * 7 + y * 3 + 40) % TerrainSprites.variantCount
                    guard let tile = others.sprite(SpriteKey(.terrain(t, variant: variant), .complete)) else { continue }
                    Preview.place(tile.base, anchor: tile.anchor, at: screen(Double(x) + 0.5, Double(y) + 0.5), in: context)
                }
            }
            // The bridges, the farther pieces first: one along x complete, one along y with its last piece building.
            let pieces: [(GridPoint, BridgeRun, Bool)] = alongX.map { ($0, .alongX, true) }
                + alongY.enumerated().map { ($0.element, .alongY, $0.offset < 4) }
            for (tile, run, complete) in pieces.sorted(by: { ($0.0.x + $0.0.y) < ($1.0.x + $1.0.y) }) {
                let key = SpriteKey(.building(.bridge, age), run.pose(complete: complete))
                let sprite = try #require(bridges.sprite(key))
                let civilization: Civilization = run == .alongX ? .sumer : .egypt
                Preview.place(Preview.tinted(base: sprite.base, mask: sprite.teamMask, colour: .of(civilization)),
                              anchor: sprite.anchor, at: screen(Double(tile.x) + 0.5, Double(tile.y) + 0.5), in: context)
            }
            // People crossing, and a few on the banks; trees by the water.
            // No merchant before the Bronze age: a Stone-age scene has a second hunter.
            let trader: UnitKind = age == .stone ? .worker : .merchant
            var things: [(SpriteKey, Double, Double, Civilization?, Bool)] = [
                (SpriteKey(.unit(.worker, age), .walking, frame: 2), 5.3, 4.5, .sumer, false),
                (SpriteKey(.unit(trader, age), .walking, frame: 7), 7.1, 4.5, .sumer, true),
                (SpriteKey(.unit(.scholar, age), .standing), 8.7, 4.45, .sumer, false),
                (SpriteKey(.unit(.engineer, age), .walking, frame: 4), 14.5, 10.4, .egypt, true),
                (SpriteKey(.unit(.worker, age), .walking, frame: 9), 14.5, 12.2, .egypt, false),
                (SpriteKey(.unit(.engineer, age), .working, frame: 3), 14.5, 14.0, .egypt, false),
                (SpriteKey(.unit(.worker, age), .standing), 2.5, 4.8, .sumer, false),
                (SpriteKey(.site(.tree), .complete), 2.5, 2.5, nil, false),
                (SpriteKey(.site(.tree), .complete), 12.5, 2.5, nil, false),
                (SpriteKey(.site(.tree), .complete), 16.5, 8.5, nil, false),
                (SpriteKey(.site(.tree), .complete), 12.5, 16.5, nil, false),
            ]
            things.sort { ($0.1 + $0.2) < ($1.1 + $1.2) }
            for (key, x, y, civilization, mirrored) in things {
                guard let sprite = others.sprite(key) else { continue }
                let image = civilization.map { Preview.tinted(base: sprite.base, mask: sprite.teamMask, colour: .of($0)) } ?? sprite.base
                let p = screen(x, y)
                if mirrored {
                    context.saveGState()
                    context.translateBy(x: p.x, y: 0)
                    context.scaleBy(x: -1, y: 1)
                    Preview.place(image, anchor: sprite.anchor, at: CGPoint(x: 0, y: p.y), in: context)
                    context.restoreGState()
                } else {
                    Preview.place(image, anchor: sprite.anchor, at: p, in: context)
                }
            }
            Preview.label("The \(age) age's bridge at game size: six pieces along x (Sumer) and five along y (Egypt), the last still building",
                          in: context, at: CGPoint(x: 30, y: Double(height) - 50), size: 24)
            try Preview.writePNG(context.makeImage()!, to: directory.appendingPathComponent("bridges-river-\(age)\(suffix).png"))
        }
    }
}
