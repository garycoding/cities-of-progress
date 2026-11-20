// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The mechanic (engineer)

/// A young mechanic in navy bib overalls with brass buckles, a grey rag
/// hanging from the pocket, over a striped shirt buttoned at the wrist;
/// an engine driver's cap of the team's colour with a black peak; black hair
/// curling at the neck, clean-shaven, a smear of oil on his cheek; nose A. He
/// carries a large spanner in his near hand and an oil can in his far one; at
/// work he tightens the great nut on an engine's cylinder, heaving the spanner
/// round twice, the nut turning a sixth of a turn, and the gauge's needle
/// trembling; fighting, he swings the spanner.
struct IndustrialPeopleMechanic: PersonLook {
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.frontArm = Limb(10 + r.lift, -6)
            r.backArm = Limb(-20, -4)
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 22, kneeLift: 42, armSwing: 22)
            r.backArm = Limb(-18 - 7 * IndustrialPeopleKit.wave(frame), -6)
            return r
        case .working:
            return heaving(frame)
        case .fighting:
            let (angle, landing) = Moves.blow(frame, ready: 74, raised: 182, struck: 60)
            var r = Rig()
            r.frontArm = Limb(angle, -6)
            r.backArm = Limb(-26 + (angle - 74) * 0.25, -12)
            r.backLeg = Limb(-18, 6)
            r.frontLeg = frame >= 6 && frame <= 9 ? Limb(22, 12) : Limb(12, 8)
            r.lean = frame < 6 ? -4 : (frame <= 9 ? 10 : 2)
            r.mouth = frame >= 6 && frame <= 8 ? .shout : .firm
            r.eyes = landing ? .wide : .open
            return r
        default:
            return nil
        }
    }

    /// The spanner's length from the middle of its jaw to its ring, and how
    /// far along it the near hand grips it.
    static let spannerLength = 18.0, spannerSize = 1.15, grip = 15.6

    // MARK: Heaving

    /// The great nut on the cylinder's face, in the picture.
    static let nut = P(31, -24)
    /// The spanner's direction from the nut through the cycle: two heaves of
    /// a twelfth of a turn each (0 to 3 and 6 to 9), the spanner taken off and
    /// set back between them.
    static let handle: [Double] = [-128, -134, -146, -158, -150, -134, -128, -134, -146, -158, -150, -134]
    /// How far the nut has turned in a frame: a sixth of a turn in the cycle,
    /// which brings a hexagon back to where it began.
    static let turn: [Double] = [0, 6, 18, 30, 30, 30, 30, 36, 48, 60, 60, 60]
    /// The frames on which the spanner is off the nut, and how far it stands off.
    static let off: [Int: Double] = [4: 2.4, 5: 1.6, 10: 2.4, 11: 1.6]
    /// The frames on which the nut bites home.
    static let home: Set<Int> = [3, 9]

    /// The spanner's jaw in a frame.
    static func jaw(_ frame: Int) -> P {
        let u = P.direction(handle[frame])
        return nut + u * (off[frame] ?? 0)
    }

    func heaving(_ frame: Int) -> Rig {
        var r = Rig()
        let effort = Self.home.contains(frame) ? 1.0 : 0
        r.backLeg = Limb(-16, 6); r.frontLeg = Limb(20 + effort * 2, 22)
        r.lean = 13 + [0, 1, 2.4, 3.4, 2, 0.6][frame % 6]
        let u = P.direction(Self.handle[frame])
        r.frontArm = IndustrialPeopleKit.reach(front: true, r, to: Self.jaw(frame) + u * Self.grip)
        r.backArm = IndustrialPeopleKit.reach(front: false, r, to: Self.jaw(frame) + u * (Self.grip - 4.2))
        r.eyes = Self.home.contains(frame) ? .closed : .down
        r.mouth = [Mouth.firm, .firm, .shout, .shout, .open, .firm][frame % 6]
        r.headTilt = 4
        return r
    }

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        if pose == .working {
            let needle = -50 + 8 * IndustrialPeopleKit.wave(frame, 0, times: 3) + Self.turn[frame] * 0.4
            IndustrialPeopleProps.engine(&d.svg, left: Self.nut.x - 11, right: Self.nut.x + 11, nut: Self.nut, turn: Self.turn[frame], needle: needle)
            // The oil can set down beside the engine.
            IndustrialPeopleProps.oilCan(&d.svg, hand: P(Self.nut.x + 17, -12))
        }
        d.figure { d in
            let working = pose == .working
            if !working {
                IndustrialPeopleKit.arm(&d, front: false, fill: .colour(IndustrialPeopleInk.shadeLight), width: 3.8, cuff: IndustrialPeopleInk.paleSoot)
                let swing = pose == .walking ? 5 * IndustrialPeopleKit.wave(frame, 0.55) : IndustrialPeopleKit.wave(frame) * 0.8
                IndustrialPeopleProps.oilCan(&d.svg, hand: d.joints.backHand, swing: swing)
                d.hand(d.joints.backHand)
            }
            IndustrialPeopleKit.trousers(&d, colour: IndustrialPeopleInk.navy, shade: IndustrialPeopleInk.darkNavy)
            Self.overalls(&d, sway: sway)
            let hand = d.joints.frontHand
            switch pose {
            case .working:
                // The spanner on the nut, through both hands.
                let jaw = IndustrialPeopleKit.body(Self.jaw(frame), d.rig)
                let degrees = IndustrialPeopleKit.degrees(from: jaw, to: hand)
                IndustrialPeopleKit.arm(&d, front: false, fill: .colour(IndustrialPeopleInk.shadeLight), width: 3.8, cuff: IndustrialPeopleInk.paleSoot)
                IndustrialPeopleProps.spanner(&d.svg, jaw: jaw, degrees: degrees, length: Self.spannerLength, size: Self.spannerSize)
                d.hand(d.joints.backHand)
                if Self.home.contains(frame) {
                    // The strain of the last heave, beside his hands.
                    d.svg.path("M\(num(hand.x - 3)),\(num(hand.y - 5)) l-1,-2.6 M\(num(hand.x + 1)),\(num(hand.y - 6)) l0.4,-2.8",
                               stroke: .colour(Ink.line), width: 1)
                }
            case .fighting:
                let degrees = d.rig.frontArm.upper - 2
                let jaw = hand + P.direction(degrees) * (Self.spannerLength - 0.6)
                IndustrialPeopleProps.spanner(&d.svg, jaw: jaw, degrees: degrees + 180, length: Self.spannerLength, size: Self.spannerSize)
                if frame == 7 { d.swish(around: d.joints.frontShoulder, radius: 28, from: 168, to: 88) }
                if frame == 8 { d.impact(at: jaw, size: 0.9) }
            default:
                // The spanner hanging from his hand, its jaw down by his knee.
                let hang = 6 + (pose == .walking ? 4 * IndustrialPeopleKit.wave(frame, 0.6) : 0.6 * IndustrialPeopleKit.wave(frame))
                let jaw = hand + P.direction(hang) * (Self.spannerLength - 0.6)
                IndustrialPeopleProps.spanner(&d.svg, jaw: jaw, degrees: hang + 180, length: Self.spannerLength, size: Self.spannerSize)
            }
            IndustrialPeopleKit.arm(&d, front: true, fill: .colour(IndustrialPeopleInk.light), width: 4, cuff: IndustrialPeopleInk.shadeLight)
            d.head(nose: .curve, hair: { d in
                // Black hair curling at the nape, under the cap.
                d.svg.path("M-11.4,-62 C-13.4,-58 -12.4,-53.2 -8.6,-51 C-9,-53 -8.4,-54.6 -7.4,-55.6 C-9.6,-56.6 -9.4,-59 -8,-61 Z",
                           fill: .colour(IndustrialPeopleInk.blackHair))
                d.svg.path("M-12.6,-56 q-1.8,1.6 -0.6,3.6", stroke: .colour(IndustrialPeopleInk.blackHair), width: 1.2)
            }, features: { d in
                // A smear of oil on the cheek.
                d.svg.path("M-1.8,-57.6 q2.4,-0.6 4.4,0.4", stroke: .colour(Ink.line), width: 1.6, opacity: 0.35)
                d.svg.path("M-1,-55.6 q1.6,-0.4 3,0.2", stroke: .colour(Ink.line), width: 1.1, opacity: 0.28)
            }, brow: { d in
                d.svg.path("M1.4,-63.6 q3.6,-1.8 7.4,-0.8", stroke: .colour(IndustrialPeopleInk.blackHair), width: 2.2)
            }, over: { d in
                Self.cap(&d)
            })
        }
    }

    /// The shirt under the bib, the overalls with their straps, buckles and pocket, and the rag.
    static func overalls(_ d: inout Drawing, sway: Double) {
        // The shirt, showing above the bib and at the sides.
        let shirt = [P(-9.4, -47.2), P(9.2, -47.2), P(11, -30), P(-11.4, -30)]
        d.svg.polygon(shirt.map { d.up($0) + P(-0.7, 0.6) }, fill: .colour(IndustrialPeopleInk.light))
        // The shirt's stripes of soot, and the open neck.
        var stripes = PathData()
        for x in stride(from: -7.6, through: 8.4, by: 2.4) { stripes.move(d.up(P(x, -46.4))); stripes.line(d.up(P(x + 0.4, -30.6))) }
        d.svg.path(stripes, stroke: .colour(IndustrialPeopleInk.paleSoot), width: 0.6)
        d.svg.polygon(shirt.map(d.up), fill: .none, stroke: .colour(Ink.line), width: 1.6)
        d.svg.polygon([P(2.6, -47.4), P(8.6, -47.4), P(6.4, -44)].map(d.up), fill: .colour(Ink.skin), stroke: .colour(Ink.line), width: 0.8)
        // The overalls: the legs' tops and seat, and the bib up the chest.
        func overallsPath(_ o: P) -> PathData {
            var p = PathData()
            p.move(d.up(P(-8.2, -40.6)) + o)
            p.line(d.up(P(9.6, -41.4)) + o)
            p.line(P(12.2, -24) + o)
            p.cubic(P(13.6, -18) + o, P(12, -14) + o, P(10.6 - sway, -12) + o)
            p.line(P(-10.6 - sway, -12) + o)
            p.cubic(P(-12.6, -16) + o, P(-12.4, -24) + o, P(-11.4, -28) + o)
            p.close()
            return p
        }
        d.svg.path(overallsPath(P(-0.7, 0.6)), fill: .colour(IndustrialPeopleInk.navy))
        // The bib's pocket with a pencil, the side seam, and the fly's stitching.
        BronzePeopleProps.shape(&d.svg, [P(0.6, -38.6), P(7.6, -38.8), P(7.8, -33.4), P(0.8, -33.2)].map(d.up), fill: .colour(IndustrialPeopleInk.darkNavy),
                                width: 0.8)
        d.svg.line([d.up(P(2, -38.4)), d.up(P(2.6, -41.6))], stroke: .colour(Ink.line), width: 1.5)
        d.svg.line([d.up(P(2, -38.4)), d.up(P(2.6, -41.6))], stroke: .colour(IndustrialPeopleInk.paleWood), width: 0.7)
        d.svg.path("M-6,-27 q-0.6,7 0.4,14.4", stroke: .colour(IndustrialPeopleInk.darkNavy), width: 0.9)
        d.svg.path("M8.6,-26 q1.6,6 -0.4,13", stroke: .colour(IndustrialPeopleInk.paleNavy), width: 0.6, opacity: 0.7)
        // The rag hanging from the hip pocket.
        let rag = P(-9.4, -24)
        d.svg.path("M\(num(rag.x)),\(num(rag.y)) q-2.4,3 \(num(-1.6 - sway)),7 q1.2,0.6 2.4,-0.4 q0.4,1 1.8,0.6 q0.4,-4 -0.4,-7.4 Z",
                   fill: .colour(IndustrialPeopleInk.paleSoot), stroke: .colour(Ink.line), width: 0.8)
        d.svg.path(overallsPath(P(0, 0)), stroke: .colour(Ink.line), width: 1.6)
        // The straps over the shoulders and their brass buckles at the bib's corners.
        for (top, bottom) in [(P(-5.6, -47), P(-8.4, -41)), (P(4.6, -47.2), P(8.8, -41))] {
            d.svg.line([d.up(top), d.up(bottom)], stroke: .colour(Ink.line), width: 3)
            d.svg.line([d.up(top), d.up(bottom)], stroke: .colour(IndustrialPeopleInk.navy), width: 1.6)
            d.svg.path(BronzePeopleProps.rounded(d.up(bottom + P(0, -0.4)), width: 2.4, height: 2, radius: 0.4, degrees: 0, shift: P(0, 0)),
                       fill: .colour(IndustrialPeopleInk.brass), stroke: .colour(Ink.line), width: 0.6)
        }
    }

    /// An engine driver's cap of the team's colour: a soft round crown over a stiff band, and a black peak.
    static func cap(_ d: inout Drawing) {
        BronzePeopleProps.shape(&d.svg, fill: .team, width: 1.5) { o in
            var p = PathData()
            p.move(P(-11.4, -62.2) + o)
            p.cubic(P(-14.6, -68) + o, P(-10, -75.6) + o, P(-0.6, -75.2) + o)
            p.cubic(P(8, -74.8) + o, P(12.6, -70.6) + o, P(10.6, -65.6) + o)
            p.cubic(P(3, -67.6) + o, P(-5, -66.4) + o, P(-11.4, -62.2) + o)
            p.close()
            return p
        }
        // The crown's soft folds.
        d.svg.path("M-8.6,-71.6 q3.6,1.6 4.6,5 M2.6,-74.4 q1.6,3 0.8,7.4", stroke: .colour(Ink.line), width: 0.7, opacity: 0.45)
        // The stiff band, also of the team's colour, its edge stitched.
        BronzePeopleProps.shape(&d.svg, fill: .team, width: 1.2) { o in
            var p = PathData()
            p.move(P(-11.8, -61.6) + o)
            p.cubic(P(-5, -66.2) + o, P(3.4, -67.4) + o, P(10.8, -65.6) + o)
            p.line(P(10.8, -62.8) + o)
            p.cubic(P(3.4, -64.4) + o, P(-5, -63.2) + o, P(-11.2, -58.8) + o)
            p.close()
            return p
        }
        // The black peak, jutting forward, and its shine.
        BronzePeopleProps.shape(&d.svg, fill: .colour(IndustrialPeopleInk.black), width: 1.2) { o in
            var p = PathData()
            p.move(P(5.6, -63.6) + o)
            p.cubic(P(10, -64.4) + o, P(14.6, -63.4) + o, P(16.4, -61.6) + o)
            p.cubic(P(13.6, -60.6) + o, P(9, -61.4) + o, P(5.6, -62) + o)
            p.close()
            return p
        }
        d.svg.path("M8.4,-63.2 q3.6,-0.4 6.4,0.8", stroke: .colour(IndustrialPeopleInk.blackSheen), width: 0.7)
        // The cap's badge: a small brass wheel.
        d.svg.circle(P(4.6, -65.6), 1.3, fill: .colour(IndustrialPeopleInk.brass), stroke: .colour(Ink.line), width: 0.6)
        d.svg.circle(P(4.6, -65.6), 0.4, fill: .colour(IndustrialPeopleInk.darkBrass))
    }
}
