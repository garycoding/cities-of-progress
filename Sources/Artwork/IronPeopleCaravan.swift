// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The caravan trader (merchant)

/// A caravan trader in a long sea-green robe striped with the light, a red
/// sash, a light headcloth bound with a red cord whose end falls to his
/// shoulder, a gold ring in his ear and a black pointed beard; nose A. On his
/// back a bundle of goods wrapped in the team's colour; in his back hand the
/// lead of a laden donkey that walks behind him, its saddle-cloth of the team's
/// colour. At work he tosses a gold coin, watches it turn in the air, and
/// catches it. The drawing's origin is between the trader's feet; the canvas
/// reaches back for the donkey.
struct IronPeopleTrader: PersonLook {
    /// `Canvas.person` with 56 more units behind, for the donkey: 190 by 135 pixels.
    static let canvas = Canvas(minX: -92, minY: -102, width: 152, height: 108, pixelsPerUnit: Canvas.person.pixelsPerUnit)

    /// Where the donkey stands: behind the trader and a little farther from the viewer.
    static let donkeyAt = P(-62, -3)

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(9.6, -40.4 - r.lift))
            r.backArm = Limb(-24, -16)
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 20, kneeLift: 38, armSwing: 22)
            r.lean = 4
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(10.4, -38.6))
            r.backArm = Limb(-38 + 4 * BronzePeopleKit.wave(frame), -12)
            return r
        case .working:
            var r = Moves.standing(frame)
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), Self.tossHand[frame])
            r.backArm = Limb(-24, -16)
            let coin = Self.coin(frame)
            // He follows the coin with his eyes and his head.
            r.headTilt = coin.flying ? max(-9, (coin.at.y + 50) * 0.5) : 2
            r.eyes = coin.flying ? .wide : (frame == 11 ? .closed : .down)
            r.mouth = frame >= 9 ? .smile : (coin.flying ? .murmur : .smile)
            return r
        default:
            return nil
        }
    }

    // MARK: The toss

    /// The tossing hand: dipped, flicked up on the second frame, and waiting to
    /// catch the coin as it falls back on the ninth.
    static let tossHand: [P] = [P(13.6, -36), P(14.6, -41.6), P(15, -40), P(14.6, -38.4), P(14.6, -38), P(14.8, -38.2),
                                P(15, -38.6), P(15.2, -39.2), P(15.2, -39.4), P(15, -38), P(14.2, -36.4), P(13.8, -35.6)]

    /// Where the coin is in a frame, and whether it is in the air.
    static func coin(_ frame: Int) -> (at: P, flying: Bool) {
        let hand = tossHand[frame]
        guard frame >= 2 && frame <= 8 else { return (hand + P(1.6, -2), false) }
        // Up from the hand on the second frame and back into it on the ninth.
        let t = Double(frame - 1) / 8
        let start = tossHand[1] + P(1.6, -2), end = tossHand[9] + P(1.6, -2)
        let x = mix(start.x, end.x, t) + 2.4 * sin(t * .pi)
        let y = mix(start.y, end.y, t) - 26 * 4 * t * (1 - t)
        return (P(x, y), true)
    }

    // MARK: The donkey

    /// How the donkey stands in a frame of a pose.
    static func donkeyPose(_ pose: SpritePose, _ frame: Int) -> IronPeopleDonkey.Pose {
        let t = Double(frame) / 12
        var p = IronPeopleDonkey.Pose()
        if pose == .walking {
            // A walk: each foot in turn, the hind before the fore on each side.
            func leg(_ shift: Double, fore: Bool) -> Limb {
                let phase = (t + shift).truncatingRemainder(dividingBy: 1)
                let swing = 0.36
                let reach = fore ? 22.0 : 18.0, back = fore ? -18.0 : -24.0
                if phase < swing {
                    let s = phase / swing
                    return Limb(mix(back, reach, ease(s)), (fore ? 64 : 46) * sin(.pi * s))
                }
                let s = (phase - swing) / (1 - swing)
                return Limb(mix(reach, back, s), fore ? 2 : 6)
            }
            p.nearHind = leg(0, fore: false); p.nearFore = leg(0.25, fore: true)
            p.farHind = leg(0.5, fore: false); p.farFore = leg(0.75, fore: true)
            p.neck = 3 * sin(4 * .pi * t)
            p.tail = 0.6 * sin(2 * .pi * t)
            p.lift = 0.5 * sin(4 * .pi * t)
        } else {
            let s = 2 * .pi * t
            p.lift = 0.35 * sin(s)
            p.neck = 2 + 2.6 * pow(max(0, sin(s + 0.8)), 3)
            p.tail = sin(s)
            p.earFlick = frame >= 4 && frame <= 6 ? (frame == 5 ? 1 : 0.6) : 0
            p.blink = frame == 7
        }
        return p
    }

    // MARK: Drawing

    /// The trader's robe: wide at the hem, its back swinging with the stride.
    static func robe(_ d: Drawing, _ o: P, sway: Double) -> PathData {
        func at(_ p: P) -> P { d.up(p) + o }
        var p = PathData()
        p.move(at(P(-8.4, -47)))
        p.line(at(P(8.6, -47)))
        p.cubic(at(P(11.6, -40)), at(P(13.4, -24)), at(P(15.6 - sway * 1.6, -6)))
        p.line(at(P(-16 - sway * 1.6, -6)))
        p.cubic(at(P(-13.4, -24)), at(P(-11.6, -40)), at(P(-8.4, -47)))
        p.close()
        return p
    }

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let donkey = IronPeopleDonkey(at: Self.donkeyAt, pose: Self.donkeyPose(pose, frame))
        donkey.draw(&d.svg)
        // The lead, from his back hand to the donkey's halter.
        let hand = d.world(d.joints.backHand)
        var lead = PathData()
        let slack = pose == .walking ? 2.4 : 5
        lead.move(hand); lead.quad((hand + donkey.halter) * 0.5 + P(0, slack), donkey.halter)
        d.svg.path(lead, stroke: .colour(Ink.line), width: 1.6)
        d.svg.path(lead, stroke: .colour(IronPeopleInk.red), width: 0.7)
        let sway = d.rig.sway
        let bounce = pose == .walking ? 1.2 * BronzePeopleKit.wave(frame, -0.2, times: 2) : 0.3 * BronzePeopleKit.wave(frame)
        d.figure { d in
            // The bundle on his back.
            IronPeopleProps.pack(&d.svg, at: d.up(P(-15.8, -43.6)) + P(0, bounce), width: 11, height: 15, degrees: -6)
            d.arm(front: false)
            d.legs()
            d.svg.path(Self.robe(d, P(-1, 1), sway: sway), fill: .colour(IronPeopleInk.darkSea))
            // Stripes of the light down the robe.
            var stripes = PathData()
            for x in [-9.0, -4.4, 0.2, 4.8, 9.4] {
                let spread = x / 9.4
                stripes.move(d.up(P(x * 0.8, -45))); stripes.line(P(x + spread * 4 - sway * 1.4 * (1 - abs(spread) * 0.2), -7))
            }
            d.svg.path(stripes, stroke: .colour(IronPeopleInk.paleSea), width: 1.2)
            d.svg.path(Self.robe(d, P(0, 0), sway: sway), stroke: .colour(Ink.line), width: 1.8)
            // The red sash, its ends hanging at the front.
            d.svg.polygon([P(-12.4, -32), P(12.2, -32.8), P(12.8, -27.4), P(-13, -26.6)].map(d.up), fill: .colour(IronPeopleInk.red),
                          stroke: .colour(Ink.line), width: 0.9)
            d.svg.polygon([P(9.6, -28), P(11.8, -28), P(13.4 - sway, -18.6), P(11, -18.4)], fill: .colour(IronPeopleInk.red),
                          stroke: .colour(Ink.line), width: 0.8)
            IronPeopleProps.purse(&d.svg, at: d.up(P(4, -27.6)))
            // The bundle's strap, over the shoulder.
            d.svg.line([d.up(P(-11, -50)), d.up(P(-4, -47.4)), d.up(P(4.4, -45)), d.up(P(9.6, -38))],
                       stroke: .colour(IronPeopleInk.leather), width: 1.9)
            if pose == .working {
                let coin = Self.coin(frame)
                let turn = Double(frame) * .pi / 3.4
                IronPeopleProps.coin(&d.svg, at: coin.at, face: coin.flying ? cos(turn) : 1)
                if frame == 9 { d.svg.path("M\(num(coin.at.x - 3.4)),\(num(coin.at.y - 3)) l-1.4,-1.4 M\(num(coin.at.x + 3.6)),\(num(coin.at.y - 3)) l1.4,-1.4",
                                           stroke: .colour(Ink.line), width: 0.9) }
            }
            d.arm(front: true)
            let flutter = pose == .walking ? BronzePeopleKit.wave(frame, times: 2) : 0.3 * BronzePeopleKit.wave(frame)
            d.head(nose: .curve, behind: { d in
                // The headcloth falling to the shoulder behind.
                BronzePeopleProps.shape(&d.svg, fill: .colour(IronPeopleInk.light), width: 1.3) { o in
                    var p = PathData()
                    p.move(P(-10.4, -62) + o)
                    p.cubic(P(-13.4, -56) + o, P(-14.6 - flutter, -50) + o, P(-13.6 - flutter * 1.4, -44.6) + o)
                    p.line(P(-7.4, -46.4) + o)
                    p.cubic(P(-8.4, -51) + o, P(-7.6, -55) + o, P(-5.6, -58) + o)
                    p.close()
                    return p
                }
                d.svg.path("M\(num(-12.6 - flutter)),-47.6 l4.6,-1", stroke: .colour(IronPeopleInk.red), width: 1)
            }, hair: { d in
                d.svg.path("M-9.4,-58.6 C-10.4,-55.4 -9.6,-52.4 -7.2,-50.6 C-7.6,-53 -7.2,-55.4 -6,-57.4 Z", fill: .colour(Ink.line))
            }, features: { d in
                // A black beard, trimmed to a point, and a moustache.
                d.svg.path("M-5.2,-54.2 C-5.8,-49.4 -3.4,-45.6 1,-43.6 C3.6,-42.4 6.4,-41.2 8.8,-38.6 C8.8,-42 10.6,-45.2 11.2,-49.4 "
                           + "C9,-48.6 6.4,-48.8 4.4,-49.6 C1.2,-50.8 -2,-52.6 -5.2,-54.2 Z", fill: .colour(Ink.line))
                d.svg.path("M4,-52.6 q3.6,-2.2 7.4,-0.4 q-1.2,1.8 -3.6,1 q-2.4,0.8 -3.8,-0.6 Z", fill: .colour(Ink.line))
            }, brow: { d in
                d.svg.path("M1.4,-63.4 q3.4,-2.2 7.2,-0.8", stroke: .colour(Ink.line), width: 1.7)
            }, over: { d in
                // The headcloth over the crown, bound with a doubled red cord.
                BronzePeopleProps.shape(&d.svg, fill: .colour(IronPeopleInk.light), width: 1.5) { o in
                    var p = PathData()
                    p.move(P(-11.2, -57) + o)
                    p.cubic(P(-13, -70) + o, P(4, -76.4) + o, P(11, -64.4) + o)
                    p.cubic(P(10.4, -63) + o, P(9.4, -62.6) + o, P(8.4, -62.8) + o)
                    p.cubic(P(2, -65) + o, P(-4.6, -63.6) + o, P(-7, -58) + o)
                    p.close()
                    return p
                }
                d.svg.path("M10.2,-66.2 C3.6,-69.4 -4.6,-68.6 -11.2,-63", stroke: .colour(Ink.line), width: 2.8)
                d.svg.path("M10.2,-66.2 C3.6,-69.4 -4.6,-68.6 -11.2,-63", stroke: .colour(IronPeopleInk.red), width: 1.5)
                // A gold ring in the ear.
                d.svg.circle(P(-9.6, -53.6), 1.5, fill: .none, stroke: .colour(Ink.line), width: 1.7)
                d.svg.circle(P(-9.6, -53.6), 1.5, fill: .none, stroke: .colour(IronPeopleInk.gold), width: 0.9)
            })
        }
    }
}

/// A donkey laden for the road, drawn from the side facing right: a grey coat
/// with a pale muzzle, belly and eye ring, a dark stripe over the shoulder,
/// long ears, a short upright mane and a tufted tail; a red halter; a
/// saddle-cloth of the team's colour with a wicker pannier and a striped roll
/// on it. Its legs are jointed like a horse's and its lower hoof rests on the
/// ground. Its local origin is on the ground under the middle of its body.
struct IronPeopleDonkey {
    struct Pose {
        var nearFore = Limb(3, 2), nearHind = Limb(-3, 4)
        var farFore = Limb(-1, 2), farHind = Limb(2, 4)
        var lift = 0.0
        /// The neck's turn in degrees about its base; positive lowers the head.
        var neck = 0.0
        /// The tail's swing, from -1 to 1.
        var tail = 0.0
        /// How far the near ear is turned back, from 0 to 1.
        var earFlick = 0.0
        var blink = false
    }

    static let foreHip = P(10.4, -26.6), hindHip = P(-11.6, -27.4)
    static let farOffset = P(2.2, -0.8)
    static let upper = 13.6, lower = 13.6
    static let neckBase = P(13, -34)
    static let coat = "#9a948b", shade = "#6d675f", pale = "#e2dbcd", dark = "#4e4943"

    let origin: P
    let pose: Pose
    private(set) var bob = 0.0

    init(at origin: P, pose: Pose) {
        self.origin = origin; self.pose = pose
        let lowest = [Leg.fore, .hind].flatMap { kind in [false, true].map { Self.leg(self, kind, far: $0, bob: 0).hoof.y } }.max() ?? 0
        bob = origin.y - lowest
    }

    enum Leg { case fore, hind }

    /// A point of the body, from the donkey's local units to the picture.
    func body(_ p: P, bob b: Double? = nil) -> P { origin + p + P(0, -pose.lift + (b ?? bob)) }

    /// A point of the neck or head, turned with the neck.
    func head(_ p: P) -> P { body(p.rotated(pose.neck, about: Self.neckBase)) }

    /// The ring of the halter, where the lead is tied.
    var halter: P { head(P(30.6, -40.4)) }

    static func leg(_ donkey: IronPeopleDonkey, _ kind: Leg, far: Bool, bob: Double) -> (top: P, joint: P, hoof: P) {
        let hip = (kind == .fore ? foreHip : hindHip) + (far ? farOffset : P(0, 0))
        let limb = kind == .fore ? (far ? donkey.pose.farFore : donkey.pose.nearFore) : (far ? donkey.pose.farHind : donkey.pose.nearHind)
        let top = donkey.body(hip, bob: bob)
        let joint = top + P.direction(limb.upper) * upper
        let hoof = joint + P.direction(kind == .fore ? limb.upper - limb.bend : limb.upper + limb.bend) * lower
        return (top, joint, hoof)
    }

    func drawLeg(_ svg: inout SVG, _ kind: Leg, far: Bool) {
        let (top, joint, hoof) = Self.leg(self, kind, far: far, bob: bob)
        let colour = far ? Self.shade : Self.coat
        let u = P.direction(BronzePeopleKit.degrees(from: joint, to: hoof)), a = P(-u.y, u.x)
        let fetlock = hoof - u * 2.2
        svg.line([top, joint], stroke: .colour(Ink.line), width: 4.6)
        svg.line([joint, fetlock], stroke: .colour(Ink.line), width: 3.2)
        svg.line([top, joint], stroke: .colour(colour), width: 2.9)
        svg.line([joint, fetlock], stroke: .colour(colour), width: 1.6)
        svg.circle(joint, 1.2, fill: .colour(colour))
        // The pale stocking above a small dark hoof.
        svg.line([fetlock - u * 2.6, fetlock], stroke: .colour(far ? Self.coat : Self.pale), width: 1.6)
        svg.polygon([fetlock - a * 1.2, fetlock + a * 1.4, hoof + a * 2 + u * 0.5, hoof - a * 1.4 + u * 0.5], fill: .colour(Ink.line))
    }

    func draw(_ svg: inout SVG) {
        svg.ellipse(origin + P(2, 0.2), 26, 3.4, fill: .colour("#000000"), opacity: 0.13)
        drawLeg(&svg, .fore, far: true)
        drawLeg(&svg, .hind, far: true)
        let line = Paint.colour(Ink.line)
        svg.raw("<g transform=\"translate(\(num(origin.x)),\(num(origin.y + bob - pose.lift)))\">")
        // The tail: a thin rope of hair ending in a dark tuft, swinging.
        let swing = pose.tail * 3
        var tail = PathData()
        tail.move(P(-17.4, -36.6)); tail.cubic(P(-21, -34), P(-21 - swing * 0.4, -28), P(-20.4 - swing, -21.6))
        svg.path(tail, stroke: line, width: 2.6)
        svg.path(tail, stroke: .colour(Self.coat), width: 1.2)
        svg.group(turned: swing * 4, about: P(-20.4 - swing, -21.6)) { svg in
            svg.ellipse(P(-20.6 - swing, -18.6), 2, 3.6, fill: .colour(Self.dark), stroke: line, width: 0.9)
        }
        // The barrel.
        func barrel(_ o: P) -> PathData {
            var p = PathData()
            p.move(P(-18, -35.6) + o)
            p.cubic(P(-18.6, -41) + o, P(-12, -42.2) + o, P(-4, -40.6) + o)
            p.cubic(P(4, -39.6) + o, P(10, -42.2) + o, P(15, -39.4) + o)
            p.cubic(P(19.2, -36.4) + o, P(18.4, -28.4) + o, P(13.4, -25.6) + o)
            p.cubic(P(6, -23.4) + o, P(-6, -23.8) + o, P(-12.2, -25.6) + o)
            p.cubic(P(-16.4, -27) + o, P(-18.6, -30.6) + o, P(-18, -35.6) + o)
            p.close()
            return p
        }
        svg.path(barrel(P(-0.8, 0.7)), fill: .colour(Self.coat))
        // The pale belly.
        svg.path("M-11.4,-26.4 C-5,-24.4 6,-24.2 12.4,-26.4 C8,-23.6 -6,-23.2 -11.4,-26.4 Z", fill: .colour(Self.pale))
        svg.path("M-16.4,-34 C-15.6,-38.6 -12,-40 -8.6,-39.2", stroke: .colour(Self.shade), width: 1.1)
        svg.path(barrel(P(0, 0)), stroke: line, width: 1.6)
        // The load: a saddle-cloth of the team's colour, fringed, bordered in the light.
        let cloth = [P(-12.6, -41.6), P(7, -41.4), P(8.8, -28.4), P(-12.8, -28.6)]
        svg.polygon([P(-13.2, -40.8), P(6.4, -40.6), P(8.2, -27.8), P(-13.4, -27.8)], fill: .team)
        svg.line([P(-12.6, -30.6), P(8.4, -30.4)], stroke: .colour(IronPeopleInk.light), width: 1.2)
        svg.polygon(cloth, fill: .none, stroke: line, width: 1.2)
        var fringe = PathData()
        var x = -12
        while x <= 8 {
            fringe.move(P(Double(x), -28.4)); fringe.line(P(Double(x) - 0.3, -26.2))
            x += 2
        }
        svg.path(fringe, stroke: line, width: 0.9)
        // The girth, under the belly.
        svg.line([P(-1.6, -41), P(-1.2, -24.6)], stroke: .colour(IronPeopleInk.leather), width: 1.8)
        // A wicker pannier on the near side, an amphora's neck standing out of it.
        let amphora = P(-1.6, -44.4)
        BronzePeopleProps.shape(&svg, [amphora + P(-1.4, 0), amphora + P(1.4, 0), amphora + P(1.8, 5), amphora + P(-1.8, 5)],
                                fill: .colour(IronPeopleInk.paleRed), width: 1)
        svg.ellipse(amphora, 2.2, 0.9, fill: .colour(IronPeopleInk.paleRed), stroke: line, width: 0.9)
        IronPeopleProps.basket(&svg, rim: P(-3, -38.6), width: 14, height: 10, handle: false)
        // A striped roll across the back, behind the pannier.
        svg.path(BronzePeopleProps.rounded(P(-11, -43.4), width: 9, height: 5, radius: 2.4, degrees: -4, shift: P(-0.6, 0.5)),
                 fill: .colour(IronPeopleInk.light))
        svg.line([P(-13.2, -45.6), P(-13.4, -41.2)], stroke: .colour(IronPeopleInk.red), width: 1.3)
        svg.line([P(-9.2, -45.8), P(-9.4, -41.4)], stroke: .colour(IronPeopleInk.red), width: 1.3)
        svg.path(BronzePeopleProps.rounded(P(-11, -43.4), width: 9, height: 5, radius: 2.4, degrees: -4, shift: P(0, 0)),
                 stroke: line, width: 1)
        // The neck and head, turned together about the neck's base.
        svg.raw("<g transform=\"rotate(\(num(pose.neck)) \(num(Self.neckBase.x)) \(num(Self.neckBase.y)))\">")
        // The far ear, behind the head.
        Self.ear(&svg, base: P(20.6, -52.4), degrees: -14, colour: Self.shade)
        func neck(_ o: P) -> PathData {
            var p = PathData()
            p.move(P(8, -40.6) + o)
            p.cubic(P(12, -46) + o, P(16.4, -50.6) + o, P(21, -53) + o)
            p.line(P(25.4, -45.4) + o)
            p.cubic(P(22.6, -40) + o, P(20.4, -33.6) + o, P(17.6, -28.6) + o)
            p.close()
            return p
        }
        svg.path(neck(P(-0.8, 0.7)), fill: .colour(Self.coat))
        // The stripe down the shoulder.
        svg.path("M10.6,-41.4 C12.6,-38 13.6,-35 14,-31", stroke: .colour(Self.dark), width: 1.6)
        svg.path(neck(P(0, 0)), stroke: line, width: 1.5)
        // The mane: a short upright brush along the crest.
        var mane = PathData()
        mane.move(P(8.6, -41.2))
        for i in 1...7 {
            let t = Double(i) / 7
            let base = P(8.6, -41.2) + (P(21, -53.4) - P(8.6, -41.2)) * t
            let tip = base + P(-1.8, -2.6)
            mane.line(base + (P(-1.2, -1.8) - P(0, 0)) * 0.3)
            mane.line(tip)
        }
        mane.line(P(21, -53.4))
        mane.close()
        svg.path(mane, fill: .colour(Self.dark), stroke: line, width: 0.8)
        // The head: long, with a heavy jaw and a pale muzzle.
        func skull(_ o: P) -> PathData {
            var p = PathData()
            p.move(P(20.4, -53.4) + o)
            p.cubic(P(25.4, -55.8) + o, P(31.2, -50.6) + o, P(34.8, -45.6) + o)
            p.cubic(P(37.2, -42.4) + o, P(36.4, -38.6) + o, P(33.2, -38.4) + o)
            p.cubic(P(30.4, -38.2) + o, P(27.4, -39.4) + o, P(25, -41.8) + o)
            p.cubic(P(22, -44.4) + o, P(19.8, -48.4) + o, P(20.4, -53.4) + o)
            p.close()
            return p
        }
        svg.path(skull(P(-0.6, 0.6)), fill: .colour(Self.coat))
        svg.path("M30.6,-46.6 C33.6,-46.6 36.4,-44 36.4,-41.2 C36.2,-38.8 34.4,-38.4 32.6,-38.6 C30,-39 29,-41.6 29.2,-43.6 "
                 + "C29.4,-45.2 29.8,-46.4 30.6,-46.6 Z", fill: .colour(Self.pale))
        svg.path("M23.4,-47.4 C24.4,-44.6 26.6,-43 28.4,-43", stroke: .colour(Self.shade), width: 1)
        svg.path(skull(P(0, 0)), stroke: line, width: 1.5)
        svg.circle(P(35.2, -42.6), 0.6, fill: line)
        svg.path("M33.8,-39.6 q1.2,0.2 2,-0.6", stroke: line, width: 0.8)
        // The near ear, flicked back now and then.
        Self.ear(&svg, base: P(22.4, -53), degrees: -4 - 40 * pose.earFlick, colour: Self.coat)
        // The halter of red rope, with a ring for the lead.
        svg.path("M23.6,-51.2 L30.4,-41.2 M32.6,-47 L29,-40", stroke: line, width: 1.8)
        svg.path("M23.6,-51.2 L30.4,-41.2 M32.6,-47 L29,-40", stroke: .colour(IronPeopleInk.red), width: 0.9)
        svg.circle(P(30.6, -40.4), 1.1, fill: .none, stroke: .colour(IronPeopleInk.iron), width: 0.8)
        // The eye in its pale ring.
        svg.circle(P(26.2, -49.8), 2.4, fill: .colour(Self.pale))
        if pose.blink {
            svg.path("M24.8,-49.8 h2.8", stroke: line, width: 1)
        } else {
            svg.circle(P(26.4, -49.8), 1.4, fill: .colour(Ink.eyeWhite), stroke: line, width: 0.7)
            svg.circle(P(26.8, -49.7), 0.7, fill: line)
        }
        svg.raw("</g>")
        svg.raw("</g>")
        drawLeg(&svg, .fore, far: false)
        drawLeg(&svg, .hind, far: false)
    }

    /// A long ear standing from `base`, turned by `degrees` (negative leans it back).
    static func ear(_ svg: inout SVG, base: P, degrees: Double, colour: String) {
        svg.group(turned: degrees, about: base) { svg in
            func leaf(_ o: P) -> PathData {
                var p = PathData()
                p.move(base + P(-1.8, 0.6) + o)
                p.quad(base + P(-3.4, -8) + o, base + P(-0.6, -14) + o)
                p.quad(base + P(2.8, -8) + o, base + P(2, 0.4) + o)
                p.close()
                return p
            }
            svg.path(leaf(P(-0.5, 0.5)), fill: .colour(colour))
            svg.path(leaf(P(0, 0)), stroke: .colour(Ink.line), width: 1.2)
            svg.path("M\(num(base.x - 0.4)),\(num(base.y - 2)) q-0.8,-5 0,-9", stroke: .colour(Self.dark), width: 1)
        }
    }
}
