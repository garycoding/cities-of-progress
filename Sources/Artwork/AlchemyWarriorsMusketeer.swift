// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The musketeer

/// A musketeer: a broad hat of deep teal with a band of the team's colour and
/// a feather in the light; long hair, an upturned moustache and a pointed
/// beard; nose C. A buff coat with gilt buttons over teal sleeves and wine
/// breeches, a falling collar of linen, a sash of the team's colour at the
/// waist knotted at the hip, folded boots, and a bandolier across the chest
/// hung with gilt-capped chargers and a priming flask. He carries a matchlock
/// musket, its slow match smouldering in the serpentine, and a forked rest.
/// Standing, he holds the musket upright beside him and leans on the rest;
/// walking, he carries the musket at the trail and the rest with it in one hand;
/// fighting, he plants the rest, lays the musket in its fork and aims, fires
/// with a flash and a cloud of smoke, then stands the musket in the fork and
/// rams the next charge home: the slow reload is half of every cycle.
struct AlchemyWarriorsMusketeer: PersonLook {
    /// The person's canvas, carried forward for the musket's reach and its smoke.
    static let canvas = Canvas(minX: -36, minY: -102, width: 136, height: 108, pixelsPerUnit: Canvas.person.pixelsPerUnit)

    static let musket = 47.5
    static let rest = 44.5
    /// Where the rest is planted when he fights.
    static let restFoot = P(25, 0)

    // MARK: The drill

    /// One frame of the fight, in the picture's units (not the leaning body's):
    /// where the musket's butt is and which way it points, where each hand
    /// holds, the rest's lean, the ramrod and the match.
    struct Drill {
        var lean: Double
        var backLeg = Limb(-14, 6), frontLeg = Limb(14, 10)
        var butt: P
        var degrees: Double
        /// How far along the musket each hand holds; nil for a hand placed by `farAt` or by the ramrod.
        var nearAlong: Double?
        var farAlong: Double?
        var restDegrees: Double
        /// Ramming: how far above the muzzle the hand holds the ramrod.
        var ram: Double?
        /// The ramrod drawn out of its pipes, beside the barrel.
        var drawing = false
        /// The serpentine, from raised (0) to down in the pan (1).
        var cock = 0.0
        var match = true
        var eyes = Eyes.open
        var mouth = Mouth.firm
        var headTilt = 0.0
    }

    /// Where the far hand hangs, holding the match, whilst he loads.
    static let farHanging = P(-10, -31)

    static let drill: [Drill] = {
        let reload = (back: Limb(-8, 4), front: Limb(10, 6))
        var d: [Drill] = [
            Drill(lean: 5, butt: P(0, -46.6), degrees: 90, nearAlong: 22, farAlong: 9, restDegrees: 179.2, cock: 0.1, headTilt: 8),
            Drill(lean: 5, butt: P(0, -46.6), degrees: 90, nearAlong: 22, farAlong: 9, restDegrees: 179.2, cock: 0.55, headTilt: 9),
            Drill(lean: 2, butt: P(-1.2, -47), degrees: 92, nearAlong: 22.5, farAlong: 9, restDegrees: 179.2, cock: 1, eyes: .closed, headTilt: 5),
            Drill(lean: 1, butt: P(-1.6, -47.2), degrees: 93.5, nearAlong: 22.5, farAlong: 8.5, restDegrees: 179.2, cock: 1, eyes: .wide,
                  mouth: .open, headTilt: 3),
            Drill(lean: 3, butt: P(8, -26), degrees: 140, nearAlong: 14, restDegrees: 182, cock: 1, headTilt: 3),
            Drill(lean: 3.5, butt: P(12.6, -3), degrees: 168, nearAlong: 30, restDegrees: 184.6, cock: 1, match: false, eyes: .down, headTilt: 4),
            Drill(lean: 4, butt: P(14, 0), degrees: 172, restDegrees: 185.9, drawing: true, cock: 1, match: false, eyes: .down, headTilt: 4),
            Drill(lean: 4, butt: P(14, 0), degrees: 172, restDegrees: 185.9, ram: 5.6, cock: 1, match: false, eyes: .down, headTilt: 4),
            Drill(lean: 4, butt: P(14, 0), degrees: 172, restDegrees: 185.9, ram: 1.8, cock: 1, match: false, eyes: .down, mouth: .murmur, headTilt: 4),
            Drill(lean: 4, butt: P(14, 0), degrees: 172, restDegrees: 185.9, ram: 6.2, cock: 1, match: false, eyes: .down, headTilt: 4),
            Drill(lean: 3, butt: P(8, -26), degrees: 140, nearAlong: 14, restDegrees: 182, cock: 0, match: false, headTilt: 4),
            Drill(lean: 4, butt: P(2, -40), degrees: 110, nearAlong: 20, farAlong: 8, restDegrees: 181, cock: 0, headTilt: 6),
        ]
        for i in 5...9 { d[i].backLeg = reload.back; d[i].frontLeg = reload.front }
        for i in [4, 10] { d[i].backLeg = Limb(-11, 5); d[i].frontLeg = Limb(12, 8) }
        d[11].backLeg = Limb(-12, 5); d[11].frontLeg = Limb(12, 8)
        return d
    }()

    /// The musket's direction as a unit vector, and the side its belly faces.
    static func axes(_ degrees: Double) -> (u: P, a: P) {
        let u = P.direction(degrees)
        return (u, P(-u.y, u.x))
    }

    /// The muzzle of a musket whose butt is at `butt`, pointing along `degrees`.
    static func muzzle(butt: P, degrees: Double) -> P {
        let (u, a) = axes(degrees)
        return butt + u * musket - a * 1.4
    }

    /// Where the near hand holds the ramrod in a frame of the fight.
    static func ramGrip(_ s: Drill) -> P? {
        let (u, a) = axes(s.degrees)
        let m = muzzle(butt: s.butt, degrees: s.degrees)
        if let ram = s.ram { return m + u * ram }
        if s.drawing { return m + u * 4.4 + a * 1.8 }
        return nil
    }

    /// The hands' places in the picture for a frame of the fight.
    static func hands(_ s: Drill) -> (near: P, far: P) {
        let (u, _) = axes(s.degrees)
        let near = ramGrip(s) ?? s.butt + u * (s.nearAlong ?? 20)
        let far = s.farAlong.map { s.butt + u * $0 } ?? farHanging
        return (near, far)
    }

    /// The rig whose hands reach `near` and `far`, points of the picture.
    static func reaching(_ r: inout Rig, near: P, far: P, elbowUp: Bool = false) {
        let bob = -max(Joints(r).backFoot.y, Joints(r).frontFoot.y)
        func local(_ p: P) -> P { IronWarriorsKit.local(p, origin: P(0, 0), lean: r.lean, bob: bob) }
        r.frontArm = BronzePeopleKit.reach(IronWarriorsKit.frontShoulder(r), local(near), elbowUp: elbowUp)
        r.backArm = BronzePeopleKit.reach(IronWarriorsKit.backShoulder(r), local(far))
    }

    // MARK: The poses

    /// Standing: the musket's butt on the ground and its muzzle at his shoulder.
    static let standingButt = P(16.6, -1.2), standingDegrees = 179.0
    static let standingRestFoot = P(-12.6, 0), standingRestDegrees = 179.0

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.backLeg = Limb(-5, 4); r.frontLeg = Limb(6, 4)
            r.mouth = .firm
            let u = P.direction(Self.standingDegrees), v = P.direction(Self.standingRestDegrees)
            Self.reaching(&r, near: Self.standingButt + u * (31.6 + r.lift * 0.4), far: Self.standingRestFoot + v * (31 + r.lift * 0.4))
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 22)
            r.mouth = .firm
            r.frontArm = BronzePeopleKit.reach(IronWarriorsKit.frontShoulder(r), P(12.4 + 1.2 * r.sway, -30.4))
            return r
        case .fighting:
            let s = Self.drill[frame]
            var r = Rig()
            r.lean = s.lean
            r.backLeg = s.backLeg; r.frontLeg = s.frontLeg
            r.eyes = s.eyes; r.mouth = s.mouth; r.headTilt = s.headTilt
            let (near, far) = Self.hands(s)
            Self.reaching(&r, near: near, far: far)
            return r
        default:
            return nil
        }
    }

    /// The musket at the trail whilst walking: its direction and where the hand holds it.
    static func trail(_ frame: Int) -> (degrees: Double, along: Double) {
        (97 + 3 * BronzePeopleKit.wave(frame), 21)
    }

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        let fight = pose == .fighting ? Self.drill[frame] : nil
        // The body leans; the musket, the rest and the smoke are placed in the picture.
        let worldOpen = "<g transform=\"rotate(\(num(-d.rig.lean)) \(num(Drawing.hips.x)) \(num(Drawing.hips.y))) translate(0,\(num(-d.bob)))\">"
        let farHand = d.world(d.joints.backHand), nearHand = d.world(d.joints.frontHand)
        d.figure { d in
            // The far arm, behind the body, with the rest or the match in its hand.
            Self.sleeve(&d, front: false)
            d.svg.raw(worldOpen)
            switch pose {
            case .standing:
                Self.rest(&d.svg, foot: Self.standingRestFoot, degrees: Self.standingRestDegrees)
            case .walking:
                break
            default:
                if let s = fight, s.farAlong == nil, !s.match { Self.match(&d.svg, inHand: farHand, frame: frame) }
            }
            d.svg.raw("</g>")
            d.hand(d.joints.backHand)
            Self.legs(&d)
            Self.coat(&d, pose: pose, frame: frame, sway: sway)
            // The musket, and the rest it lies in when he fights.
            d.svg.raw(worldOpen)
            switch pose {
            case .standing:
                Self.musket(&d.svg, butt: Self.standingButt, degrees: Self.standingDegrees, cock: 0, match: true, ramrod: true, frame: frame)
            case .walking:
                let t = Self.trail(frame)
                let u = P.direction(t.degrees)
                // The rest, carried in the same hand, its fork forward and up.
                let restDegrees = 150 + 2 * BronzePeopleKit.wave(frame)
                Self.rest(&d.svg, foot: nearHand - P.direction(restDegrees) * 21, degrees: restDegrees)
                Self.musket(&d.svg, butt: nearHand - u * t.along, degrees: t.degrees, cock: 0, match: true, ramrod: true, frame: frame)
            default:
                if let s = fight {
                    Self.rest(&d.svg, foot: Self.restFoot, degrees: s.restDegrees)
                    Self.musket(&d.svg, butt: s.butt, degrees: s.degrees, cock: s.cock, match: s.match,
                                ramrod: s.ram == nil && !s.drawing, frame: frame)
                    Self.ramrod(&d.svg, s)
                    if s.farAlong != nil { d.hand(farHand) }
                }
            }
            d.svg.raw("</g>")
            Self.sleeve(&d, front: true)
            Self.head(&d, pose: pose, frame: frame)
        }
        if let s = fight { Self.shot(&d.svg, frame: frame, drill: s) }
    }

    /// An arm in a teal sleeve with a linen cuff, and its hand.
    static func sleeve(_ d: inout Drawing, front: Bool) {
        let j = d.joints
        let points = front ? [j.frontShoulder, j.frontElbow, j.frontHand] : [j.backShoulder, j.backElbow, j.backHand]
        let shade = front ? AlchemyWarriorsInk.teal : AlchemyWarriorsInk.darkTeal
        let cuffAt = points[2] + (points[1] - points[2]) * (2.2 / Joints.forearm)
        d.svg.line([points[0], points[1], cuffAt], stroke: .colour(Ink.line), width: 4.6)
        d.svg.line([points[0], points[1], cuffAt], stroke: .colour(shade), width: 3)
        d.svg.line([cuffAt, points[2]], stroke: .colour(Ink.line), width: 1.9)
        let along = P.direction(BronzePeopleKit.degrees(from: points[1], to: points[2])), across = P(-along.y, along.x)
        AlchemyWarriorsKit.shape(&d.svg, [cuffAt + across * 2.6 - along * 0.4, cuffAt + across * 2 + along * 1.6, cuffAt - across * 2 + along * 1.6,
                                          cuffAt - across * 2.6 - along * 0.4], fill: .colour(AlchemyWarriorsInk.linen), width: 0.8)
        if front {
            // The slashes of the sleeve at the shoulder.
            d.svg.line([points[0] + P(-1, 2), points[0] + (points[1] - points[0]) * 0.55 + P(-0.6, 0)],
                       stroke: .colour(AlchemyWarriorsInk.paleTeal), width: 0.8)
            d.hand(points[2])
        }
    }

    /// The legs in wine breeches to the knee and folded boots of leather.
    static func legs(_ d: inout Drawing) {
        let j = d.joints
        d.svg.group(turned: -d.rig.lean, about: Drawing.hips) { svg in
            for front in [false, true] {
                let hip = front ? Joints.frontHip : Joints.backHip
                let knee = front ? j.frontKnee : j.backKnee, foot = front ? j.frontFoot : j.backFoot
                let shade = front ? AlchemyWarriorsInk.wine : AlchemyWarriorsInk.darkWine
                let u = P.direction(BronzePeopleKit.degrees(from: knee, to: foot))
                let below = knee + u * 1.4
                // The leg itself, the breeches over the thigh, and the boot.
                svg.line([knee, foot, foot + P(4.5, 0.3)], stroke: .colour(Ink.line), width: 2.1)
                svg.line([hip, knee, below], stroke: .colour(Ink.line), width: 5.2)
                svg.line([hip, knee, below], stroke: .colour(shade), width: 3.6)
                let top = knee + u * 3.6
                svg.line([top, foot, foot + P(4.6, 0.3)], stroke: .colour(Ink.line), width: 3.8)
                svg.line([top + u * 0.4, foot + P(0.2, -0.2)], stroke: .colour(front ? AlchemyWarriorsInk.leather : AlchemyWarriorsInk.darkLeather), width: 2)
                let a = P(-u.y, u.x)
                BronzePeopleProps.shape(&svg, [top + a * 3.2 - u * 0.6, top + a * 2.6 + u * 2.2, top - a * 2.6 + u * 2.2, top - a * 3.2 - u * 0.6],
                                        fill: .colour(front ? AlchemyWarriorsInk.leather : AlchemyWarriorsInk.darkLeather), width: 0.9)
                svg.line([foot + P(-1.6, 0.6), foot + P(-1.4, 1.6)], stroke: .colour(Ink.line), width: 1.4)
            }
        }
    }

    /// The buff coat, the sash, the bandolier and the collar.
    static func coat(_ d: inout Drawing, pose: SpritePose, frame: Int, sway: Double) {
        let swing = pose == .walking ? sway : 0
        d.garment(colour: [P(-13.2, -46.4), P(9.4, -48.4), P(12.6, -39.6), P(12, -28.4), P(16.4 + swing * 0.6, -12.8), P(-16.6 + swing * 0.6, -12.4),
                           P(-13.4, -28.4)],
                  outline: [P(-9.4, -47.4), P(9.2, -47.4), P(11.8, -40), P(11.2, -29), P(15 + swing * 0.6, -13.8), P(-15.2 + swing * 0.6, -13.8),
                            P(-12.6, -29)], fill: .colour(AlchemyWarriorsInk.buff)) { d in
            // The opening at the front, the split of the skirt, the hem's welt and the buttons.
            d.svg.line([d.up(P(8.6, -47)), d.up(P(10.6, -29.6))], stroke: .colour(AlchemyWarriorsInk.darkBuff), width: 1)
            d.svg.line([P(6.4, -27.4), P(9.4 + swing * 0.6, -14.2)], stroke: .colour(Ink.line), width: 1, opacity: 0.6)
            d.svg.line([P(-14.6 + swing * 0.6, -15.6), P(14.4 + swing * 0.6, -15.8)], stroke: .colour(AlchemyWarriorsInk.paleBuff), width: 1.1)
            d.svg.line([P(-6, -26.6), P(-7.2 + swing * 0.4, -15.4)], stroke: .colour(AlchemyWarriorsInk.darkBuff), width: 0.8)
            for i in 0..<5 {
                let y = -44.4 + Double(i) * 3.4
                d.svg.circle(d.up(P(8.4 + Double(i) * 0.4, y)), 0.75, fill: .colour(AlchemyWarriorsInk.gilt), stroke: .colour(Ink.line), width: 0.4)
            }
        }
        // The sash, knotted at the hip, its ends hanging.
        d.band([P(-13.6, -31.4), P(12, -31.6), P(11.6, -27.4), P(-13.8, -27)])
        let knot = d.up(P(-11.4, -29.2))
        let flap = pose == .walking ? 1.4 * sway : 0.4 * BronzePeopleKit.wave(frame)
        AlchemyWarriorsKit.shape(&d.svg, [knot + P(-0.6, -1), knot + P(-4.6 - flap, 9.4), knot + P(-2.6 - flap, 10.6), knot + P(1.2, 0.8)], fill: .team, width: 0.9)
        AlchemyWarriorsKit.shape(&d.svg, [knot + P(-1, 0), knot + P(-1.6 - flap * 0.6, 12.4), knot + P(0.8 - flap * 0.6, 12), knot + P(1.4, 0.4)],
                                 fill: .team, width: 0.9)
        d.svg.polygon([P(-13.6, -31.4), P(12, -31.6), P(11.6, -27.4), P(-13.8, -27)].map(d.up), fill: .none, stroke: .colour(Ink.line), width: 1.1)
        d.svg.circle(knot, 1.7, fill: .team, stroke: .colour(Ink.line), width: 0.9)
        // The bandolier, from the near shoulder across to the far hip, and what hangs from it.
        let from = d.up(P(8.6, -47)), to = d.up(P(-12.2, -24.4))
        let a = P.direction(BronzePeopleKit.degrees(from: from, to: to) + 90) * 1.4
        AlchemyWarriorsKit.shape(&d.svg, [from + a, to + a, to - a, from - a], fill: .colour(AlchemyWarriorsInk.darkLeather), width: 0.9)
        let hang = pose == .walking ? -2 * sway : 0
        for i in 0..<5 {
            let t = 0.18 + Double(i) * 0.15
            let at = from + (to - from) * t
            let bottom = at + P(hang * 0.3, 5.4)
            d.svg.line([at, at + P(hang * 0.1, 1.4)], stroke: .colour(Ink.line), width: 0.6)
            let charger = [at + P(-1.2, 1.4), at + P(1.2, 1.4), bottom + P(1.1, 0), bottom + P(-1.1, 0)]
            AlchemyWarriorsKit.shape(&d.svg, charger, fill: .colour(AlchemyWarriorsInk.darkWood), width: 0.7)
            d.svg.polygon([at + P(-1.3, 1.2), at + P(1.3, 1.2), at + P(1.3, 2.6), at + P(-1.3, 2.6)], fill: .colour(AlchemyWarriorsInk.gilt),
                          stroke: .colour(Ink.line), width: 0.5)
        }
        // The priming flask at the bandolier's end, and the bullet bag.
        let flask = to + P(1.4 + hang * 0.3, 4.4)
        d.svg.ellipse(flask + P(-0.4, 0.4), 2, 2.6, fill: .colour(AlchemyWarriorsInk.gilt))
        d.svg.ellipse(flask, 2, 2.6, fill: .none, stroke: .colour(Ink.line), width: 0.8)
        d.svg.line([flask + P(0, -2.6), flask + P(0.3, -4)], stroke: .colour(Ink.line), width: 1)
        d.svg.path("M\(num(to.x - 3.6)),\(num(to.y + 1)) q-1.6,4 1.2,5.4 q2.4,-0.4 1.8,-4.6 Z", fill: .colour(AlchemyWarriorsInk.leather),
                   stroke: .colour(Ink.line), width: 0.8)
        // The falling collar of linen.
        AlchemyWarriorsKit.shape(&d.svg, [d.up(P(-6.8, -49.2)), d.up(P(8.4, -49.4)), d.up(P(11.2, -45)), d.up(P(4.2, -43.4)), d.up(P(1, -45.6)),
                                          d.up(P(-7.4, -45.4))], fill: .colour(AlchemyWarriorsInk.linen), width: 1)
        d.svg.line([d.up(P(4.4, -46.2)), d.up(P(4.4, -42.8))], stroke: .colour(Ink.line), width: 0.6)
    }

    /// The head: long hair, an upturned moustache and a pointed beard, nose C,
    /// and the broad hat with its band of the team's colour and its feather.
    static func head(_ d: inout Drawing, pose: SpritePose, frame: Int) {
        let flutter = pose == .walking ? 0.8 * BronzePeopleKit.wave(frame, 0.2) : 0.25 * BronzePeopleKit.wave(frame)
        d.head(nose: .hook, behind: { d in
            BronzePeopleProps.shape(&d.svg, fill: .colour(AlchemyWarriorsInk.hair), width: 1.1) { o in
                var p = PathData()
                p.move(P(-6, -66) + o)
                p.cubic(P(-13.6, -64) + o, P(-14.2, -54) + o, P(-12.6, -46.6) + o)
                p.quad(P(-10.4, -44.2) + o, P(-8.2, -46) + o)
                p.quad(P(-6, -44.6) + o, P(-4.4, -47) + o)
                p.cubic(P(-4.6, -54) + o, P(-3, -60) + o, P(-6, -66) + o)
                p.close()
                return p
            }
            d.svg.path("M-11.4,-56 q-1,4 -0.2,7.4 M-8.4,-55 q-0.8,4 0,7", stroke: .colour(Ink.line), width: 0.6, opacity: 0.6)
        }, hair: { d in
            d.svg.path("M-10.8,-62 C-9.6,-56 -9.8,-53 -10.6,-51 L-7.6,-52.2 C-6.6,-56 -6.8,-60 -7.8,-63.4 Z", fill: .colour(AlchemyWarriorsInk.hair))
        }, features: { d in
            // An upturned moustache and a pointed beard.
            d.svg.path("M5.4,-52.8 q3,-1.8 6,-0.6 q1.6,-0.4 2.4,-2.4 q0.4,2.6 -2,3.8 q-3.6,0.8 -6.4,-0.8 Z", fill: .colour(AlchemyWarriorsInk.hair),
                       stroke: .colour(Ink.line), width: 0.5)
            d.svg.path("M6.6,-49.4 q2.4,0.4 4,-0.6 q-0.2,3 -2.2,5 q-0.6,-2.4 -1.8,-4.4 Z", fill: .colour(AlchemyWarriorsInk.hair),
                       stroke: .colour(Ink.line), width: 0.5)
        }, brow: { d in
            d.svg.path("M1.8,-63.2 q3.4,-1.4 6.8,0", stroke: .colour(Ink.line), width: 1.5)
        }, over: { d in
            hat(&d.svg, flutter: flutter)
        })
    }

    /// The broad hat: the brim seen nearly edge on and turned up behind, the
    /// crown, the team's band, and a feather in the light swept back over the brim.
    static func hat(_ svg: inout SVG, flutter f: Double) {
        BronzePeopleProps.shape(&svg, fill: .colour(AlchemyWarriorsInk.teal), width: 1.3) { o in
            var p = PathData()
            p.move(P(-18.6, -72) + o)
            p.cubic(P(-14.6, -68.4) + o, P(-6, -67.2) + o, P(2, -67.6) + o)
            p.cubic(P(10, -67.8) + o, P(16.4, -68.4) + o, P(20.2, -66.4) + o)
            p.cubic(P(21, -64.6) + o, P(18, -63.6) + o, P(14.6, -63.8) + o)
            p.cubic(P(6, -64.2) + o, P(-4, -63.8) + o, P(-10.6, -65) + o)
            p.cubic(P(-15.6, -66) + o, P(-19.6, -68.6) + o, P(-18.6, -72) + o)
            p.close()
            return p
        }
        svg.path("M-9.8,-65.8 C-3,-64.8 7,-65 15.6,-64.8", stroke: .colour(AlchemyWarriorsInk.paleTeal), width: 0.8)
        BronzePeopleProps.shape(&svg, fill: .colour(AlchemyWarriorsInk.teal), width: 1.4) { o in
            var p = PathData()
            p.move(P(-8.4, -67.8) + o)
            p.cubic(P(-9.4, -75) + o, P(-7, -81.4) + o, P(0.6, -82) + o)
            p.cubic(P(7.6, -82.2) + o, P(9.6, -75.6) + o, P(8.8, -67.8) + o)
            p.cubic(P(3, -66.8) + o, P(-3, -66.8) + o, P(-8.4, -67.8) + o)
            p.close()
            return p
        }
        svg.path("M-5.6,-75.6 C-4.8,-79 -2.4,-80.4 0.4,-80.6", stroke: .colour(AlchemyWarriorsInk.paleTeal), width: 0.9)
        // The band.
        BronzePeopleProps.shape(&svg, fill: .team, width: 1, shift: P(-0.5, 0.4)) { o in
            var p = PathData()
            p.move(P(-8.6, -68.2) + o)
            p.cubic(P(-3, -67.2) + o, P(3, -67.2) + o, P(8.9, -68.2) + o)
            p.line(P(8.9, -71.4) + o)
            p.cubic(P(3, -70.4) + o, P(-3, -70.4) + o, P(-8.9, -71.4) + o)
            p.close()
            return p
        }
        // The feather.
        BronzePeopleProps.shape(&svg, fill: .colour(AlchemyWarriorsInk.light), width: 1) { o in
            var p = PathData()
            p.move(P(-7.6, -71.6) + o)
            p.cubic(P(-12, -79 - f) + o, P(-20, -79 - f) + o, P(-25.6 - f, -71.4 - f * 0.6) + o)
            p.cubic(P(-21.6, -73.4 - f * 0.6) + o, P(-14.6, -73.4) + o, P(-8.4, -68.6) + o)
            p.close()
            return p
        }
        var barbs = PathData()
        for i in 1...4 {
            let x = -9.6 - Double(i) * 3.2
            let y = -75.6 - f * Double(i) / 4 + Double(i) * 0.3
            barbs.move(P(x, y)); barbs.line(P(x - 1.4, y + 1.8))
        }
        svg.path(barbs, stroke: .colour(Ink.line), width: 0.6, opacity: 0.7)
    }

    // MARK: The musket and the rest

    /// The matchlock: a wooden stock with a brass butt plate, the barrel along
    /// its top with the ramrod in pipes beneath, the lock with its pan and the
    /// serpentine holding the slow match, and the trigger lever under the wrist.
    static func musket(_ svg: inout SVG, butt: P, degrees: Double, cock: Double, match: Bool, ramrod: Bool, frame: Int) {
        let (u, a) = axes(degrees)
        func at(_ t: Double, _ s: Double) -> P { butt + u * t + a * s }
        // The trigger lever, under the wrist.
        svg.line([at(12.6, 1.2), at(9.2, 4.6)], stroke: .colour(Ink.line), width: 1)
        // The barrel along the top.
        svg.line([at(10, -1.4), at(musket, -1.4)], stroke: .colour(Ink.line), width: 2.4)
        svg.line([at(10.4, -1.4), at(musket - 0.3, -1.4)], stroke: .colour(AlchemyWarriorsInk.barrel), width: 1.3)
        svg.line([at(14, -1.8), at(musket - 1, -1.8)], stroke: .colour(AlchemyWarriorsInk.barrelLight), width: 0.4)
        // The stock.
        let stock = [at(0, -1.7), at(12, -1), at(40, -0.8), at(40.8, 0.1), at(40, 1), at(15, 1.3), at(12.4, 1.5), at(9, 1.7), at(4, 2.7), at(0.4, 3.2)]
        AlchemyWarriorsKit.shape(&svg, stock, fill: .colour(AlchemyWarriorsInk.wood), width: 0.9)
        svg.line([at(1.4, 1.8), at(8, 0.6)], stroke: .colour(AlchemyWarriorsInk.darkWood), width: 0.6)
        if ramrod {
            svg.line([at(18, 1.9), at(46, 1.9)], stroke: .colour(Ink.line), width: 1.3)
            svg.line([at(18.4, 1.9), at(45.6, 1.9)], stroke: .colour(AlchemyWarriorsInk.paleWood), width: 0.6)
        }
        // The butt plate and the barrel's bands, in brass.
        svg.line([at(0, -1.7), at(0.4, 3.2)], stroke: .colour(AlchemyWarriorsInk.gilt), width: 1.2)
        for t in [24.0, 34.0] {
            svg.line([at(t, -2.6), at(t, 1.2)], stroke: .colour(AlchemyWarriorsInk.darkGilt), width: 0.8)
        }
        svg.line([at(musket - 0.8, -2.6), at(musket - 0.8, -0.2)], stroke: .colour(Ink.line), width: 1)
        // The lock plate and the pan.
        svg.polygon([at(9.6, -0.4), at(15.4, -0.4), at(15.4, 0.9), at(9.6, 0.9)], fill: .colour(AlchemyWarriorsInk.barrelLight),
                    stroke: .colour(Ink.line), width: 0.6)
        svg.polygon([at(10.4, -2.4), at(12.4, -2.4), at(12.4, -1.6), at(10.4, -1.6)], fill: .colour(AlchemyWarriorsInk.gilt),
                    stroke: .colour(Ink.line), width: 0.5)
        // The serpentine, from its pivot on the lock to its jaws.
        let jaws = at(mix(9.4, 11.2, cock), mix(-4.8, -2.8, cock))
        let pivot = at(14, 0.2)
        var serpentine = PathData()
        serpentine.move(pivot)
        serpentine.quad(at(14, -2.6) + (jaws - at(11, -3)) * 0.5, jaws)
        svg.path(serpentine, stroke: .colour(Ink.line), width: 1.3)
        if match {
            // The slow match in the jaws, smouldering, its cord trailing back.
            let end = jaws + u * 1.2 - a * 0.4
            var cord = PathData()
            cord.move(end); cord.quad(jaws - u * 3 - a * 1.6, jaws - u * 4.6 + a * 1.2)
            svg.path(cord, stroke: .colour(Ink.line), width: 1.1)
            svg.path(cord, stroke: .colour(AlchemyWarriorsInk.paleBuff), width: 0.5)
            ember(&svg, at: end, frame: frame)
        }
    }

    /// The glowing end of the match, and a thread of smoke curling up from it.
    static func ember(_ svg: inout SVG, at p: P, frame: Int) {
        svg.circle(p, 1, fill: .colour(AlchemyWarriorsInk.ember), stroke: .colour(Ink.line), width: 0.4)
        let sway = 1.2 * BronzePeopleKit.wave(frame)
        var wisp = PathData()
        wisp.move(p + P(0, -1.2))
        wisp.cubic(p + P(1.6 + sway, -3.4), p + P(-1.6 + sway, -5), p + P(0.4 + sway * 1.4, -7.6))
        svg.path(wisp, stroke: .colour(AlchemyWarriorsInk.smokeShade), width: 0.7, opacity: 0.8)
    }

    /// A coil of slow match held in the hand whilst he loads, burning at both ends.
    static func match(_ svg: inout SVG, inHand hand: P, frame: Int) {
        var cord = PathData()
        cord.move(hand + P(1.4, -2.6))
        cord.quad(hand + P(-0.6, 0.6), hand + P(-1.6, 4.6))
        cord.quad(hand + P(-3, 7.6), hand + P(-0.4, 8.6))
        svg.path(cord, stroke: .colour(Ink.line), width: 1.2)
        svg.path(cord, stroke: .colour(AlchemyWarriorsInk.paleBuff), width: 0.5)
        ember(&svg, at: hand + P(1.6, -2.8), frame: frame)
    }

    /// The forked rest: an ash staff with an iron spike at its foot and an
    /// iron fork at its head, `rest` long from `foot` along `degrees`.
    static func rest(_ svg: inout SVG, foot: P, degrees: Double) {
        let u = P.direction(degrees), a = P(-u.y, u.x)
        let top = foot + u * rest
        svg.line([foot + u * 2, top], stroke: .colour(Ink.line), width: 2.4)
        svg.line([foot + u * 2.3, top - u * 0.3], stroke: .colour(AlchemyWarriorsInk.paleWood), width: 1.1)
        svg.line([foot, foot + u * 2.6], stroke: .colour(AlchemyWarriorsInk.barrel), width: 1.4)
        var fork = PathData()
        fork.move(top + a * 2.4 + u * 3)
        fork.line(top + a * 2.1)
        fork.quad(top - u * 1.2, top - a * 2.1)
        fork.line(top - a * 2.4 + u * 3)
        svg.path(fork, stroke: .colour(Ink.line), width: 1.7)
        svg.path(fork, stroke: .colour(AlchemyWarriorsInk.barrelLight), width: 0.6)
    }

    /// The ramrod in his hand: drawn out beside the barrel, or in the muzzle.
    static func ramrod(_ svg: inout SVG, _ s: Drill) {
        guard let grip = ramGrip(s) else { return }
        let (u, a) = axes(s.degrees)
        let m = muzzle(butt: s.butt, degrees: s.degrees)
        let bottom: P, top: P
        if s.drawing {
            top = grip + u * 3
            bottom = grip - u * 30
        } else {
            bottom = m
            top = grip + u * 9
        }
        svg.line([bottom, top], stroke: .colour(Ink.line), width: 1.5)
        svg.line([bottom + u * 0.3, top - u * 0.3], stroke: .colour(AlchemyWarriorsInk.paleWood), width: 0.7)
        svg.circle(top, 0.8, fill: .colour(AlchemyWarriorsInk.barrelLight), stroke: .colour(Ink.line), width: 0.4)
        if s.ram != nil && s.mouth == .murmur && s.ram! < 2 {
            // The charge rammed home.
            var tap = PathData()
            for side in [-1.0, 1.0] {
                tap.move(m + a * (side * 2.2) - u * 0.4); tap.line(m + a * (side * 4.4) + u * 0.6)
            }
            svg.path(tap, stroke: .colour(Ink.line), width: 0.9)
        }
    }

    // MARK: The shot

    /// The flash at the muzzle and the pan, and the cloud of smoke that rolls
    /// forward and thins whilst he reloads.
    static func shot(_ svg: inout SVG, frame: Int, drill s: Drill) {
        let fired = drill[2]
        let origin = muzzle(butt: fired.butt, degrees: fired.degrees)
        let pan = fired.butt + axes(fired.degrees).u * 11.4 + axes(fired.degrees).a * -2.6
        if frame == 2 {
            // The flash: a star stretched along the barrel.
            var star: [P] = [], core: [P] = []
            for i in 0..<12 {
                let angle = fired.degrees + Double(i) * 30
                let forward = max(0, cos(Double(i) * 30 * .pi / 180))
                let r = i % 2 == 0 ? 5 + 10 * forward : 2.6
                star.append(origin + P.direction(angle) * r + P.direction(fired.degrees) * 2)
                core.append(origin + P.direction(angle) * (i % 2 == 0 ? r * 0.5 : 1.2) + P.direction(fired.degrees) * 2)
            }
            svg.polygon(star.map { $0 + P(-0.5, 0.5) }, fill: .colour(AlchemyWarriorsInk.flash))
            svg.polygon(star, fill: .none, stroke: .colour(Ink.line), width: 1)
            svg.polygon(core, fill: .colour(AlchemyWarriorsInk.flashCore))
            // The pan's flash.
            AlchemyWarriorsKit.smoke(&svg, at: pan, puffs: [(P(0, -2), 1.8), (P(-1.6, -4.4), 1.4)], opacity: 0.9)
            svg.path("M\(num(pan.x - 2)),\(num(pan.y - 1)) l-2,-2 M\(num(pan.x)),\(num(pan.y - 2)) l0,-3 M\(num(pan.x + 2)),\(num(pan.y - 1)) l2,-2",
                     stroke: .colour(AlchemyWarriorsInk.darkGilt), width: 0.9)
        }
        // The cloud: puffs that grow, rise and drift forward frame by frame.
        let ages: [Int: (spread: Double, rise: Double, size: Double, opacity: Double)] = [
            2: (0.35, 0, 0.55, 0.95), 3: (0.75, 1, 0.9, 0.95), 4: (1, 3, 1.05, 0.9), 5: (1.15, 5.5, 1.15, 0.75),
            6: (1.27, 8, 1.2, 0.55), 7: (1.36, 10.5, 1.2, 0.36), 8: (1.4, 13, 1.15, 0.2),
        ]
        guard let age = ages[frame] else { return }
        let base: [(P, Double)] = [(P(5, 0), 3.4), (P(10.5, -2), 4.4), (P(17, 0.4), 5), (P(23, -3.4), 4.6), (P(28, 0.6), 4),
                                   (P(14, -6), 3.6), (P(21.6, 3.4), 3.2), (P(32, -2.6), 3)]
        let puffs = base.map { (p, r) in (P(p.x * age.spread, p.y * (0.8 + age.spread * 0.3) - age.rise * (0.6 + p.x / 40)), r * age.size) }
        AlchemyWarriorsKit.smoke(&svg, at: origin + P(1, 0), puffs: puffs, opacity: age.opacity)
    }
}
