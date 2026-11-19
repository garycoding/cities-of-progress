// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// The people of the Stone age: the hunter (worker), the elder (scholar), the
// builder (engineer), the clubman, the slinger and the founder. Each has its
// own clothing, headgear or hair, tool or weapon, nose and mark of its own
// (docs/art-style.md), and moves on the shared skeleton. Warfighters wear the
// team's colour on their clothes; the others carry it as a band, an apron, a
// cloak's trim or a banner.

enum StonePeople {
    /// The kinds drawn in the Stone age, with what each looks like.
    static func person(_ kind: UnitKind) -> (any PersonLook)? {
        switch kind {
        case .worker: Hunter()
        case .scholar: Elder()
        case .engineer: Builder()
        case .clubman: Clubman()
        case .slinger: Slinger()
        case .founder: Founder()
        case .merchant, .spearman, .archer, .chariot: nil
        }
    }

    /// The nose each kind is drawn with (docs/art-style.md, "Noses"): all five
    /// forms, the founder sharing the hunter's.
    static func nose(_ kind: UnitKind) -> Nose? {
        switch kind {
        case .worker: Hunter.nose
        case .scholar: Elder.nose
        case .engineer: Builder.nose
        case .clubman: Clubman.nose
        case .slinger: Slinger.nose
        case .founder: Founder.nose
        case .merchant, .spearman, .archer, .chariot: nil
        }
    }
}

// MARK: - The hunter (worker)

/// The approved worker: a hide tunic with dark spots and a zigzag hem, the
/// team's band at the waist, swept black hair, a brow; nose A. A stone axe for
/// work (the approved two-handed chop) and for fighting (a one-handed hack).
struct Hunter: PersonLook {
    static let nose = Nose.curve

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing: Moves.standing(frame)
        case .walking: Moves.walking(frame)
        case .working: chop(frame)
        case .fighting: hack(frame)
        default: nil
        }
    }

    /// The approved chop: raised two-handed over the shoulder, struck, recovered.
    func chopAngle(_ frame: Int) -> Double {
        let p = Moves.phase(frame)
        if p < 0.55 { return 70 + (195 - 70) * ease(p / 0.55) }
        if p < 0.72 { return 195 - (195 - 55) * pow((p - 0.55) / 0.17, 2) }
        return 55 + 15 * ease((p - 0.72) / 0.28)
    }

    func chop(_ frame: Int) -> Rig {
        let angle = chopAngle(frame)
        var r = Rig()
        r.backLeg = Limb(-16, 8); r.frontLeg = Limb(18, 8)
        r.frontArm = Limb(angle, -6); r.backArm = Limb(angle - 4, -2)
        r.lean = Moves.phase(frame) < 0.55 ? -5 : 7
        r.mouth = frame >= 7 && frame <= 9 ? .firm : .smile
        return r
    }

    func hack(_ frame: Int) -> Rig {
        let (angle, landing) = Moves.blow(frame, ready: 64, raised: 172, struck: 44)
        var r = Rig()
        // The elbow bent at the ready, straightening as the axe goes up.
        r.frontArm = Limb(angle, mix(14, -10, min(max((angle - 64) / 108, 0), 1)))
        r.backArm = Limb(36 - (angle - 64) * 0.3, 24)
        r.backLeg = Limb(-16, 6)
        r.frontLeg = frame >= 6 && frame <= 9 ? Limb(24, 14) : Limb(14, 8)
        r.lean = frame < 6 ? -3 : (frame <= 9 ? 9 : 3)
        r.mouth = frame >= 6 && frame <= 8 ? .shout : .firm
        r.eyes = landing ? .wide : .open
        return r
    }

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        d.figure { d in
            d.arm(front: false)
            d.legs()
            d.garment(colour: [P(-12, -46), P(8, -48), P(14, -14), P(-16, -13)],
                      outline: [P(-8, -47), P(8, -47), P(13, -16), P(-14, -16)], fill: .colour(Ink.hide)) { d in
                for (c, rx, ry) in [(P(-6, -36), 2.4, 1.7), (P(4, -28), 2.4, 1.7), (P(-4, -21), 2.0, 1.5), (P(7, -40), 2.0, 1.5)] {
                    d.svg.ellipse(d.up(c), rx, ry, fill: .colour(Ink.darkHide))
                }
                d.band([P(-11, -33), P(12, -34), P(12, -29), P(-12, -28)])
            }
            d.svg.path("M-14,-16 l3,4 l3,-4 l3,4 l3,-4 l3,4 l3,-4 l3,4 l3,-4", stroke: .colour(Ink.line), width: 1.3)
            switch pose {
            case .working:
                d.axe(at: d.joints.frontHand, degrees: chopAngle(frame) + 4)
                if frame == 9 || frame == 10 { d.chips(at: P(33, -34)) }
            case .fighting:
                // The axe in line with the forearm, its blade leading.
                d.axe(at: d.joints.frontHand, degrees: d.rig.frontArm.upper + d.rig.frontArm.bend + 8)
                if frame == 7 { d.swish(around: d.joints.frontShoulder, radius: 27, from: 150, to: 70) }
            default:
                break
            }
            d.arm(front: true)
            d.head(nose: Hunter.nose, hair: { d in
                d.svg.path("M-9,-60 C-10,-72 5,-73 9,-65 C3,-68 -2,-64 -4,-58 C-6,-56 -8,-57 -9,-60 Z", fill: .colour(Ink.line))
            }, brow: { d in
                d.svg.path("M1,-64.5 q4,-2 7,0", stroke: .colour(Ink.line), width: 1.4)
            })
        }
    }
}

// MARK: - The elder (scholar)

/// An old man in a long moss robe patterned with waves, the team's colour as a
/// sash; bald, with white hair at the back, a long white beard and a bushy
/// white brow; nose F. He walks with a stick; at work he hangs it from his
/// other hand, reads a stone tablet, and looks up as a thought arrives.
struct Elder: PersonLook {
    static let nose = Nose.bulb

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.lean = 4; r.headTilt = 2; r.mouth = .firm
            r.frontArm = Limb(22 + r.lift, 30)
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 15, kneeLift: 30, armSwing: 12)
            r.lean = 6; r.headTilt = 2; r.mouth = .firm
            r.frontArm = Limb(22 + 8 * sin(Moves.phase(frame) * 2 * .pi), 30)
            return r
        case .working:
            var r = Moves.standing(frame)
            r.lean = 3; r.mouth = .firm
            r.backArm = Limb(-40, 10)
            r.frontArm = Limb(78, 44)
            if frame < 7 {
                // Reading: the head bowed over the tablet, nodding along, murmuring.
                r.headTilt = frame % 3 == 1 ? 9 : 7
                r.eyes = .down
                r.mouth = frame % 2 == 0 ? .murmur : .firm
            } else {
                // The thought arrives: the head comes up, the eye widens, the mouth opens.
                r.headTilt = -3
                r.eyes = frame == 11 ? .open : .wide
                r.mouth = frame == 11 ? .firm : .open
                r.frontArm = Limb(72, 40)
            }
            return r
        default:
            return nil
        }
    }

    /// A walking stick through `hand`, reaching the ground.
    func stick(_ d: inout Drawing, at hand: P, degrees: Double) {
        let below = max(0, -d.bob - hand.y) / cos(degrees * .pi / 180) + 0.6
        d.staff(at: hand, degrees: degrees, above: 2.4, below: below)
    }

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        d.figure { d in
            // At work, the stick hangs from the hand behind him.
            if pose == .working { stick(&d, at: d.joints.backHand, degrees: 2) }
            d.arm(front: false)
            d.legs()
            let hemBack = P(-16 - sway * 1.5, -4), hemFront = P(15 - sway * 1.5, -4)
            d.garment(colour: [P(-11.5, -46), P(8, -48), hemFront + P(1.5, 1.5), hemBack + P(-2, 2)],
                      outline: [P(-8, -47), P(8, -47), hemFront, hemBack], fill: .colour(Ink.moss)) { d in
                // Waves across the robe.
                for y in [-37.0, -27.0, -17.0, -9.0] {
                    let share = (y + 47) / 43
                    let left = -8 + (hemBack.x + 8) * share + 2.2, right = 8 + (hemFront.x - 8) * share - 2.2
                    var path = PathData()
                    path.move(d.up(P(left, y)))
                    var x = left
                    var crest = true
                    while x + 3 <= right {
                        path.quad(d.up(P(x + 1.5, y + (crest ? -1.6 : 1.6))), d.up(P(x + 3, y)))
                        x += 3; crest.toggle()
                    }
                    d.svg.path(path, stroke: .colour(Ink.light), width: 1.1)
                }
                // The sash, from the back shoulder to the front hip.
                d.band([P(-9.5, -44), P(-4.5, -47.5), P(11.4, -26.5), P(11.8, -21)])
            }
            d.svg.path("M\(num(hemBack.x)),-4 L\(num(hemFront.x)),-4", stroke: .colour(Ink.line), width: 1.8)
            if pose == .working {
                d.tablet(at: d.joints.frontHand + P(-0.6, -1.6), degrees: -14)
                if frame >= 8 && frame <= 10 { d.insight() }
            } else {
                // Otherwise he leans on it, planted a little ahead of his feet.
                stick(&d, at: d.joints.frontHand, degrees: -4)
            }
            d.arm(front: true)
            d.head(nose: Elder.nose, hair: { d in
                // White hair at the back of a bald head.
                d.svg.path("M-10.8,-61.6 C-12.6,-56.4 -10.6,-50.8 -6.4,-48.6 C-6.2,-52.6 -7.4,-56.6 -5.4,-60.6 C-7.6,-60 -9.6,-60.4 -10.8,-61.6 Z",
                           fill: .colour(Ink.light), stroke: .colour(Ink.line), width: 1)
                d.svg.path("M-4,-65.8 q3.4,-1.8 6.6,-0.8", stroke: .colour(Ink.light), width: 1.2)
            }, features: { d in
                // A long white beard and moustache.
                d.svg.path("M-2.8,-52.6 C0.8,-49.4 6.6,-48.8 10.8,-52.4 C11.6,-46 8.8,-39.6 3.4,-35.6 C2.8,-40.4 0,-44.4 -2.8,-46.8 Z",
                           fill: .colour(Ink.light), stroke: .colour(Ink.line), width: 1.2)
                d.svg.path("M-0.6,-45.8 q2.4,2.6 3.4,6.2 M3.8,-48.2 q2,3 2,6.4", stroke: .colour(Ink.line), width: 0.8, opacity: 0.6)
                d.svg.path("M5.2,-53.8 q2.8,-1.8 6,-0.4 q-1.4,1.8 -3,1.2 q-1.6,0.8 -3,-0.8 Z",
                           fill: .colour(Ink.light), stroke: .colour(Ink.line), width: 1)
            }, brow: { d in
                d.svg.path("M0.2,-64 q4.4,-3.8 9,-1.2 q-4.4,-0.2 -9,1.2 Z", fill: .colour(Ink.light), stroke: .colour(Ink.line), width: 1.1)
            })
        }
    }
}

// MARK: - The builder (engineer)

/// A stocky builder in a light tunic striped like woven cloth, a leather cap
/// with a short brim, a bushy moustache; nose B. The team's colour is his
/// apron. A stone mallet: at work he drives a stake; fighting, he swings it.
struct Builder: PersonLook {
    static let nose = Nose.button

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            return Moves.standing(frame)
        case .walking:
            return Moves.walking(frame)
        case .working:
            return work(frame)
        case .fighting:
            let (angle, landing) = Moves.blow(frame, ready: 80, raised: 185, struck: 70)
            var r = Rig()
            r.frontArm = Limb(angle, -6)
            r.backArm = Limb(-30 + (angle - 80) * 0.25, -10)
            r.backLeg = Limb(-18, 6)
            r.frontLeg = frame >= 6 && frame <= 9 ? Limb(22, 12) : Limb(12, 8)
            r.lean = frame < 6 ? -4 : (frame <= 9 ? 10 : 2)
            r.mouth = landing ? .shout : .firm
            r.eyes = landing ? .wide : .open
            return r
        default:
            return nil
        }
    }

    /// Driving a post: the mallet raised over seven frames, brought down onto
    /// the post's top, and rebounding.
    static func workBlow(_ frame: Int) -> (angle: Double, landing: Bool) {
        Moves.blow(frame, ready: 66, raised: 165, struck: 58, raiseFrames: 7)
    }

    func work(_ frame: Int) -> Rig {
        let (angle, landing) = Builder.workBlow(frame)
        var r = Rig()
        r.backLeg = Limb(-12, 6); r.frontLeg = Limb(16, 14)
        r.lean = 10
        r.frontArm = Limb(angle, -4)
        r.backArm = Limb(24, 30)
        r.mouth = .firm
        r.eyes = landing ? .closed : .down
        return r
    }

    /// The mallet's angle at work: the handle a little ahead of the arm.
    static func workMallet(_ rig: Rig) -> Double { rig.frontArm.upper + 18 }

    /// The top of the post he drives: where the mallet's face lands, in the
    /// picture's space, so that the blow always meets it.
    static let postTop: P = {
        let frame = (0..<12).first { workBlow($0).landing } ?? 9
        let rig = Builder().work(frame)
        let d = Drawing(layer: .base, rig: rig, phase: 0)
        let u = P.direction(workMallet(rig)), across = P(-u.y, u.x)
        return d.world(d.joints.frontHand + u * 11.5 + across * 3.6)
    }()

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        if pose == .working {
            // The post stands upright on the ground, outside the leaning body.
            let top = Builder.postTop + P(0, 0.4)
            d.svg.ellipse(P(top.x, 0), 4.5, 1.3, fill: .colour("#000000"), opacity: 0.13)
            d.svg.polygon([P(top.x - 3.1, top.y + 0.8), P(top.x + 1.7, top.y + 0.6), P(top.x + 1.9, 0.8), P(top.x - 3.3, 1)],
                          fill: .colour(Ink.wood))
            d.svg.polygon([P(top.x - 2.4, top.y), P(top.x + 2.4, top.y), P(top.x + 2.6, 0), P(top.x - 2.6, 0)], fill: .none,
                          stroke: .colour(Ink.line), width: 1.3)
            d.svg.ellipse(top, 2.4, 0.9, fill: .colour(Ink.hide), stroke: .colour(Ink.line), width: 1)
            d.svg.path("M\(num(top.x - 0.8)),\(num(top.y * 0.7)) v4 M\(num(top.x + 1)),\(num(top.y * 0.35)) v3",
                       stroke: .colour(Ink.line), width: 0.9)
        }
        d.figure { d in
            d.arm(front: false)
            d.legs()
            d.garment(colour: [P(-13, -46), P(9, -48), P(15, -14), P(-17, -13)],
                      outline: [P(-9, -47), P(9, -47), P(14, -16), P(-15, -16)], fill: .colour(Ink.light)) { d in
                // Woven stripes.
                for x in [-9.0, -4.0, 1.0, 6.0] {
                    d.svg.line([d.up(P(x + 0.4, -44)), P(x * 1.35, -17)], stroke: .colour(Ink.hide), width: 1.6)
                }
                // The apron, in the team's colour, from a belt at the waist.
                d.band([P(1.5, -33), P(13.5, -34), P(16, -11.5), P(3.5, -11)])
            }
            d.svg.polygon([P(2.6, -33.6), P(12.4, -33.6), P(14.6, -12.4), P(4.2, -12.4)], fill: .none,
                          stroke: .colour(Ink.line), width: 1.3)
            d.svg.line([d.up(P(-10.4, -33.4)), d.up(P(12.6, -34.4))], stroke: .colour(Ink.line), width: 2)
            // A fringe at the hem.
            d.svg.path("M-13,-16 v2.6 M-10,-16 v2.6 M-7,-16 v2.6 M-4,-16 v2.6 M-1,-16 v2.6", stroke: .colour(Ink.line), width: 1.1)
            let hand = d.joints.frontHand
            switch pose {
            case .working:
                d.mallet(at: hand, degrees: Builder.workMallet(d.rig))
            case .fighting:
                d.mallet(at: hand, degrees: d.rig.frontArm.upper + 10)
                if frame == 7 { d.swish(around: d.joints.frontShoulder, radius: 25, from: 160, to: 90) }
            default:
                d.mallet(at: hand, degrees: d.rig.frontArm.upper + d.rig.frontArm.bend + 14)
            }
            d.arm(front: true, width: 2.1)
            d.head(nose: Builder.nose, hair: { d in
                d.svg.path("M-9.8,-60 C-10.6,-63 -9.6,-55 -7.6,-52.8 C-7,-55.4 -6.6,-57.8 -5.2,-59.6 Z", fill: .colour(Ink.line))
            }, features: { d in
                // A bushy moustache.
                d.svg.path("M4.4,-54 q3.4,-2.6 7.2,-0.6 q-1,2.4 -3.6,1.4 q-2,1.4 -3.6,-0.8 Z", fill: .colour(Ink.line))
            }, brow: { d in
                d.svg.path("M1.6,-64 q3.4,-1.4 6.4,-0.2", stroke: .colour(Ink.line), width: 1.5)
            }, over: { d in
                // A leather cap with a short brim.
                d.svg.path("M-11.2,-58.6 C-12.6,-71 2.6,-73.8 9.4,-65.6 L14.2,-64.8 L13.6,-63 L-11.2,-58.6 Z", fill: .colour(Ink.hide))
                d.svg.path("M-10.6,-59.4 C-11.4,-70.6 3,-72.8 9.6,-65.2 L14.4,-64.4 L13.8,-62.6 L-10.6,-59.4 Z", stroke: .colour(Ink.line), width: 1.5)
                d.svg.path("M-1.6,-71.2 q1.6,4.4 1.8,9.4", stroke: .colour(Ink.darkHide), width: 1)
            })
        }
        // The blow landing on the post, over the mallet's head.
        if pose == .working && Builder.workBlow(frame).landing {
            d.burst(at: Builder.postTop + P(0, -1.4), from: 96, to: 264, size: 1.2)
        }
    }
}

// MARK: - The clubman

/// A bare-chested warrior in a kilt of the team's colour with a zigzag hem, a
/// hide strap across his chest, wild spiky hair, a heavy brow and a scar on
/// the cheek; nose C. A heavy wooden club, held upright at the ready and
/// brought down two-handed.
struct Clubman: PersonLook {
    static let nose = Nose.hook

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing, .working:
            var r = Moves.standing(frame)
            r.backLeg = Limb(-7, 4); r.frontLeg = Limb(8, 4)
            r.frontArm = Limb(38 + r.lift, 44)
            r.mouth = .firm
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 26)
            r.frontArm = Limb(38, 44)
            r.mouth = .firm
            return r
        case .fighting:
            let (angle, landing) = Moves.blow(frame, ready: 120, raised: 210, struck: 62)
            var r = Rig()
            r.frontArm = Limb(angle, -6)
            r.backArm = Limb(angle - 8, 2)
            r.backLeg = Limb(-20, 6)
            r.frontLeg = frame >= 6 && frame <= 9 ? Limb(26, 16) : Limb(14, 8)
            r.lean = frame < 6 ? -6 : (frame <= 9 ? 12 : 2)
            r.mouth = frame >= 6 && frame <= 8 ? .shout : .firm
            r.eyes = landing ? .wide : .open
            return r
        default:
            return nil
        }
    }

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        d.figure { d in
            d.arm(front: false, width: 2.4)
            d.legs()
            // The bare chest.
            d.garment(colour: [P(-11.4, -46), P(9, -48), P(10.6, -28), P(-10.6, -27.4)],
                      outline: [P(-8.4, -47), P(9, -47), P(9.8, -30), P(-9.6, -30)], fill: .colour(Ink.skin)) { d in
                d.svg.path("M\(num(1.6)),\(num(d.up(P(0, -41)).y)) q3.6,1.8 6.8,-0.2", stroke: .colour(Ink.line), width: 1)
            }
            // The strap across it.
            d.band([P(-8.6, -46.4), P(-4.4, -47.2), P(10, -31.6), P(6.4, -30.6)], fill: .colour(Ink.darkHide))
            // The kilt, in the team's colour.
            d.garment(colour: [P(-12.6, -31), P(11, -32.4), P(14.6, -14), P(-16.4, -13)],
                      outline: [P(-10.2, -31), P(10.4, -31), P(13, -16), P(-14, -16)], fill: .team) { d in
                d.svg.path("M-8,-26.4 l4,-2 l4,2 l4,-2 l4,2", stroke: .colour(Ink.line), width: 1.1)
            }
            d.svg.path("M-14,-16 l3,4 l3,-4 l3,4 l3,-4 l3,4 l3,-4 l3,4 l3,-4", stroke: .colour(Ink.line), width: 1.3)
            d.svg.line([d.up(P(-10.4, -31.4)), d.up(P(10.6, -31.6))], stroke: .colour(Ink.darkHide), width: 2.4)
            let hand = d.joints.frontHand
            switch pose {
            case .fighting:
                let angle = d.rig.frontArm.upper
                d.club(at: hand, degrees: angle - 4, length: 20)
                if frame == 7 { d.swish(around: d.joints.frontShoulder, radius: 33, from: 175, to: 80) }
                if frame == 8 { d.impact(at: hand + P.direction(angle - 4) * 24, size: 1.1) }
            default:
                d.club(at: hand, degrees: 176, length: 20)
            }
            d.arm(front: true, width: 2.4)
            d.head(nose: Clubman.nose, hair: { d in
                d.svg.path("M-10.2,-59 L-13.8,-63.4 L-9.6,-64.8 L-11.2,-69.8 L-5.8,-67.6 L-4.6,-72.8 L-0.6,-68.6 L2.8,-72.4 "
                           + "L4.4,-67.4 L9,-68.8 L7.6,-64.6 C3,-66.8 -2,-64.4 -4.4,-59.6 C-6.4,-57.4 -8.8,-57.6 -10.2,-59 Z",
                           fill: .colour(Ink.line))
            }, features: { d in
                // A scar across the cheek, stitched.
                d.svg.path("M0.2,-57.6 l3.8,4.8 M1,-55.4 l1.7,-1.3 M2.3,-53.8 l1.7,-1.3", stroke: .colour(Ink.line), width: 0.9)
            }, brow: { d in
                d.svg.path("M1.2,-65.6 L9,-63", stroke: .colour(Ink.line), width: 2.3)
            })
        }
    }
}

// MARK: - The slinger

/// A young, light warrior in a short tunic of the team's colour with a light
/// zigzag across it, a hide headband whose tails stream behind, a topknot and
/// freckles; nose E. A sling: it hangs from his hand, and in a fight he whirls
/// it and lets the stone fly.
struct Slinger: PersonLook {
    static let nose = Nose.line

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing, .working:
            var r = Moves.standing(frame)
            r.frontArm = Limb(14 + r.lift * 2, -4)
            return r
        case .walking:
            return Moves.walking(frame)
        case .fighting:
            var r = Rig()
            r.backLeg = Limb(-16, 6)
            if frame < 8 {
                // The whirl: the arm raised forward, the sling going round the hand.
                r.frontArm = Limb(100 + 4 * sin(Double(frame) / 8 * 2 * .pi), 8)
                r.frontLeg = Limb(12, 8)
                r.lean = -3
                r.mouth = .firm
            } else {
                // The release, and the follow-through.
                let t = Double(frame - 8) / 3
                r.frontArm = Limb(mix(96, 46, t), -6)
                r.frontLeg = Limb(22, 12)
                r.lean = mix(9, 4, t)
                r.mouth = frame == 8 ? .shout : .firm
                r.eyes = frame == 8 ? .wide : .open
            }
            r.backArm = Limb(-24, -8)
            return r
        default:
            return nil
        }
    }

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        d.figure { d in
            d.arm(front: false)
            d.legs()
            // A pouch of stones at the back hip.
            d.svg.ellipse(P(-12.4, -21), 2.6, 3, fill: .colour(Ink.hide), stroke: .colour(Ink.line), width: 1.1)
            d.garment(colour: [P(-11, -46), P(7.5, -48), P(12.6, -16), P(-14.6, -15)],
                      outline: [P(-7.6, -47), P(7.6, -47), P(11.6, -18.4), P(-12.6, -18.4)], fill: .team) { d in
                // A light zigzag across the chest.
                d.svg.path("M\(num(-8.4)),\(num(d.up(P(0, -36)).y)) l3,-2.6 l3,2.6 l3,-2.6 l3,2.6 l3,-2.6", stroke: .colour(Ink.light), width: 1.4)
                d.svg.path("M-11.4,-24.6 l3,-2.2 l3,2.2 l3,-2.2 l3,2.2 l3,-2.2 l3,2.2 l3,-2.2", stroke: .colour(Ink.light), width: 1.2)
            }
            d.svg.line([d.up(P(-10.6, -30)), d.up(P(10.2, -30.6))], stroke: .colour(Ink.darkHide), width: 1.8)
            let at = d.joints.frontHand
            switch pose {
            case .fighting:
                if frame < 8 {
                    let around = Double(frame) / 8 * 360
                    // Round the hand, in the plane of the picture.
                    d.sling(at: at, degrees: 180 - around, length: 6)
                    d.swish(around: at, radius: 6.8, from: 180 - around + 140, to: 180 - around + 20)
                } else {
                    d.sling(at: at, degrees: mix(70, 20, Double(frame - 8) / 3), length: 9, loaded: false)
                    let flight = Double(frame - 8)
                    d.stone(at: P(24 + flight * 9, -50 + flight * 1.5))
                    if frame == 8 { d.impact(at: P(22, -50), size: 0.6) }
                }
            case .walking:
                d.sling(at: at, degrees: d.rig.frontArm.upper * 0.4, length: 9)
            default:
                d.sling(at: at, degrees: 4 * sin(d.phase * 2 * .pi), length: 9)
            }
            d.arm(front: true, width: 1.8)
            let flutter = 2 * sin(d.phase * 4 * .pi) + (pose == .walking ? 1.5 : 0)
            d.head(nose: Slinger.nose, behind: { d in
                // The headband's tails, streaming behind.
                d.svg.path("M-10.6,-60.4 q-4.6,\(num(1 + flutter * 0.4)) -8.6,\(num(3.4 + flutter))", stroke: .colour(Ink.line), width: 2.8)
                d.svg.path("M-10.6,-60.4 q-4.6,\(num(1 + flutter * 0.4)) -8.6,\(num(3.4 + flutter))", stroke: .colour(Ink.hide), width: 1.4)
                d.svg.path("M-10.4,-59.6 q-3,\(num(2.6 - flutter * 0.3)) -6,\(num(6 - flutter * 0.6))", stroke: .colour(Ink.line), width: 2.8)
                d.svg.path("M-10.4,-59.6 q-3,\(num(2.6 - flutter * 0.3)) -6,\(num(6 - flutter * 0.6))", stroke: .colour(Ink.hide), width: 1.4)
            }, hair: { d in
                d.svg.path("M-9.4,-59.6 C-10.4,-70.6 4.4,-72.6 9,-65.4 C3.2,-67.6 -2,-64.4 -4.4,-59 C-6.2,-57 -8.4,-57.6 -9.4,-59.6 Z",
                           fill: .colour(Ink.line))
                // The topknot.
                d.svg.circle(P(-4.2, -70.6), 2.9, fill: .colour(Ink.line))
            }, features: { d in
                for c in [P(1.4, -55.6), P(3.2, -54.4), P(4.8, -55.8)] { d.svg.circle(c, 0.5, fill: .colour(Ink.darkHide)) }
            }, brow: { _ in }, over: { d in
                // The headband, rising toward the front.
                d.svg.polygon([P(-11, -62.4), P(9, -67.8), P(9.8, -65.4), P(-10.6, -59.8)].map { $0 + P(-0.5, 0.5) }, fill: .colour(Ink.hide))
                d.svg.polygon([P(-11, -62.4), P(9, -67.8), P(9.8, -65.4), P(-10.6, -59.8)], fill: .none, stroke: .colour(Ink.line), width: 1.2)
            })
        }
    }
}

// MARK: - The founder

/// The one who founds a new town: a long hide cloak trimmed in the team's
/// colour, a light tunic with chevrons, long dark hair under a headdress of
/// antlers (as Stone-age people wore them), and a short dark beard; nose A, as
/// the hunter's, since the two differ most in outline. A pole with a pennant
/// of the team's colour, which streams and ripples.
struct Founder: PersonLook {
    static let nose = Nose.curve

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing, .working:
            var r = Moves.standing(frame)
            r.frontArm = Limb(34 + r.lift, 58)
            r.mouth = .firm
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 22)
            r.frontArm = Limb(34, 58)
            r.mouth = .firm
            return r
        default:
            return nil
        }
    }

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        d.figure { d in
            // The cloak behind, its hem swinging back as he walks.
            let hem = P(-21 - abs(sway) * 2.5, -9)
            d.svg.polygon([d.up(P(-9, -47.6)), d.up(P(-2, -47)), P(-3, -12), hem + P(1, 1)], fill: .colour(Ink.hide))
            d.svg.polygon([d.up(P(-9.6, -45.8)), d.up(P(-6.6, -46.4)), hem + P(4.6, 0.4), hem + P(0.6, -0.4)], fill: .team)
            d.svg.polygon([d.up(P(-7.4, -47.6)), d.up(P(-1.4, -47)), P(-2.4, -12.4), hem], fill: .none,
                          stroke: .colour(Ink.line), width: 1.6)
            d.arm(front: false)
            d.legs()
            d.garment(colour: [P(-11.6, -46), P(8, -48), P(13.4, -15), P(-14.6, -14)],
                      outline: [P(-8, -47), P(8, -47), P(12.4, -17), P(-13, -17)], fill: .colour(Ink.light)) { d in
                // Chevrons down the front.
                for y in [-40.0, -33.0, -26.0] {
                    d.svg.path("M\(num(-1)),\(num(d.up(P(0, y)).y)) l3.4,2.6 l3.4,-2.6", stroke: .colour(Ink.moss), width: 1.6)
                }
            }
            d.svg.line([d.up(P(-11, -30.4)), d.up(P(10.6, -31))], stroke: .colour(Ink.darkHide), width: 2.2)
            d.zigzag(from: P(-13, -17), to: P(12.4, -17), teeth: 4, depth: 3)
            // The banner, carried upright.
            let hand = d.joints.frontHand
            let wave = pose == .walking ? d.phase * 2 : d.phase
            d.banner(at: hand, foot: hand.y + 26, top: -86, wave: wave)
            d.arm(front: true)
            d.head(nose: Founder.nose, behind: { d in
                // A pair of antlers rising from the crown, the far one behind.
                for (base, reach) in [(P(-5.6, -64.8), 9.0), (P(-1.6, -66.2), 7.0)] {
                    let tip = base + P(-reach, -20.5), bend = base + P(2.4, -12.4)
                    func along(_ t: Double) -> P { base * ((1 - t) * (1 - t)) + bend * (2 * (1 - t) * t) + tip * (t * t) }
                    var antler = PathData()
                    antler.move(base); antler.quad(bend, tip)
                    for (t, prong) in [(0.38, P(4.6, -4.6)), (0.68, P(4.2, -5.2))] {
                        antler.move(along(t)); antler.line(along(t) + prong)
                    }
                    antler.move(tip); antler.line(tip + P(-2.6, 0.6))
                    d.svg.path(antler, stroke: .colour(Ink.line), width: 3.6)
                    d.svg.path(antler, stroke: .colour(Ink.light), width: 1.8)
                }
            }, hair: { d in
                // Long dark hair to the shoulders.
                d.svg.path("M-9.8,-60.4 C-11,-71 4,-73 9.2,-65.4 C3.4,-67.6 -1.6,-65 -3.6,-61.4 C-5.6,-58 -6.4,-53 -5.4,-48 "
                           + "L-11.6,-48.4 C-12.8,-52 -11.8,-57 -9.8,-60.4 Z", fill: .colour(Ink.line))
            }, features: { d in
                // A short dark beard along the jaw.
                d.svg.path("M-2.4,-50.8 C1.4,-47.8 7,-47.4 10.2,-50.6 C9.8,-47 7.6,-44.4 5,-43.4 C3,-44.6 -0.2,-46.8 -2.4,-50.8 Z",
                           fill: .colour(Ink.line))
            }, brow: { d in
                d.svg.path("M1,-64.6 l7.4,-0.6", stroke: .colour(Ink.line), width: 1.5)
            }, over: { d in
                d.svg.path("M-11.2,-63 q10,-6.4 21,-4.2", stroke: .colour(Ink.line), width: 3.2)
                d.svg.path("M-11.2,-63 q10,-6.4 21,-4.2", stroke: .colour(Ink.hide), width: 1.6)
            })
        }
    }
}
