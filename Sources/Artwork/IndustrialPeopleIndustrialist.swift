// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The industrialist (merchant)

/// A portly industrialist in a frock coat of soot-grey broadcloth with a
/// black velvet collar, its skirts to the knee, a waistcoat of the team's
/// colour across his belly with a gold watch chain looped over it, a winged
/// collar and a black silk cravat with a pin, striped trousers, and a tall
/// black silk hat with a soot band; grey hair, a short grey beard round the
/// jaw and a heavy moustache; nose C. He carries a black cane with a brass
/// knob and a roll of plans under his arm; at work he plants the cane, draws
/// his hunter from his waistcoat pocket, thumbs its lid open, consults it,
/// and snaps it shut.
struct IndustrialPeopleIndustrialist: PersonLook {
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            // The near hand on the cane's knob, the plans under the far arm.
            r.frontArm = IndustrialPeopleKit.reach(front: true, r, to: Self.caneKnob)
            r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(-10.4, -30.8 - r.lift * 0.5))
            r.mouth = .hidden
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 17, kneeLift: 32, armSwing: 18)
            r.lean = -1
            r.frontArm = Limb(14 + 12 * IndustrialPeopleKit.wave(frame, 0.5), -10)
            r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(-10.4, -30.8))
            r.mouth = .hidden
            return r
        case .working:
            return consulting(frame)
        default:
            return nil
        }
    }

    /// The cane's knob under the near hand when he stands, and its tip on the ground, in the picture.
    static let caneKnob = P(14.6, -36.4)
    static let caneTip = P(19.6, 0)

    // MARK: Consulting the watch

    /// How far the watch's lid is open in each frame of the cycle.
    static let lid: [Double] = [0, 0.5, 1, 1, 1, 1, 1, 1, 1, 0.5, 0, 0]
    /// The watch in the picture: drawn up from the pocket, held before him, and lowered a little as it shuts.
    static func watchAt(_ frame: Int) -> P {
        let rise: [Double] = [0, 0.6, 1, 1, 1, 1, 1, 1, 1, 0.8, 0.5, 0.2]
        return P(18.4, -38.4 - 5.4 * rise[frame])
    }

    /// Where the far hand holds the planted cane, and where the cane's tip is.
    static let restingHand = P(-14.2, -30.6)
    static let restingTip = P(-19.6, 0)

    func consulting(_ frame: Int) -> Rig {
        var r = Moves.standing(frame)
        r.lean = -1
        r.frontArm = IndustrialPeopleKit.reach(front: true, r, to: Self.watchAt(frame) + P(-1.4, 3))
        r.backArm = IndustrialPeopleKit.reach(front: false, r, to: Self.restingHand)
        let reading = Self.lid[frame] >= 1
        r.headTilt = reading ? 12 : 6
        r.eyes = reading ? .down : (frame == 11 ? .closed : .open)
        r.mouth = .hidden
        return r
    }

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        d.figure { d in
            let working = pose == .working
            if working {
                // The cane planted behind him in the far hand.
                let hand = IndustrialPeopleKit.body(Self.restingHand, d.rig), tip = IndustrialPeopleKit.body(Self.restingTip, d.rig)
                let degrees = IndustrialPeopleKit.degrees(from: hand, to: tip)
                IndustrialPeopleProps.cane(&d.svg, top: hand - P.direction(degrees) * 3, degrees: degrees, length: BronzePeopleKit.length(tip - hand) + 3)
            }
            IndustrialPeopleKit.arm(&d, front: false, fill: .colour(IndustrialPeopleInk.darkSoot), width: 4.6, cuff: Ink.eyeWhite)
            IndustrialPeopleKit.trousers(&d, colour: IndustrialPeopleInk.paleSoot, shade: IndustrialPeopleInk.soot, stripe: IndustrialPeopleInk.darkSoot)
            Self.coat(&d, sway: sway, pose: pose)
            // The plans under his far arm, held by the hand at their near end, or pressed to his side while the hand keeps the cane.
            if working {
                IndustrialPeopleProps.plans(&d.svg, at: d.up(P(-9.4, -36.4)), degrees: 64, length: 15)
            } else {
                let hand = d.joints.backHand
                IndustrialPeopleProps.plans(&d.svg, at: hand + P(-1.8, -1.8), degrees: 64, length: 15)
                d.hand(hand)
            }
            let hand = d.joints.frontHand
            switch pose {
            case .standing:
                let knob = IndustrialPeopleKit.body(Self.caneKnob, d.rig), tip = IndustrialPeopleKit.body(Self.caneTip, d.rig)
                IndustrialPeopleProps.cane(&d.svg, top: knob + P(0, -0.6), degrees: IndustrialPeopleKit.degrees(from: knob, to: tip),
                                           length: BronzePeopleKit.length(tip - knob) + 0.4)
            case .walking:
                // The cane swung with his stride, its tip clear of the ground.
                let degrees = 18 + 14 * IndustrialPeopleKit.wave(frame, 0.5)
                IndustrialPeopleProps.cane(&d.svg, top: hand - P.direction(degrees) * 4.4, degrees: degrees, length: 30)
            case .working:
                let watch = IndustrialPeopleKit.body(Self.watchAt(frame), d.rig)
                IndustrialPeopleProps.chain(&d.svg, from: d.up(P(6.6, -31)), to: watch + P(3.8, -1), sag: 4)
                IndustrialPeopleProps.watch(&d.svg, at: watch, open: Self.lid[frame], minutes: 12 + Double(frame) * 0.6)
            default:
                break
            }
            IndustrialPeopleKit.arm(&d, front: true, fill: .colour(IndustrialPeopleInk.soot), width: 4.8, cuff: Ink.eyeWhite)
            if pose == .working {
                // His thumb on the watch's edge.
                d.svg.path("M\(num(hand.x + 0.8)),\(num(hand.y - 1)) q1.4,-1.2 1.8,-2.8", stroke: .colour(Ink.line), width: 1.1)
            }
            d.head(nose: .hook, behind: { d in
                // Grey hair at the back, below the hat.
                d.svg.path("M-11.6,-63 C-13.2,-58 -12.6,-53.2 -10.4,-50.6 L-6.6,-51.6 C-7.8,-55 -7.6,-59 -6.6,-62.6 Z",
                           fill: .colour(IndustrialPeopleInk.greyHair), stroke: .colour(Ink.line), width: 0.9)
            }, hair: { d in
                d.svg.path("M-7.2,-63 C-6.4,-59.6 -6.2,-56.4 -5.2,-53.6 C-4.2,-55.6 -4,-59 -4.4,-62.6 Z", fill: .colour(IndustrialPeopleInk.greyHair))
            }, features: { d in
                // A short grey beard round the jaw, and a heavy moustache over the mouth.
                d.svg.path("M-5.2,-55 C-5,-49.6 -1.6,-46 3.4,-45.2 C7,-44.6 10.4,-45.8 11.6,-48.4 C12,-49.6 11.6,-50.8 10.8,-51.4 "
                           + "C8.6,-50 5.6,-49.8 3.4,-50.8 C0.6,-52 -2.6,-53.4 -5.2,-55 Z",
                           fill: .colour(IndustrialPeopleInk.greyHair), stroke: .colour(Ink.line), width: 0.9)
                d.svg.path("M0,-49.6 q1,1 2.2,0.8 M4.6,-47.4 q1,1 2.2,0.6", stroke: .colour(IndustrialPeopleInk.paleSoot), width: 0.6)
                d.svg.path("M3.6,-53.6 C5.6,-55.6 9.6,-55.8 12.2,-53.6 C12.8,-52.4 12.4,-51 11.4,-50.4 C10.2,-51.6 8.4,-52 6.6,-51.6 "
                           + "C5.4,-51.2 4.4,-50.6 3.6,-50 C3,-51.2 3,-52.6 3.6,-53.6 Z",
                           fill: .colour(IndustrialPeopleInk.greyHair), stroke: .colour(Ink.line), width: 0.9)
            }, brow: { d in
                d.svg.path("M1.2,-64.2 q3.8,-2.4 7.8,-0.8", stroke: .colour(Ink.line), width: 2.6)
                d.svg.path("M1.2,-64.2 q3.8,-2.4 7.8,-0.8", stroke: .colour(IndustrialPeopleInk.greyHair), width: 1.3)
            }, over: { d in
                Self.hat(&d)
            })
        }
    }

    /// The frock coat with its velvet collar and skirts, the waistcoat over the belly, the chain, and the collar and cravat.
    static func coat(_ d: inout Drawing, sway: Double, pose: SpritePose) {
        let hemBack = P(-17 - sway * 1.4, -9), hemFront = P(9.6 - sway * 1.2, -9)
        // The coat: shoulders, a back that falls to the skirts, and the front cut away below the waist.
        func coatPath(_ o: P) -> PathData {
            var p = PathData()
            p.move(d.up(P(-9.6, -47.6)) + o)
            p.line(d.up(P(9.4, -47.6)) + o)
            p.cubic(d.up(P(13.6, -42)) + o, P(15.6, -32) + o, P(13.6, -24) + o)
            p.line(P(9, -21) + o)
            p.line(hemFront + o)
            p.line(hemBack + o)
            p.cubic(P(-15.4, -24) + o, d.up(P(-13.6, -40)) + o, d.up(P(-9.6, -47.6)) + o)
            p.close()
            return p
        }
        d.svg.path(coatPath(P(-0.8, 0.8)), fill: .colour(IndustrialPeopleInk.soot))
        // The folds of the skirts, and the seam at the waist.
        var folds = PathData()
        for (top, bottom) in [(P(-11, -22), P(-13.6, -9.6)), (P(-4, -22), P(-5, -9.6)), (P(3.6, -22), P(4.4, -9.6))] {
            folds.move(top); folds.quad((top + bottom) * 0.5 + P(-1 - sway, 0), bottom + P(-sway, 0))
        }
        d.svg.path(folds, stroke: .colour(IndustrialPeopleInk.darkSoot), width: 1.1)
        d.svg.line([P(-13.6, -23), P(9, -22.4)], stroke: .colour(IndustrialPeopleInk.darkSoot), width: 1)
        // The waistcoat over the belly, in the team's colour, its buttons and its pockets.
        func vest(_ o: P) -> [P] {
            [P(1.4, -47), P(9.6, -47), P(13.2, -38), P(13.8, -29), P(11, -22.6), P(6.4, -20.8), P(2, -22)].map { d.up($0) + o }
        }
        d.svg.polygon(vest(P(-0.6, 0.6)), fill: .team)
        var buttons = PathData()
        for i in 0..<4 {
            let y = -41.4 + Double(i) * 4.4, x = 9 + (i == 1 || i == 2 ? 1.6 : 0.6)
            buttons.move(d.up(P(x, y))); buttons.line(d.up(P(x + 0.2, y + 0.2)))
        }
        d.svg.path(buttons, stroke: .colour(Ink.line), width: 1.6)
        d.svg.line([d.up(P(6.6, -31)), d.up(P(10.6, -31.4))], stroke: .colour(Ink.line), width: 0.7)
        d.svg.polygon(vest(P(0, 0)), fill: .none, stroke: .colour(Ink.line), width: 1)
        // The coat's lapel over the waistcoat's near edge, in black velvet, and the collar.
        d.svg.polygon([P(-1, -47.8), P(4.4, -47.8), P(3.8, -41), P(2.6, -30), P(1, -29)].map(d.up), fill: .colour(IndustrialPeopleInk.black),
                      stroke: .colour(Ink.line), width: 0.9)
        d.svg.line([d.up(P(3.8, -41)), d.up(P(1.4, -39.2))], stroke: .colour(IndustrialPeopleInk.blackSheen), width: 0.7)
        d.svg.path(coatPath(P(0, 0)), stroke: .colour(Ink.line), width: 1.8)
        // The watch chain looped from a buttonhole to the pocket, unless he has the watch out.
        if pose != .working {
            IndustrialPeopleProps.chain(&d.svg, from: d.up(P(10.2, -37)), to: d.up(P(9.6, -31)), sag: 0)
            IndustrialPeopleProps.chain(&d.svg, from: d.up(P(10.2, -37)), to: d.up(P(5, -31.4)), sag: 2.6)
            d.svg.circle(d.up(P(10.2, -37)), 0.6, fill: .colour(IndustrialPeopleInk.brass), stroke: .colour(Ink.line), width: 0.4)
        }
        // The winged collar and the black silk cravat with its pin.
        let lift = d.rig.lift
        d.svg.polygon([P(1.4, -48.8 - lift), P(9.2, -49 - lift), P(8.4, -46.6 - lift), P(2.2, -46.4 - lift)], fill: .colour(Ink.eyeWhite),
                      stroke: .colour(Ink.line), width: 0.8)
        d.svg.path("M3,\(num(-46.8 - lift)) q3,-0.8 5.4,0 q0.6,2.6 -1,4.6 q-1.4,0.8 -2.8,0 q-1.6,-2 -1.6,-4.6 Z",
                   fill: .colour(IndustrialPeopleInk.black), stroke: .colour(Ink.line), width: 0.8)
        d.svg.circle(P(5.8, -44.6 - lift), 0.6, fill: .colour(IndustrialPeopleInk.paleBrass))
    }

    /// A tall black silk hat: the crown a little wider at the top, a soot band, and the curled brim.
    static func hat(_ d: inout Drawing) {
        BronzePeopleProps.shape(&d.svg, fill: .colour(IndustrialPeopleInk.black), width: 1.5) { o in
            var p = PathData()
            p.move(P(-9.4, -65) + o)
            p.line(P(-10.6, -86.6) + o)
            p.quad(P(0, -88.4) + o, P(10.6, -86.6) + o)
            p.line(P(9.4, -66) + o)
            p.close()
            return p
        }
        // The band, and the silk's sheen.
        d.svg.polygon([P(-9.4, -65.4), P(9.4, -66.4), P(9.2, -70), P(-9.6, -69)], fill: .colour(IndustrialPeopleInk.soot), stroke: .colour(Ink.line),
                      width: 0.8)
        d.svg.line([P(-5.4, -71.6), P(-6.2, -85.2)], stroke: .colour(IndustrialPeopleInk.blackSheen), width: 1.3)
        d.svg.line([P(-2.8, -72), P(-3.2, -85.8)], stroke: .colour(IndustrialPeopleInk.blackSheen), width: 0.6)
        // The brim, curled up at the sides.
        BronzePeopleProps.shape(&d.svg, fill: .colour(IndustrialPeopleInk.black), width: 1.3) { o in
            var p = PathData()
            p.move(P(-14.6, -64.4) + o)
            p.cubic(P(-12, -67.4) + o, P(10, -68.6) + o, P(14.4, -66.4) + o)
            p.cubic(P(15.4, -64.4) + o, P(13, -63.6) + o, P(10.6, -64.6) + o)
            p.cubic(P(3, -65.6) + o, P(-5, -64.8) + o, P(-11.4, -62.4) + o)
            p.cubic(P(-13.2, -62) + o, P(-14.8, -62.8) + o, P(-14.6, -64.4) + o)
            p.close()
            return p
        }
    }
}
