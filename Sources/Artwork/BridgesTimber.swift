// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// The wooden bridge of the Stone, Bronze and Iron ages: a deck on two
// stringers, carried at each end of the piece by a bent of two timber piles
// standing in the water, with a post at each end and in the middle of each
// side and a rope (or, in the Iron age, a timber rail) between them. The Stone
// age lays round logs across the stringers; the Bronze and Iron ages lay sawn
// planks. Eight logs or planks to the tile, every other one a shade apart, so
// that the pattern runs on unbroken from piece to piece.

/// The colours of one age's wooden bridge, from that age's palette.
struct BridgesTimberInk: Sendable {
    /// The deck's top, and every other log or plank.
    var top: String
    var topAlt: String
    /// A log's lit crown, or the edge of a plank.
    var highlight: String
    /// Timber in the light and in shade.
    var lit: String
    var shade: String
    /// The cut end of a log.
    var cutEnd: String
    /// The rope between the posts, or the colour of the rail.
    var rope: String
    /// A post's cap: bronze, iron, or none.
    var cap: String?
    /// Round logs rather than sawn planks.
    var logs: Bool
    /// A timber handrail rather than a rope.
    var handrail: Bool
    /// Nails or straps of iron.
    var iron: String?

    static func of(_ age: Age) -> BridgesTimberInk {
        switch age {
        case .stone:
            // Hide and moss: barked logs, a rope of twisted grass.
            BridgesTimberInk(top: "#b98a58", topAlt: "#a87a4b", highlight: "#cfa070", lit: "#8a5a33", shade: "#6b4a2a",
                             cutEnd: "#d9b47e", rope: "#d9b47e", cap: nil, logs: true, handrail: false, iron: nil)
        case .bronze:
            // Sawn planks bleached by the sun, a reed rope, bronze caps on the posts.
            BridgesTimberInk(top: "#b8854d", topAlt: "#a8743f", highlight: "#cf9f66", lit: "#8a5a33", shade: "#6b4a2a",
                             cutEnd: "#d9b47e", rope: "#cda85e", cap: "#b47b36", logs: false, handrail: false, iron: nil)
        default:
            // Iron: darker oiled planks, a timber handrail, iron straps and nails.
            BridgesTimberInk(top: "#a8743f", topAlt: "#956538", highlight: "#bd8a52", lit: "#8a5a33", shade: "#6b4a2a",
                             cutEnd: "#cda85e", rope: "#a8743f", cap: "#5f5b56", logs: false, handrail: true, iron: "#5f5b56")
        }
    }
}

extension BridgesPainter {
    /// Half the deck's width, in tiles.
    static let timberHalfWidth = 0.32

    mutating func timber(_ ink: BridgesTimberInk, complete: Bool) {
        let w = Self.timberHalfWidth, h = BridgesLook.timber.deckHeight, t = 2.2, e = Self.overlap
        let count = 8, step = 1.0 / Double(count)
        // Where the deck is laid: all of it, or, whilst building, its back half.
        let laid = complete ? 0.5 : 0.0
        // The water in the deck's shadow.
        film(level(-0.5, laid, -w, w + 0.06, 0), opacity: 0.2)
        // The bents at both ends: the far piles, the brace across the near
        // end's bent (seen under the deck where the bridge meets a bank), the near piles.
        let pileV = w - 0.05
        for u in [-0.5, 0.5] { pile(u, -pileV, top: h - t, ink) }
        pole(at(0.5, -pileV, h - t - 0.3), at(0.5, pileV, 0.9), width: 1.2, colour: ink.shade, line: 0.6)
        for u in [-0.5, 0.5] { pile(u, pileV, top: h - t, ink) }

        // The near stringer, and the end of the deck where it meets the next piece.
        colour(along(w, -0.5 - e, 0.5 + e, h - t, h), .colour(side(ink.lit, ink.shade)))
        colour(across(0.5, -w, w, h - t, h), .colour(end(ink.lit, ink.shade)))
        line([at(-0.5, w, h - t), at(0.5, w, h - t), at(0.5, -w + 0.04, h - t)], width: 0.9)

        // The deck.
        if complete {
            colour(level(-0.5 - e, 0.5 + e, -w, w, h), .colour(ink.top))
        } else {
            colour(level(-0.5 - e, laid, -w, w, h), .colour(ink.top))
            // The stringers' tops, bare beyond the laid planks, and a joist across.
            colour(level(laid, 0.5 + e, w - 0.06, w, h), .colour(ink.highlight))
            colour(level(laid, 0.5 + e, -w, -w + 0.06, h), .colour(ink.highlight))
            line([at(laid, w - 0.06, h), at(0.5, w - 0.06, h)], width: 0.6)
            line([at(laid, -w + 0.06, h), at(0.5, -w + 0.06, h)], width: 0.6)
            block(0.22, 0.29, -w + 0.06, w - 0.06, h - 1.6, h - 0.3, top: ink.highlight, lit: ink.lit, shade: ink.shade,
                  width: 0.6)
        }
        for k in 0..<count where k % 2 == 1 {
            let u0 = -0.5 + Double(k) * step
            if u0 + step <= laid + 0.001 { colour(level(u0, u0 + step, -w, w, h), .colour(ink.topAlt)) }
        }
        for k in 0...count {
            let u = -0.5 + Double(k) * step
            guard u <= laid + 0.001 else { continue }
            line([at(u, -w, h), at(u, w, h)], width: ink.logs ? 0.7 : 0.5, opacity: 0.8)
            guard k < count, u + step <= laid + 0.001 else { continue }
            let mid = u + step / 2
            if ink.logs {
                // A log's lit crown, and its cut end on the near side.
                line([at(mid - step * 0.18, -w + 0.04, h), at(mid - step * 0.18, w - 0.04, h)], width: 0.8,
                     colour: ink.highlight, opacity: 0.9)
                let end = at(mid, w, h - 1.1)
                svg.ellipse(end + Self.nudge, 1.75, 1.3, fill: .colour(ink.cutEnd))
                svg.ellipse(end, 1.75, 1.3, fill: .none, stroke: .colour(BridgesInk.line), width: 0.5)
                svg.circle(end + P(0.2, 0), 0.4, fill: .colour(ink.lit))
            } else {
                // The plank's grain, and its nails over the stringers.
                line([at(mid + step * 0.12, -w + 0.1, h), at(mid + step * 0.12, -w + 0.3, h)], width: 0.4, opacity: 0.45)
                line([at(mid - step * 0.15, w - 0.28, h), at(mid - step * 0.15, w - 0.1, h)], width: 0.4, opacity: 0.45)
                if let iron = ink.iron {
                    for v in [-w + 0.04, w - 0.04] { svg.circle(at(mid, v, h), 0.45, fill: .colour(iron)) }
                }
            }
        }
        if !ink.logs {
            // The planks' ends along the near side, over the stringer.
            line([at(-0.5, w, h - 0.9), at(laid, w, h - 0.9)], width: 0.5, opacity: 0.8)
            for k in 0...count {
                let u = -0.5 + Double(k) * step
                if u <= laid + 0.001 { line([at(u, w, h), at(u, w, h - 0.9)], width: 0.5) }
            }
        }
        line([at(-0.5, w, h), at(complete ? 0.5 : laid, w, h)], width: 1)
        line([at(-0.5, -w, h), at(complete ? 0.5 : laid, -w, h)], width: 0.8)
        if !complete {
            line([at(laid, w, h), at(0.5, w, h)], width: 0.9)
            line([at(laid, -w, h), at(0.5, -w, h)], width: 0.8)
            line([at(laid, -w, h), at(laid, w, h)], width: 0.8)
            // Planks lying across the bare stringers, and two more stacked on the laid ones.
            for (u0, skew) in [(0.06, 0.05), (0.33, -0.04)] { loosePlank(u0, skew: skew, w: w, h: h, ink) }
            block(-0.4, -0.12, -0.16, -0.02, h, h + 0.9, top: ink.highlight, lit: ink.lit, shade: ink.shade, width: 0.6)
            block(-0.37, -0.09, -0.15, -0.01, h + 0.9, h + 1.8, top: ink.highlight, lit: ink.lit, shade: ink.shade,
                  width: 0.6)
        }

        // The far rail, the owner's pennant, the near rail.
        let railTop = h + 5.0
        for v in [-w + 0.03, w - 0.03] {
            let posts: [Double] = complete ? [-0.5, 0, 0.5] : [-0.5]
            for u in posts { railPost(u, v, from: h - 0.6, to: railTop, ink) }
            if complete {
                if ink.handrail {
                    pole(at(-0.5 - e, v, railTop - 0.5), at(0.5 + e, v, railTop - 0.5), width: 1.4, colour: ink.highlight,
                         line: 0.6)
                } else {
                    cord(at(-0.5, v, railTop - 0.4), at(0, v, railTop - 0.4), sag: 0.8, colour: ink.rope)
                    cord(at(0, v, railTop - 0.4), at(0.5, v, railTop - 0.4), sag: 0.8, colour: ink.rope)
                }
            }
            if v < 0 {
                let foot = complete ? at(0, v, railTop) : at(0, v, h)
                pennant(at: foot, height: complete ? 8.5 : 13, staff: ink.shade)
            }
        }
    }

    /// A pile standing in the water at (`u`, `v`), its top at `top`.
    private mutating func pile(_ u: Double, _ v: Double, top: Double, _ ink: BridgesTimberInk) {
        let foot = at(u, v, 0)
        submerged(at: foot, width: 2.8)
        post(u, v, -0.4, top, width: 2.8, colour: side(ink.lit, ink.shade), line: 0.7)
        ripple(at: foot, 2.4)
    }

    /// A rail post at (`u`, `v`) from `h0` to `h1`, with its cap or its strap.
    private mutating func railPost(_ u: Double, _ v: Double, from h0: Double, to h1: Double, _ ink: BridgesTimberInk) {
        post(u, v, h0, h1, width: 1.8, colour: side(ink.lit, ink.shade), line: 0.6)
        if let cap = ink.cap {
            let top = at(u, v, h1)
            svg.ellipse(top + P(-0.3, 0.2), 1.25, 0.8, fill: .colour(cap))
            svg.ellipse(top, 1.25, 0.8, fill: .none, stroke: .colour(BridgesInk.line), width: 0.5)
        }
        if let iron = ink.iron {
            line([at(u, v, h0 + 1.4) + P(-0.9, 0), at(u, v, h0 + 1.4) + P(0.9, 0)], width: 0.9, colour: iron)
        }
    }

    /// A loose plank lying across the stringers from `u0`, turned a little by `skew`.
    private mutating func loosePlank(_ u0: Double, skew: Double, w: Double, h: Double, _ ink: BridgesTimberInk) {
        let width = 0.1, lift = 0.8, v0 = -w - 0.05, v1 = w + 0.05
        let top = [at(u0, v0, h + lift), at(u0 + width, v0, h + lift), at(u0 + width + skew, v1, h + lift),
                   at(u0 + skew, v1, h + lift)]
        let face = [at(u0 + skew, v1, h), at(u0 + width + skew, v1, h), at(u0 + width + skew, v1, h + lift),
                    at(u0 + skew, v1, h + lift)]
        let edge = [at(u0 + width + skew, v1, h), at(u0 + width, v0, h), at(u0 + width, v0, h + lift),
                    at(u0 + width + skew, v1, h + lift)]
        colour(edge, .colour(end(ink.lit, ink.shade)), shift: Self.nudge)
        colour(face, .colour(ink.cutEnd), shift: Self.nudge)
        colour(top, .colour(ink.top), shift: Self.nudge)
        line(top, closed: true, width: 0.6)
        line([at(u0 + skew, v1, h + lift), at(u0 + skew, v1, h), at(u0 + width + skew, v1, h), at(u0 + width, v0, h)],
             width: 0.6)
        line([at(u0 + width + skew, v1, h), at(u0 + width + skew, v1, h + lift)], width: 0.5)
    }
}
