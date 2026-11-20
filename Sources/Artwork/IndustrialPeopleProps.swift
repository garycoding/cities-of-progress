// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation

// What the peaceful people of the Industrial age wear and hold: the colours of
// the age (docs/art-style.md, "Palettes") and the things drawn at a hand or on
// the ground. Each is drawn as the Alchemy age's props are
// (AlchemyPeopleProps.swift): its colour a little out of register with its
// outline, along a direction in degrees from straight down, positive toward
// the front.

/// The colours of the Industrial age (brick, navy, soot and the light), with
/// the shades that cloth, leather, coal, iron, brass and glass need. The line,
/// the skin and the eye are the ones every age shares (`Ink`).
enum IndustrialPeopleInk {
    static let brick = "#c2683c"
    static let navy = "#3f5f7a"
    static let soot = "#6b6258"
    static let light = "#efe0c2"
    static let darkBrick = "#8a4426"
    static let paleBrick = "#e0a07a"
    static let darkNavy = "#2a4258"
    static let paleNavy = "#8aa3b8"
    static let darkSoot = "#47413b"
    static let paleSoot = "#a39a8e"
    /// Linen in shadow: the light's own shade.
    static let shadeLight = "#cfbd98"
    static let leather = "#7a4a2a"
    static let darkLeather = "#55321b"
    static let paleLeather = "#b07a50"
    static let wood = "#8a5a33"
    static let darkWood = "#5e3c20"
    static let paleWood = "#c49a66"
    /// Iron and steel, with their light and shade.
    static let iron = "#6f7275"
    static let ironDark = "#45474a"
    static let ironLight = "#c9ccce"
    /// Brass, for the instrument, the oil can, the watch and its chain.
    static let brass = "#c9a24a"
    static let darkBrass = "#8f6f2a"
    static let paleBrass = "#ecd28a"
    /// Coal, and the dull shine on its faces.
    static let coal = "#2f2b29"
    static let coalSheen = "#77706a"
    /// Black silk and broadcloth: the top hat, the cane and the boots.
    static let black = "#2b2627"
    static let blackSheen = "#5e5657"
    /// The liquid in the scientist's flask, and its bubbles.
    static let liquid = "#a9c9d8"
    static let darkLiquid = "#6f98ad"
    static let glass = "#e3efee"
    static let steam = "#f3eadb"
    static let brownHair = "#5a3a24"
    static let gingerHair = "#a35a2c"
    static let greyHair = "#b1aa9c"
    static let blackHair = "#2f2622"
}

/// Geometry and dress the looks share: trousers on the jointed legs, sleeves
/// on the jointed arms, and a point in the picture brought into the leaning body.
enum IndustrialPeopleKit {
    /// Both legs in trousers of `colour` (the far one in `shade`), to boots at
    /// the ankle: upright whatever the body's lean, as `Drawing.legs` draws
    /// them, with the seat of the trousers between the hips.
    static func trousers(_ d: inout Drawing, colour: String, shade: String, stripe: String? = nil) {
        let j = d.joints
        let legs = [(Joints.backHip, j.backKnee, j.backFoot, shade), (Joints.frontHip, j.frontKnee, j.frontFoot, colour)]
        d.svg.group(turned: -d.rig.lean, about: Drawing.hips) { svg in
            // The seat, under the coat or the apron.
            var seat = PathData()
            seat.move(P(8.2, -22)); seat.line(P(-10.4, -22))
            seat.cubic(P(-10.2, -18.4), P(-8.8, -14.4), P(-6, -12.6))
            seat.line(P(8.4, -12.6)); seat.close()
            svg.path(seat, fill: .colour(colour), stroke: .colour(Ink.line), width: 1.2)
            for (hip, knee, foot, cloth) in legs {
                // The trouser leg ends a little above the foot, where the boot begins.
                let ankle = foot + (knee - foot) * (2.2 / Joints.shin)
                svg.line([hip, knee, ankle], stroke: .colour(Ink.line), width: 5.2)
                svg.line([hip, knee, ankle], stroke: .colour(cloth), width: 3.3)
                if let stripe {
                    // Pinstripes down the leg.
                    svg.line([hip + P(-0.6, 0), knee + P(-0.6, 0), ankle + P(-0.6, 0)], stroke: .colour(stripe), width: 0.5)
                    svg.line([hip + P(0.8, 0), knee + P(0.8, 0), ankle + P(0.8, 0)], stroke: .colour(stripe), width: 0.5)
                }
                boot(&svg, ankle: ankle, foot: foot)
            }
        }
    }

    /// A laced boot of black leather from the ankle to the toe, its sole on the ground under the foot.
    static func boot(_ svg: inout SVG, ankle: P, foot: P) {
        let corners = [ankle + P(-1.9, -0.4), ankle + P(1.7, -0.4), foot + P(3.6, -1.4), foot + P(5.6, -0.2), foot + P(5.4, 0.9), foot + P(-2.2, 0.9)]
        BronzePeopleProps.shape(&svg, corners, fill: .colour(IndustrialPeopleInk.black), width: 1, shift: P(-0.4, 0.3))
        svg.line([foot + P(0.4, -1.6), foot + P(3.4, -1.2)], stroke: .colour(IndustrialPeopleInk.blackSheen), width: 0.6)
    }

    /// An arm in a sleeve: the sleeve of `fill` from the shoulder to the elbow
    /// and, unless `rolled`, on to the wrist, `width` thick; rolled, it ends in
    /// a turned-back roll above the elbow's crook and the forearm is bare.
    /// Then the hand.
    static func arm(_ d: inout Drawing, front: Bool, fill: Paint, width: Double = 4.4, rolled: Bool = false, cuff: String? = nil) {
        let shoulder = front ? d.joints.frontShoulder : d.joints.backShoulder
        let elbow = front ? d.joints.frontElbow : d.joints.backElbow
        let hand = front ? d.joints.frontHand : d.joints.backHand
        d.svg.line([shoulder, elbow, hand], stroke: .colour(Ink.line), width: 1.9)
        let forearm = hand - elbow
        let fl = max(BronzePeopleKit.length(forearm), 0.01)
        let fu = forearm * (1 / fl)
        let end = rolled ? elbow + fu * 1.6 : elbow + fu * (fl - 1.6)
        d.svg.line([shoulder, elbow, end], stroke: .colour(Ink.line), width: width + 1.8)
        d.svg.line([shoulder, elbow, end], stroke: fill, width: width)
        let a = P(-fu.y, fu.x)
        if rolled {
            // The roll of the turned-back sleeve.
            let w = width * 0.62
            d.svg.polygon([end + a * w - fu * 0.4, end - a * w - fu * 0.4, end - a * w + fu * 2, end + a * w + fu * 2], fill: fill,
                          stroke: .colour(Ink.line), width: 0.9)
            d.svg.line([end + a * (w - 0.6) + fu * 0.8, end - a * (w - 0.6) + fu * 0.8], stroke: .colour(Ink.line), width: 0.6, opacity: 0.6)
        } else if let cuff {
            let w = width * 0.56
            d.svg.polygon([end + a * w - fu * 0.6, end - a * w - fu * 0.6, end - a * w + fu * 1.2, end + a * w + fu * 1.2],
                          fill: .colour(cuff), stroke: .colour(Ink.line), width: 0.8)
        }
        d.hand(hand)
    }

    /// The arm that puts its hand at `world`, a point of the picture.
    static func reach(front: Bool, _ rig: Rig, to world: P, elbowUp: Bool = false) -> Limb {
        AlchemyPeopleKit.reach(front: front, rig, to: world, elbowUp: elbowUp)
    }

    /// A point of the picture in the body's own units (the inverse of `Drawing.world`).
    static func body(_ world: P, _ rig: Rig) -> P { AlchemyPeopleKit.body(world, rig) }

    /// The direction from `a` to `b`, in the figure's degrees.
    static func degrees(from a: P, to b: P) -> Double { BronzePeopleKit.degrees(from: a, to: b) }

    /// A value through a cycle of 12 frames.
    static func wave(_ frame: Int, _ shift: Double = 0, times: Double = 1) -> Double { BronzePeopleKit.wave(frame, shift, times: times) }
}

/// The props, each drawn into an `SVG`.
enum IndustrialPeopleProps {
    static let ink = Paint.colour(Ink.line)

    /// A point `along` the direction `u` and `side` across it (along `a`) from `origin`.
    static func at(_ origin: P, _ u: P, _ a: P, _ along: Double, _ side: Double) -> P { origin + u * along + a * side }

    // MARK: The factory hand's

    /// The length of a shovel from its grip to the edge of its blade.
    static let shovelLength = 36.0

    /// A coal shovel: a D-handle at `grip`, an ash shaft along `degrees`, and
    /// a broad iron blade at the far end, its edge `shovelLength` from the grip.
    /// `load` (0 to 1) heaps coal on the blade's upper face.
    static func shovel(_ svg: inout SVG, grip: P, degrees: Double, load: Double = 0) {
        let u = P.direction(degrees), a = P(-u.y, u.x)
        let neck = grip + u * (shovelLength - 8.6)
        // The D-handle: a loop of ash, and its cross-grip.
        let loop = [at(grip, u, a, 2.4, -2.2), at(grip, u, a, -1.4, -2.4), at(grip, u, a, -2.2, 0), at(grip, u, a, -1.4, 2.4), at(grip, u, a, 2.4, 2.2)]
        svg.line(loop, stroke: ink, width: 2.6)
        svg.line(loop, stroke: .colour(IndustrialPeopleInk.paleWood), width: 1.1)
        // The shaft.
        svg.line([grip + u * 2.2, neck], stroke: ink, width: 3)
        svg.line([grip + u * 2.2, neck], stroke: .colour(IndustrialPeopleInk.paleWood), width: 1.6)
        // The iron socket clasping the shaft, and the blade.
        BronzePeopleProps.shape(&svg, [at(neck, u, a, -2.4, 1), at(neck, u, a, -2.4, -1), at(neck, u, a, 1.4, -1.8), at(neck, u, a, 1.4, 1.8)],
                                fill: .colour(IndustrialPeopleInk.ironDark), width: 0.9, shift: P(-0.3, 0.3))
        let blade = [at(neck, u, a, 1.2, 2.4), at(neck, u, a, 1.2, -2.4), at(neck, u, a, 8.6, -3.6), at(neck, u, a, 9.2, 0), at(neck, u, a, 8.6, 3.6)]
        BronzePeopleProps.shape(&svg, blade, fill: .colour(IndustrialPeopleInk.iron), width: 1.1, shift: P(-0.5, 0.4))
        svg.line([at(neck, u, a, 2.2, 0.6), at(neck, u, a, 7.6, 0.8)], stroke: .colour(IndustrialPeopleInk.ironLight), width: 0.8)
        // The coal heaped on the side of the blade that faces up.
        if load > 0 {
            let up = a.y < 0 ? a : a * -1
            for (along, side, size) in [(3.6, 2.6, 1.7), (6.2, 2.8, 1.9), (4.8, 4.2, 1.5), (7.8, 2.0, 1.3)] where size * load > 0.6 {
                coalLump(&svg, at: neck + u * along + up * side * load, size: size * load, turn: along * 37)
            }
        }
    }

    /// The edge of a shovel's blade drawn by `shovel` with the same arguments.
    static func shovelEdge(grip: P, degrees: Double) -> P { grip + P.direction(degrees) * shovelLength }

    /// A lump of coal: an angular black stone with a dull shine on one face.
    static func coalLump(_ svg: inout SVG, at c: P, size s: Double, turn: Double = 0) {
        let corners = [P(-1, -0.8), P(0.3, -1.1), P(1.1, -0.2), P(0.7, 0.9), P(-0.6, 0.8), P(-1.2, 0.1)].map { c + $0.rotated(turn, about: P(0, 0)) * s }
        svg.polygon(corners, fill: .colour(IndustrialPeopleInk.coal), stroke: ink, width: 0.6)
        svg.line([corners[0] + (corners[1] - corners[0]) * 0.3, corners[1] + (corners[2] - corners[1]) * 0.5], stroke: .colour(IndustrialPeopleInk.coalSheen),
                 width: 0.6)
    }

    /// A heap of coal on the ground from `left` to `right`, `height` at its
    /// peak, its lumps showing along the slope, and a few fallen at its foot.
    static func coalHeap(_ svg: inout SVG, left: Double, right: Double, height h: Double) {
        let w = right - left, peak = left + w * 0.46
        svg.ellipse(P(left + w / 2, 0.4), w / 2 + 2, 2.2, fill: .colour("#000000"), opacity: 0.13)
        BronzePeopleProps.shape(&svg, fill: .colour(IndustrialPeopleInk.coal), width: 1.3) { o in
            var p = PathData()
            p.move(P(left, 0) + o)
            p.line(P(left + w * 0.16, -h * 0.42) + o)
            p.line(P(left + w * 0.24, -h * 0.5) + o)
            p.line(P(left + w * 0.34, -h * 0.84) + o)
            p.line(P(peak, -h) + o)
            p.line(P(left + w * 0.58, -h * 0.9) + o)
            p.line(P(left + w * 0.7, -h * 0.66) + o)
            p.line(P(left + w * 0.8, -h * 0.5) + o)
            p.line(P(left + w * 0.92, -h * 0.2) + o)
            p.line(P(right, 0) + o)
            p.close()
            return p
        }
        // The faces of the lumps in the heap: their edges and their shine.
        var edges = PathData(), shine = PathData()
        let marks: [(Double, Double)] = [(0.2, 0.28), (0.34, 0.56), (0.48, 0.8), (0.6, 0.5), (0.74, 0.3), (0.4, 0.22), (0.86, 0.14), (0.54, 0.2)]
        for (fx, fy) in marks {
            let c = P(left + w * fx, -h * fy)
            edges.move(c + P(-1.6, 0.6)); edges.line(c + P(-0.4, -0.8)); edges.line(c + P(1.4, -0.4))
            shine.move(c + P(-0.9, -0.6)); shine.line(c + P(0.3, -1.4))
        }
        svg.path(edges, stroke: .colour(IndustrialPeopleInk.coalSheen), width: 0.6)
        svg.path(shine, stroke: .colour(IndustrialPeopleInk.paleSoot), width: 0.6)
        for (x, turn) in [(left - 1.6, 20.0), (right + 1.8, 70.0), (right + 4.6, 10.0)] {
            coalLump(&svg, at: P(x, -1.1), size: 1.2, turn: turn)
        }
    }

    /// A spanner of forged steel: its open jaw at `jaw`, its handle running
    /// from it along `degrees` for `length`, a ring at the far end.
    static func spanner(_ svg: inout SVG, jaw: P, degrees: Double, length: Double = 17, size: Double = 1) {
        let u = P.direction(degrees), a = P(-u.y, u.x)
        let end = jaw + u * length
        svg.line([jaw + u * 2.4 * size, end], stroke: ink, width: 3.6 * size)
        svg.line([jaw + u * 2.4 * size, end], stroke: .colour(IndustrialPeopleInk.iron), width: 2 * size)
        svg.line([jaw + u * 4 * size + a * 0.4, end - u * 1.6 + a * 0.4], stroke: .colour(IndustrialPeopleInk.ironLight), width: 0.6 * size)
        // The jaw: a broad head open away from the handle.
        var head: [P] = []
        for i in 0...12 {
            let t = (-130 + Double(i) * 260 / 12) * .pi / 180
            // An angle measured from the handle's direction, so that the gap faces away from it.
            head.append(jaw + (u * cos(t) + a * sin(t)) * 3.6 * size)
        }
        head.append(jaw - u * 1.2 * size + a * 1.4 * size)
        head.append(jaw + u * 0.2 * size)
        head.append(jaw - u * 1.2 * size - a * 1.4 * size)
        BronzePeopleProps.shape(&svg, head, fill: .colour(IndustrialPeopleInk.iron), width: 1.1, shift: P(-0.3, 0.3))
        // The ring at the far end.
        svg.circle(end + u * 1.4 * size, 2.3 * size, fill: .colour(IndustrialPeopleInk.iron), stroke: ink, width: 1.1)
        svg.circle(end + u * 1.4 * size, 0.9 * size, fill: .colour(IndustrialPeopleInk.ironDark))
    }

    // MARK: The mechanic's

    /// An oil can of tinned brass hanging from its handle at `hand`, swinging
    /// by `swing` degrees: a round body, a long spout reaching forward and up.
    static func oilCan(_ svg: inout SVG, hand: P, swing: Double = 0) {
        svg.group(turned: swing, about: hand) { svg in
            let c = hand + P(0, 7.4)
            // The handle from the hand to the can's shoulder behind.
            svg.path("M\(num(hand.x - 0.4)),\(num(hand.y)) q\(num(-4)),0.4 \(num(-4.4)),\(num(4.2))", stroke: ink, width: 1.8)
            svg.path("M\(num(hand.x - 0.4)),\(num(hand.y)) q\(num(-4)),0.4 \(num(-4.4)),\(num(4.2))", stroke: .colour(IndustrialPeopleInk.brass), width: 0.7)
            // The spout.
            svg.line([c + P(2.4, -2.2), c + P(11, -9.4)], stroke: ink, width: 2.2)
            svg.line([c + P(2.4, -2.2), c + P(11, -9.4)], stroke: .colour(IndustrialPeopleInk.brass), width: 0.9)
            // The body: a squat drum, wider at its foot.
            BronzePeopleProps.shape(&svg, [c + P(-2.6, -3.2), c + P(2.6, -3.2), c + P(4.6, 3.4), c + P(-4.6, 3.4)], fill: .colour(IndustrialPeopleInk.brass),
                                    width: 1.1, shift: P(-0.4, 0.3))
            svg.ellipse(c + P(0, -3.4), 2.6, 0.9, fill: .colour(IndustrialPeopleInk.paleBrass), stroke: ink, width: 0.8)
            svg.line([c + P(-3.4, 0.6), c + P(3.4, 0.6)], stroke: .colour(IndustrialPeopleInk.darkBrass), width: 0.8)
            svg.line([c + P(-1.2, -2.2), c + P(-2.6, 2.6)], stroke: .colour(IndustrialPeopleInk.paleBrass), width: 0.8)
        }
    }

    /// The end of a steam engine's cylinder on its cast-iron bed, standing on
    /// the ground from `left` to `right`, its face a flange held by bolts, the
    /// great nut at its middle (`nut`) turned by `turn` degrees, and a gauge on top.
    static func engine(_ svg: inout SVG, left: Double, right: Double, nut: P, turn: Double, needle: Double) {
        let w = right - left
        svg.ellipse(P(left + w / 2, 0.4), w / 2 + 3, 2.4, fill: .colour("#000000"), opacity: 0.13)
        // The bed: a plinth of iron painted brick-red, its feet bolted down.
        BronzePeopleProps.shape(&svg, [P(left - 1.6, 0), P(right + 1.6, 0), P(right, -5), P(left, -5)], fill: .colour(IndustrialPeopleInk.brick), width: 1.2)
        svg.line([P(left + 0.6, -3.8), P(right - 0.6, -3.8)], stroke: .colour(IndustrialPeopleInk.paleBrick), width: 0.7)
        for x in [left + 1.6, right - 1.6] {
            svg.circle(P(x, -2.4), 0.8, fill: .colour(IndustrialPeopleInk.ironLight), stroke: ink, width: 0.5)
        }
        // The cylinder's flange: a round face of iron, on a cast pedestal painted like the bed.
        let r = min(w * 0.5, -nut.y - 5) - 0.4
        BronzePeopleProps.shape(&svg, [P(nut.x - r * 0.6, nut.y + r * 0.5), P(nut.x + r * 0.6, nut.y + r * 0.5), P(nut.x + r * 0.9, -5),
                                       P(nut.x - r * 0.9, -5)], fill: .colour(IndustrialPeopleInk.brick), width: 1.2)
        svg.line([P(nut.x - r * 0.5, -6.6), P(nut.x + r * 0.5, -6.6)], stroke: .colour(IndustrialPeopleInk.darkBrick), width: 0.8)
        svg.circle(nut + P(-0.6, 0.6), r, fill: .colour(IndustrialPeopleInk.iron))
        svg.circle(nut, r, fill: .none, stroke: ink, width: 1.4)
        svg.circle(nut, r * 0.74, fill: .none, stroke: .colour(IndustrialPeopleInk.ironDark), width: 0.9)
        svg.path("M\(num(nut.x - r * 0.7)),\(num(nut.y - r * 0.5)) a\(num(r * 0.86)),\(num(r * 0.86)) 0 0 1 \(num(r * 1.1)),\(num(-r * 0.4))",
                 stroke: .colour(IndustrialPeopleInk.ironLight), width: 0.9)
        // The ring of bolts round the face.
        for i in 0..<8 {
            let t = Double(i) / 8 * 2 * .pi
            svg.circle(nut + P(cos(t), sin(t)) * (r * 0.86), 0.75, fill: .colour(IndustrialPeopleInk.ironLight), stroke: ink, width: 0.5)
        }
        // The gauge on its pipe above the flange, its needle trembling.
        let gauge = P(nut.x + r * 0.2, nut.y - r - 4.4)
        svg.line([P(gauge.x, nut.y - r + 0.6), gauge + P(0, 2)], stroke: ink, width: 2)
        svg.line([P(gauge.x, nut.y - r + 0.6), gauge + P(0, 2)], stroke: .colour(IndustrialPeopleInk.brass), width: 0.8)
        svg.circle(gauge, 2.8, fill: .colour(IndustrialPeopleInk.light), stroke: .colour(IndustrialPeopleInk.darkBrass), width: 1.1)
        svg.circle(gauge, 3.4, fill: .none, stroke: ink, width: 0.7)
        svg.line([gauge, gauge + P.direction(180 + needle) * 2.2], stroke: .colour(IndustrialPeopleInk.darkBrick), width: 0.7)
        // The great nut, a hexagon facing us.
        nutFace(&svg, at: nut, turn: turn, radius: 3.2)
    }

    /// A hexagonal nut seen end on at `c`, turned by `turn` degrees, with its bolt's end in it.
    static func nutFace(_ svg: inout SVG, at c: P, turn: Double, radius r: Double) {
        let corners = (0..<6).map { i -> P in
            let t = (Double(i) * 60 + turn) * .pi / 180
            return c + P(cos(t), sin(t)) * r
        }
        BronzePeopleProps.shape(&svg, corners, fill: .colour(IndustrialPeopleInk.ironLight), width: 1, shift: P(-0.3, 0.3))
        svg.circle(c, r * 0.42, fill: .colour(IndustrialPeopleInk.iron), stroke: ink, width: 0.6)
        // A chalk mark on one flat, so that its turning shows.
        let mark = (corners[0] + corners[1]) * 0.5
        svg.line([c + (mark - c) * 0.55, mark], stroke: .colour(IndustrialPeopleInk.light), width: 0.8)
    }

    /// A drop of oil, round below and pointed above.
    static func drop(_ svg: inout SVG, at c: P, size s: Double = 1) {
        svg.path("M\(num(c.x)),\(num(c.y - 1.6 * s)) q\(num(1.3 * s)),\(num(1.4 * s)) 0,\(num(2.4 * s)) q\(num(-1.3 * s)),\(num(-1 * s)) 0,\(num(-2.4 * s)) Z",
                 fill: .colour(IndustrialPeopleInk.darkSoot), stroke: ink, width: 0.5)
    }

    // MARK: The scientist's

    /// A conical flask of glass standing with its foot's middle at `base`,
    /// `height` tall, half full of a pale blue liquid in which bubbles rise at
    /// `boil` (0 to 1 through the cycle; nil when it is still).
    static func conicalFlask(_ svg: inout SVG, base: P, height h: Double, boil: Double?) {
        let half = h * 0.42, neck = h * 0.14
        let level = base.y - h * 0.46
        // The liquid: the flask below the level.
        let atLevel = half * (1 - (base.y - level) / (h * 0.62))
        svg.polygon([P(base.x - half, base.y), P(base.x + half, base.y), P(base.x + atLevel, level), P(base.x - atLevel, level)],
                    fill: .colour(IndustrialPeopleInk.liquid))
        svg.line([P(base.x - atLevel, level), P(base.x + atLevel, level)], stroke: .colour(IndustrialPeopleInk.darkLiquid), width: 0.7)
        if let boil {
            // Bubbles rising from the floor of the flask to the surface, each in its own phase.
            for (k, x) in [(0.0, -0.3), (0.37, 0.25), (0.7, -0.02)] {
                let p = (boil + k).truncatingRemainder(dividingBy: 1)
                let y = base.y - 1 - p * (base.y - level - 1.6)
                svg.circle(P(base.x + x * half * (1 - p * 0.4), y), 0.5 + p * 0.5, fill: .colour(IndustrialPeopleInk.glass), stroke: .colour(IndustrialPeopleInk.darkLiquid),
                           width: 0.4)
            }
        }
        // The glass: sloping sides to the neck, the neck, and the lip.
        let top = base.y - h
        let outline = [P(base.x - neck * 0.55, top + 1), P(base.x - neck * 0.55, base.y - h * 0.62), P(base.x - half, base.y - 0.4),
                       P(base.x - half + 0.6, base.y), P(base.x + half - 0.6, base.y), P(base.x + half, base.y - 0.4),
                       P(base.x + neck * 0.55, base.y - h * 0.62), P(base.x + neck * 0.55, top + 1)]
        svg.polygon(outline, fill: .colour(IndustrialPeopleInk.glass), opacity: 0.35)
        svg.line(outline, stroke: ink, width: 1)
        svg.line([P(base.x - neck * 0.9, top + 0.6), P(base.x + neck * 0.9, top + 0.6)], stroke: ink, width: 1.5)
        svg.line([P(base.x - half * 0.5, base.y - h * 0.2), P(base.x - neck * 0.2, base.y - h * 0.56)], stroke: .colour("#ffffff"), width: 0.8, opacity: 0.85)
    }

    /// A tripod of iron over a brass spirit lamp, standing on the ground at
    /// `x`, its ring `height` above the ground, the lamp's flame flickering by `flicker`.
    static func burner(_ svg: inout SVG, x: Double, height h: Double, flicker: Double) {
        svg.ellipse(P(x, 0.4), 9, 2, fill: .colour("#000000"), opacity: 0.13)
        // The lamp: a squat brass reservoir and its wick.
        BronzePeopleProps.shape(&svg, [P(x - 3.4, 0), P(x + 3.4, 0), P(x + 2.6, -3.6), P(x - 2.6, -3.6)], fill: .colour(IndustrialPeopleInk.brass), width: 1)
        svg.line([P(x - 2.4, -1.4), P(x + 2.4, -1.4)], stroke: .colour(IndustrialPeopleInk.darkBrass), width: 0.6)
        svg.line([P(x, -3.6), P(x, -5)], stroke: ink, width: 1.2)
        // The flame: a blue-tipped tongue that leans and stretches.
        let tip = P(x + flicker * 0.9, -9.6 - abs(flicker) * 0.8)
        svg.path("M\(num(x - 1.3)),-5 Q\(num(x - 1.4)),-7.6 \(num(tip.x)),\(num(tip.y)) Q\(num(x + 1.6)),-7.4 \(num(x + 1.3)),-5 Z",
                 fill: .colour(IndustrialPeopleInk.paleBrass), stroke: ink, width: 0.7)
        svg.path("M\(num(x - 0.5)),-5.2 Q\(num(x)),-6.8 \(num(x + flicker * 0.4)),-7.6 Q\(num(x + 0.7)),-6.4 \(num(x + 0.5)),-5.2 Z",
                 fill: .colour(IndustrialPeopleInk.brick))
        // The tripod's legs and its ring with the gauze on it.
        for (foot, top) in [(x - 6.4, x - 4.6), (x + 6.4, x + 4.6)] {
            svg.line([P(foot, 0), P(top, -h)], stroke: ink, width: 1.8)
            svg.line([P(foot, 0), P(top, -h)], stroke: .colour(IndustrialPeopleInk.iron), width: 0.7)
        }
        svg.line([P(x, -h + 0.6), P(x + 0.4, -1.8)], stroke: ink, width: 1.2, opacity: 0.55)
        svg.line([P(x - 5.6, -h), P(x + 5.6, -h)], stroke: ink, width: 2)
        svg.line([P(x - 5, -h - 0.1), P(x + 5, -h - 0.1)], stroke: .colour(IndustrialPeopleInk.ironLight), width: 0.7)
    }

    /// A notebook bound in brick-red cloth, open at `c` and turned by
    /// `degrees`: two pages, the near one written over `written` (0 to 1) of
    /// its lines.
    static func notebook(_ svg: inout SVG, at c: P, degrees: Double, written: Double) {
        svg.group(at: c, turned: degrees) { svg in
            svg.polygon([P(-7.2, -1.2), P(7.2, -1.2), P(7.6, 1.6), P(0, 2.2), P(-7.6, 1.6)], fill: .colour(IndustrialPeopleInk.darkBrick), stroke: ink, width: 0.9)
            for side in [-1.0, 1.0] {
                var page = PathData()
                page.move(P(0, 1)); page.quad(P(side * 3.4, -0.9), P(side * 6.8, -0.5))
                page.line(P(side * 6.6, -5)); page.quad(P(side * 3.4, -5.6), P(0, -4)); page.close()
                svg.path(page, fill: .colour(IndustrialPeopleInk.light), stroke: ink, width: 0.8)
            }
            // The far page full; the near one filling line by line.
            var lines = PathData()
            for row in 0..<3 {
                let y = -3.8 + Double(row) * 1.2
                lines.move(P(-1.4, y + 0.2)); lines.line(P(-5.6, y - 0.1))
            }
            let rows = 3.0 * written
            for row in 0..<3 where Double(row) < rows {
                let y = -3.8 + Double(row) * 1.2
                let length = min(1, rows - Double(row)) * 4.2
                lines.move(P(1.4, y + 0.2)); lines.line(P(1.4 + length, y - 0.1 * length / 4.2))
            }
            svg.path(lines, stroke: .colour(IndustrialPeopleInk.navy), width: 0.5)
            svg.line([P(0, 1), P(0, -4)], stroke: ink, width: 0.7)
        }
    }

    /// The same notebook shut, centred on `c` and turned by `degrees`, an elastic band round it.
    static func shutNotebook(_ svg: inout SVG, at c: P, degrees: Double, width w: Double = 7.6, height h: Double = 10.6) {
        svg.group(at: c, turned: degrees) { svg in
            svg.polygon([P(-w / 2 + 1, -h / 2 + 1), P(w / 2 + 1.1, -h / 2 + 1), P(w / 2 + 1.1, h / 2 + 0.6), P(-w / 2 + 1, h / 2 + 0.6)],
                        fill: .colour(IndustrialPeopleInk.light), stroke: ink, width: 0.8)
            svg.path(BronzePeopleProps.rounded(P(0, 0), width: w, height: h, radius: 0.9, degrees: 0, shift: P(-0.5, 0.4)),
                     fill: .colour(IndustrialPeopleInk.brick))
            svg.path(BronzePeopleProps.rounded(P(0, 0), width: w, height: h, radius: 0.9, degrees: 0, shift: P(0, 0)), stroke: ink, width: 1)
            svg.line([P(w * 0.22, -h / 2 + 0.3), P(w * 0.22, h / 2 - 0.3)], stroke: .colour(IndustrialPeopleInk.darkSoot), width: 0.8)
            svg.line([P(-w / 2 + 0.8, -h / 2 + 0.4), P(-w / 2 + 0.8, h / 2 - 0.4)], stroke: ink, width: 1.1, opacity: 0.5)
        }
    }

    /// A pencil in the hand at `hand`, its point `length` along `degrees`.
    static func pencil(_ svg: inout SVG, at hand: P, degrees: Double, length: Double = 6.4) {
        let u = P.direction(degrees)
        let back = hand - u * 2.4, point = hand + u * length
        svg.line([back, point - u * 1.4], stroke: ink, width: 1.9)
        svg.line([back, point - u * 1.4], stroke: .colour(IndustrialPeopleInk.navy), width: 0.9)
        svg.line([point - u * 1.6, point], stroke: .colour(IndustrialPeopleInk.paleWood), width: 1)
        svg.circle(point, 0.35, fill: ink)
    }

    // MARK: The industrialist's

    /// A cane of black lacquered wood with a brass knob at `top`, running
    /// along `degrees` for `length` to its brass ferrule.
    static func cane(_ svg: inout SVG, top: P, degrees: Double, length: Double) {
        let u = P.direction(degrees)
        let tip = top + u * length
        svg.line([top, tip], stroke: ink, width: 2.4)
        svg.line([top + u * 1, tip - u * 1.4], stroke: .colour(IndustrialPeopleInk.blackSheen), width: 0.6)
        svg.line([tip - u * 1.4, tip], stroke: .colour(IndustrialPeopleInk.brass), width: 1.2)
        svg.circle(top - u * 0.6 + P(-0.3, 0.3), 1.9, fill: .colour(IndustrialPeopleInk.brass))
        svg.circle(top - u * 0.6, 1.9, fill: .none, stroke: ink, width: 0.9)
        svg.circle(top - u * 0.6 + P(-0.6, -0.6), 0.5, fill: .colour(IndustrialPeopleInk.paleBrass))
    }

    /// Plans rolled up and tied: a roll of navy blueprint paper centred on
    /// `c` along `degrees`, `length` long, its pale curl showing at each end.
    static func plans(_ svg: inout SVG, at c: P, degrees: Double, length: Double = 15) {
        let u = P.direction(degrees), a = P(-u.y, u.x)
        let r = 1.9
        let start = c - u * (length / 2), end = c + u * (length / 2)
        BronzePeopleProps.shape(&svg, [start + a * r, end + a * r, end - a * r, start - a * r], fill: .colour(IndustrialPeopleInk.navy), width: 1,
                                shift: P(-0.4, 0.3))
        // The fine white lines of the drawing showing on the outer turn.
        svg.line([start + u * 2 + a * 0.6, end - u * 3 + a * 0.6], stroke: .colour(IndustrialPeopleInk.paleNavy), width: 0.5)
        // The ends of the roll, curled.
        for p in [start, end] {
            svg.ellipse(p, 1, r, fill: .colour(IndustrialPeopleInk.light), stroke: ink, width: 0.7)
            svg.circle(p, 0.5, fill: .none, stroke: .colour(IndustrialPeopleInk.navy), width: 0.4)
        }
        // The tape tied round its middle.
        svg.line([c + a * (r + 0.3) + u * 1, c - a * (r + 0.3) + u * 1], stroke: .colour(IndustrialPeopleInk.paleBrick), width: 1.1)
    }

    /// A gold hunter watch at `c`, its lid open by `open` (0 shut, 1 thrown back),
    /// its hands at `minutes` past the hour.
    static func watch(_ svg: inout SVG, at c: P, open: Double, minutes: Double) {
        let r = 3.4
        // The lid, swinging up from its hinge at the top: a disc seen more nearly full as it opens.
        if open > 0.05 {
            let lid = c + P(0, -r - r * open * 0.95)
            svg.ellipse(lid + P(-0.3, 0.3), r, r * open * 0.95, fill: .colour(IndustrialPeopleInk.brass))
            svg.ellipse(lid, r, r * open * 0.95, fill: .none, stroke: ink, width: 0.8)
            if open > 0.5 { svg.ellipse(lid, r * 0.6, r * open * 0.55, fill: .none, stroke: .colour(IndustrialPeopleInk.darkBrass), width: 0.5) }
        }
        svg.circle(c + P(r * 0.96, -r * 0.3), 0.9, fill: .none, stroke: .colour(IndustrialPeopleInk.darkBrass), width: 0.6)
        svg.circle(c + P(-0.3, 0.3), r, fill: .colour(IndustrialPeopleInk.brass))
        svg.circle(c, r, fill: .none, stroke: ink, width: 0.9)
        if open > 0.5 {
            svg.circle(c, r * 0.72, fill: .colour(IndustrialPeopleInk.light))
            let t = minutes / 60 * 2 * .pi
            svg.line([c, c + P(sin(t), -cos(t)) * (r * 0.62)], stroke: ink, width: 0.4)
            svg.line([c, c + P(0.6, -0.9) * (r * 0.38)], stroke: ink, width: 0.5)
        } else {
            svg.circle(c, r * 0.62, fill: .none, stroke: .colour(IndustrialPeopleInk.darkBrass), width: 0.5)
            svg.circle(c + P(-0.8, -0.8), 0.5, fill: .colour(IndustrialPeopleInk.paleBrass))
        }
    }

    /// A watch chain of brass links from `from` to `to`, sagging by `sag`.
    static func chain(_ svg: inout SVG, from: P, to: P, sag: Double) {
        let mid = (from + to) * 0.5 + P(0, sag)
        var p = PathData()
        p.move(from); p.quad(mid, to)
        svg.path(p, stroke: ink, width: 1.4)
        svg.path(p, stroke: .colour(IndustrialPeopleInk.brass), width: 0.7)
        // The links picked out along it.
        var links = PathData()
        for i in 1..<6 {
            let t = Double(i) / 6
            let q = from * ((1 - t) * (1 - t)) + mid * (2 * t * (1 - t)) + to * (t * t)
            links.move(q + P(-0.2, -0.2)); links.line(q + P(0.2, 0.2))
        }
        svg.path(links, stroke: .colour(IndustrialPeopleInk.paleBrass), width: 0.6)
    }
}
