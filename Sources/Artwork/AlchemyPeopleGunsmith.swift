// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The gunsmith (engineer)

/// A broad gunsmith in a jerkin of brown leather laced up the front and cut
/// into tabs at the hip, over a linen shirt with full sleeves, puffed wine
/// breeches, a belt with a powder horn and his hammer at it, a knitted cap of
/// the team's colour with a rolled band; a bushy black beard, a smudge of soot
/// on his cheek, and a heavy brow; nose E. He carries a musket barrel in his
/// hand, muzzle up; at work he holds it with tongs on the anvil, hot from the forge,
/// and hammers it, sparks flying at each blow; fighting, he swings the hammer.
struct AlchemyPeopleGunsmith: PersonLook {
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(13.4, -31.4 - r.lift * 0.6))
            r.mouth = .hidden
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 22, kneeLift: 42, armSwing: 24)
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(13.6, -31.6 + 0.8 * BronzePeopleKit.wave(frame, times: 2)))
            r.mouth = .hidden
            return r
        case .working:
            var r = Self.hammering(frame)
            r.backArm = AlchemyPeopleKit.reach(front: false, r, to: Self.tongsGrip)
            return r
        case .fighting:
            let (angle, landing) = Moves.blow(frame, ready: 78, raised: 186, struck: 66)
            var r = Rig()
            r.frontArm = Limb(angle, -6)
            r.backArm = Limb(-28 + (angle - 78) * 0.25, -12)
            r.backLeg = Limb(-18, 6)
            r.frontLeg = frame >= 6 && frame <= 9 ? Limb(22, 12) : Limb(12, 8)
            r.lean = frame < 6 ? -4 : (frame <= 9 ? 10 : 2)
            r.mouth = .hidden
            r.eyes = landing ? .wide : .open
            return r
        default:
            return nil
        }
    }

    /// The barrel in his hand, muzzle up and leaning forward a little.
    static let carried = 164.0

    // MARK: Hammering

    /// The frame on which the hammer meets the barrel.
    static let strike = 9

    /// The skeleton at the anvil, before the far arm is sent to the tongs.
    static func hammering(_ frame: Int) -> Rig {
        let (angle, landing) = Moves.blow(frame, ready: 66, raised: 170, struck: 40, raiseFrames: 7)
        var r = Rig()
        r.backLeg = Limb(-14, 6); r.frontLeg = Limb(22, 24)
        r.lean = 13
        r.frontArm = Limb(angle, -4)
        r.mouth = .hidden
        r.eyes = landing ? .closed : .down
        return r
    }

    /// The hammer's direction from the hand, in the body.
    static func hammerDegrees(_ pose: SpritePose, _ rig: Rig) -> Double {
        switch pose {
        case .working, .fighting: rig.frontArm.upper + 8
        default: rig.frontArm.upper + rig.frontArm.bend + 14
        }
    }

    /// Where the hammer's face meets the barrel, in the picture.
    static let struck: P = {
        let rig = hammering(strike)
        let d = Drawing(layer: .base, rig: rig, phase: 0)
        return d.world(AlchemyPeopleProps.hammerFace(at: d.joints.frontHand, degrees: hammerDegrees(.working, rig)))
    }()

    /// The barrel on the anvil: its breech toward him, held in the tongs, its muzzle away.
    static var breech: P { P(struck.x - 9, struck.y + 1.6) }
    static var muzzle: P { P(struck.x + 17, struck.y + 1.6) }
    /// The anvil's face, just under the barrel.
    static var anvilTop: Double { -(struck.y + 3.4) }
    /// Where the far hand holds the tongs, and where their jaws close on the breech.
    static var tongsGrip: P { breech + P(-9, -5.4) }

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        if pose == .working {
            AlchemyPeopleProps.anvil(&d.svg, left: Self.struck.x - 7, right: Self.struck.x + 6, top: Self.anvilTop)
            // The barrel cools a little between blows and glows again from the forge's heat in it.
            AlchemyPeopleProps.barrel(&d.svg, breech: Self.breech, muzzle: Self.muzzle, heat: 0.75 + 0.25 * BronzePeopleKit.wave(frame, 0.5))
        }
        d.figure { d in
            if pose != .working { d.arm(front: false, width: 2.1) }
            d.legs()
            if pose == .standing || pose == .walking {
                // The hammer hanging at his belt behind.
                AlchemyPeopleProps.hammer(&d.svg, at: d.up(P(-11.6, -29)), degrees: 6 - sway * 6, haft: 10)
            }
            Self.body(&d, sway: sway)
            if pose == .working {
                // The far arm across him to the tongs, and the tongs to the breech.
                d.arm(front: false, width: 2.1)
                let hand = d.joints.backHand
                let jaws = AlchemyPeopleKit.body(Self.breech + P(0.6, 0), d.rig)
                AlchemyPeopleProps.tongs(&d.svg, at: hand, degrees: BronzePeopleKit.degrees(from: hand, to: jaws),
                                         length: BronzePeopleKit.length(jaws - hand))
                d.hand(hand)
            }
            let hand = d.joints.frontHand
            switch pose {
            case .working, .fighting:
                let degrees = Self.hammerDegrees(pose, d.rig)
                AlchemyPeopleProps.hammer(&d.svg, at: hand, degrees: degrees)
                if pose == .working, frame == Self.strike || frame == Self.strike + 1 {
                    AlchemyPeopleProps.sparks(&d.svg, at: AlchemyPeopleKit.body(Self.struck, d.rig), spread: frame == Self.strike ? 0 : 1)
                }
                if pose == .fighting {
                    if frame == 7 { d.swish(around: d.joints.frontShoulder, radius: 26, from: 168, to: 88) }
                    if frame == 8 { d.impact(at: AlchemyPeopleProps.hammerFace(at: hand, degrees: degrees), size: 0.9) }
                }
            default:
                // The barrel in his hand, muzzle up, swaying a little with his stride.
                let u = P.direction(Self.carried + (pose == .walking ? 3 * BronzePeopleKit.wave(frame, 0.3) : 0))
                AlchemyPeopleProps.barrel(&d.svg, breech: hand - u * 9, muzzle: hand + u * 20)
            }
            d.arm(front: true, width: 2.2)
            // The full sleeve of the shirt on the upper arm.
            Self.sleeve(&d, from: d.joints.frontShoulder, to: d.joints.frontElbow)
            d.hand(hand)
            d.head(nose: .line, hair: { d in
                d.svg.path("M-11.4,-61 C-12.8,-56.4 -11.6,-52 -7.6,-50.4 C-8.4,-52.2 -8,-54 -7,-55.4 C-8.6,-56.2 -8.8,-58.6 -7.4,-60.4 Z",
                           fill: .colour(AlchemyPeopleInk.blackHair))
            }, features: { d in
                // A bushy black beard round the jaw, its curls picked out, and a moustache over it.
                d.svg.path("M-6.4,-56.6 C-7,-50 -3.4,-44.6 2.4,-43 C6,-42 9.6,-43 11.6,-45.4 C12.6,-47 12.4,-49.4 11.2,-50.6 "
                           + "C9,-49.4 6,-49.6 4,-50.6 C1,-52 -2.4,-54.4 -6.4,-56.6 Z",
                           fill: .colour(AlchemyPeopleInk.blackHair), stroke: .colour(Ink.line), width: 1)
                d.svg.path("M-2.6,-49.6 q1,1.2 2.2,0.6 M1.6,-46.6 q1,1.2 2.2,0.6 M6.2,-45.6 q1,1.2 2.2,0.4", stroke: .colour("#5a4a40"), width: 0.7)
                d.svg.path("M3.6,-52.6 q4,-2.6 8.4,-0.6 q0.2,1.6 -1.2,2.4 q-1.6,-1 -3.6,-0.4 q-2.4,0.6 -3.6,-1.4 Z",
                           fill: .colour(AlchemyPeopleInk.blackHair))
                // Soot on his cheek.
                d.svg.ellipse(P(-0.6, -57.4), 2.4, 1.4, fill: .colour(Ink.line), opacity: 0.32)
                d.svg.ellipse(P(0.6, -55.8), 1.2, 0.7, fill: .colour(Ink.line), opacity: 0.25)
            }, brow: { d in
                d.svg.path("M0.8,-63.6 q4,-2.6 8,-0.2", stroke: .colour(Ink.line), width: 2.6)
            }, over: { d in
                Self.cap(&d)
            })
        }
    }

    /// The breeches, the shirt and the laced jerkin over it, the belt, and the powder horn.
    static func body(_ d: inout Drawing, sway: Double) {
        // The puffed breeches of wine, gathered above the knee.
        BronzePeopleProps.shape(&d.svg, fill: .colour(AlchemyPeopleInk.wine), width: 1.4) { o in
            var p = PathData()
            p.move(P(-12.4, -19) + o)
            p.line(P(11.6, -19) + o)
            p.cubic(P(14.6, -15) + o, P(13.6, -10.6) + o, P(9.6 - sway, -8.2) + o)
            p.line(P(-9.6 - sway, -8.2) + o)
            p.cubic(P(-14.4, -10.6) + o, P(-15.4, -15) + o, P(-12.4, -19) + o)
            p.close()
            return p
        }
        // Their slashes, showing the light lining.
        for x in [-6.0, 0.0, 6.0] {
            d.svg.path("M\(num(x - 0.6)),-16.6 q0.8,3 0,6", stroke: .colour(AlchemyPeopleInk.paleWine), width: 1.1)
        }
        // The jerkin: brown leather from the shoulders to the hip, open at the throat on the shirt.
        let jerkin = [P(-9.4, -47.2), P(9.4, -47.2), P(13.6, -19.6), P(-14.2, -19.6)]
        d.svg.polygon(jerkin.map { d.up($0) + P(-0.7, 0.6) }, fill: .colour(AlchemyPeopleInk.leather))
        // The shirt at the throat.
        d.svg.polygon([P(2, -47.4), P(9, -47.4), P(6.4, -40.4)].map(d.up), fill: .colour(AlchemyPeopleInk.light), stroke: .colour(Ink.line), width: 0.9)
        // The lacing up the front, and the seams.
        var lacing = PathData()
        for i in 0..<5 {
            let y = -39.6 + Double(i) * 3.6
            lacing.move(d.up(P(4.6, y))); lacing.line(d.up(P(8.4, y + 1.8)))
            lacing.move(d.up(P(8.4, y))); lacing.line(d.up(P(4.6, y + 1.8)))
        }
        d.svg.path(lacing, stroke: .colour(AlchemyPeopleInk.paleLeather), width: 0.8)
        d.svg.path("M6.5,\(num(-40.8 - d.rig.lift)) L6.6,-21.6", stroke: .colour(Ink.line), width: 0.9)
        var seams = PathData()
        seams.move(d.up(P(-4.6, -46.4))); seams.line(P(-7, -21))
        d.svg.path(seams, stroke: .colour(AlchemyPeopleInk.darkLeather), width: 0.9)
        d.svg.polygon(jerkin.map(d.up), fill: .none, stroke: .colour(Ink.line), width: 1.6)
        // The tabs at the hip, swinging a little.
        for i in 0..<5 {
            let x0 = -14.2 + Double(i) * 5.56
            let tab = [P(x0 + 0.2, -19.8), P(x0 + 5.4, -19.8), P(x0 + 5.2 - sway * 0.6, -15), P(x0 + 0.6 - sway * 0.6, -15)]
            BronzePeopleProps.shape(&d.svg, tab, fill: .colour(AlchemyPeopleInk.leather), width: 1.1)
        }
        // The belt and its buckle.
        d.svg.polygon([P(-14, -23.6), P(13.4, -23.6), P(13.6, -20.2), P(-14.2, -20.2)], fill: .colour(AlchemyPeopleInk.darkLeather),
                      stroke: .colour(Ink.line), width: 0.9)
        d.svg.path(BronzePeopleProps.rounded(P(9, -21.9), width: 3.4, height: 3.6, radius: 0.6, degrees: 0, shift: P(0, 0)),
                   stroke: .colour(AlchemyPeopleInk.ironLight), width: 0.9)
        // The powder horn hanging from its cord at the back hip.
        d.svg.line([d.up(P(-8, -46)), P(-10.6, -24)], stroke: .colour(Ink.line), width: 0.8)
        AlchemyPeopleProps.powderHorn(&d.svg, at: P(-10, -18.4))
    }

    /// A full sleeve of linen on the upper arm, from `shoulder` to `elbow`.
    static func sleeve(_ d: inout Drawing, from shoulder: P, to elbow: P) {
        let along = elbow - shoulder
        let length = max(BronzePeopleKit.length(along), 0.01)
        let u = along * (1 / length), a = P(-u.y, u.x)
        let middle = shoulder + u * (length * 0.5)
        var p = PathData()
        p.move(shoulder + a * 2.4)
        p.quad(middle + a * 4.4, elbow + a * 1.6)
        p.line(elbow - a * 1.6)
        p.quad(middle - a * 4.4, shoulder - a * 2.4)
        p.close()
        d.svg.path(p, fill: .colour(AlchemyPeopleInk.light), stroke: .colour(Ink.line), width: 1.1)
        d.svg.line([middle - u * 1.6, middle + u * 2.4], stroke: .colour(AlchemyPeopleInk.shadeLight), width: 0.9)
        d.svg.line([elbow + a * 1.8 - u * 0.4, elbow - a * 1.8 - u * 0.4], stroke: .colour(Ink.line), width: 1.4)
    }

    /// A knitted cap of the team's colour, round on the crown, its band rolled up in ribs.
    static func cap(_ d: inout Drawing) {
        BronzePeopleProps.shape(&d.svg, fill: .team, width: 1.5) { o in
            var p = PathData()
            p.move(P(-11.4, -62) + o)
            p.cubic(P(-13, -71) + o, P(-6, -77) + o, P(0, -76.4) + o)
            p.cubic(P(6.4, -76) + o, P(10.8, -71) + o, P(10.8, -65.2) + o)
            p.cubic(P(3, -67.6) + o, P(-5, -66.4) + o, P(-11.4, -62) + o)
            p.close()
            return p
        }
        // The knit's rows on the crown.
        d.svg.path("M-7,-72.4 q2.4,2.6 2.6,6.4 M-1.2,-75.2 q1.4,3.6 1.2,8.4 M5,-74 q0.4,3.4 -0.4,7.2", stroke: .colour(Ink.line), width: 0.6,
                   opacity: 0.45)
        // The rolled band, ribbed.
        BronzePeopleProps.shape(&d.svg, fill: .team, width: 1.3) { o in
            var p = PathData()
            p.move(P(-12, -61.6) + o)
            p.cubic(P(-5, -66.4) + o, P(3.4, -67.8) + o, P(11.2, -65.6) + o)
            p.line(P(11, -62.2) + o)
            p.cubic(P(3.4, -64.2) + o, P(-5, -63) + o, P(-11, -58.6) + o)
            p.close()
            return p
        }
        d.svg.path("M-8,-62.2 l0.4,2.6 M-4,-64.2 l0.3,2.6 M0,-65.4 l0.2,2.6 M4,-65.8 l0.1,2.6 M8,-65.6 l0,2.6", stroke: .colour(Ink.line),
                   width: 0.6, opacity: 0.6)
    }
}
