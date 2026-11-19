// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// Three of the four peaceful sectors in their Iron-age looks: the farmer
// (worker), the philosopher (scholar) and the siege engineer (engineer); the
// caravan trader is in IronPeopleCaravan.swift. Each wears wool and linen of
// the age's colours and carries iron, has a nose of its own (docs/art-style.md,
// "Noses") different from his Bronze stage's, and moves on the shared
// skeleton. The team's colour is where the earlier ages put it for the same
// sector: the worker's sash, the scholar's stole (here the rolled edge of his
// mantle), the engineer's apron (here its band) and his cap.

// MARK: - The farmer (worker)

/// A farmer in a short tunic of iron-grey wool with a red hem patterned in
/// the light, the team's sash knotted at the waist, a sickle tucked in at the
/// back, a broad straw hat with a red band, and a stalk of grain between his
/// teeth; nose B. He carries his hoe on his shoulder with a basket of grain
/// hanging from its haft behind him; at work he sets the basket down and
/// breaks the soil with the hoe in the approved two-handed chop, clods flying
/// where it bites; fighting, he hacks with it.
struct IronPeopleFarmer: PersonLook {
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.frontArm = Self.carry(lift: r.lift)
            return r
        case .walking:
            var r = Moves.walking(frame)
            r.frontArm = Self.carry(lift: BronzePeopleKit.wave(frame, times: 2))
            return r
        case .working:
            return hoeing(frame)
        case .fighting:
            return hack(frame)
        default:
            return nil
        }
    }

    /// The front hand at the shoulder, steadying the hoe that rests on it.
    static func carry(lift: Double) -> Limb { Limb(30 + lift, 128) }
    /// The hoe on the shoulder: its haft runs back and a little up from the hand.
    static let carried = -97.0
    /// How far behind the hand the basket hangs from the haft.
    static let hangs = 33.0
    static let workingHaft = 32.0

    /// The approved chop (docs/art/worker-animation.gif), brought down to the ground.
    static func hoeAngle(_ frame: Int) -> Double {
        let p = Moves.phase(frame)
        if p < 0.55 { return 70 + (195 - 70) * ease(p / 0.55) }
        if p < 0.72 { return 195 - (195 - 30) * pow((p - 0.55) / 0.17, 2) }
        return 30 + 40 * ease((p - 0.72) / 0.28)
    }

    /// The frame on which the hoe bites.
    static let strike = 9

    func hoeing(_ frame: Int) -> Rig {
        let angle = Self.hoeAngle(frame)
        var r = Rig()
        r.backLeg = Limb(-16, 8); r.frontLeg = Limb(20, 12)
        r.frontArm = Limb(angle, -6); r.backArm = Limb(angle - 6, -2)
        r.lean = [-2, -4, -5, -5, -5, -5, -5, 2, 10, 14, 11, 4][frame]
        r.mouth = frame >= 8 && frame <= 10 ? .firm : .smile
        r.eyes = frame == 9 ? .wide : .open
        return r
    }

    func hack(_ frame: Int) -> Rig {
        let (angle, landing) = Moves.blow(frame, ready: 85, raised: 172, struck: 48)
        var r = Rig()
        r.frontArm = Limb(angle, -10)
        r.backArm = Limb(42 - (angle - 85) * 0.35, 24)
        r.backLeg = Limb(-16, 6)
        r.frontLeg = frame >= 6 && frame <= 9 ? Limb(22, 14) : Limb(14, 8)
        r.lean = frame < 6 ? -3 : (frame <= 9 ? 9 : 3)
        r.mouth = frame >= 6 && frame <= 8 ? .shout : .firm
        r.eyes = landing ? .wide : .open
        return r
    }

    /// The hoe while working: its blade end, its haft's direction from there, and its blade's side.
    static func workingHoe(_ hand: P, _ frame: Int) -> (end: P, toward: P, side: P) {
        let u = P.direction(hoeAngle(frame) + 4)
        return (hand + u * workingHaft, u * -1, P(-u.y, u.x))
    }

    /// Where the hoe's edge bites the ground, in the picture: the turned earth lies there.
    static let bite: P = {
        let rig = IronPeopleFarmer().hoeing(strike)
        let d = Drawing(layer: .base, rig: rig, phase: 0)
        let hoe = workingHoe(d.joints.frontHand, strike)
        return d.world(IronPeopleProps.hoeEdge(end: hoe.end, toward: hoe.toward, side: hoe.side))
    }()

    /// Where the basket stands while he works or fights.
    static let basketDown = P(-27, -9)

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        if pose == .working || pose == .fighting {
            d.svg.ellipse(Self.basketDown + P(0.6, 9), 8, 2, fill: .colour("#000000"), opacity: 0.13)
            IronPeopleProps.basket(&d.svg, rim: Self.basketDown, width: 13, height: 9)
        }
        if pose == .working {
            IronPeopleProps.soil(&d.svg, from: Self.bite.x - 9, to: Self.bite.x + 7, peak: Self.bite.x - 1, height: max(2.4, -Self.bite.y + 1))
        }
        d.figure { d in
            let hand = d.joints.frontHand
            let carrying = pose == .standing || pose == .walking
            let carryU = P.direction(Self.carried)
            if carrying {
                // The basket hanging from the haft behind him, swinging with his stride.
                let hook = hand + carryU * Self.hangs
                let swing = pose == .walking ? 9 * BronzePeopleKit.wave(frame, 0.15) : 1.6 * BronzePeopleKit.wave(frame, 0.2)
                d.svg.group(turned: swing, about: hook) { svg in
                    svg.line([hook, hook + P(0, 4)], stroke: .colour(Ink.line), width: 0.9)
                    IronPeopleProps.basket(&svg, rim: hook + P(0, 11.6), width: 13, height: 9, stir: swing / 9)
                }
            }
            d.arm(front: false)
            d.legs()
            // The ends of the sash, hanging at the front hip.
            for (dx, length) in [(0.0, 9.5), (2.2, 7.5)] {
                let top = P(9.4 + dx * 0.4, -27)
                let end = top + P(1.6 - sway * 2 + dx * 0.5, length)
                d.svg.polygon([top + P(-1.1, 0), top + P(1.1, 0), end + P(0.9, 0), end + P(-0.9, 0)], fill: .team,
                              stroke: .colour(Ink.line), width: 0.9)
            }
            // The tunic: iron-grey wool, a red hem with a light zigzag woven in it.
            let top = (P(-8.5, -47), P(8.5, -47)), hem = (P(-15, -14.5), P(13.5, -14.5))
            d.garment(colour: [P(-12.5, -46), P(9, -48), P(14.6, -12.6), P(-16.6, -12.2)],
                      outline: [top.0, top.1, hem.1, hem.0], fill: .colour(IronPeopleInk.grey)) { d in
                d.svg.polygon([P(-14.4, -19.6), P(13, -19.6), P(14.1, -13), P(-16.1, -12.8)], fill: .colour(IronPeopleInk.red))
                var zig = PathData()
                var x = -13.6, up = true
                zig.move(P(x, -17.2))
                while x + 2 <= 12.6 {
                    x += 2; up.toggle()
                    zig.line(P(x, up ? -18.4 : -15.4))
                }
                d.svg.path(zig, stroke: .colour(IronPeopleInk.light), width: 0.9)
                // Flecks in the wool.
                var flecks = PathData()
                for (x, y) in [(-6.0, -42.0), (2.0, -40.0), (-9.0, -36.0), (5.5, -36.5), (-2.0, -23.0), (6.0, -22.4), (-10.0, -22.8)] {
                    flecks.move(d.up(P(x, y))); flecks.line(d.up(P(x + 1.2, y + 0.4)))
                }
                d.svg.path(flecks, stroke: .colour(IronPeopleInk.darkGrey), width: 0.9)
                // The sash, in the team's colour.
                d.band([P(-13.2, -31.8), P(12.4, -32.8), P(13, -26.6), P(-13.8, -25.6)])
                d.svg.line([d.up(P(-13.2, -31.8)), d.up(P(12.4, -32.8))], stroke: .colour(Ink.line), width: 0.9)
                d.svg.line([P(-13.8, -25.6), P(13, -26.6)], stroke: .colour(Ink.line), width: 0.9)
            }
            // The knot of the sash.
            d.svg.ellipse(P(10.4, -29.2), 2, 2.6, fill: .team, stroke: .colour(Ink.line), width: 0.9)
            // The sickle, tucked into the sash at the back, its blade curling down behind.
            IronPeopleProps.sickle(&d.svg, at: d.up(P(-11, -33.4)), degrees: 10, point: -1, size: 0.72)
            switch pose {
            case .working:
                let hoe = Self.workingHoe(hand, frame)
                IronPeopleProps.hoe(&d.svg, end: hoe.end, toward: hoe.toward, length: Self.workingHaft + 4, side: hoe.side)
                if frame == Self.strike || frame == Self.strike + 1 {
                    IronPeopleProps.clods(&d.svg, at: IronPeopleProps.hoeEdge(end: hoe.end, toward: hoe.toward, side: hoe.side) + P(-1, -1),
                                          spread: frame == Self.strike ? 0 : 1)
                }
            case .fighting:
                let u = P.direction(d.rig.frontArm.upper - 2)
                let end = hand + u * 22
                IronPeopleProps.hoe(&d.svg, end: end, toward: u * -1, length: 26, side: P(-u.y, u.x))
                if frame == 7 { d.swish(around: d.joints.frontShoulder, radius: 33, from: 160, to: 70) }
                if frame == 8 { d.impact(at: IronPeopleProps.hoeEdge(end: end, toward: u * -1, side: P(-u.y, u.x)), size: 1) }
            default:
                // On the shoulder: the blade just before the hand, hanging down, the haft running back over the shoulder.
                let end = hand - carryU * 3.4
                IronPeopleProps.hoe(&d.svg, end: end, toward: carryU, length: 40, side: P(carryU.y, -carryU.x))
            }
            d.arm(front: true)
            d.head(nose: .button, hair: { d in
                // Brown curls at the nape, under the hat.
                d.svg.path("M-11.2,-61 C-12.8,-56.4 -11.4,-51.8 -7.6,-50.2 C-8.4,-52.2 -8,-54 -7,-55.4 C-8.6,-56.4 -8.6,-58.6 -7.4,-60.4 Z",
                           fill: .colour(IronPeopleInk.hair))
            }, features: { d in
                // A stalk of grain between his teeth.
                d.svg.line([P(8.2, -50.6), P(17.6, -54.4)], stroke: .colour(IronPeopleInk.darkStraw), width: 0.8)
                d.svg.group(at: P(17.4, -54.6), turned: -112) { svg in
                    svg.ellipse(P(-0.3, 0.3), 1, 2.4, fill: .colour(IronPeopleInk.grain))
                    svg.ellipse(P(0, 0), 1, 2.4, fill: .none, stroke: .colour(Ink.line), width: 0.6)
                }
            }, brow: { d in
                d.svg.path("M1.8,-63.2 q3.2,-1.2 6.2,0", stroke: .colour(Ink.line), width: 1.6)
            }, over: { d in
                Self.hat(&d)
            })
        }
    }

    /// A broad straw hat: a low crown with a red band, and a wide brim that dips at the front and back.
    static func hat(_ d: inout Drawing) {
        BronzePeopleProps.shape(&d.svg, fill: .colour(IronPeopleInk.straw), width: 1.4) { o in
            var p = PathData()
            p.move(P(-8.8, -65) + o)
            p.cubic(P(-9.6, -73) + o, P(7.6, -74.6) + o, P(8.6, -65.6) + o)
            p.close()
            return p
        }
        // The band.
        d.svg.path("M-8.9,-66.6 C-3,-68 3.6,-68.2 8.7,-67.2 L8.6,-65.2 C3.6,-66.2 -3,-66 -8.8,-64.6 Z", fill: .colour(IronPeopleInk.red),
                   stroke: .colour(Ink.line), width: 0.8)
        BronzePeopleProps.shape(&d.svg, fill: .colour(IronPeopleInk.straw), width: 1.4) { o in
            var p = PathData()
            p.move(P(-18.2, -62.2) + o)
            p.cubic(P(-12, -66.6) + o, P(9, -67.6) + o, P(19, -63.2) + o)
            p.cubic(P(16.4, -61.6) + o, P(10, -62.6) + o, P(1, -63) + o)
            p.cubic(P(-8, -63) + o, P(-14, -61) + o, P(-18.2, -62.2) + o)
            p.close()
            return p
        }
        // The weave of the straw.
        d.svg.path("M-14,-63.4 l1.6,1 M-9,-64.4 l1.6,1 M-4,-64.8 l1.6,1 M1,-65 l1.6,1 M6,-64.8 l1.6,1 M11,-64.2 l1.6,1 "
                   + "M-6,-70 l1.2,1.2 M-1,-71.4 l1.2,1.2 M4,-70.6 l1.2,1.2", stroke: .colour(IronPeopleInk.darkStraw), width: 0.8)
    }
}

// MARK: - The philosopher (scholar)

/// A philosopher in a long linen chiton finely pleated, a sea-green mantle
/// draped over his back shoulder and wrapped round him, its rolled edge in the
/// team's colour edged with the light running across his chest, and a key
/// pattern in the light along its hem; bald, with a fringe of white hair, a
/// long white beard and bushy white brows; nose C. He carries a scroll; at
/// work he teaches: the scroll in his back hand, he raises a finger, brings
/// the point home with a beat of the hand, opens his palm to his listeners,
/// and talks throughout.
struct IronPeoplePhilosopher: PersonLook {
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.lean = 1
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(15.2, -33.6 - r.lift * 0.5))
            r.mouth = .smile
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 16, kneeLift: 30, armSwing: 14)
            r.lean = 3
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(15.2, -33.6))
            return r
        case .working:
            return teach(frame)
        default:
            return nil
        }
    }

    /// The gesturing hand through the lesson: raised with a finger up (frames
    /// 2 to 4), brought down in a beat (6), opened outward (8 and 9), and back.
    static let gesture: [P] = [P(14.2, -38.6), P(15.4, -44.6), P(16.4, -51.6), P(16.2, -55.6), P(16, -56), P(17.6, -48.4),
                               P(19.6, -40.6), P(21, -42.4), P(21.8, -44.4), P(21.4, -44), P(18.6, -41.2), P(15.6, -39)]
    static let fingerUp = 2...4
    static let palmOpen = 7...9

    /// Where the back hand holds the scroll whilst he teaches.
    static let scrollHeld = P(3, -27.2)

    func teach(_ frame: Int) -> Rig {
        var r = Moves.standing(frame)
        r.lean = 2
        r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), Self.gesture[frame], elbowUp: false)
        r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), Self.scrollHeld + P(-1.4, 1.6))
        r.headTilt = [0, -2, -4, -5, -5, 0, 5, 3, 0, -1, 0, 0][frame]
        r.mouth = [Mouth.smile, .murmur, .open, .open, .murmur, .open, .shout, .murmur, .open, .murmur, .smile, .smile][frame]
        r.eyes = frame == 11 ? .closed : (frame == 6 ? .wide : .open)
        return r
    }

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        d.figure { d in
            if pose != .working { d.arm(front: false) }
            d.legs()
            // The chiton, long to the ankles, finely pleated.
            let hemBack = P(-15.6 - sway * 1.4, -3.6), hemFront = P(14.6 - sway * 1.4, -3.6)
            d.garment(colour: [P(-11.5, -46), P(8, -48), hemFront + P(1.5, 1.5), hemBack + P(-2, 2)],
                      outline: [P(-8, -47), P(8, -47), hemFront, hemBack], fill: .colour(IronPeopleInk.light)) { d in
                var pleats = PathData()
                for f in [0.25, 0.5, 0.75] {
                    pleats.move(P(hemBack.x + (hemFront.x - hemBack.x) * f, -4.4))
                    pleats.line(P(hemBack.x + (hemFront.x - hemBack.x) * f + 0.4, -12))
                }
                d.svg.path(pleats, stroke: .colour(IronPeopleInk.darkGrey), width: 0.7, opacity: 0.7)
            }
            // The mantle: over the back shoulder and down his back, wrapped round
            // below the chest, its rolled edge running from the back shoulder to the front hip.
            let back = P(-17.4 - sway * 1.6, -11), front = P(15.4 - sway * 1.6, -12.6)
            let mantle = [P(-9.6, -47.6), P(-4, -48), P(14.2, -27.4), front, back]
            d.svg.polygon([P(-11, -46.6), P(-4.6, -47.4), P(13.6, -26.6), front + P(-0.8, 1.2), back + P(-1.2, 1.2)].map(d.up),
                          fill: .colour(IronPeopleInk.darkSea))
            // Its folds, falling from the rolled edge.
            var folds = PathData()
            for (start, end) in [(P(-6.2, -42), back + P(4, -0.6)), (P(0, -38.6), P(-2, -11.8)), (P(5.8, -34), P(6.4, -12.2)),
                                 (P(10.6, -29.4), front + P(-3.6, 0.2))] {
                folds.move(d.up(start)); folds.quad(d.up((start + end) * 0.5 + P(-2.4, 0)), end)
            }
            d.svg.path(folds, stroke: .colour(IronPeopleInk.deepSea), width: 1.1)
            // A border of the team's colour along its hem, with a key pattern in the light.
            d.svg.polygon([back + P(0.6, 0), front + P(-0.6, 0), front + P(-0.6, -4), back + P(0.8, -4)], fill: .team)
            d.svg.line([back + P(0.8, -4), front + P(-0.6, -4)], stroke: .colour(Ink.line), width: 0.8)
            var key = PathData()
            var x = back.x + 2
            while x + 3.2 <= front.x - 1.4 {
                let y = back.y + (front.y - back.y) * ((x - back.x) / (front.x - back.x)) - 1.6
                key.move(P(x, y)); key.line(P(x, y - 2.2)); key.line(P(x + 2.2, y - 2.2)); key.line(P(x + 2.2, y - 1.1))
                key.line(P(x + 1.1, y - 1.1))
                x += 3.2
            }
            d.svg.path(key, stroke: .colour(IronPeopleInk.light), width: 0.8)
            // The rolled edge, in the team's colour, edged in the light.
            let edge = [P(-10.6, -46), P(-3.4, -48.8), P(16, -29.4), P(13.4, -22.2)]
            d.band(edge)
            d.svg.line([d.up(edge[0]), d.up(edge[3])], stroke: .colour(IronPeopleInk.light), width: 1.1)
            d.svg.line([d.up(edge[1]), d.up(edge[2])], stroke: .colour(IronPeopleInk.light), width: 1.1)
            d.svg.polygon(mantle.map(d.up), fill: .none, stroke: .colour(Ink.line), width: 1.6)
            d.svg.line([d.up(edge[0]), d.up(edge[3])], stroke: .colour(Ink.line), width: 0.8)
            if pose == .working {
                d.arm(front: false)
                IronPeopleProps.scroll(&d.svg, at: Self.scrollHeld + d.chest, degrees: -28)
                let hand = d.joints.frontHand
                if Self.fingerUp.contains(frame) {
                    // The raised finger, and the point it makes.
                    d.svg.line([hand + P(0.4, -1), hand + P(0.9, -5.2)], stroke: .colour(Ink.line), width: 2.4)
                    d.svg.line([hand + P(0.4, -1), hand + P(0.9, -5)], stroke: .colour(Ink.skin), width: 1)
                    if frame == 3 || frame == 4 {
                        d.svg.path("M\(num(hand.x - 3.6)),\(num(hand.y - 7.6)) l-1.6,-1.6 M\(num(hand.x + 1)),\(num(hand.y - 9)) l0,-2.4 "
                                   + "M\(num(hand.x + 5)),\(num(hand.y - 7.4)) l1.6,-1.6", stroke: .colour(Ink.line), width: 1.1)
                    }
                }
                if Self.palmOpen.contains(frame) {
                    // The fingers spread, palm up.
                    d.svg.path("M\(num(hand.x + 1)),\(num(hand.y - 0.6)) l3,-1.6 M\(num(hand.x + 1.4)),\(num(hand.y + 0.4)) l3.4,-0.2 "
                               + "M\(num(hand.x + 1)),\(num(hand.y + 1.2)) l2.8,1.2", stroke: .colour(Ink.line), width: 1)
                }
                if frame == 6 { d.burst(at: hand + P(1, 2.4), from: 20, to: 140, size: 0.8) }
            } else {
                IronPeopleProps.scroll(&d.svg, at: d.joints.frontHand + P(0.8, -3), degrees: -74)
            }
            d.arm(front: true)
            d.head(nose: .hook, hair: { d in
                // A fringe of white hair round the back of a bald crown.
                d.svg.path("M-10.6,-63.4 C-13.2,-58 -12,-52.4 -7.6,-50 C-7.6,-53 -7.8,-56 -6.6,-58.8 C-8,-59.6 -9.6,-61.4 -10.6,-63.4 Z",
                           fill: .colour(IronPeopleInk.paleGrey), stroke: .colour(Ink.line), width: 0.8)
            }, features: { d in
                // A long white beard, falling in waves, and a moustache.
                d.svg.path("M-5.2,-54.6 C-6.4,-49 -4.4,-43.4 -0.6,-40.4 C1.6,-38.8 4,-38 6,-37.6 C6.6,-40.4 9.6,-43.2 11,-47 "
                           + "C11.6,-48.8 11.4,-50.2 10.8,-51 C8.4,-49.6 5.6,-49.6 3.4,-50.4 C0.6,-51.4 -2.4,-53 -5.2,-54.6 Z",
                           fill: .colour(IronPeopleInk.paleGrey), stroke: .colour(Ink.line), width: 1)
                d.svg.path("M-2.6,-48.4 q1.2,2 0.6,4.6 M1,-47.4 q1.4,2.4 0.8,5.4 M4.6,-47.8 q1.2,2.4 0.4,5.4 M7.8,-48.6 q0.8,2 -0.2,4",
                           stroke: .colour(IronPeopleInk.darkGrey), width: 0.7)
                d.svg.path("M3.6,-52.8 q3.8,-2 7.6,-0.2 q-1.4,1.6 -3.8,0.8 q-2.4,1 -3.8,-0.6 Z", fill: .colour(IronPeopleInk.paleGrey),
                           stroke: .colour(Ink.line), width: 0.8)
            }, brow: { d in
                // Bushy white brows, and the lines of a thinker's forehead.
                d.svg.path("M0.6,-64 q3.8,-2.6 8,-0.8", stroke: .colour(Ink.line), width: 3.2)
                d.svg.path("M0.6,-64 q3.8,-2.6 8,-0.8", stroke: .colour(IronPeopleInk.paleGrey), width: 1.8)
                d.svg.path("M-1.2,-66.4 q3,-1.1 6,-0.2", stroke: .colour(Ink.line), width: 0.8, opacity: 0.7)
            })
        }
    }
}

// MARK: - The siege engineer (engineer)

/// A broad siege engineer in a sea-green tunic with an iron-grey hem, a leather
/// apron bound at the waist with a band of the team's colour, a felt cap of the
/// team's colour, a coil of rope over his shoulder and a measuring rod painted in
/// bands thrust through his belt behind; a heavy moustache, stubble, and a scar
/// across the cheek; nose F. He carries an iron hammer; at work he drives an
/// iron spike into a squared timber bound with iron, and sparks fly at each
/// blow; fighting, he swings the hammer.
struct IronPeopleEngineer: PersonLook {
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.mouth = .hidden
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 22)
            r.mouth = .hidden
            return r
        case .working:
            let (angle, landing) = Moves.blow(frame, ready: 62, raised: 168, struck: 32, raiseFrames: 7)
            var r = Rig()
            r.backLeg = Limb(-14, 6); r.frontLeg = Limb(26, 34)
            r.lean = 17
            r.frontArm = Limb(angle, -4)
            r.backArm = Limb(32, 36)
            r.mouth = .hidden
            r.eyes = landing ? .closed : .down
            return r
        case .fighting:
            let (angle, landing) = Moves.blow(frame, ready: 80, raised: 185, struck: 70)
            var r = Rig()
            r.frontArm = Limb(angle, -6)
            r.backArm = Limb(-30 + (angle - 80) * 0.25, -10)
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

    /// The frame on which the hammer meets the spike.
    static let strike = 9

    /// The hammer's direction from the hand for a pose.
    static func hammerDegrees(_ pose: SpritePose, _ rig: Rig) -> Double {
        switch pose {
        case .working, .fighting: rig.frontArm.upper + 10
        default: rig.frontArm.upper + rig.frontArm.bend + 14
        }
    }

    /// Where the hammer's face meets the spike's head, in the picture.
    static let spikeHead: P = {
        let rig = IronPeopleEngineer().rig(.working, strike)!
        let d = Drawing(layer: .base, rig: rig, phase: 0)
        return d.world(IronPeopleProps.hammerFace(at: d.joints.frontHand, degrees: hammerDegrees(.working, rig))) + P(0, 1.2)
    }()

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        if pose == .working {
            let head = Self.spikeHead
            let top = head.y + 3.4
            IronPeopleProps.timber(&d.svg, left: head.x - 15, width: 30, height: -top)
            IronPeopleProps.spike(&d.svg, head: head, length: 3.6)
        }
        d.figure { d in
            // The coil of rope at his back hip and the rod through his belt, behind him.
            IronPeopleProps.coil(&d.svg, at: d.up(P(-14.4, -27)), rx: 4.6, ry: 7, degrees: 8)
            IronPeopleProps.rod(&d.svg, from: d.up(P(-9.6, -16)), to: d.up(P(-16.4, -58)))
            d.arm(front: false)
            d.legs()
            d.garment(colour: [P(-13, -46), P(9, -48), P(15, -13), P(-17, -12.5)],
                      outline: [P(-9, -47), P(9, -47), P(14, -15), P(-15.5, -15)], fill: .colour(IronPeopleInk.darkSea)) { d in
                d.svg.polygon([P(-15.1, -18), P(13.7, -18), P(14.6, -13.2), P(-16.6, -12.8)], fill: .colour(IronPeopleInk.grey))
                // Light stitching in rows.
                var stitches = PathData()
                for (row, y) in [-42.5, -37.5].enumerated() {
                    var x = -8.6 + (row % 2 == 0 ? 0 : 1.5)
                    while x + 1.2 <= 1 {
                        stitches.move(d.up(P(x, y))); stitches.line(d.up(P(x + 1.2, y)))
                        x += 3
                    }
                }
                d.svg.path(stitches, stroke: .colour(IronPeopleInk.paleSea), width: 0.9)
            }
            // The leather apron, from the chest to the knee, stitched round its edge.
            let apron = [P(1.4, -42), P(11, -43), P(17.4, -11), P(3, -10.4)]
            d.svg.polygon(apron.map { d.up($0) + P(-0.7, 0.6) }, fill: .colour(IronPeopleInk.leather))
            var stitching = PathData()
            for i in 0..<9 {
                let t = Double(i) / 9
                let p = apron[0] + (apron[3] - apron[0]) * t + P(1.4, 0)
                stitching.move(d.up(p)); stitching.line(d.up(p + P(0.3, 1.2)))
                let q = apron[1] + (apron[2] - apron[1]) * t + P(-1.4, 0)
                stitching.move(d.up(q)); stitching.line(d.up(q + P(0.3, 1.2)))
            }
            d.svg.path(stitching, stroke: .colour(IronPeopleInk.paleLeather), width: 0.8)
            // A pocket with a spike in it.
            d.svg.line([d.up(P(9.6, -27.4)), d.up(P(10.4, -22.6))], stroke: .colour(IronPeopleInk.iron), width: 1.4)
            d.svg.polygon([P(5.4, -24), P(12.8, -24.4), P(13.4, -17.6), P(6, -17.2)].map(d.up), fill: .colour(IronPeopleInk.darkLeather),
                          stroke: .colour(Ink.line), width: 0.9)
            d.svg.polygon(apron.map(d.up), fill: .none, stroke: .colour(Ink.line), width: 1.3)
            // The band of the team's colour that binds the apron at the waist, edged in the light, and its knot.
            d.svg.polygon([P(-12, -35.4), P(14.6, -36.4), P(15.2, -29.8), P(-12.6, -28.8)].map(d.up), fill: .colour(IronPeopleInk.light))
            d.band([P(-11.8, -34.6), P(14.4, -35.6), P(14.8, -30.6), P(-12.2, -29.6)])
            d.svg.polygon([P(-12, -35.4), P(14.6, -36.4), P(15.2, -29.8), P(-12.6, -28.8)].map(d.up), fill: .none,
                          stroke: .colour(Ink.line), width: 1)
            // The rope over the shoulder, from the coil behind.
            IronPeopleProps.rope(&d.svg, [d.up(P(5.4, -47.4)), d.up(P(1.6, -42.4)), d.up(P(-4, -36.6)), d.up(P(-12.4, -31.4))],
                                 width: 2.2)
            let hand = d.joints.frontHand
            let degrees = Self.hammerDegrees(pose, d.rig)
            IronPeopleProps.hammer(&d.svg, at: hand, degrees: degrees)
            switch pose {
            case .working:
                if frame == Self.strike || frame == Self.strike + 1 {
                    IronPeopleProps.sparks(&d.svg, at: Self.spikeHead, spread: frame == Self.strike ? 0 : 1)
                }
            case .fighting:
                if frame == 7 { d.swish(around: d.joints.frontShoulder, radius: 26, from: 165, to: 90) }
                if frame == 8 { d.impact(at: IronPeopleProps.hammerFace(at: hand, degrees: degrees), size: 0.9) }
            default:
                break
            }
            d.arm(front: true, width: 2.2)
            d.head(nose: .bulb, hair: { d in
                // Dark curls at the nape, under the cap.
                d.svg.path("M-11.2,-60.6 C-12.8,-56 -11.4,-51.4 -7.4,-49.8 C-8.2,-51.6 -7.6,-53.2 -6.4,-54.4 C-8.2,-55.2 -8.4,-57.4 -7,-59.4 Z",
                           fill: .colour(Ink.line))
            }, features: { d in
                // Stubble, a shadow along the jaw.
                d.svg.path("M-5,-54 C-4.6,-49.6 0,-47.4 5,-47.2 C8,-47.2 10.4,-48.2 11.2,-50.4 C8,-49.6 4,-50 0,-51.4 C-2,-52.2 -3.6,-53 -5,-54 Z",
                           fill: .colour(Ink.line), opacity: 0.2)
                // A scar across the cheek, stitched.
                d.svg.path("M0.6,-58.4 L5.6,-54", stroke: .colour("#9a4a32"), width: 1.1)
                d.svg.path("M1.6,-56.4 l1.4,-1.4 M3.2,-55 l1.4,-1.4", stroke: .colour("#9a4a32"), width: 0.7)
                // A heavy moustache.
                d.svg.path("M3.4,-52.8 q4,-3 8.6,-0.8 q0.4,1.4 -1,2.6 q-1.4,-1.2 -3.4,-0.6 q-2.6,0.6 -4.2,-1.2 Z", fill: .colour(Ink.line))
            }, brow: { d in
                d.svg.path("M1.2,-63.8 q3.8,-1.6 7.4,0.2", stroke: .colour(Ink.line), width: 2)
            }, over: { d in
                Self.cap(&d)
            })
        }
    }

    /// A felt cap of the team's colour with a high rounded crown and a
    /// rolled brim of the light.
    static func cap(_ d: inout Drawing) {
        BronzePeopleProps.shape(&d.svg, fill: .team, width: 1.5) { o in
            var p = PathData()
            p.move(P(-11, -60.8) + o)
            p.cubic(P(-12.4, -69.4) + o, P(-6.4, -75.6) + o, P(-0.6, -75.6) + o)
            p.cubic(P(5, -75.6) + o, P(9.4, -70.6) + o, P(10.4, -64.2) + o)
            p.cubic(P(4, -66.4) + o, P(-4, -65.2) + o, P(-11, -60.8) + o)
            p.close()
            return p
        }
        d.svg.path("M10.2,-64.6 C4,-67 -4,-65.8 -11,-61.4", stroke: .colour(Ink.line), width: 3.4)
        d.svg.path("M10.2,-64.6 C4,-67 -4,-65.8 -11,-61.4", stroke: .colour(IronPeopleInk.light), width: 1.8)
    }
}
