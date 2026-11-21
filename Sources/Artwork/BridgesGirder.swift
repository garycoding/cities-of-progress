// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation

// The iron bridge of the Industrial age: a deck of iron plates on two riveted
// plate girders, carried at each end of the piece by a pair of cast-iron
// columns standing in the water, braced across, and a low Warren truss of
// riveted bars along each side, painted bottle green. Each piece holds two
// panels of the truss; its end posts stand on the joints, so that a row of
// pieces shows the truss's zigzag unbroken from bank to bank.

extension BridgesPainter {
    /// Half the deck's width, in tiles.
    static let girderHalfWidth = 0.32

    mutating func girders(complete: Bool) {
        typealias I = IndustrialOldBuildingsInk
        let w = Self.girderHalfWidth, h = BridgesLook.girder.deckHeight, t = 2.6, e = Self.overlap
        let laid = complete ? 0.5 : 0.0
        film(level(-0.5, laid, -w, w + 0.06, 0), opacity: 0.2)

        // The columns at both ends, far before near, with the bracing across the near end's pair.
        let columnV = w - 0.05
        for u in [-0.5, 0.5] { column(u, -columnV, top: h - t) }
        pole(at(0.5, -columnV, h - t - 0.2), at(0.5, columnV, 0.8), width: 0.8, colour: I.greenShade, line: 0.4)
        pole(at(0.5, columnV, h - t - 0.2), at(0.5, -columnV, 0.8), width: 0.8, colour: I.greenShade, line: 0.4)
        for u in [-0.5, 0.5] { column(u, columnV, top: h - t) }

        // The near girder and its end, with flanges, stiffeners and rivets.
        colour(along(w, -0.5 - e, 0.5 + e, h - t, h), .colour(side(I.green, I.greenShade)))
        colour(across(0.5, -w, w, h - t, h), .colour(end(I.green, I.greenShade)))
        line([at(-0.5, w, h - t + 0.6), at(0.5, w, h - t + 0.6)], width: 0.45, opacity: 0.8)
        line([at(-0.5, w, h - 0.6), at(0.5, w, h - 0.6)], width: 0.45, opacity: 0.8)
        for k in 0..<4 {
            let u = -0.5 + Double(k) / 4 + 1.0 / 8
            line([at(u, w, h - t + 0.6), at(u, w, h - 0.6)], width: 0.5, opacity: 0.8)
        }
        for k in 0..<16 {
            let u = -0.5 + Double(k) / 16 + 1.0 / 32
            for r in [h - 0.3, h - t + 0.3] { svg.circle(at(u, w, r), 0.38, fill: .colour(I.greenDark)) }
        }
        line([at(-0.5, w, h - t), at(0.5, w, h - t), at(0.5, -w + 0.04, h - t)], width: 0.9)

        // The deck: iron plates, or, whilst building, cross girders over the water beyond the laid plates.
        colour(level(-0.5 - e, laid, -w, w, h), .colour(I.sootLight))
        if !complete {
            colour(level(laid, 0.5 + e, w - 0.05, w, h), .colour(I.greenLight))
            colour(level(laid, 0.5 + e, -w, -w + 0.05, h), .colour(I.greenLight))
            line([at(laid, w - 0.05, h), at(0.5, w - 0.05, h)], width: 0.5)
            line([at(laid, -w + 0.05, h), at(0.5, -w + 0.05, h)], width: 0.5)
            for u in [0.12, 0.37] {
                block(u, u + 0.05, -w + 0.05, w - 0.05, h - 1.4, h - 0.2, top: I.greenLight, lit: I.green,
                      shade: I.greenShade, width: 0.5)
            }
        }
        for k in 0...4 {
            let u = -0.5 + Double(k) / 4
            guard u <= laid + 0.001 else { continue }
            line([at(u, -w, h), at(u, w, h)], width: 0.5, opacity: 0.8)
            guard k < 4, u + 0.25 <= laid + 0.001 else { continue }
            // The plates' raised tread, and a rivet at each corner.
            for j in 0..<3 {
                let a = u + 0.06 + Double(j) * 0.07
                line([at(a, -0.12, h), at(a + 0.025, -0.06, h)], width: 0.4, opacity: 0.5)
                line([at(a, 0.08, h), at(a + 0.025, 0.14, h)], width: 0.4, opacity: 0.5)
            }
            for (du, v) in [(0.03, -w + 0.05), (0.22, -w + 0.05), (0.03, w - 0.05), (0.22, w - 0.05)] {
                svg.circle(at(u + du, v, h), 0.4, fill: .colour(I.sootDark))
            }
        }
        line([at(-0.5, w, h), at(0.5, w, h)], width: 1)
        line([at(-0.5, -w, h), at(0.5, -w, h)], width: 0.8)
        if !complete {
            line([at(laid, -w, h), at(laid, w, h)], width: 0.7)
            // Girders lying across the deck, waiting to be raised.
            girderLying(-0.36, -0.2, 0.18, h: h)
            girderLying(-0.22, -0.14, 0.24, h: h + 1.3)
        }

        // The far truss, the owner's pennant, the near truss.
        let rise = 6.0
        for v in [-w + 0.03, w - 0.03] {
            truss(v, h: h, rise: rise, complete: complete || v < 0, partial: !complete)
            if v < 0 {
                let foot = complete ? at(0, v, h + rise) : at(-0.5, v, h + rise)
                pennant(at: foot, height: 7.5, staff: I.sootDark)
            }
        }
    }

    /// A cast-iron column standing in the water at (`u`, `v`), its top at `top`.
    private mutating func column(_ u: Double, _ v: Double, top: Double) {
        typealias I = IndustrialOldBuildingsInk
        let foot = at(u, v, 0)
        submerged(at: foot, width: 3.2)
        post(u, v, -0.4, top, width: 3.2, colour: side(I.greenLight, I.green), line: 0.7)
        // A collar near the water and a cap under the girder.
        for r in [0.9, top - 0.5] {
            let c = at(u, v, r)
            svg.ellipse(c + P(-0.3, 0.2), 2.1, 0.75, fill: .colour(I.greenShade))
            svg.ellipse(c, 2.1, 0.75, fill: .none, stroke: .colour(BridgesInk.line), width: 0.5)
        }
        ripple(at: foot, 2.6)
    }

    /// The truss along the side at `v`: two Warren panels between end posts on
    /// the joints, under a top chord, with gusset plates at the nodes. Whilst
    /// building (`partial`), only the back panel's end post and first bar on
    /// the far side, and the near side's end post.
    private mutating func truss(_ v: Double, h: Double, rise: Double, complete: Bool, partial: Bool) {
        typealias I = IndustrialOldBuildingsInk
        let paint = side(I.greenLight, I.green), e = Self.overlap
        let top = h + rise
        func bar(_ u0: Double, _ h0: Double, _ u1: Double, _ h1: Double, _ width: Double = 1.25) {
            pole(at(u0, v, h0), at(u1, v, h1), width: width, colour: paint, line: 0.5)
        }
        if partial {
            bar(-0.5, h, -0.5, top, 1.5)
            if v < 0 { bar(-0.5, h, -0.25, top) }
            return
        }
        guard complete else { return }
        bar(-0.5, h, -0.25, top)
        bar(-0.25, top, 0, h)
        bar(0, h, 0.25, top)
        bar(0.25, top, 0.5, h)
        bar(-0.5, h, -0.5, top, 1.5)
        bar(0.5, h, 0.5, top, 1.5)
        bar(-0.5 - e, top, 0.5 + e, top, 1.6)
        // Gusset plates at the nodes, each with its rivets.
        for (u, r, up) in [(-0.25, top, false), (0.25, top, false), (0.0, h, true)] {
            let c = at(u, v, r), s = up ? -1.0 : 1.0
            let plate = [c + P(-2.2, 0), c + P(2.2, 0), c + P(0, 2.6 * s)]
            shape(plate, .colour(I.greenLight), width: 0.45, shift: P(-0.3, 0.2))
            for p in [c + P(-1, 0.5 * s), c + P(1, 0.5 * s), c + P(0, 1.5 * s)] {
                svg.circle(p, 0.36, fill: .colour(I.greenDark))
            }
        }
        for k in 0..<8 {
            let u = -0.5 + Double(k) / 8 + 1.0 / 16
            svg.circle(at(u, v, top), 0.32, fill: .colour(I.greenDark))
        }
    }

    /// A riveted I-girder lying across the deck from `v0` to `v1` at `u`.
    private mutating func girderLying(_ u: Double, _ v0: Double, _ v1: Double, h: Double) {
        typealias I = IndustrialOldBuildingsInk
        block(u, u + 0.06, v0, v1, h, h + 1.3, top: I.greenLight, lit: I.green, shade: I.greenShade, width: 0.5)
        line([at(u + 0.03, v0, h + 1.3), at(u + 0.03, v1, h + 1.3)], width: 0.4, opacity: 0.7)
    }
}
