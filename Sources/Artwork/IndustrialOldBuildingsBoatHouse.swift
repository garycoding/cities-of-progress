// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation

// The Industrial-age boat house (ruled 2026-11-21, plan D7): a boathouse of
// red brick with a slipway. A long shed of brick on a plinth of stone stands
// on a yard of granite setts, its ridge along x under a roof of slate with a
// chimney stack for the boiler of its steam winch. Its gable end faces the
// screen's lower right, opening in a tall arched doorway; out of it runs the
// slipway, a channel of timber sleepers between stone copings with two iron
// rails, down to the footprint's edge, and on the rails a trawler's bow rests
// on its cradle, half hauled out, its chain running back to the winch. A band
// of the owner's colour runs under the eaves of the long wall, edged in the
// light colour, and the owner's pennant flies from the gable's apex; a
// lifebuoy hangs beside the door, and a gas lamp, a bollard, fish boxes and
// barrels stand on the quay. The footprint lies on land and the water may
// lie beside any of its edges, so the slipway reads as the way down to it.
// Under construction: the setts laid, the slipway's sleepers and rails down,
// the walls raised part way in fresh brick with the doorway's arch on its
// centring, scaffolding with the owner's pennant, and bricks, slates and
// timbers to hand. Its footprint is two tiles square: x and y run from -1 to 1.

/// The boat house's measurements, about the centre of its footprint: distances
/// in tiles along the map's axes, heights in points.
private enum Slip {
    /// The shed: its extent, the yard's height, its eaves and its ridge.
    static let x0 = -0.84, x1 = 0.3, y0 = -0.76, y1 = 0.14
    static let yard = 2.0, eave = 28.0, ridge = 50.0
    /// The middle of the gable end, on which the doorway and the slipway are centred.
    static let ym = (y0 + y1) / 2
    /// The slipway: its half width, and the height it falls to at the footprint's edge.
    static let half = 0.2, foot = 0.4
    /// The rails, either side of the slipway's middle.
    static let gauge = 0.1
    /// Where the trawler's stem stands, along x.
    static let stem = 0.86
}

extension IndustrialOldBuildingsPainter {
    mutating func boatHouse(complete: Bool) {
        cobbles(1, height: Slip.yard)
        if complete { boatShed() } else { boatShedRising() }
    }

    // MARK: The complete boat house

    private mutating func boatShed() {
        typealias I = IndustrialOldBuildingsInk
        let (x0, y0, x1, y1, h0, e) = (Slip.x0, Slip.y0, Slip.x1, Slip.y1, Slip.yard, Slip.eave)
        let long = (x1 - x0) * 32, end = (y1 - y0) * 32
        // Fish boxes stacked behind the slipway, and the shed's shadow across the yard to the right.
        fishBoxes(0.56, -0.92, on: h0)
        shadow([iso(x1, y0, h0), iso(x1 + 0.34, y0 + 0.14, h0), iso(x1 + 0.34, y1 + 0.1, h0), iso(x1, y1, h0)])
        slipway(rails: true)
        block(x0, y0, x1, y1, h0, e, top: nil, left: .colour(I.brick), right: .colour(I.brickShade))
        // The long wall: plinth, brick, pilasters between tall arched windows, and the owner's band under the eaves.
        wall(.left, from: x0, y1, at: h0) { p in
            p.shape(p.panel(0, 0, long, 2.6), .colour(I.footing), width: 0.6)
            p.brickwork(0, long, 2.6, e - h0)
            for u in [0.0, long / 3, long * 2 / 3, long] {
                p.pilaster(min(max(u, 1.5), long - 1.5), 2.6, 12.4, w: 3)
            }
            for k in 0..<3 {
                p.archedWindow(long * (Double(k) + 0.5) / 3, 3.6, w: 5.2, h: 7.4)
            }
            // The string course and the owner's band over the windows, below the eaves' shadow.
            p.stringCourse(0, long, 12.4, 13.3)
            p.paintedBand(0, long, 14.3, 16.5)
            p.drainpipe(long - 1.2, from: e - h0 - 1)
        }
        // The gable end: the tall doorway open on the slipway, quoins, and the lifebuoy beside it.
        wall(.right, from: x1, y1, at: h0) { p in
            p.shape(p.panel(0, 0, end, 2.6), .colour(I.footingShade), width: 0.6)
            p.brickwork(0, end, 2.6, e - h0)
            p.quoins(at: 0, atStart: true, from: 2.6, to: e - h0, course: 3.2, reach: 3.4)
            p.quoins(at: end, atStart: false, from: 2.6, to: e - h0, course: 3.2, reach: 3.4)
            let door = (Slip.y1 - Slip.ym) * 32
            p.archedDoors(door, 0, w: 15, h: 19.4, open: true)
            p.lifebuoy(at: p.uv(door + 11.4, 11), radius: 2.6)
        }
        // Inside the doorway: the rails running on into the dark, the winch's chain, and the hull.
        doorwayGloom()
        trawlerBow()
        // The roof, its gable over the doorway, an oculus in the gable's brick.
        gableAlongX(x0, y0, x1, y1, eave: e, ridge: Slip.ridge, over: 0.06, gableWall: .colour(I.brickShade)) { p, w, rise in
            p.gableBrickwork(w, rise)
            p.oculus(w / 2, rise * 0.4, radius: 3.4)
        }
        // The winch-house's stack through the roof's far slope, toward the back.
        chimneyStack(-0.66, -0.56, -0.48, -0.38, from: Slip.ridge - 10, to: Slip.ridge + 9, pots: 2)
        pennant(at: iso(x1 + 0.06, Slip.ym, Slip.ridge + 7), height: 14, length: 14)
        // The quay in front: a bollard at the slipway's foot, a lamp, barrels and a coil of rope.
        bollard(at: iso(0.9, Slip.ym + Slip.half + 0.12, h0))
        ropeCoil(at: iso(0.66, 0.3, h0))
        gasLamp(at: iso(0.82, 0.72, h0), height: 22)
        barrel(at: iso(-0.62, 0.5, h0), size: 0.85)
        barrel(at: iso(-0.38, 0.62, h0), size: 0.8)
        fishBoxes(-0.02, 0.5, on: h0)
    }

    /// The slipway: a channel from the doorway to the footprint's edge, its
    /// floor of timber sleepers falling from the yard to `Slip.foot`, between
    /// copings of dressed stone; with `rails`, the two iron rails along it.
    private mutating func slipway(rails: Bool) {
        typealias I = IndustrialOldBuildingsInk
        let (a, b) = (Slip.x1 - 0.02, 1.0)
        let (l, r) = (Slip.ym - Slip.half, Slip.ym + Slip.half)
        func floor(_ x: Double) -> Double { Slip.yard - 1.4 - (Slip.yard - 1.4 - Slip.foot) * (x - a) / (b - a) }
        // The channel's floor, wet and darker toward its foot, and its far inner wall.
        colour([iso(a, l, floor(a)), iso(b, l, floor(b)), iso(b, r, floor(b)), iso(a, r, floor(a))], .colour(I.timberDark))
        colour([iso(a, l, floor(a)), iso(b, l, floor(b)), iso(b, l, Slip.yard), iso(a, l, Slip.yard)], .colour(I.stoneShade))
        colour([iso(0.7, l, floor(0.7)), iso(b, l, floor(b)), iso(b, r, floor(b)), iso(0.7, r, floor(0.7))], .colour(I.dark), opacity: 0.25)
        // The sleepers across it.
        var x = a + 0.05
        while x < b - 0.02 {
            let h = floor(x) + 0.5
            shape([iso(x - 0.02, l + 0.02, h), iso(x + 0.02, l + 0.02, h), iso(x + 0.02, r - 0.02, h), iso(x - 0.02, r - 0.02, h)],
                  .colour(I.timber), width: 0.4)
            x += 0.075
        }
        if rails {
            for y in [Slip.ym - Slip.gauge, Slip.ym + Slip.gauge] {
                let p0 = iso(a, y, floor(a) + 1.4), p1 = iso(b, y, floor(b) + 1.4)
                svg.line([p0, p1], stroke: .colour(I.line), width: 1.7)
                svg.line([p0 + P(0, -0.3), p1 + P(0, -0.3)], stroke: .colour(I.ironLight), width: 0.6)
            }
        }
        line([iso(a, l, floor(a)), iso(b, l, floor(b))], width: 0.7)
        // The copings of dressed stone along both sides, the near one's face toward the viewer.
        for (y, w) in [(l - 0.05, l), (r, r + 0.05)] {
            shape([iso(a, y, Slip.yard + 0.6), iso(b, y, Slip.yard + 0.6), iso(b, w, Slip.yard + 0.6), iso(a, w, Slip.yard + 0.6)],
                  .colour(I.stoneTop), width: 0.6)
            for k in 1..<6 {
                let x = a + (b - a) * Double(k) / 6
                line([iso(x, y, Slip.yard + 0.6), iso(x, w, Slip.yard + 0.6)], width: 0.4, opacity: 0.5)
            }
        }
        shape([iso(a, r, floor(a)), iso(b, r, floor(b)), iso(b, r, Slip.yard + 0.6), iso(a, r, Slip.yard + 0.6)], .colour(I.stone),
              width: 0.7)
        // The end of the near coping and of the channel at the footprint's edge.
        shape([iso(b, r, Slip.yard + 0.6), iso(b, r + 0.05, Slip.yard + 0.6), iso(b, r + 0.05, 0), iso(b, r, floor(b))],
              .colour(I.stoneShade), width: 0.6)
        line([iso(b, l, floor(b)), iso(b, r, floor(b))], width: 0.8)
    }

    /// The dark of the shed seen through the open doorway: the rails running
    /// in, the chain from the winch, and the cradle's far end.
    private mutating func doorwayGloom() {
        typealias I = IndustrialOldBuildingsInk
        let x = Slip.x1
        for y in [Slip.ym - Slip.gauge, Slip.ym + Slip.gauge] {
            svg.line([iso(x, y, Slip.yard + 0.6), iso(x - 0.14, y, Slip.yard + 0.6)], stroke: .colour(I.ironLight), width: 0.6, opacity: 0.6)
        }
        // The winch's drum, faintly, at the back of the shed.
        svg.ellipse(iso(x - 0.02, Slip.ym + 0.02, 10), 2.6, 3.2, fill: .colour(I.iron), opacity: 0.55)
    }

    /// The bow of a trawler resting on its cradle on the rails, half out of the
    /// doorway: its black hull with a light rubbing strake and a green boot
    /// top, its stem raking forward, and the haul chain from the cradle back to the winch.
    private mutating func trawlerBow() {
        typealias I = IndustrialOldBuildingsInk
        let x0 = Slip.x1 - 0.02, ym = Slip.ym
        let keel = Slip.yard + 2.6, sheer = Slip.yard + 13.0, beam = 0.15
        /// The hull's half breadth along x, narrowing to the stem.
        func breadth(_ x: Double, _ k: Double) -> Double {
            let t = min(max((Slip.stem - x) / (Slip.stem - x0), 0), 1)
            return beam * k * pow(t, 0.55)
        }
        let xs = stride(from: x0, through: Slip.stem, by: 0.03).map { $0 } + [Slip.stem]
        // The cradle under it: two timber bearers on the rails, wedged.
        for x in [x0 + 0.08, x0 + 0.22] {
            pole(iso(x, ym - Slip.gauge - 0.03, Slip.yard + 1.6), iso(x, ym + Slip.gauge + 0.03, Slip.yard + 1.6), width: 2, colour: I.timber)
            pole(iso(x, ym + Slip.gauge, Slip.yard + 2), iso(x, ym + 0.06, keel + 3), width: 1.4, colour: I.timberLight)
        }
        // The chain hangs from the stem's foot in a curve back to the doorway, link by link.
        let (c0, c1, c2) = (iso(Slip.stem - 0.02, ym, keel + 6), iso((Slip.stem + x0) / 2, ym + 0.02, keel - 0.6), iso(x0 - 0.02, ym, keel + 1))
        for k in 0...9 {
            let t = Double(k) / 9
            let p = c0 * ((1 - t) * (1 - t)) + c1 * (2 * t * (1 - t)) + c2 * (t * t)
            svg.ellipse(p, k % 2 == 0 ? 1.1 : 0.6, k % 2 == 0 ? 0.6 : 1, fill: .none, stroke: .colour(I.ironDark), width: 0.6)
        }
        // The near side, from the sheer down to the keel, and the far side's top over it.
        let nearSheer = xs.map { iso($0, ym + breadth($0, 1), sheer + 2.2 * pow(($0 - x0) / (Slip.stem - x0), 2)) }
        let nearKeel = xs.map { x -> P in
            let t = (x - x0) / (Slip.stem - x0)
            return iso(x, ym + breadth(x, 0.35), keel + 9 * pow(max(t - 0.55, 0) / 0.45, 1.6))
        }
        let farSheer = xs.map { iso($0, ym - breadth($0, 1), sheer + 2.2 * pow(($0 - x0) / (Slip.stem - x0), 2)) }
        shape(farSheer + nearSheer.reversed(), .colour(I.oakLight), width: 0.8)
        // The deck's planking, seen over the near bulwark.
        for k in 1..<4 {
            let f = Double(k) / 4
            let row = xs.map { iso($0, ym - breadth($0, 1) + 2 * breadth($0, 1) * f, sheer + 2.2 * pow(($0 - x0) / (Slip.stem - x0), 2)) }
            line(row, width: 0.3, opacity: 0.5)
        }
        let side = nearSheer + nearKeel.reversed()
        colour(side, .colour(I.sootDark))
        // The boot top of bottle green along the foot of the side, and the light rubbing strake under the sheer.
        let boot = nearKeel.map { $0 + P(0, -0.2) } + nearKeel.reversed().map { $0 + P(0, -3.4) }
        colour(boot, .colour(I.green))
        line(nearSheer.map { $0 + P(0, 2.2) }, width: 1.6)
        svg.line(nearSheer.map { $0 + P(0, 2.2) }, stroke: .colour(I.light), width: 0.9)
        line(side, closed: true, width: 1.1)
        // The hawse pipe near the stem.
        let hawse = iso(Slip.stem - 0.07, ym + breadth(Slip.stem - 0.07, 1), sheer - 1.4)
        svg.circle(hawse, 1, fill: .colour(I.dark), stroke: .colour(I.line), width: 0.5)
    }

    /// A round window in a gable drawn with `wall`, centred on (`u`, `v`): glass
    /// in a ring of dressed stone with four keystones, and a glazing cross.
    private mutating func oculus(_ u: Double, _ v: Double, radius r: Double) {
        typealias I = IndustrialOldBuildingsInk
        let c = uv(u, v)
        svg.circle(c + shift, r + 1.4, fill: .colour(I.stoneTop))
        svg.circle(c, r + 1.4, fill: .none, stroke: .colour(I.line), width: 0.6)
        svg.circle(c, r, fill: .colour(I.glass), stroke: .colour(I.line), width: 0.6)
        svg.path("M\(num(c.x - r)),\(num(c.y)) h\(num(2 * r)) M\(num(c.x)),\(num(c.y - r)) v\(num(2 * r))", stroke: .colour(I.light), width: 0.6)
        colour([c + P(-r * 0.7, -r * 0.1), c + P(-r * 0.1, -r * 0.7), c + P(-r * 0.6, -r * 0.6)], .colour(I.glassLight), opacity: 0.8)
    }

    /// A lifebuoy hung on a wall drawn with `wall`, its centre at `c`: a ring of
    /// the light colour quartered in bottle green, on a peg.
    private mutating func lifebuoy(at c: P, radius r: Double) {
        typealias I = IndustrialOldBuildingsInk
        svg.line([c + P(0, -r - 0.6), c + P(0, -r - 1.6)], stroke: .colour(I.line), width: 0.8)
        svg.circle(c + shift * 0.5, r, fill: .none, stroke: .colour(I.light), width: r * 0.7)
        for a in [20.0, 200] {
            svg.path(AlchemyWarriorsKit.arc(c + shift * 0.5, r, from: a, to: a + 50), stroke: .colour(I.green), width: r * 0.7)
        }
        svg.circle(c, r + r * 0.35, fill: .none, stroke: .colour(I.line), width: 0.5)
        svg.circle(c, r - r * 0.35, fill: .none, stroke: .colour(I.line), width: 0.5)
    }

    /// A bollard of cast iron standing at `foot` on the screen: a squat post with a cap, a rope's turn about it.
    private mutating func bollard(at foot: P) {
        typealias I = IndustrialOldBuildingsInk
        svg.ellipse(foot + P(1, 0.6), 3, 1.2, fill: .colour("#000000"), opacity: 0.16)
        shape([foot + P(-2, 0), foot + P(-1.6, -5), foot + P(1.6, -5), foot + P(2, 0)], .colour(I.iron), width: 0.6)
        svg.ellipse(foot + P(0, -5.4), 2.6, 1.1, fill: .colour(I.iron), stroke: .colour(I.line), width: 0.6)
        svg.line([foot + P(-0.6, -4.6), foot + P(-0.8, -0.6)], stroke: .colour(I.ironLight), width: 0.5)
        svg.ellipse(foot + P(0, -2.6), 2.2, 0.8, fill: .none, stroke: .colour(I.straw), width: 1)
    }

    /// A coil of rope lying at `p` on the screen, in flat rings.
    private mutating func ropeCoil(at p: P) {
        typealias I = IndustrialOldBuildingsInk
        svg.ellipse(p + P(0.6, 0.4), 5.4, 2.4, fill: .colour("#000000"), opacity: 0.14)
        for (k, r) in [5.0, 3.8, 2.6].enumerated() {
            svg.ellipse(p + P(0, -Double(k) * 0.9), r, r * 0.42, fill: .colour(I.straw), stroke: .colour(I.line), width: 0.6)
        }
        svg.ellipse(p + P(0, -1.8), 1.2, 0.5, fill: .colour(I.strawShade))
    }

    /// Fish boxes of sawn timber stacked at (x, y) on the map, on `h`: two below, one above, their ends showing.
    private mutating func fishBoxes(_ x: Double, _ y: Double, on h: Double) {
        for (dx, dy, dh) in [(0.0, 0.0, 0.0), (0.16, 0.0, 0.0), (0.08, 0.0, 4.0)] {
            crate(x + dx, y + dy, x + dx + 0.14, y + dy + 0.2, from: h + dh, height: 4)
        }
    }

    // MARK: Under construction

    /// The boat house being built: the setts laid and the slipway's sleepers
    /// and rails down; the walls raised part way in fresh brick, the doorway's
    /// opening spanned by its timber centring; scaffolding along the long wall
    /// with the owner's pennant; a ladder; and bricks, slates and timbers to hand.
    private mutating func boatShedRising() {
        typealias I = IndustrialOldBuildingsInk
        let (x0, y0, x1, y1, h0) = (Slip.x0, Slip.y0, Slip.x1, Slip.y1, Slip.yard)
        let top = 15.0
        let long = (x1 - x0) * 32, end = (y1 - y0) * 32
        slates(0.52, -0.94, 0.7, -0.66, from: h0, height: 6)
        shadow([iso(x1, y0, h0), iso(x1 + 0.2, y0 + 0.1, h0), iso(x1 + 0.2, y1 + 0.06, h0), iso(x1, y1, h0)])
        slipway(rails: true)
        shell(x0, y0, x1, y1, from: h0, floor: h0, to: top, thickness: 0.07, lit: .colour(I.rawBrick),
              shade: .colour(I.rawBrickShade), top: .colour(I.brickTop), ground: .colour(I.pavingShade)) { p in
            p.bricks(-0.5, -0.56, -0.24, -0.36, from: h0, height: 5)
            p.basket(at: p.iso(-0.1, -0.4, h0), size: 0.9)
        }
        wall(.left, from: x0, y1, at: h0) { p in
            p.shape(p.panel(0, 0, long, 2.6), .colour(I.rawStone), width: 0.6)
            p.brickwork(0, long, 2.6, top - h0, opacity: 0.4, burnt: false)
            for k in 0..<3 {
                let u = long * (Double(k) + 0.5) / 3
                p.shape(p.panel(u - 2.7, 6.6, u + 2.7, top - h0), .colour(I.dark), width: 0.8)
            }
        }
        wall(.right, from: x1, y1, at: h0) { p in
            p.shape(p.panel(0, 0, end, 2.6), .colour(I.rawStoneShade), width: 0.6)
            p.brickwork(0, end, 2.6, top - h0, opacity: 0.4, burnt: false)
            let door = (Slip.y1 - Slip.ym) * 32
            p.shape(p.panel(door - 7.5, 0, door + 7.5, top - h0), .colour(I.dark), width: 0.9)
            // The centring for the doorway's arch: a half round of boards on two props.
            p.centring(door, top - h0 - 0.4, radius: 7.5)
        }
        scaffold([(x0 + 0.1, y1 + 0.16), (-0.27, y1 + 0.16), (x1 - 0.1, y1 + 0.16)], from: h0, height: 34, levels: [12, 24], boards: 12,
                 inward: (0, -0.13))
        pennant(at: iso(x1 - 0.1, y1 + 0.16, h0 + 34), height: 11, length: 13)
        ladder(foot: iso(x1 + 0.1, 0.0, h0), iso(x1 + 0.1, 0.08, h0), head: iso(x1 + 0.02, 0.0, top + 6), iso(x1 + 0.02, 0.08, top + 6),
               rungs: 5)
        timbers(-0.7, 0.62, length: 0.6, on: h0)
        bricks(0.5, 0.42, 0.74, 0.66, from: h0, height: 6)
        bollard(at: iso(0.9, Slip.ym + Slip.half + 0.12, h0))
        basket(at: iso(0.18, 0.62, h0), size: 0.9)
    }

    /// The timber centring of an arch on a wall drawn with `wall`: a half round
    /// of boards centred on `u` and springing at `v`, on two props.
    private mutating func centring(_ u: Double, _ v: Double, radius r: Double) {
        typealias I = IndustrialOldBuildingsInk
        let arc = [uv(u - r, v)] + (1...12).map { k -> P in
            let a = Double(k) / 12 * .pi
            return uv(u - r * cos(a), v + r * sin(a))
        }
        colour(arc, .colour(I.timberLight))
        var d = PathData()
        d.move(arc[0])
        for p in arc.dropFirst() { d.line(p) }
        d.close()
        svg.path(d, stroke: .colour(I.line), width: 0.7)
        for k in 1..<4 {
            let a = Double(k) / 4 * .pi
            line([uv(u, v), uv(u - r * cos(a), v + r * sin(a))], width: 0.4, opacity: 0.6)
        }
        for s in [-1.0, 1.0] { timber(uv(u + s * (r - 1.4), 0.2), uv(u + s * (r - 1.4), v), width: 1.6, paint: I.timber) }
    }
}
