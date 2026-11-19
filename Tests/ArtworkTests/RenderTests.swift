// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import AppKit
import CoreGraphics
import Foundation
import GameCore
import Testing
@testable import Artwork

/// Renders the batch for a person to judge, into the directory named by the
/// environment variable `ARTWORK_RENDERS`; skipped when it is not set.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["ARTWORK_RENDERS"] != nil))
struct RenderTests {
    let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["ARTWORK_RENDERS"] ?? "/", isDirectory: true)

    static let kinds: [UnitKind] = [.worker, .scholar, .engineer, .clubman, .slinger, .founder]

    /// For each kind and pose, its 12 frames enlarged (three times the game's
    /// pixels, drawn from the same SVG) in two rows, and beneath them the
    /// sprites themselves at their own size.
    @Test func posesAsStrips() throws {
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("strips"), withIntermediateDirectories: true)
        let sprites = CartoonSprites()
        let large = Canvas.person.scaled(to: 4)
        let colour = TeamColour.of(.sumer)
        for pose in sprites.poses {
            guard case .unit(let kind, _) = pose.subject, let look = StonePeople.person(kind) else { continue }
            let cellW = large.pixelWidth, cellH = large.pixelHeight
            let small = Canvas.person
            let width = cellW * 6, height = cellH * 2 + small.pixelHeight + 20
            let ground = Preview.ground(width: width, height: height, tile: 256)
            let context = Raster.bitmap(width: width, height: height)!
            context.draw(ground, in: CGRect(x: 0, y: 0, width: width, height: height))
            for frame in 0..<12 {
                let drawn = try #require(look.render(pose.pose, frame: frame, canvas: large))
                let image = Preview.tinted(base: drawn.base, mask: drawn.mask, colour: colour)
                let col = frame % 6, row = frame / 6
                let x = Double(col * cellW), y = Double(height - (row + 1) * cellH)
                context.draw(image, in: CGRect(x: x, y: y, width: Double(cellW), height: Double(cellH)))
                Preview.label("\(frame)", in: context, at: CGPoint(x: x + 8, y: y + 8), size: 18)
                let sprite = try #require(sprites.sprite(SpriteKey(pose.subject, pose.pose, frame: frame)))
                let smallImage = Preview.tinted(base: sprite.base, mask: sprite.teamMask, colour: colour)
                context.draw(smallImage, in: CGRect(x: Double(frame * (small.pixelWidth + 8) + 8), y: 10,
                                                    width: Double(small.pixelWidth), height: Double(small.pixelHeight)))
            }
            let name = "\(kind)-\(pose.pose.rawValue).png"
            try Preview.writePNG(context.makeImage()!, to: directory.appendingPathComponent("strips").appendingPathComponent(name))
            // The sprite's own pictures, untinted, for checking pixel by pixel.
            let sprite = try #require(sprites.sprite(SpriteKey(pose.subject, pose.pose, frame: 0)))
            try FileManager.default.createDirectory(at: directory.appendingPathComponent("sprites"), withIntermediateDirectories: true)
            try Preview.writePNG(sprite.base, to: directory.appendingPathComponent("sprites/\(kind)-\(pose.pose.rawValue)-base.png"))
            if let mask = sprite.teamMask {
                try Preview.writePNG(mask, to: directory.appendingPathComponent("sprites/\(kind)-\(pose.pose.rawValue)-mask.png"))
            }
        }
    }
}
