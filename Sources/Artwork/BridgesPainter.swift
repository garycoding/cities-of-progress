// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// The drawing kit the three looks of the bridge share. A piece is drawn in
// its own coordinates: `u` along the run and `v` across it, in tiles from the
// tile's centre, and `h` in points above the water. Along x, u is the map's x
// and v its y; along y the two change places, so that one drawing gives both
// runs, each lit as every building is lit: the face looking toward +y (the
// screen's lower left) in the light, the face looking toward +x (its lower
// right) in shade.

/// Draws one layer of a bridge piece: its picture or its team-colour mask.
struct BridgesPainter {
    var svg: SVG
    let run: BridgeRun

    /// How far a field of colour sits from its line on the screen, in points:
    /// the slight misregistration of the style (docs/art-style.md).
    static let register = P(-1.0, 0.7)
    /// The smaller shift of small parts: posts, piles, stones.
    static let nudge = P(-0.6, 0.45)
    /// How far a part that runs the length of the piece is drawn past each
    /// edge of the tile, so that two pieces side by side overlap rather than
    /// leave a hairline where their anti-aliased edges meet.
    static let overlap = 0.02

    init(layer: Layer, run: BridgeRun) {
        svg = SVG(layer: layer)
        self.run = run
    }

    // MARK: The projection

    /// The screen point `h` points above the water at `u` along the run and
    /// `v` across it, in tiles from the tile's centre.
    func at(_ u: Double, _ v: Double, _ h: Double = 0) -> P {
        let x = run == .alongX ? u : v, y = run == .alongX ? v : u
        return P((x - y) * 32, (x + y) * 16 - h)
    }

    /// A level rectangle from `u0` to `u1` along and `v0` to `v1` across, at
    /// height `h`.
    func level(_ u0: Double, _ u1: Double, _ v0: Double, _ v1: Double, _ h: Double) -> [P] {
        [at(u0, v0, h), at(u1, v0, h), at(u1, v1, h), at(u0, v1, h)]
    }

    /// An upright face across the run at `u`, from `v0` to `v1`, from `h0` up to `h1`.
    func across(_ u: Double, _ v0: Double, _ v1: Double, _ h0: Double, _ h1: Double) -> [P] {
        [at(u, v0, h0), at(u, v1, h0), at(u, v1, h1), at(u, v0, h1)]
    }

    /// An upright face along the run at `v`, from `u0` to `u1`, from `h0` up to `h1`.
    func along(_ v: Double, _ u0: Double, _ u1: Double, _ h0: Double, _ h1: Double) -> [P] {
        [at(u0, v, h0), at(u1, v, h0), at(u1, v, h1), at(u0, v, h1)]
    }

    /// The colour of a face that looks across the run toward the viewer (+v):
    /// lit along x, where it faces +y, and in shade along y.
    func side(_ lit: String, _ shade: String) -> String { run == .alongX ? lit : shade }

    /// The colour of a face that looks along the run toward the viewer (+u):
    /// in shade along x, where it faces +x, and lit along y.
    func end(_ lit: String, _ shade: String) -> String { run == .alongX ? shade : lit }

    // MARK: Colour and line

    /// A flat field of colour, a little out of register with its line.
    mutating func colour(_ points: [P], _ paint: Paint, shift: P = BridgesPainter.register, opacity: Double = 1) {
        svg.polygon(points.map { $0 + shift }, fill: paint, opacity: opacity)
    }

    /// The dark line through the points.
    mutating func line(_ points: [P], closed: Bool = false, width: Double = 1, colour: String = BridgesInk.line,
                       opacity: Double = 1) {
        var d = PathData()
        d.move(points[0])
        for point in points.dropFirst() { d.line(point) }
        if closed { d.close() }
        svg.path(d, stroke: .colour(colour), width: width, opacity: opacity)
    }

    /// A shape: its colour, then its line all round.
    mutating func shape(_ points: [P], _ paint: Paint, width: Double = 0.9, shift: P = BridgesPainter.register) {
        colour(points, paint, shift: shift)
        line(points, closed: true, width: width)
    }

    /// A darker film over what is drawn: shadow on the water or under a vault.
    mutating func film(_ points: [P], opacity: Double) {
        svg.polygon(points, fill: .colour(BridgesInk.line), opacity: opacity)
    }

    /// A timber or a bar from `a` to `b`, `width` points thick on the screen:
    /// its colour a little out of register, then its line.
    mutating func pole(_ a: P, _ b: P, width: Double, colour paint: String, line: Double = 0.8) {
        let d = b - a, l = max(0.001, (d.x * d.x + d.y * d.y).squareRoot())
        let n = P(-d.y / l, d.x / l) * (width / 2)
        shape([a + n, b + n, b - n, a - n], .colour(paint), width: line, shift: BridgesPainter.nudge)
    }

    /// An upright post standing at (`u`, `v`) from `h0` to `h1`.
    mutating func post(_ u: Double, _ v: Double, _ h0: Double, _ h1: Double, width: Double, colour: String,
                       line: Double = 0.8) {
        pole(at(u, v, h0), at(u, v, h1), width: width, colour: colour, line: line)
    }

    /// A block from `u0` to `u1` along and `v0` to `v1` across, from `h0` up
    /// to `h1`: its top, the face toward +v and the face toward +u, each
    /// coloured as the light falls on it, then its line.
    mutating func block(_ u0: Double, _ u1: Double, _ v0: Double, _ v1: Double, _ h0: Double, _ h1: Double,
                        top: String, lit: String, shade: String, width: Double = 0.8, shift: P = BridgesPainter.nudge) {
        colour(along(v1, u0, u1, h0, h1), .colour(side(lit, shade)), shift: shift)
        colour(across(u1, v0, v1, h0, h1), .colour(end(lit, shade)), shift: shift)
        colour(level(u0, u1, v0, v1, h1), .colour(top), shift: shift)
        line([at(u0, v1, h0), at(u1, v1, h0), at(u1, v0, h0), at(u1, v0, h1), at(u0, v0, h1), at(u0, v1, h1)],
             closed: true, width: width)
        line([at(u0, v1, h1), at(u1, v1, h1), at(u1, v0, h1)], width: width * 0.8)
        line([at(u1, v1, h1), at(u1, v1, h0)], width: width * 0.8)
    }

    /// A slack cord from `a` to `b`, hanging `sag` points at its middle: its
    /// colour a little out of register, then a thin line.
    mutating func cord(_ a: P, _ b: P, sag: Double, colour: String, width: Double = 1.5) {
        func trace(_ o: P) -> PathData {
            var d = PathData()
            d.move(a + o)
            d.quad((a + b) * 0.5 + P(0, 2 * sag) + o, b + o)
            return d
        }
        svg.path(trace(BridgesPainter.nudge), stroke: .colour(colour), width: width)
        svg.path(trace(P(0, 0)), stroke: .colour(BridgesInk.line), width: 0.6)
    }

    /// Rings on the water about the foot of a pile or a pier at `foot`, `r`
    /// points wide: the front of an ellipse in the light of the water's waves.
    mutating func ripple(at foot: P, _ r: Double) {
        var d = PathData()
        d.move(foot + P(-r, -0.2))
        d.quad(foot + P(0, r * 0.55), foot + P(r, -0.2))
        svg.path(d, stroke: .colour(BridgesInk.ripple), width: 0.8, opacity: 0.9)
        var e = PathData()
        e.move(foot + P(-r - 1.8, 1.2))
        e.quad(foot + P(-r * 0.4, 2.4), foot + P(-r * 0.1, 2.1))
        svg.path(e, stroke: .colour(BridgesInk.ripple), width: 0.6, opacity: 0.7)
    }

    /// The part of a pile or a pier below the water, `width` wide at `foot`:
    /// the water's own colour unknown, a dark film suggests its depth.
    mutating func submerged(at foot: P, width: Double, depth: Double = 2.2) {
        let r = width / 2
        film([foot + P(-r, 0), foot + P(r, 0), foot + P(r * 0.8, depth), foot + P(-r * 0.8, depth)], opacity: 0.22)
    }

    /// A small swallowtail pennant in the team's colour on a staff whose foot
    /// is at `foot`, `height` points tall, with a dot in the light colour.
    mutating func pennant(at foot: P, height: Double, staff: String) {
        let top = foot - P(0, height)
        func cloth(_ o: P) -> PathData {
            var d = PathData()
            d.move(top + P(0.4, 0.9) + o)
            d.quad(top + P(4.4, 0.2) + o, top + P(8.8, 1.5) + o)
            d.line(top + P(6.4, 3.4) + o)
            d.line(top + P(8.8, 5.4) + o)
            d.quad(top + P(4.4, 6.1) + o, top + P(0.4, 6) + o)
            d.close()
            return d
        }
        svg.line([foot, top - P(0, 0.6)], stroke: .colour(staff), width: 1.3)
        svg.line([foot + P(0.55, 0), top + P(0.55, 0)], stroke: .colour(BridgesInk.line), width: 0.45, opacity: 0.8)
        svg.path(cloth(BridgesPainter.nudge), fill: .team)
        svg.circle(top + P(3.2, 3.3), 0.95, fill: .colour(BridgesInk.light))
        svg.path(cloth(P(0, 0)), stroke: .colour(BridgesInk.line), width: 0.7)
        svg.circle(top - P(0, 1), 0.9, fill: .colour(BridgesInk.finial), stroke: .colour(BridgesInk.line), width: 0.5)
    }
}

/// The colours every look shares: the line, the light, and the water's marks.
enum BridgesInk {
    static let line = Ink.line
    static let light = Ink.light
    /// The waves' light on the water (`TerrainInk.shallowLight`).
    static let ripple = TerrainInk.shallowLight
    /// The knob atop a pennant's staff.
    static let finial = "#c9a35a"
}
