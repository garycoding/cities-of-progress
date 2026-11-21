// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation

// The stone bridge of the Alchemy age: two round-headed arches to the tile,
// springing from three piers, one in the middle of the tile and one on each of
// its edges, every pier with a pointed cutwater on the near side; a ring of
// pale voussoirs round each arch against rougher spandrels; and a paved road
// between two low parapets of dressed stone with a coping. The piers on the
// edges stand on the joints between pieces, so that a row of pieces shows
// arch, pier, arch at one pitch, and the bridge's last piece ends on a pier at
// the bank. (One flat arch to the tile was tried, and at game size it read as
// a slot under a slab.)

extension BridgesPainter {
    /// Half the road's width over the parapets' outer faces, in tiles.
    static let stoneHalfWidth = 0.36

    mutating func arches(complete: Bool) {
        typealias I = AlchemyOldBuildingsInk
        let w = Self.stoneHalfWidth, h = BridgesLook.stone.deckHeight, e = Self.overlap
        // The parapet's height and thickness.
        let ph = 2.6, pt = 0.09
        // Each arch: its centre, its half-span, where it springs, how far it rises, its ring's depth.
        let centres = [-0.25, 0.25], s = 0.18, spring = 0.6, rise = 3.4, ring = 1.0
        let steps = 12
        /// The underside of the arch about `c` at `u` (a half ellipse from pier to pier).
        func intrados(_ c: Double, _ u: Double) -> Double {
            let x = (u - c) / s
            return spring + rise * max(0, 1 - x * x).squareRoot()
        }
        /// The arch ring's back about `c` at `u`, from the springing of a wider ellipse.
        func extrados(_ c: Double, _ u: Double) -> Double {
            let x = (u - c) / (s + 0.045)
            return spring + (rise + ring) * max(0, 1 - x * x).squareRoot()
        }
        func arc(_ c: Double, _ half: Double) -> [Double] {
            (0...steps).map { c - half + 2 * half * Double($0) / Double(steps) }
        }
        let wallTop = complete ? h + ph : h
        let shallow = P(-0.5, 0.35)

        // The road and the far parapet's inner face and coping; or, whilst
        // building, rubble over the back arch and the front arch's bare ring.
        if complete {
            colour(level(-0.5 - e, 0.5 + e, -w + pt, w - pt, h), .colour(I.paving))
            for k in 0..<8 {
                let u = -0.5 + Double(k) / 8 + 1.0 / 16, r = k % 2 == 0 ? -0.1 : 0.1
                line([at(u, r - 0.08, h), at(u, r + 0.08, h)], width: 0.45, opacity: 0.45)
            }
            for v in [-0.1, 0.1] { line([at(-0.5, v, h), at(0.5, v, h)], width: 0.4, opacity: 0.3) }
            colour(along(-w + pt, -0.5 - e, 0.5 + e, h, h + ph), .colour(side(I.stone, I.stoneShade)), shift: shallow)
            colour(level(-0.5 - e, 0.5 + e, -w, -w + pt, h + ph), .colour(I.stoneTop), shift: shallow)
            for k in 0..<6 {
                let u = -0.5 + Double(k) / 6
                line([at(u, -w + pt, h + 0.2), at(u, -w + pt, h + ph - 0.2)], width: 0.45, opacity: 0.7)
            }
            line([at(-0.5, -w + pt, h), at(0.5, -w + pt, h)], width: 0.7)
            line([at(-0.5, -w + pt, h + ph), at(0.5, -w + pt, h + ph)], width: 0.8)
            line([at(-0.5, -w, h + ph), at(0.5, -w, h + ph)], width: 0.6, opacity: 0.8)
            pennant(at: at(0, -w + pt / 2, h + ph), height: 8, staff: I.ironDark)
        } else {
            colour(level(-0.5 - e, 0, -w, w, h), .colour(I.rawStoneShade))
            let front = arc(0.25, s + 0.045)
            let back = front.map { at($0, w, extrados(0.25, $0)) } + front.reversed().map { at($0, -w, extrados(0.25, $0)) }
            colour(back, .colour(I.footing))
            line(front.map { at($0, -w, extrados(0.25, $0)) }, width: 0.7)
            for u in stride(from: 0.25 - s + 0.03, to: 0.25 + s, by: 0.06) {
                line([at(u, -w + 0.02, extrados(0.25, u)), at(u, w - 0.02, extrados(0.25, u))], width: 0.45, opacity: 0.7)
            }
            // The piers' tops between the arches, level with the springing of the fill.
            colour(level(0.43, 0.5 + e, -w, w, extrados(0.25, 0.43)), .colour(I.footing))
            colour(across(0, -w, w, h - 0.2, h), .colour(end(I.rawStone, I.rawStoneShade)))
            line([at(0, w, h - 0.2), at(0, w, h), at(0, -w, h)], width: 0.8)
            line([at(-0.5, -w, h), at(0, -w, h)], width: 0.7)
            for (u, v) in [(-0.34, -0.2), (-0.2, 0.08), (-0.38, 0.14), (-0.12, -0.12)] {
                svg.ellipse(at(u, v, h), 1.6, 0.8, fill: .colour(I.rawStone), stroke: .colour(BridgesInk.line), width: 0.4)
            }
        }

        // The near face: piers and spandrels, with the arches' openings left out.
        var face: [P] = [at(-0.5 - e, w, 0)]
        for c in centres {
            face += [at(c - s, w, 0)] + arc(c, s).map { at($0, w, intrados(c, $0)) } + [at(c + s, w, 0)]
        }
        face += [at(0.5 + e, w, 0)]
        if complete {
            face += [at(0.5 + e, w, h), at(-0.5 - e, w, h)]
        } else {
            // The back arch's spandrels filled to the road, the front arch's ring standing bare.
            face += [at(0.5 + e, w, extrados(0.25, 0.43))]
            face += arc(0.25, s + 0.045).reversed().map { at($0, w, extrados(0.25, $0)) }
            face += [at(0.0, w, h), at(-0.5 - e, w, h)]
        }
        colour(face, .colour(side(I.footing, I.footingShade)))

        // The openings: the water under each arch in shadow, darker under the vault.
        for c in centres {
            let curve = arc(c, s).map { at($0, w, intrados(c, $0)) }
            film([at(c - s, w, 0)] + curve + [at(c + s, w, 0)], opacity: 0.45)
            film([at(c - s, w, spring + 1)] + curve + [at(c + s, w, spring + 1)], opacity: 0.22)
            if complete || c < 0 {
                line([at(c - s * 0.6, w, 0.45), at(c + s * 0.2, w, 0.45)], width: 0.6, colour: BridgesInk.ripple, opacity: 0.6)
            } else {
                centring(c, s: s, w: w, spring: spring, intrados: { intrados(c, $0) })
            }
        }

        // The rings of voussoirs, each with its keystone.
        for c in centres {
            let inner = arc(c, s), outer = arc(c, s + 0.045)
            let band = inner.map { at($0, w, intrados(c, $0)) } + outer.reversed().map { at($0, w, extrados(c, $0)) }
            colour(band, .colour(side(I.stoneTop, I.stone)), shift: shallow)
            line(inner.map { at($0, w, intrados(c, $0)) }, width: 0.8)
            line(outer.map { at($0, w, extrados(c, $0)) }, width: 0.7)
            for i in 1..<steps where i != steps / 2 {
                line([at(inner[i], w, intrados(c, inner[i])), at(outer[i], w, extrados(c, outer[i]))], width: 0.5, opacity: 0.85)
            }
            let key = [at(c - 0.025, w, intrados(c, c - 0.025)), at(c + 0.025, w, intrados(c, c + 0.025)),
                       at(c + 0.035, w, extrados(c, c) + 0.4), at(c - 0.035, w, extrados(c, c) + 0.4)]
            shape(key, .colour(side(I.rawStoneTop, I.stoneTop)), width: 0.6, shift: shallow)
        }

        // Courses in the spandrels, then the parapet on the near face.
        for c in [-0.5, 0.0, 0.5] {
            for (n, r) in [1.9, 3.8].enumerated() {
                // From the pier's middle to the ring of the arch beside it, at this height.
                let k = (r - spring) / (rise + ring)
                let reach = 0.25 - (s + 0.045) * max(0, 1 - k * k).squareRoot() - 0.01
                guard reach > 0.02 else { continue }
                line([at(max(c - reach, -0.5), w, r), at(min(c + reach, 0.5), w, r)], width: 0.45, opacity: 0.7)
                let joint = c + (n % 2 == 0 ? 0.025 : -0.025)
                if abs(joint) <= 0.5 { line([at(joint, w, r - 1.8), at(joint, w, r - 0.1)], width: 0.45, opacity: 0.7) }
            }
        }
        if complete {
            colour(along(w, -0.5 - e, 0.5 + e, h - 0.4, wallTop), .colour(side(I.stone, I.stoneShade)), shift: shallow)
            line([at(-0.5, w, h - 0.4), at(0.5, w, h - 0.4)], width: 0.8)
            for k in 0..<6 {
                let u = -0.5 + Double(k) / 6 + 1.0 / 12
                line([at(u, w, h), at(u, w, wallTop - 0.7)], width: 0.45, opacity: 0.7)
            }
            line([at(-0.5, w, wallTop - 0.7), at(0.5, w, wallTop - 0.7)], width: 0.5, opacity: 0.8)
            // The near parapet's coping.
            colour(level(-0.5 - e, 0.5 + e, w - pt, w, wallTop), .colour(I.stoneTop), shift: shallow)
            line([at(-0.5, w - pt, wallTop), at(0.5, w - pt, wallTop)], width: 0.6)
            line([at(-0.5, w, wallTop), at(0.5, w, wallTop)], width: 0.9)
        } else {
            line([at(-0.5, w, h), at(0, w, h)], width: 0.8)
            for (u, v) in [(-0.25, 0.1), (-0.4, -0.12)] {
                block(u, u + 0.12, v - 0.06, v + 0.06, h, h + 1.6, top: I.rawStoneTop, lit: I.rawStone,
                      shade: I.rawStoneShade, width: 0.6)
            }
            pennant(at: at(-0.15, -w + 0.06, h), height: 12, staff: I.timberDark)
        }
        var foot = [P]()
        for c in [-0.5] + centres.flatMap({ [$0 - s, $0 + s] }) + [0.5] { foot.append(at(c, w, 0)) }
        for i in stride(from: 0, to: foot.count, by: 2) { line([foot[i], foot[i + 1]], width: 0.8) }

        // The cutwaters on the piers.
        for u in [-0.5, 0, 0.5] { cutwater(u, w: w, height: 3.2) }
    }

    /// A pointed cutwater against the near face at `u`, from the water to `height`, with a sloping cap.
    private mutating func cutwater(_ u: Double, w: Double, height hc: Double) {
        typealias I = AlchemyOldBuildingsInk
        let c = 0.06, d = 0.1
        let left = [at(u - c, w, 0), at(u, w + d, 0), at(u, w + d, hc), at(u - c, w, hc)]
        let right = [at(u, w + d, 0), at(u + c, w, 0), at(u + c, w, hc), at(u, w + d, hc)]
        submerged(at: at(u, w + d, 0), width: 3.6)
        colour(left, .colour(side(I.stone, I.stoneShade)), shift: Self.nudge)
        colour(right, .colour(end(I.stone, I.stoneShade)), shift: Self.nudge)
        let apex = at(u, w, hc + 1.6)
        colour([at(u - c, w, hc), at(u, w + d, hc), apex], .colour(I.stoneTop), shift: Self.nudge)
        colour([at(u, w + d, hc), at(u + c, w, hc), apex], .colour(side(I.stone, I.stoneShade)), shift: Self.nudge)
        line([at(u - c, w, 0), at(u, w + d, 0), at(u + c, w, 0)], width: 0.8)
        line([at(u, w + d, 0), at(u, w + d, hc)], width: 0.6)
        line([at(u - c, w, 0), at(u - c, w, hc), apex, at(u + c, w, hc), at(u + c, w, 0)], width: 0.7)
        line([at(u - c, w, hc), at(u, w + d, hc), at(u + c, w, hc)], width: 0.6)
        line([at(u, w + d, hc), apex], width: 0.5)
        line([at(u - c * 0.5, w + d * 0.5, 1.6), at(u, w + d, 1.6), at(u + c * 0.5, w + d * 0.5, 1.6)], width: 0.4,
             opacity: 0.7)
        ripple(at: at(u, w + d, 0), 2.4)
    }

    /// The timber centring that holds an arch whilst it is built, seen in its opening.
    private mutating func centring(_ c: Double, s: Double, w: Double, spring: Double, intrados: (Double) -> Double) {
        typealias I = AlchemyOldBuildingsInk
        pole(at(c - s, w, spring), at(c + s, w, spring), width: 1, colour: I.timberLight, line: 0.5)
        for k in [-0.6, 0.0, 0.6] {
            pole(at(c + k * s * 0.3, w, spring), at(c + k * s, w, intrados(c + k * s) - 0.2), width: 0.7,
                 colour: I.timber, line: 0.4)
        }
        for k in [-0.7, 0.7] { pole(at(c + k * s, w, 0), at(c + k * s, w, spring), width: 0.8, colour: I.timber, line: 0.4) }
    }
}
