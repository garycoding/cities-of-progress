// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore
import Synchronization

// The bridge (ruled 2026-11-21): one water tile's piece of a straight bridge,
// drawn for each age from the Stone to the Industrial, running along the map's
// x axis or its y axis, complete and under construction. Three looks serve the
// five ages: wooden planks on timber piles with a rail on each side (Stone,
// Bronze and Iron, each in its own palette), stone arches with a parapet
// (Alchemy), and an iron girder deck between riveted trusses (Industrial).
//
// The key names no neighbours, so every piece is drawn to join the pieces on
// either side of it along its run: the deck reaches the tile's two edges
// across the run, and everything that repeats along it (planks, posts, piers,
// truss panels) is spaced so that it divides the tile evenly. What stands on
// a joint (a pile, a post, a pier) is drawn by both pieces in the same place,
// so that the later piece, drawn in front, repeats it whole and the last piece
// of a bridge still ends on it at the bank.

/// The sprites of the bridge: `SpriteSubject.building(.bridge, age)` for every
/// age from `.stone` to `.industrial`, in the poses `BridgeRun.pose(complete:)`
/// gives, at frame 0. Every other key gives nil, the bridge's own `complete`
/// and `underConstruction` among them. A picture is drawn the first time it is
/// asked for and kept.
public struct BridgeSprites: SpriteSource {
    private let kept = BridgesKept()

    public init() {}

    public func sprite(_ key: SpriteKey) -> SpriteImage? {
        guard let piece = BridgesPiece(key) else { return nil }
        if let known = kept.images.withLock({ $0[piece] }) { return known }
        guard let made = piece.render() else { return nil }
        return kept.images.withLock { images in
            if let first = images[piece] { return first }
            images[piece] = made
            return made
        }
    }
}

/// The pictures drawn so far, safe to share between the threads that ask.
final class BridgesKept: Sendable {
    let images = Mutex<[BridgesPiece: SpriteImage]>([:])
}

/// The three ways a bridge is built.
enum BridgesLook: Sendable {
    /// Planks on timber piles, with a rope or a rail on each side.
    case timber
    /// Stone arches under a parapet.
    case stone
    /// An iron deck between riveted trusses, on iron columns.
    case girder

    /// The height of the walking surface above the water, in points: low, so
    /// that a person drawn at the tile's ground level reads as standing on it.
    var deckHeight: Double {
        switch self {
        case .timber: 6
        case .stone: 6
        case .girder: 6
        }
    }
}

/// One of the batch's pictures: an age's piece, along a run, complete or not.
struct BridgesPiece: Hashable, Sendable {
    var age: Age
    var run: BridgeRun
    var complete: Bool

    /// The ages this batch draws.
    static let ages: [Age] = [.stone, .bronze, .iron, .alchemy, .industrial]

    /// Every key of the batch.
    static let keys: [SpriteKey] = ages.flatMap { age in
        BridgeRun.allCases.flatMap { run in
            [true, false].map { SpriteKey(.building(.bridge, age), run.pose(complete: $0)) }
        }
    }

    init(age: Age, run: BridgeRun, complete: Bool) {
        self.age = age; self.run = run; self.complete = complete
    }

    /// The piece a key names, or nil where the key is not this batch's.
    init?(_ key: SpriteKey) {
        guard key.frame == 0, case .building(.bridge, let age) = key.subject, BridgesPiece.ages.contains(age),
              let found = BridgeRun.allCases.lazy.compactMap({ run -> (BridgeRun, Bool)? in
                  if key.pose == run.pose(complete: true) { return (run, true) }
                  if key.pose == run.pose(complete: false) { return (run, false) }
                  return nil
              }).first
        else { return nil }
        self.init(age: age, run: found.0, complete: found.1)
    }

    var look: BridgesLook {
        switch age {
        case .alchemy: .stone
        case .industrial, .silicon, .ai: .girder
        case .stone, .bronze, .iron: .timber
        }
    }

    /// The part of the picture's plane every piece covers, in points, with the
    /// origin on the water at the centre of the tile, drawn at twice its size
    /// (docs/architecture.md, "Sprites"): the tile's width with a margin, room
    /// above for a rail and the pennant, and room below for the piers' feet.
    static let canvas = Canvas(minX: -40, minY: -44, width: 80, height: 68, pixelsPerUnit: 2)

    /// The picture and its team-colour mask, anchored at the centre of the tile.
    func render() -> SpriteImage? {
        render(on: BridgesPiece.canvas)?.sprite(anchor: BridgesPiece.canvas.anchor)
    }

    /// The picture on a canvas of the batch's area at any scale (to look closely).
    func render(on canvas: Canvas) -> Rendered? {
        Raster.render(on: canvas) { svg in
            var painter = BridgesPainter(layer: svg.layer, run: run)
            switch look {
            case .timber: painter.timber(BridgesTimberInk.of(age), complete: complete)
            case .stone: painter.arches(complete: complete)
            case .girder: painter.girders(complete: complete)
            }
            svg = painter.svg
        }
    }
}
