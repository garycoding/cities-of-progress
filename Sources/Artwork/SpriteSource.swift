// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import CoreGraphics
import GameCore

/// One sprite, ready to draw (docs/architecture.md, "Sprites").
public struct SpriteImage: @unchecked Sendable {
    /// The picture, drawn facing right, at twice its size in points (for Retina).
    public var base: CGImage
    /// White where the civilization's colour goes, transparent elsewhere; the
    /// drawing tints it with `TeamColour` and lays it over `base`. `nil` where
    /// the subject carries no team colour (sites, terrain).
    public var teamMask: CGImage?
    /// The point at the subject's feet (for a building, the centre of its
    /// footprint's front edge), as a fraction of the image: (0, 0) is the
    /// bottom left, as SpriteKit's anchor point has it.
    public var anchor: (x: Double, y: Double)

    public init(base: CGImage, teamMask: CGImage?, anchor: (x: Double, y: Double)) {
        self.base = base; self.teamMask = teamMask; self.anchor = anchor
    }
}

/// Supplies sprites by key. `MapDrawing` asks; `Artwork` answers. A missing
/// sprite returns `nil`, and the drawing then shows a placeholder shape, so that
/// neither waits for the other.
public protocol SpriteSource: Sendable {
    func sprite(_ key: SpriteKey) -> SpriteImage?
}

/// A source with no sprites at all: everything is drawn as a placeholder.
public struct EmptySpriteSource: SpriteSource {
    public init() {}
    public func sprite(_ key: SpriteKey) -> SpriteImage? { nil }
}
