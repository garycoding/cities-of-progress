// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation

// The Bronze-age boat house (ruled 2026-11-21): a reed-roofed shed on a quay
// of plastered mud brick, as the marsh people still build their reed halls. A
// vault of reed matting stands on arches of bundled reed; its end toward +x is
// open, framed by a thick bundled arch between two tall reed columns with
// tufted heads, bound in the owner's colour; a reed boat lies in it on its
// chocks, its curled bow out under the arch. The quay's two faces carry a band
// of the owner's colour, a pennant flies over the arch, a mooring post with a
// bronze ring stands at the quay's edge, a net hangs to dry on two poles, and
// jars and a stack of reed bundles stand about. The footprint lies on land and
// the water may lie beside any of its edges. Its footprint is two tiles
// square: x and y run from -1 to 1.
//
// Under construction: the quay of bare mud brick, the arches of bundled reed
// planted and tied, one mat laid over them, the columns half raised, and
// bundles of reed stacked ready.

/// The boat house's measurements, about the centre of its footprint: distances
/// in tiles along the map's axes, heights in points.
private enum ReedShed {
    /// The quay's height.
    static let quay = 6.0
    /// The vault: its length along x, its span along y, and the height of its crown above the quay.
    static let x0 = -0.86, x1 = 0.3, y0 = -0.72, y1 = 0.24, crown = 31.0
    static var yc: Double { (y0 + y1) / 2 }
    /// The inks the shed adds to the Bronze palette: reed in the sun, and the shed's dark inside.
    static let reedLit = "#e2c47e"
    static let inside = "#4a3a2c"
}

extension BronzeBuildingsPainter {
    mutating func boatHouse(complete: Bool) {
        shedQuay(complete: complete)
        if complete { reedShed() } else { reedShedRising() }
    }

    // MARK: The quay

    /// The quay over the whole footprint: plastered brick with the owner's band
    /// along both faces, or bare brick while it is built.
    private mutating func shedQuay(complete: Bool) {
        typealias I = BronzeBuildingsInk
        let h = complete ? ReedShed.quay : ReedShed.quay - 1.5
        if complete {
            block(-1, -1, 1, 1, 0, h, top: .colour(I.paving), left: .colour(I.light), right: .colour(I.plasterShade), width: 1)
            for (side, x, y) in [(BronzeBuildingsSide.left, -1.0, 1.0), (.right, 1.0, 1.0)] {
                wall(side, from: x, y) { p in
                    p.paintedBand(2, 62, 1.6, 4)
                }
            }
            // The paving's joints over the quay's top.
            var d = PathData()
            for k in stride(from: -0.6, through: 0.61, by: 0.4) {
                d.move(iso(k, -0.98, h)); d.line(iso(k, 0.98, h))
                d.move(iso(-0.98, k, h)); d.line(iso(0.98, k, h))
            }
            svg.path(d, stroke: .colour(I.pavingShade), width: 0.6)
        } else {
            block(-1, -1, 1, 1, 0, h, top: .colour(I.rawBrickTop), left: .colour(I.rawBrick), right: .colour(I.rawBrickShade), width: 1)
            for (side, x, y) in [(BronzeBuildingsSide.left, -1.0, 1.0), (.right, 1.0, 1.0)] {
                wall(side, from: x, y) { p in p.courses(0, 64, 0, h) }
            }
        }
    }

    // MARK: Bundles of reed

    /// A bundle of reed along a line on the screen, `width` points thick: its
    /// line, its colour, the reeds' streaks along it, and bindings across it at
    /// the fractions `binds` of its length, in the owner's colour where `team`.
    private mutating func reedBundle(_ points: [P], width: Double, binds: [Double] = [], team: Bool = false,
                                     colour paint: String = BronzeBuildingsInk.reed) {
        typealias I = BronzeBuildingsInk
        guard points.count > 1 else { return }
        svg.line(points, stroke: .colour(I.line), width: width + 1.2)
        svg.line(points, stroke: .colour(paint), width: width)
        // The streaks of the reeds, either side of the middle.
        for k in [-0.26, 0.24] where width > 2.6 {
            svg.line(Self.offset(points, by: width * k), stroke: .colour(I.reedShade), width: 0.5)
        }
        for t in binds {
            let (at, along) = Self.point(points, at: t)
            let across = P(-along.y, along.x) * (width / 2 + 0.3)
            svg.line([at - across, at + across], stroke: .colour(I.line), width: 2.4)
            svg.line([at - across * 0.92, at + across * 0.92], stroke: team ? .team : .colour(I.terracotta), width: 1.3)
        }
    }

    /// A line on the screen moved `by` points to its left as it runs.
    private static func offset(_ points: [P], by k: Double) -> [P] {
        points.indices.map { i in
            let a = points[max(i - 1, 0)], b = points[min(i + 1, points.count - 1)]
            let u = (b - a) * (1 / max(((b - a).x * (b - a).x + (b - a).y * (b - a).y).squareRoot(), 1e-6))
            return points[i] + P(-u.y, u.x) * k
        }
    }

    /// The point a fraction `t` of the way along a line on the screen, and the line's direction there.
    private static func point(_ points: [P], at t: Double) -> (P, P) {
        var lengths: [Double] = []
        for (a, b) in zip(points, points.dropFirst()) { lengths.append(((b - a).x * (b - a).x + (b - a).y * (b - a).y).squareRoot()) }
        var left = lengths.reduce(0, +) * min(max(t, 0), 1)
        for (i, length) in lengths.enumerated() {
            if left <= length || i == lengths.count - 1 {
                let a = points[i], b = points[i + 1]
                let u = (b - a) * (1 / max(length, 1e-6))
                return (a + (b - a) * min(left / max(length, 1e-6), 1), u)
            }
            left -= length
        }
        return (points[0], P(1, 0))
    }

    /// A point of the vault's arch at `x`: `s` from 0 at its foot on the far
    /// side (toward -y), over the crown at 0.5, to 1 at its foot on the near side.
    private func archPoint(_ x: Double, _ s: Double, crown: Double = ReedShed.crown, out: Double = 0) -> P {
        let a = s * .pi
        let half = (ReedShed.y1 - ReedShed.y0) / 2 + out / 36
        // The marsh arch: fuller at the shoulders than a half circle, a little pointed at the crown.
        let rise = pow(sin(a), 0.62)
        return iso(x, ReedShed.yc - half * cos(a), ReedShed.quay + (crown + out) * rise)
    }

    private func arch(_ x: Double, from s0: Double = 0, to s1: Double = 1, crown: Double = ReedShed.crown, out: Double = 0) -> [P] {
        (0...24).map { i in archPoint(x, s0 + (s1 - s0) * Double(i) / 24, crown: crown, out: out) }
    }

    /// A tall column of bundled reed standing at (x, y) on the quay, `height` points tall, bound at intervals, its head a tuft.
    private mutating func reedColumn(_ x: Double, _ y: Double, height: Double, tuft: Bool = true) {
        typealias I = BronzeBuildingsInk
        let foot = iso(x, y, ReedShed.quay), top = foot - P(0, height)
        shadow([foot + P(1, 0.5), foot + P(9, -2.5), foot + P(10, 0.5), foot + P(2, 2.2)], opacity: 0.16)
        if tuft {
            // The reeds' heads, spread above the last binding.
            var d = PathData()
            for k in -3...3 {
                let a = Double(k) * 11
                d.move(top + P(0, 2)); d.line(top + P.direction(180 + a) * 7.5 + P(0, 2))
            }
            svg.path(d, stroke: .colour(I.line), width: 2.4)
            svg.path(d, stroke: .colour(I.reedShade), width: 1.2)
        }
        reedBundle([foot, top], width: 6.4, binds: [0.18, 0.42, 0.66, 0.9], team: true, colour: ReedShed.reedLit)
    }

    // MARK: The complete shed

    private mutating func reedShed() {
        typealias I = BronzeBuildingsInk
        let (x0, x1, y0, y1, q) = (ReedShed.x0, ReedShed.x1, ReedShed.y0, ReedShed.y1, ReedShed.quay)
        // The vault's shadow on the quay, to the right.
        shadow([iso(x0 + 0.2, y0, q), iso(x1 + 0.3, y0, q), iso(x1 + 0.3, y1 + 0.06, q), iso(x0 + 0.2, y1 + 0.06, q)], opacity: 0.12)
        // Jars by the far side.
        jar(at: iso(0.55, -0.84, q), size: 1.1)
        jar(at: iso(0.74, -0.8, q), size: 0.8, paint: I.clay)
        // The vault: the matting between the far arch and the open end.
        vault()
        // The open end: the shed's dark inside, the arches seen through it, and the boat on its chocks.
        let opening = arch(x1)
        colour(opening, .colour(ReedShed.inside))
        svg.raw("<defs><clipPath id=\"bronze-boat-house-inside\"><polygon points=\"\(opening.map { "\(num($0.x)),\(num($0.y))" }.joined(separator: " "))\"/></clipPath></defs>")
        svg.raw("<g clip-path=\"url(#bronze-boat-house-inside)\">")
        for (k, x) in [x1 - 0.3, x1 - 0.62, x1 - 0.94].enumerated() {
            svg.line(arch(x), stroke: .colour(I.reedShade), width: 2.6 - Double(k) * 0.5, opacity: 0.55 - Double(k) * 0.12)
        }
        colour([iso(x0, y0, q), iso(x1, y0, q), iso(x1, y1, q), iso(x0, y1, q)], .colour(I.dark), opacity: 0.5)
        shedBoat(from: -0.5, to: x1 + 0.3, y: ReedShed.yc, h: q, within: -1...x1)
        svg.raw("</g>")
        // The arch round the open end, the boat's bow out under it, and the columns either side.
        reedBundle(arch(x1, out: 1.2), width: 4.6, binds: [0.1, 0.3, 0.5, 0.7, 0.9])
        shedBoat(from: -0.5, to: x1 + 0.3, y: ReedShed.yc, h: q, within: x1...1)
        reedColumn(x1 + 0.03, y0 - 0.05, height: ReedShed.crown + 9)
        pennant(at: archPoint(x1, 0.5, out: 3), height: 16)
        reedColumn(x1 + 0.03, y1 + 0.05, height: ReedShed.crown + 9)
        // Before the open end: the mooring post, and reed bundles stacked at the front.
        mooringPost(at: iso(0.86, ReedShed.yc + 0.1, q))
        reedStack(at: (-0.1, 0.72))
        // The net drying on its poles at the front corner.
        dryingNet(from: (-0.93, 0.36), to: (-0.93, 0.92))
    }

    /// The vault's matting: its shape between the arch at the far end and the
    /// one at the open end, lit toward the near side, its courses running along
    /// it, its ribs over the arches, and the line round it.
    private mutating func vault() {
        typealias I = BronzeBuildingsInk
        let (x0, x1) = (ReedShed.x0, ReedShed.x1)
        let band = arch(x0) + arch(x1).reversed()
        colour(band, .colour(I.reed))
        // The near slope, in the sun.
        let lit = arch(x0, from: 0.62, to: 1) + arch(x1, from: 0.62, to: 1).reversed()
        colour(lit, .colour(ReedShed.reedLit))
        // The courses of the matting along the vault, the lower ones closer as the slope turns toward the viewer.
        var d = PathData()
        for s in stride(from: 0.4, through: 0.97, by: 0.065) {
            d.move(archPoint(x0 + 0.02, s)); d.line(archPoint(x1 - 0.02, s))
        }
        svg.path(d, stroke: .colour(I.reedShade), width: 0.6)
        // The ribs of the arches under the matting, each a ridge with its binding.
        let ribs = 5
        for k in 1..<ribs {
            let x = x0 + (x1 - x0) * Double(k) / Double(ribs)
            let rib = arch(x, from: 0.5, to: 1, out: 0.5)
            svg.line(rib, stroke: .colour(I.reedShade), width: 2.2)
            svg.line(rib, stroke: .colour(I.line), width: 0.7)
        }
        line(band, closed: true, width: 1.1)
        // The matting's ragged foot along the near side.
        var fringe = PathData()
        for k in 0...18 {
            let p = iso(x0 + (x1 - x0) * Double(k) / 18, ReedShed.y1, ReedShed.quay + 0.6)
            fringe.move(p); fringe.line(p + P(k % 2 == 0 ? -0.3 : 0.3, k % 3 == 0 ? 2 : 1.3))
        }
        svg.path(fringe, stroke: .colour(I.line), width: 0.6)
    }

    /// The reed boat resting on two chocks along x at `y`, from `x0` to `x1`
    /// tiles, on `h`: a bundle thickest in its middle, its bow curled up at `x1`
    /// and its stern raised at `x0`, bound along its length. Only what lies
    /// between `within` along x is drawn, so that the part inside the shed can
    /// be drawn through its open end and the part outside over the arch.
    private mutating func shedBoat(from x0: Double, to x1: Double, y: Double, h: Double, within: ClosedRange<Double>) {
        typealias I = BronzeBuildingsInk
        for x in [x0 + 0.25, x1 - 0.32] where within.contains(x) {
            block(x - 0.04, y - 0.12, x + 0.04, y + 0.12, h, h + 2.4, top: .colour(I.timberLight), left: .colour(I.timber),
                  right: .colour(I.timberDark), width: 0.7)
        }
        // The hull: thick stretches along it, each a little thinner toward the ends.
        let steps = 16
        func x(_ t: Double) -> Double { x0 + (x1 - x0) * t }
        func lift(_ t: Double) -> Double { 4.4 + 4 * pow(abs(2 * t - 1), 2.4) }
        func thickness(_ t: Double) -> Double { 2.8 + 3.4 * pow(sin(t * .pi), 0.7) }
        let ts = (0...steps).map { Double($0) / Double(steps) }
        let line = ts.map { iso(x($0), y, h + lift($0)) }
        let drawn = (0..<steps).filter { within.contains(x((ts[$0] + ts[$0 + 1]) / 2)) }
        guard let first = drawn.first, let last = drawn.last else { return }
        for paint in [I.line, I.reed] {
            for i in drawn {
                let w = thickness((ts[i] + ts[i + 1]) / 2)
                svg.line([line[i], line[i + 1]], stroke: .colour(paint), width: paint == I.line ? w + 1.2 : w)
            }
        }
        let part = Array(line[first...(last + 1)])
        svg.line(Self.offset(part, by: -1.1), stroke: .colour(I.reedShade), width: 0.5)
        svg.line(Self.offset(part, by: 1), stroke: .colour(ReedShed.reedLit), width: 0.8)
        for t in [0.2, 0.35, 0.5, 0.65, 0.8] where within.contains(x(t)) {
            let (at, along) = Self.point(line, at: t)
            let across = P(-along.y, along.x) * (thickness(t) / 2 + 0.3)
            svg.line([at - across, at + across], stroke: .colour(I.line), width: 2.2)
            svg.line([at - across * 0.9, at + across * 0.9], stroke: .colour(I.terracotta), width: 1.1)
        }
        // The bow, curling up and over, and the stern post.
        if within.contains(x1) {
            let foot = line.last!
            let bow = [foot, foot + P(3, -3), foot + P(4.4, -7.5), foot + P(3.6, -11), foot + P(1.4, -12.6), foot + P(0.2, -11.4)]
            reedBundle(bow, width: 2.8, binds: [0.15, 0.4])
        }
        if within.contains(x0) {
            let foot = line.first!
            reedBundle([foot, foot + P(-2.6, -3), foot + P(-3.4, -8)], width: 2.8, binds: [0.3])
        }
    }

    /// The mooring post: a timber post with a bronze ring at its head and a rope made fast to it.
    private mutating func mooringPost(at foot: P) {
        typealias I = BronzeBuildingsInk
        pole(foot + P(0, 1), foot - P(0, 15), width: 2.8, colour: I.timber)
        svg.ellipse(foot - P(0, 15), 1.4, 0.7, fill: .colour(I.timberLight), stroke: .colour(I.line), width: 0.6)
        svg.ellipse(foot - P(-1.8, 11.5), 2.2, 2.4, fill: .none, stroke: .colour(I.line), width: 1.8)
        svg.ellipse(foot - P(-1.8, 11.5), 2.2, 2.4, fill: .none, stroke: .colour(I.bronzeLight), width: 0.9)
        var rope = PathData()
        rope.move(foot - P(0, 6)); rope.quad(foot + P(5, -1), foot + P(9, 3))
        svg.path(rope, stroke: .colour(I.line), width: 1.7)
        svg.path(rope, stroke: .colour(I.reedShade), width: 0.8)
    }

    /// A net hung to dry between two poles at (x, y) on the quay: its mesh sagging between them, weights along its foot.
    private mutating func dryingNet(from a: (Double, Double), to b: (Double, Double)) {
        typealias I = BronzeBuildingsInk
        let q = ReedShed.quay, top = 20.0
        let pa = iso(a.0, a.1, q), pb = iso(b.0, b.1, q)
        pole(pa + P(0, 0.5), pa - P(0, top + 2), width: 1.6, colour: I.timber)
        let ta = pa - P(0, top), tb = pb - P(0, top)
        let sag = P(0, 3)
        // The mesh: lines from the bar down to the foot, and across.
        var mesh = PathData()
        for k in 0...8 {
            let t = Double(k) / 8
            let upper = ta + (tb - ta) * t + sag * (4 * t * (1 - t))
            mesh.move(upper); mesh.line(upper + P(0.6, 12))
        }
        for row in [4.0, 8.0, 12.0] {
            for k in 0..<8 {
                let t = Double(k) / 8, u = Double(k + 1) / 8
                let a1 = ta + (tb - ta) * t + sag * (4 * t * (1 - t)) + P(0.2 * row / 4, row)
                let b1 = ta + (tb - ta) * u + sag * (4 * u * (1 - u)) + P(0.2 * row / 4, row)
                mesh.move(a1); mesh.line(b1)
            }
        }
        svg.path(mesh, stroke: .colour(I.line), width: 0.5, opacity: 0.85)
        var bar = PathData()
        bar.move(ta); bar.quad((ta + tb) * 0.5 + sag * 2, tb)
        svg.path(bar, stroke: .colour(I.line), width: 1.2)
        for k in 0...8 {
            let t = Double(k) / 8
            svg.circle(ta + (tb - ta) * t + sag * (4 * t * (1 - t)) + P(0.6, 12.4), 0.8, fill: .colour(I.stone), stroke: .colour(I.line), width: 0.4)
        }
        pole(pb + P(0, 0.5), pb - P(0, top + 2), width: 1.6, colour: I.timber)
    }

    /// Bundles of cut reed stacked on the quay at (x, y), lying along y: three below and two on them.
    private mutating func reedStack(at c: (Double, Double)) {
        let q = ReedShed.quay
        let rows: [[(Double, Double)]] = [[(-0.1, 0), (0, 0), (0.1, 0)], [(-0.05, 3.6), (0.05, 3.6)]]
        shadow([iso(c.0 - 0.18, c.1 - 0.2, q), iso(c.0 + 0.2, c.1 - 0.2, q), iso(c.0 + 0.2, c.1 + 0.24, q), iso(c.0 - 0.18, c.1 + 0.24, q)],
               opacity: 0.12)
        for row in rows {
            for (dx, dh) in row {
                let a = iso(c.0 + dx, c.1 - 0.17, q + 2 + dh), b = iso(c.0 + dx, c.1 + 0.17, q + 2 + dh)
                reedBundle([a, b], width: 4, binds: [0.25, 0.75])
                // The cut ends toward the viewer.
                svg.ellipse(b, 2, 1.8, fill: .colour(ReedShed.reedLit), stroke: .colour(BronzeBuildingsInk.line), width: 0.7)
            }
        }
    }

    // MARK: Under construction

    /// The shed being built: the arches planted and tied at their crowns, one
    /// mat laid over the far end, the columns half raised, and reed to hand.
    private mutating func reedShedRising() {
        typealias I = BronzeBuildingsInk
        let (x0, x1) = (ReedShed.x0, ReedShed.x1)
        let q = ReedShed.quay - 1.5
        let ribs = 4
        let xs = (0...ribs).map { x0 + (x1 - x0) * Double($0) / Double(ribs) }
        // The arches, the farthest first, each tied at its crown.
        for (k, x) in xs.enumerated() {
            let rib = arch(x).map { $0 + P(0, 1.5) }
            reedBundle(rib, width: 3.6, binds: [0.2, 0.5, 0.8])
            if k == 0 {
                // The first mat, laid over the far arches.
                let mat = arch(xs[0]).map { $0 + P(0, 1.5) } + arch(xs[1]).map { $0 + P(0, 1.5) }.reversed()
                colour(mat, .colour(I.reed))
                var d = PathData()
                for s in stride(from: 0.4, through: 0.97, by: 0.08) {
                    d.move(archPoint(xs[0], s) + P(0, 1.5)); d.line(archPoint(xs[1], s) + P(0, 1.5))
                }
                svg.path(d, stroke: .colour(I.reedShade), width: 0.6)
                line(mat, closed: true, width: 1)
            }
        }
        // The ridge pole tying the crowns together.
        pole(archPoint(x0, 0.5) + P(0, 1.5), archPoint(x1, 0.5) + P(0, 1.5), width: 1.6, colour: I.timber)
        pennant(at: archPoint(x1, 0.5, out: 2) + P(0, 1.5), height: 14)
        // The columns, half raised, and the reed waiting for them.
        for y in [ReedShed.y0 - 0.05, ReedShed.y1 + 0.05] {
            let foot = iso(x1 + 0.03, y, q), top = foot - P(0, 16)
            reedBundle([foot, top], width: 6.4, binds: [0.3, 0.75], team: true, colour: ReedShed.reedLit)
            svg.ellipse(top, 3.2, 1.6, fill: .colour(I.reedShade), stroke: .colour(I.line), width: 0.7)
        }
        reedStackRising(at: (0.66, 0.6), h: q)
        reedStackRising(at: (-0.5, 0.74), h: q)
        bricks(0.55, -0.9, 0.85, -0.7, from: q, courses: 2)
        basket(at: iso(0.75, -0.25, q), size: 1)
    }

    /// Loose bundles of reed lying on the bare quay, ready to be bound into the shed.
    private mutating func reedStackRising(at c: (Double, Double), h: Double) {
        for (dy, dh) in [(-0.1, 0.0), (0.05, 0.0), (-0.03, 3.4)] {
            let a = iso(c.0 - 0.2, c.1 + dy, h + 2 + dh), b = iso(c.0 + 0.2, c.1 + dy, h + 2 + dh)
            reedBundle([a, b], width: 4, binds: [0.3, 0.7])
            svg.ellipse(b, 1.8, 2, fill: .colour(ReedShed.reedLit), stroke: .colour(BronzeBuildingsInk.line), width: 0.7)
        }
    }
}
