// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import CoreGraphics
import Foundation
import GameCore
import Testing
@testable import Artwork

/// The Stone age's buildings (`StoneBuildingSprites`): which keys they answer,
/// where their pictures stand, and that they are drawn the same every time.
@Suite struct StoneBuildingsTests {
    private static let kinds: [BuildingKind] = [.townCentre, .house, .storagePit, .boatHouse]
    private static let poses: [SpritePose] = [.complete, .underConstruction]
    private static let keys = kinds.flatMap { kind in poses.map { SpriteKey(.building(kind, .stone), $0) } }

    /// An image's pixels as premultiplied RGBA, top row first.
    private struct Pixels {
        let width: Int, height: Int
        let bytes: [UInt8]

        init(_ image: CGImage) {
            width = image.width
            height = image.height
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            bytes.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                        bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            self.bytes = bytes
        }

        /// The alpha at column `x`, row `y` from the top, both rounded.
        func alpha(_ x: Double, _ y: Double) -> UInt8 {
            let column = Int(x.rounded()), row = Int(y.rounded())
            guard column >= 0, row >= 0, column < width, row < height else { return 0 }
            return bytes[(row * width + column) * 4 + 3]
        }
    }

    @Test func everyKeyOfTheBatchHasASpriteWithAMask() throws {
        let source = StoneBuildingSprites()
        for key in Self.keys {
            let sprite = try #require(source.sprite(key), "no sprite for \(key)")
            let mask = try #require(sprite.teamMask, "no team mask for \(key)")
            #expect(mask.width == sprite.base.width && mask.height == sprite.base.height, "\(key)")
        }
    }

    /// The anchor is the centre of the footprint's diamonds, at twice the size
    /// in points: the trodden ground drawn on the footprint (a little inside
    /// it, its corners rounded) covers the points most of the way from the
    /// anchor to each corner, nothing lies just beyond the side and front
    /// corners, and nothing at all lies below the front corner.
    @Test func theAnchorIsTheCentreOfTheFootprint() throws {
        let source = StoneBuildingSprites()
        for key in Self.keys {
            guard case .building(let kind, _) = key.subject else { continue }
            let sprite = try #require(source.sprite(key))
            let pixels = Pixels(sprite.base)
            let x = sprite.anchor.x * Double(pixels.width), y = (1 - sprite.anchor.y) * Double(pixels.height)
            let size = Catalogue.standard.stats(kind).footprint
            let (fx, fy) = (Double(size.x) / 2, Double(size.y) / 2)
            // A map offset from the footprint's centre, in pixels from the anchor (y downward).
            func corner(_ mx: Double, _ my: Double) -> (Double, Double) {
                ((mx - my) * Projection.tileWidth, (mx + my) * Projection.tileHeight)
            }
            let corners = [corner(-fx, -fy), corner(fx, -fy), corner(fx, fy), corner(-fx, fy)]
            for (cx, cy) in corners {
                #expect(pixels.alpha(x + cx * 0.8, y + cy * 0.8) > 200, "\(key): ground missing toward (\(cx), \(cy))")
            }
            let (right, front, left) = (corners[1], corners[2], corners[3])
            #expect(pixels.alpha(x + right.0 + 6, y + right.1) == 0, "\(key): drawn beyond the right corner")
            #expect(pixels.alpha(x + left.0 - 6, y + left.1) == 0, "\(key): drawn beyond the left corner")
            let below = Int((y + front.1 + 3).rounded())
            #expect(below < pixels.height, "\(key): no room below the front corner")
            for row in below..<pixels.height {
                for column in 0..<pixels.width where pixels.alpha(Double(column), Double(row)) != 0 {
                    Issue.record("\(key): drawn below the front corner at (\(column), \(row))")
                    return
                }
            }
        }
    }

    @Test func nothingIsCutOffAtTheEdges() throws {
        let source = StoneBuildingSprites()
        for key in Self.keys {
            let sprite = try #require(source.sprite(key))
            for image in [sprite.base, try #require(sprite.teamMask)] {
                let pixels = Pixels(image)
                let w = pixels.width - 1, h = pixels.height - 1
                let edge = (0...w).flatMap { [($0, 0), ($0, h)] } + (0...h).flatMap { [(0, $0), (w, $0)] }
                #expect(edge.allSatisfy { pixels.alpha(Double($0.0), Double($0.1)) == 0 }, "\(key) touches its edge")
            }
        }
    }

    @Test func everyOtherKeyGivesNil() {
        let source = StoneBuildingSprites()
        var others = SpriteKey.required(through: .bronze).filter { !Self.keys.contains($0) }
        for kind in Self.kinds {
            for frame in 1..<SpriteKey.framesPerPose {
                for pose in Self.poses { others.append(SpriteKey(.building(kind, .stone), pose, frame: frame)) }
            }
            for pose in [SpritePose.standing, .walking, .working, .fighting, "ruined"] {
                others.append(SpriteKey(.building(kind, .stone), pose))
            }
            for age in Age.allCases where age != .stone {
                others.append(SpriteKey(.building(kind, age), .complete))
            }
        }
        for kind in BuildingKind.allCases where !Self.kinds.contains(kind) {
            others.append(SpriteKey(.building(kind, .stone), .complete))
            others.append(SpriteKey(.building(kind, .stone), .underConstruction))
        }
        for key in others { #expect(source.sprite(key) == nil, "\(key) should be nil") }
    }

    /// Two sources, each drawing afresh, give the same pixels for every key.
    @Test func theSameKeyGivesTheSamePixels() throws {
        let first = StoneBuildingSprites(), second = StoneBuildingSprites()
        for key in Self.keys {
            let a = try #require(first.sprite(key)), b = try #require(second.sprite(key))
            #expect(Pixels(a.base).bytes == Pixels(b.base).bytes, "\(key): the picture differs")
            let maskA = try #require(a.teamMask), maskB = try #require(b.teamMask)
            #expect(Pixels(maskA).bytes == Pixels(maskB).bytes, "\(key): the mask differs")
            #expect(a.anchor == b.anchor, "\(key): the anchor differs")
        }
    }

    @Test func theBatchRendersInUnderThreeSeconds() throws {
        let source = StoneBuildingSprites()
        let clock = ContinuousClock()
        let elapsed = try clock.measure {
            for key in Self.keys { _ = try #require(source.sprite(key)) }
        }
        #expect(elapsed < .seconds(3), "the batch took \(elapsed)")
    }
}
