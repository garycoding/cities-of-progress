// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import CoreGraphics
import Foundation
import GameCore
import Testing
@testable import Artwork

/// Renders the Alchemy age's boats' art for a person to judge, into the
/// directory named by the environment variable `BOATS_RENDERS`, as the Stone
/// age's renders are (`StoneBoatsRenders`), each file's name beginning with
/// `alchemy-` so that the two sets lie side by side, and ending with
/// `BOATS_RENDERS_SUFFIX` where it is set; skipped when `BOATS_RENDERS` is not
/// set. The sheets are PNG, the movement animated GIF at 12 frames a second,
/// all on the game's own water and ground tiles, in Sumer's colour.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["BOATS_RENDERS"] != nil))
struct AlchemyBoatsRenders {
    private let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["BOATS_RENDERS"] ?? "/", isDirectory: true)
    private let suffix = ProcessInfo.processInfo.environment["BOATS_RENDERS_SUFFIX"] ?? ""
    private let colour = TeamColour.of(.sumer)

    private func write(_ image: CGImage, _ name: String) throws {
        let url = directory.appendingPathComponent("alchemy-\(name)\(suffix).png")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Preview.writePNG(image, to: url)
    }

    private func writeGIF(_ frames: [CGImage], _ name: String) throws {
        let url = directory.appendingPathComponent("alchemy-\(name)\(suffix).gif")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Preview.writeGIF(frames, to: url)
    }

    // MARK: The boat house

    /// The boat house, complete and under construction, enlarged on its
    /// cobbled quay, and at game size beside the Alchemy age's house.
    @Test func boatHouse() throws {
        let width = 1600, height = 900
        let context = Raster.bitmap(width: width, height: height)!
        context.draw(Preview.ground(width: width, height: height, tile: 256), in: CGRect(x: 0, y: 0, width: width, height: height))
        let source = AlchemyOldBuildingSprites()
        for (i, complete) in [true, false].enumerated() {
            let key = SpriteKey(.building(.boatHouse, .alchemy), complete ? .complete : .underConstruction)
            let large = AlchemyOldBuildingsArt.canvas(.boatHouse).scaled(to: 4.4)
            let drawn = try #require(Raster.render(on: large) { svg in
                var painter = AlchemyOldBuildingsPainter(layer: svg.layer)
                painter.boatHouse(complete: complete)
                svg = painter.svg
            })
            Preview.place(Preview.tinted(base: drawn.base, mask: drawn.mask, colour: colour), anchor: large.anchor,
                          at: CGPoint(x: 330 + Double(i) * 640, y: 330), in: context)
            Preview.label(complete ? "complete" : "under construction", in: context, at: CGPoint(x: 230 + Double(i) * 640, y: 40), size: 24)
            let sprite = try #require(source.sprite(key))
            Preview.place(Preview.tinted(base: sprite.base, mask: sprite.teamMask, colour: colour), anchor: sprite.anchor,
                          at: CGPoint(x: 1420, y: 520 - Double(i) * 330), in: context)
        }
        let house = try #require(source.sprite(SpriteKey(.building(.house, .alchemy), .complete)))
        Preview.place(Preview.tinted(base: house.base, mask: house.teamMask, colour: colour), anchor: house.anchor,
                      at: CGPoint(x: 1420, y: 760), in: context)
        Preview.label("at game size, the house above for scale", in: context, at: CGPoint(x: 1260, y: 40), size: 16)
        Preview.label("The Alchemy age's boat house, in Sumer's colour", in: context, at: CGPoint(x: 28, y: Double(height) - 48), size: 26)
        try write(context.makeImage()!, "boat-house")
    }
}
