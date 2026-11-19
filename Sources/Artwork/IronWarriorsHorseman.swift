// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The horseman

/// A horseman: a rider on the shared figure, seated on a bay horse drawn as the
/// chariot's horses are (`BronzePeopleSteed`), over a saddle cloth of the
/// team's colour, fringed and patterned in the light, under a leather saddle
/// with horns. The rider wears an iron helmet with a cheek guard and a plume of
/// legion red, a shirt of iron mail over a sea-green tunic, and a sea-green cloak
/// that streams behind him; a heavy moustache; nose F. He carries a spear with
/// a pennant of the team's colour below its blade, and holds the reins in his
/// other hand. Standing, the horse breathes and tosses its head; walking, it
/// trots, the legs moving in diagonal pairs, and the rider rises with the
/// stride; fighting, the horse paws the ground whilst the rider raises the
/// spear overhand and drives it forward over the horse's head. The origin is
/// on the ground at the centre of the horse's hooves.
struct IronWarriorsHorseman: PersonLook {
    static let canvas = Canvas(minX: -56, minY: -146, width: 152, height: 152, pixelsPerUnit: Canvas.person.pixelsPerUnit)

    /// Where the horse stands, in its own units, so that the centre of its hooves is at the origin.
    static let horseOrigin = P(-0.8, 0)
    /// The horse is the chariot's horse drawn larger, so that it stands
    /// rightly to its rider: its withers come to about the height of a man's shoulder.
    static let horseScale = 1.3
    /// The saddle sits back from the withers, so that the rider clears the horse's neck.
    static let seatShift = P(-4.4, 0.3)

    // MARK: The rider

    /// One frame of the overhand strike: the spear hand and the spear's direction.
    static let strike: [(hand: P, degrees: Double)] = [
        (P(13, -40), 150), (P(14.4, -45), 134), (P(15.6, -49), 118), (P(16.6, -51.6), 108), (P(16.4, -53), 102), (P(16, -53.4), 102),
        (P(18.6, -52.6), 92), (P(21.6, -51.6), 86), (P(22.4, -51.2), 85), (P(20, -51.6), 90), (P(17, -47), 112), (P(14.4, -42), 138),
    ]

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        var r = Moves.standing(pose == .standing ? frame : 0)
        r.backLeg = Limb(-4, 4); r.frontLeg = Limb(34, 50)
        r.mouth = .firm
        switch pose {
        case .standing:
            r.lean = 1
            r.frontArm = BronzePeopleKit.reach(IronWarriorsKit.frontShoulder(r), P(15, -38 - r.lift))
        case .walking:
            r.lean = 4
            r.lift = 0
            r.frontArm = BronzePeopleKit.reach(IronWarriorsKit.frontShoulder(r), P(13.4, -40 + 0.6 * BronzePeopleKit.wave(frame, times: 2)))
        case .fighting:
            let s = Self.strike[frame]
            r.lift = 0
            r.lean = [2, 0, -2, -4, -5, -5, 2, 9, 10, 7, 4, 3][frame]
            r.frontArm = BronzePeopleKit.reach(IronWarriorsKit.frontShoulder(r), s.hand, elbowUp: s.hand.y < -50)
            r.mouth = frame == 7 || frame == 8 ? .shout : .firm
            r.eyes = frame == 8 ? .wide : .open
        default:
            return nil
        }
        r.backArm = BronzePeopleKit.reach(IronWarriorsKit.backShoulder(r), P(9, -33))
        return r
    }

    // MARK: The horse

    static func horse(_ pose: SpritePose, _ frame: Int) -> BronzePeopleSteed.Pose {
        let t = Double(frame) / 12
        var p = BronzePeopleSteed.Pose()
        switch pose {
        case .walking:
            // A trot: the near fore and far hind move together, then the other pair.
            func fore(_ shift: Double) -> Limb {
                let s = 2 * .pi * (t + shift)
                return Limb(5 + 22 * sin(s), 6 + 76 * pow(max(0, cos(s)), 1.4))
            }
            func hind(_ shift: Double) -> Limb {
                let s = 2 * .pi * (t + shift)
                return Limb(-12 + 19 * sin(s), 18 + 46 * pow(max(0, cos(s)), 1.4))
            }
            p.fore = fore(0); p.farHind = hind(0.02)
            p.hind = hind(0.5); p.farFore = fore(0.52)
            let s = 4 * .pi * t
            p.pitch = 1.2 * sin(s + 0.8)
            p.neck = -1.5 + 2.4 * sin(s + 1.4)
            p.tail = 0.45 + 0.2 * sin(s)
            p.mane = 0.5 + 0.35 * sin(s + 0.4)
        case .fighting:
            // The near forefoot paws the ground as the rider strikes, the head up and the ears laid back.
            let up = pow(sin(.pi * t), 2)
            p.fore = Limb(4 + 40 * up, 4 + 86 * up)
            p.farFore = Limb(3 - 2 * up, 3)
            p.hind = Limb(-16 - 3 * up, 22 + 4 * up)
            p.farHind = Limb(-14 - 3 * up, 20 + 4 * up)
            p.pitch = 4 * up
            p.neck = 4 * up
            p.tail = 0.3 * up
            p.mane = 0.5 * up
            p.mouthOpen = up > 0.5
            p.earBack = up > 0.3
        default:
            let s = 2 * .pi * t
            p.lift = 0.4 * sin(s)
            p.neck = -2 + 7 * pow(max(0, sin(s)), 3)
            p.tail = 0.25 * sin(s * 2)
            p.mane = 0.15 * sin(s)
            p.blink = frame == 5
            p.earBack = frame >= 3 && frame <= 6
        }
        return p
    }

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let horse = BronzePeopleSteed(at: Self.horseOrigin, pose: Self.horse(pose, frame), coat: "#8e5634", shade: "#5f3820")
        let k = Self.horseScale
        d.svg.ellipse(P(0, 0.2), 38, 4.2, fill: .colour("#000000"), opacity: 0.13)
        d.svg.raw("<g transform=\"scale(\(num(k)))\">")
        horse.draw(&d.svg, near: true)
        Self.saddle(&d.svg, horse)
        d.svg.raw("</g>")
        // The rider rises from the saddle with each stride of the trot.
        let rise = pose == .walking ? 1.1 + 1.1 * sin(4 * .pi * Double(frame) / 12 + 0.6) : 0
        let seat = horse.body(P(-1.6, -48.4) + Self.seatShift) * k + P(0, -rise)
        let at = seat - P(0, -15)
        Self.rider(&d, pose, frame, at: at, bit: horse.mouth * k)
        // Dust kicked up by the hooves as they strike the ground.
        if pose == .walking && frame % 6 == 1 {
            BronzePeopleProps.dust(&d.svg, at: horse.hoof(frame < 6 ? .hind : .fore) * k + P(-5, -1), size: 0.8, opacity: 0.45)
        }
        if pose == .fighting && frame == 11 {
            d.burst(at: horse.hoof(.fore) * k + P(1, -1), from: 100, to: 170, size: 0.9)
        }
    }

    /// The saddle cloth, in the team's colour with a border and a zigzag in the
    /// light and a fringe at its hem, and the leather saddle over it.
    static func saddle(_ svg: inout SVG, _ horse: BronzePeopleSteed) {
        func seatAt(_ p: P) -> P { horse.body(p + seatShift) }
        let cloth = [P(-10.4, -47.4), P(7.4, -48.6), P(9.4, -33.2), P(-11.6, -32.6)].map(seatAt)
        svg.polygon(cloth.map { $0 + P(-0.7, 0.6) }, fill: .team)
        let inner = [P(-8.8, -45.4), P(6.2, -46.4), P(7.6, -35.2), P(-10, -34.8)].map(seatAt)
        svg.polygon(inner, fill: .none, stroke: .colour(IronWarriorsInk.light), width: 1)
        var zig = PathData()
        for i in 0...8 {
            let x = -8.6 + Double(i) * 2
            let p = seatAt(P(x, -37.2 - (i % 2 == 0 ? 0 : 2.2) + x * 0.02))
            if i == 0 { zig.move(p) } else { zig.line(p) }
        }
        svg.path(zig, stroke: .colour(IronWarriorsInk.light), width: 0.9)
        svg.polygon(cloth, fill: .none, stroke: .colour(Ink.line), width: 1.3)
        var fringe = PathData()
        for i in 0..<9 {
            let x = -10.8 + Double(i) * 2.5
            let top = seatAt(P(x, -32.8 + 0.03 * x))
            fringe.move(top); fringe.line(top + P(-0.3, 2.2))
        }
        svg.path(fringe, stroke: .colour(Ink.line), width: 0.9)
        // The saddle, with a horn before and behind the seat.
        let seat = [P(-9.6, -47.6), P(-8.6, -51.6), P(-6.4, -49.6), P(3.4, -50.2), P(5.8, -52.6), P(7, -48.8), P(6.4, -46.4), P(-8.8, -45.6)]
        IronWarriorsKit.shape(&svg, seat.map(seatAt), fill: .colour(IronWarriorsInk.leather), width: 1.2)
        // The girth under the belly.
        svg.line([seatAt(P(3.4, -46.4)), seatAt(P(4.6, -27.6))], stroke: .colour(Ink.line), width: 2.2)
        svg.line([seatAt(P(3.4, -46.4)), seatAt(P(4.6, -27.6))], stroke: .colour(IronWarriorsInk.leather), width: 1)
    }

    /// The rider, his figure's origin at `at`: the cloak, the reins, the near
    /// leg down the horse's side, the mail, the spear and the head.
    static func rider(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int, at: P, bit: P) {
        let lean = d.rig.lean
        func world(_ p: P) -> P { at + p.rotated(lean, about: Drawing.hips) }
        d.svg.raw("<g transform=\"translate(\(num(at.x)),\(num(at.y))) rotate(\(num(lean)) \(num(Drawing.hips.x)) \(num(Drawing.hips.y)))\">")
        // The cloak, streaming back from the shoulders.
        let flutter: Double
        switch pose {
        case .walking: flutter = 1 + 0.5 * BronzePeopleKit.wave(frame, times: 2)
        case .fighting: flutter = 0.4 + 0.3 * BronzePeopleKit.wave(frame)
        default: flutter = 0.15 * BronzePeopleKit.wave(frame)
        }
        let neckBack = d.up(P(-4, -48.4)), shoulderBack = d.up(P(-12, -46)), under = d.up(P(-6.6, -44))
        BronzePeopleProps.shape(&d.svg, fill: .colour(IronWarriorsInk.deepSea), width: 1.3) { o in
            var p = PathData()
            p.move(neckBack + o)
            p.cubic(shoulderBack + o, P(-16 - flutter * 4, -36 + flutter) + o, P(-19 - flutter * 7, -24 - flutter * 3) + o)
            p.line(P(-15 - flutter * 6, -22.6 - flutter * 2.4) + o)
            p.line(P(-12.4 - flutter * 4, -25 - flutter * 1.6) + o)
            p.cubic(P(-11, -32) + o, P(-9.6, -40) + o, under + o)
            p.close()
            return p
        }
        d.arm(front: false)
        // The near leg, down the horse's side, in a leather boot.
        let hip = Joints.frontHip
        let knee = hip + P.direction(34) * Joints.thigh
        let foot = knee + P.direction(34 - 50) * Joints.shin
        d.svg.line([hip, knee, foot], stroke: .colour(Ink.line), width: 3.6)
        d.svg.line([hip, knee, foot], stroke: .colour(IronWarriorsInk.deepSea), width: 1.8)
        let u = P.direction(-16)
        IronWarriorsKit.shape(&d.svg, [foot - u * 5 + P(-1.6, 0), foot - u * 5 + P(1.8, 0), foot + P(5.6, 0.2), foot + P(5.2, 2), foot + P(-1.8, 1.8)],
                              fill: .colour(IronWarriorsInk.leather), width: 1.1)
        // The tunic's skirt over the thigh.
        d.garment(colour: [P(-12.4, -30), P(11.6, -30.4), P(17.4, -17.4), P(6, -14.8), P(-9.4, -19.4)],
                  outline: [P(-11, -29.6), P(11, -29.6), P(16.2, -18.4), P(5.6, -16), P(-8.6, -20.4)], fill: .colour(IronWarriorsInk.deepSea)) { d in
            d.svg.line([P(-8.2, -21.8), P(5.4, -17.4), P(15.2, -19.6)], stroke: .colour(IronWarriorsInk.paleSea), width: 1.2)
        }
        // The mail shirt: rows of iron rings.
        d.garment(colour: [P(-12.2, -46.4), P(9.2, -48.4), P(12.6, -27.4), P(-13.6, -27)],
                  outline: [P(-8.4, -47.2), P(8.8, -47.2), P(12, -28.4), P(-12.8, -28.4)], fill: .colour(IronWarriorsInk.iron)) { d in
            var rings = PathData()
            for row in 0..<6 {
                let y = -44.6 + Double(row) * 3
                let half = 8.6 + Double(row) * 0.6
                var x = -half + Double(row % 2) * 1.3
                while x < half - 0.6 {
                    let p = d.up(P(x, y))
                    rings.move(p); rings.quad(p + P(1.2, 1.6), p + P(2.4, 0))
                    x += 2.6
                }
            }
            d.svg.path(rings, stroke: .colour(IronWarriorsInk.ironDark), width: 0.7)
        }
        d.svg.line([d.up(P(-13, -28.6)), d.up(P(12.2, -28.8))], stroke: .colour(Ink.line), width: 3)
        d.svg.line([d.up(P(-12.6, -28.6)), d.up(P(11.8, -28.8))], stroke: .colour(IronWarriorsInk.leather), width: 1.6)
        // The spear.
        let hand = d.joints.frontHand
        switch pose {
        case .fighting:
            let degrees = strike[frame].degrees
            spear(&d.svg, at: hand, degrees: degrees, ahead: 44, behind: 10, flutter: Double(frame) / 12)
            let tip = hand + P.direction(degrees) * 44
            if frame == 7 {
                d.svg.path("M\(num(tip.x - 26)),\(num(tip.y - 5)) l12,1.2 M\(num(tip.x - 24)),\(num(tip.y + 2.6)) l12,1.2",
                           stroke: .colour(Ink.line), width: 1.1, opacity: 0.6)
            }
            if frame == 8 { d.impact(at: tip + P.direction(degrees) * 1.4, size: 1) }
        case .walking:
            spear(&d.svg, at: hand, degrees: 146 + BronzePeopleKit.wave(frame, times: 2), ahead: 40, behind: 16, flutter: Double(frame) / 6)
        default:
            spear(&d.svg, at: hand, degrees: 176, ahead: 44, behind: 12, flutter: Double(frame) / 12)
        }
        d.arm(front: true)
        d.head(nose: .bulb, hair: { d in
            d.svg.path("M-10.2,-55 C-11.4,-58 -11,-60.6 -9.6,-62.6 L-6.8,-58 Z", fill: .colour(Ink.line))
        }, features: { d in
            // A heavy moustache, drooping at the ends.
            d.svg.path("M3,-53.4 q4.4,-2.4 8.6,-0.6 q0.6,2.4 -0.6,4.4 q-1.4,-2.2 -3.6,-2.2 q-2.4,-0.2 -4.4,-1.6 Z", fill: .colour(Ink.line))
        }, brow: { d in
            d.svg.path("M1.4,-63.6 q3.6,-1.8 7,-0.4", stroke: .colour(Ink.line), width: 1.8)
        }, over: { d in
            IronWarriorsKit.helmet(&d, crest: .plume)
        })
        d.svg.raw("</g>")
        // The reins, from the hand to the bit.
        let reinHand = world(d.joints.backHand)
        var rein = PathData()
        rein.move(reinHand); rein.quad((reinHand + bit) * 0.5 + P(0, pose == .walking ? 1.6 : 3.4), bit)
        d.svg.path(rein, stroke: .colour(Ink.line), width: 0.9)
    }

    /// A spear through `hand`: an iron head `ahead` along `degrees`, a pennant of
    /// the team's colour below it, its butt `behind`.
    static func spear(_ svg: inout SVG, at hand: P, degrees: Double, ahead: Double, behind: Double, flutter: Double) {
        let u = P.direction(degrees), a = P(-u.y, u.x)
        let tip = hand + u * ahead, butt = hand - u * behind
        // The pennant, tied below the head and streaming back from the shaft.
        let tie = tip - u * 13
        let back = P(-1, 0.25)
        func w(_ along: Double) -> Double { 1.2 * sin(2 * .pi * flutter - along * 2.4) * along }
        let flag = [tie, tie - u * 5.6, tie - u * 5.6 + back * 11 + P(0, 1.2 + w(1)), tie - u * 2.8 + back * 7.6 + P(0, w(0.7)),
                    tie + back * 11 + P(0, -0.6 + w(1))]
        svg.polygon(flag.map { $0 + P(-0.6, 0.6) }, fill: .team)
        svg.polygon(flag, fill: .none, stroke: .colour(Ink.line), width: 1)
        svg.line([butt, tip - u * 6], stroke: .colour(Ink.line), width: 2.8)
        svg.line([butt + u * 0.6, tip - u * 6.2], stroke: .colour(IronWarriorsInk.wood), width: 1.5)
        // The iron head, long and narrow.
        let base = tip - u * 9
        IronWarriorsKit.shape(&svg, [base + a * 1.2, base + u * 4 + a * 2.2, tip, base + u * 4 - a * 2.2, base - a * 1.2],
                              fill: .colour(IronWarriorsInk.ironLight), width: 1)
        svg.line([base + u * 1, tip - u * 1.6], stroke: .colour(IronWarriorsInk.ironDark), width: 0.6)
        svg.line([butt, butt - u * 2.2], stroke: .colour(IronWarriorsInk.ironDark), width: 2.2)
    }
}
