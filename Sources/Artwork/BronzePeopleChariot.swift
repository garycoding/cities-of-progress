// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The chariot

/// A war chariot: two horses under a yoke, drawing a two-wheeled car whose
/// side panel is painted in the team's colour, with plumes of the same colour on
/// the horses' heads. The driver, built on the shared figure, wears a light
/// tunic with the team's sash and a headband whose ends stream behind him; nose
/// E. Standing, the horses breathe and toss their heads; moving, they gallop and
/// the four-spoked wheels turn; fighting, the horses rear and strike with their
/// forefeet whilst the driver swings a bronze sickle-sword (a khopesh). The
/// drawing's origin is on the ground under the axle, where the near wheel meets it.
struct BronzePeopleChariot: PersonLook {
    /// The ground under the axle at the origin; the horses run 110 units ahead.
    static let canvas = Canvas(minX: -32, minY: -108, width: 144, height: 116, pixelsPerUnit: Canvas.person.pixelsPerUnit)

    static let wheelRadius = 14.0
    /// The car's floor, on which the driver stands.
    static let floor = -15.6
    /// Where each horse stands: the near one, and the far one a little behind it and ahead.
    static let nearHorse = P(60, 0), farHorse = P(66.4, -4.4)
    /// The wheels turn this many degrees a frame when moving: under half the
    /// 90 degrees between spokes, so that they never seem to turn backward, and a
    /// whole turn in the 12 frames, so that the cycle repeats without a jump.
    static let turn = 30.0

    // MARK: The driver

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing, .working:
            var r = Moves.standing(frame)
            r.lean = 2
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(14.4, -40.4 - r.lift))
            r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(6.6, -40 - r.lift))
            r.mouth = .firm
            return r
        case .walking:
            var r = Moves.standing(0)
            let shake = 0.6 * BronzePeopleKit.wave(frame, times: 2)
            r.lean = 9
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(16, -42.6 + shake))
            r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(7.4, -42 + shake))
            r.mouth = .open
            return r
        case .fighting:
            let (angle, landing) = Moves.blow(frame, ready: 70, raised: 192, struck: 58)
            var r = Moves.standing(0)
            r.frontArm = Limb(angle, -8)
            r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(6.6, -41))
            r.lean = frame < 6 ? -4 : (frame <= 9 ? 8 : 2)
            r.mouth = frame >= 6 && frame <= 8 ? .shout : .firm
            r.eyes = landing ? .wide : .open
            return r
        default:
            return nil
        }
    }

    // MARK: The horses

    /// How the near and far horse stand in a frame of a pose.
    static func horses(_ pose: SpritePose, _ frame: Int) -> (near: BronzePeopleSteed.Pose, far: BronzePeopleSteed.Pose) {
        let t = Double(frame) / 12
        func gallop(_ shift: Double) -> BronzePeopleSteed.Pose {
            var p = BronzePeopleSteed.Pose()
            func fore(_ phase: Double) -> Limb {
                let s = 2 * .pi * (t + shift + phase)
                return Limb(6 + 34 * sin(s), 6 + 84 * pow(max(0, cos(s)), 1.3))
            }
            func hind(_ phase: Double) -> Limb {
                let s = 2 * .pi * (t + shift + phase)
                return Limb(-12 + 30 * sin(s), 18 + 52 * pow(max(0, cos(s)), 1.3))
            }
            p.hind = hind(0); p.farHind = hind(0.1); p.fore = fore(0.42); p.farFore = fore(0.52)
            let s = 2 * .pi * (t + shift)
            p.lift = 2.2 + 1.8 * sin(s + 0.6)
            p.pitch = 3.4 * sin(s + 2.2)
            p.neck = -3 + 5 * sin(s + 1.2)
            p.tail = 0.8 + 0.2 * sin(s * 2)
            p.mane = 1 + 0.5 * sin(s * 2 + 0.4)
            p.mouthOpen = true
            return p
        }
        func stand(_ shift: Double, toss: Bool) -> BronzePeopleSteed.Pose {
            var p = BronzePeopleSteed.Pose()
            let s = 2 * .pi * (t + shift)
            p.lift = 0.4 * sin(s)
            p.neck = toss ? -2 + 7 * pow(max(0, sin(s)), 3) : 1.5 * sin(s)
            p.tail = 0.25 * sin(s * 2)
            p.mane = 0.15 * sin(s)
            p.blink = frame == (toss ? 5 : 9)
            p.earBack = toss && frame >= 3 && frame <= 6
            return p
        }
        func rear(_ shift: Double) -> BronzePeopleSteed.Pose {
            var p = BronzePeopleSteed.Pose()
            let s = 2 * .pi * (t + shift)
            let up = (1 - cos(s)) / 2
            p.pitch = 16 * up
            p.lift = 1.6 * up
            p.neck = -6 * up
            p.hind = Limb(-6 - 10 * up, 30 * up + 18)
            p.farHind = Limb(-4 - 10 * up, 30 * up + 18)
            p.fore = Limb(6 + 64 * up + 14 * up * sin(s * 2), 6 + 110 * up)
            p.farFore = Limb(6 + 58 * up + 14 * up * sin(s * 2 + 1.6), 6 + 104 * up)
            p.tail = 0.5 * up
            p.mane = 0.7 * up
            p.mouthOpen = up > 0.4
            p.earBack = up > 0.5
            return p
        }
        switch pose {
        case .walking: return (gallop(0), gallop(0.06))
        case .fighting: return (rear(0), rear(0.05))
        default: return (stand(0, toss: true), stand(0.35, toss: false))
        }
    }

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let (nearPose, farPose) = Self.horses(pose, frame)
        let near = BronzePeopleSteed(at: Self.nearHorse, pose: nearPose, coat: "#a8643a", shade: "#7e4626")
        let far = BronzePeopleSteed(at: Self.farHorse, pose: farPose, coat: "#6f3d22", shade: "#4f2a17")
        // Rolling forward (to the right), the wheels turn clockwise: their angle falls.
        let spin = pose == .walking ? -Double(frame) * Self.turn : (pose == .fighting ? 4 * BronzePeopleKit.wave(frame) : 0)
        let bounce = pose == .walking ? 0.7 * abs(BronzePeopleKit.wave(frame, 0.1, times: 1)) : 0
        // The shadow on the ground, under the car and the team.
        d.svg.ellipse(P(42, 0.2), 62, 4.4, fill: .colour("#000000"), opacity: 0.13)
        Self.wheel(&d.svg, at: P(4.6, -Self.wheelRadius - 3.6), degrees: spin + 20, far: true)
        far.draw(&d.svg, near: false)
        // The pole, from under the car to the yoke on the horses' withers.
        let yoke = near.withers + P(1.4, -0.6)
        var pole = PathData()
        pole.move(P(12, -14.8 - bounce)); pole.quad(P(40, -15 - bounce), yoke)
        d.svg.path(pole, stroke: .colour(Ink.line), width: 3.2)
        d.svg.path(pole, stroke: .colour(BronzePeopleInk.wood), width: 1.8)
        Self.driver(&d, pose, frame, rise: bounce)
        Self.car(&d.svg, rise: bounce)
        near.draw(&d.svg, near: true)
        // The yoke saddle on the near horse's withers.
        d.svg.polygon([yoke + P(-3.4, 2.4), yoke + P(0, -2.4), yoke + P(3.4, 2.4), yoke + P(0, 0.6)], fill: .colour(BronzePeopleInk.bronze),
                      stroke: .colour(Ink.line), width: 1)
        Self.wheel(&d.svg, at: P(0, -Self.wheelRadius), degrees: spin, far: false)
        // The reins, from the driver's hands to each horse's bit.
        let place = Self.place(rise: bounce)
        let front = d.world(d.joints.frontHand) + place, back = d.world(d.joints.backHand) + place
        let slack = pose == .walking ? 0.6 : 4
        let reinHands = pose == .fighting ? [back, back] : [front, back]
        for (hand, bit) in zip(reinHands, [near.mouth, far.mouth]) {
            var rein = PathData()
            rein.move(hand); rein.quad((hand + bit) * 0.5 + P(0, slack), bit)
            d.svg.path(rein, stroke: .colour(Ink.line), width: 0.9)
        }
        // Dust thrown up by the hooves at the gallop, and by the forefeet as they come down.
        if pose == .walking && (frame % 6 == 2 || frame % 6 == 3) {
            BronzePeopleProps.dust(&d.svg, at: near.hoof(.hind) + P(-5, -1), size: frame % 6 == 2 ? 0.8 : 1.1, opacity: 0.5)
        }
        if pose == .fighting && (frame == 0 || frame == 11) {
            for hoof in [near.hoof(.fore), far.hoof(.fore)] { d.burst(at: hoof + P(1, -1), from: 100, to: 170, size: 0.9) }
        }
    }

    /// Where the driver's figure stands, beyond its own lean and bob: on the car's floor.
    static func place(rise: Double) -> P { P(-1, floor - rise) }

    /// The driver, standing on the car's floor: only what shows above its side.
    static func driver(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int, rise: Double) {
        let at = place(rise: rise) + P(0, d.bob)
        d.svg.raw("<g transform=\"translate(\(num(at.x)),\(num(at.y))) rotate(\(num(d.rig.lean)) \(num(Drawing.hips.x)) \(num(Drawing.hips.y)))\">")
        d.arm(front: false)
        d.garment(colour: [P(-11.6, -46), P(8.6, -48), P(12.4, -18), P(-13.4, -17.4)],
                  outline: [P(-8, -47), P(8.4, -47), P(11.4, -19.4), P(-12, -19.4)], fill: .colour(BronzePeopleInk.light)) { d in
            d.band([P(-9.4, -44.4), P(-4.6, -47.6), P(11.8, -26.8), P(10.8, -21.6)])
        }
        let hand = d.joints.frontHand
        if pose == .fighting {
            let degrees = d.rig.frontArm.upper - 4
            khopesh(&d.svg, at: hand, degrees: degrees)
            if frame == 7 { d.swish(around: d.joints.frontShoulder, radius: 25, from: 175, to: 80) }
            if frame == 8 { d.impact(at: hand + P.direction(degrees) * 15, size: 1) }
        }
        d.arm(front: true)
        let flutter = pose == .walking ? 2.6 + BronzePeopleKit.wave(frame, times: 3) : 0.6 * BronzePeopleKit.wave(frame)
        d.head(nose: .line, behind: { d in
            for (dy, length) in [(0.0, 10.0), (1.6, 8.0)] {
                let top = P(-10.8, -62.6 + dy)
                let end = top + P(-length + flutter * 0.4, 3.6 - flutter * 1.3 + dy)
                d.svg.polygon([top + P(0, -1), top + P(0, 1), end + P(0, 0.6), end + P(0, -0.6)],
                              fill: .colour(BronzePeopleInk.verdigris), stroke: .colour(Ink.line), width: 0.8)
            }
        }, hair: { d in
            d.svg.path("M-9.8,-59.6 C-10.8,-70.8 4.2,-72.8 9,-65.4 C3.2,-67.6 -1.8,-64.8 -4,-59.4 C-6,-57.2 -8.2,-57.6 -9.8,-59.6 Z",
                       fill: .colour(Ink.line))
        }, features: { d in
            // A short pointed beard.
            d.svg.path("M2.6,-50 C3.6,-46.4 6,-44.6 8.6,-44.2 C8.8,-46.4 9.4,-48.6 10.6,-50.2 C8,-49.2 5.2,-49.2 2.6,-50 Z", fill: .colour(Ink.line))
        }, brow: { d in
            d.svg.path("M1.8,-63.8 q3.2,-1.6 6.4,-0.6", stroke: .colour(Ink.line), width: 1.4)
        }, over: { d in
            d.svg.path("M-10.8,-61.8 Q-1,-67.8 10.2,-65.6", stroke: .colour(Ink.line), width: 3.4)
            d.svg.path("M-10.8,-61.8 Q-1,-67.8 10.2,-65.6", stroke: .colour(BronzePeopleInk.verdigris), width: 1.8)
        })
        d.svg.raw("</g>")
    }

    /// The car: a floor on the axle and a side panel of the team's colour,
    /// bordered in the light and studded with bronze, rising to a curved front.
    static func car(_ svg: inout SVG, rise: Double) {
        func outline(_ o: P) -> PathData {
            var p = PathData()
            p.move(P(-13, floor) + o)
            p.line(P(14.6, floor) + o)
            p.cubic(P(18.2, -22.6) + o, P(18.4, -35.6) + o, P(12.8, -42.4) + o)
            p.line(P(-6.6, -38.8) + o)
            p.cubic(P(-10.6, -38.4) + o, P(-13.2, -35.6) + o, P(-13, -31.6) + o)
            p.close()
            return p
        }
        let up = P(0, -rise)
        svg.path(outline(up + P(-0.8, 0.7)), fill: .team)
        var border = PathData()
        border.move(P(-10.6, floor - 2.4) + up)
        border.line(P(12.6, floor - 2.4) + up)
        border.cubic(P(15.4, -23.6) + up, P(15.6, -34) + up, P(11.6, -39.6) + up)
        border.line(P(-6.2, -36.4) + up)
        border.cubic(P(-9, -36) + up, P(-10.8, -34) + up, P(-10.6, -31.6) + up)
        border.close()
        svg.path(border, stroke: .colour(BronzePeopleInk.light), width: 1.2)
        // A rosette painted on the panel, in the light.
        let rosette = P(7.4, -30.4) + up
        for i in 0..<8 {
            svg.circle(rosette + P.direction(Double(i) * 45) * 2.6, 1.1, fill: .colour(BronzePeopleInk.light))
        }
        svg.circle(rosette, 1.3, fill: .colour(BronzePeopleInk.gold), stroke: .colour(Ink.line), width: 0.5)
        svg.path(outline(up), stroke: .colour(Ink.line), width: 1.6)
        // The rail, of bent wood capped in bronze, and the studs along it.
        svg.line([P(-12.4, -36.2) + up, P(-6.6, -39.4) + up, P(12.6, -43) + up], stroke: .colour(Ink.line), width: 3)
        svg.line([P(-12.4, -36.2) + up, P(-6.6, -39.4) + up, P(12.6, -43) + up], stroke: .colour(BronzePeopleInk.bronze), width: 1.6)
        for x in stride(from: -4.0, through: 10.0, by: 4.6) {
            svg.circle(P(x, -38.4 - (x + 6.6) * 0.17) + up, 0.8, fill: .colour(BronzePeopleInk.bronzeLight), stroke: .colour(Ink.line), width: 0.4)
        }
        svg.line([P(-13.6, floor) + up, P(15.4, floor) + up], stroke: .colour(Ink.line), width: 2.2)
    }

    /// A spoked wheel centred on `c`, turned by `degrees`: a wooden felloe with a
    /// dark tyre, four spokes, and a bronze hub. The far wheel is darker and is
    /// seen through the gaps of the car.
    static func wheel(_ svg: inout SVG, at c: P, degrees: Double, far: Bool) {
        let r = wheelRadius
        let wood = far ? "#5c3c22" : BronzePeopleInk.wood
        svg.circle(c, r - 1.3, fill: .none, stroke: .colour(wood), width: 2.8)
        svg.circle(c, r, fill: .none, stroke: .colour(Ink.line), width: 2)
        svg.circle(c, r - 2.7, fill: .none, stroke: .colour(Ink.line), width: 0.9)
        for i in 0..<4 {
            let u = P.direction(degrees + Double(i) * 90)
            svg.line([c + u * 2.6, c + u * (r - 2.6)], stroke: .colour(Ink.line), width: 2.6)
            svg.line([c + u * 2.8, c + u * (r - 2.8)], stroke: .colour(wood), width: 1.2)
            svg.circle(c + u * (r - 1.3), 0.7, fill: .colour(far ? BronzePeopleInk.bronzeDark : BronzePeopleInk.bronzeLight))
        }
        svg.circle(c, 3, fill: .colour(far ? BronzePeopleInk.bronzeDark : BronzePeopleInk.bronze), stroke: .colour(Ink.line), width: 1.1)
        svg.circle(c, 1, fill: .colour(Ink.line))
    }

    /// A khopesh: a short grip, a straight neck of bronze and a curved blade,
    /// its edge on the outside of the curve leading the blow.
    static func khopesh(_ svg: inout SVG, at hand: P, degrees: Double) {
        svg.group(at: hand, turned: -degrees) { svg in
            svg.line([P(0, -2.4), P(0, 3.6)], stroke: .colour(BronzePeopleInk.handle), width: 2.4)
            func blade(_ o: P) -> PathData {
                var p = PathData()
                p.move(P(-0.9, 3.4) + o)
                p.line(P(-0.9, 8.4) + o)
                p.cubic(P(-1.4, 14.6) + o, P(-6.6, 18.4) + o, P(-9.2, 14.4) + o)
                p.cubic(P(-6, 15.4) + o, P(-2.8, 13) + o, P(1, 8.6) + o)
                p.line(P(1, 3.4) + o)
                p.close()
                return p
            }
            svg.path(blade(P(0.6, 0.5)), fill: .colour(BronzePeopleInk.bronze))
            svg.path(blade(P(0, 0)), stroke: .colour(Ink.line), width: 1)
            svg.path("M-1.6,9.8 C-2.2,13.8 -5.2,16.4 -7.8,15", stroke: .colour(BronzePeopleInk.bronzeLight), width: 0.7)
        }
    }
}

/// A horse of the chariot's team, drawn from the side facing right: a barrel,
/// an arched neck with a dark mane, a long head with a bridle and a plume of the
/// team's colour, a flowing tail, and four jointed legs whose lower hoof rests
/// on the ground. Its local origin is on the ground under the middle of its body.
struct BronzePeopleSteed {
    struct Pose {
        var fore = Limb(2, 2), hind = Limb(-16, 22)
        var farFore = Limb(2, 2), farHind = Limb(-16, 22)
        /// The body's rise in degrees, nose up, about the hind hip.
        var pitch = 0.0
        var lift = 0.0
        /// The neck's turn in degrees about its base; negative raises the head.
        var neck = 0.0
        var tail = 0.0
        var mane = 0.0
        var blink = false
        var mouthOpen = false
        var earBack = false
    }

    enum Leg { case fore, hind }

    static let foreHip = P(13, -29), hindHip = P(-11.4, -28.8)
    static let farOffset = P(2.4, -0.8)
    static let upper = 14.5, lower = 14.5
    static let neckBase = P(17, -42)

    let origin: P
    let pose: Pose
    let coat: String
    let shade: String
    private(set) var bob = 0.0

    init(at origin: P, pose: Pose, coat: String, shade: String) {
        self.origin = origin; self.pose = pose; self.coat = coat; self.shade = shade
        bob = -(Self.allLegs(self, bob: 0).map { $0.hoof.y }.max() ?? 0) + origin.y
    }

    /// A point of the body, from the horse's local units to the picture.
    func body(_ p: P, bob b: Double? = nil) -> P {
        origin + p.rotated(-pose.pitch, about: Self.hindHip) + P(0, -pose.lift + (b ?? bob))
    }

    /// A point of the neck or head, turned with the neck.
    func head(_ p: P) -> P { body(p.rotated(pose.neck, about: Self.neckBase)) }

    var mouth: P { head(P(37.4, -54.4)) }
    var withers: P { body(P(10.4, -47.2)) }

    /// One leg: its top, joint and hoof in the picture.
    static func leg(_ horse: BronzePeopleSteed, _ kind: Leg, far: Bool, bob: Double) -> (top: P, joint: P, hoof: P) {
        let hip = (kind == .fore ? foreHip : hindHip) + (far ? farOffset : P(0, 0))
        let limb = kind == .fore ? (far ? horse.pose.farFore : horse.pose.fore) : (far ? horse.pose.farHind : horse.pose.hind)
        let top = horse.body(hip, bob: bob)
        let joint = top + P.direction(limb.upper) * upper
        let hoof = joint + P.direction(kind == .fore ? limb.upper - limb.bend : limb.upper + limb.bend) * lower
        return (top, joint, hoof)
    }

    static func allLegs(_ horse: BronzePeopleSteed, bob: Double) -> [(top: P, joint: P, hoof: P)] {
        [leg(horse, .fore, far: false, bob: bob), leg(horse, .hind, far: false, bob: bob),
         leg(horse, .fore, far: true, bob: bob), leg(horse, .hind, far: true, bob: bob)]
    }

    func hoof(_ kind: Leg) -> P { Self.leg(self, kind, far: false, bob: bob).hoof }

    func drawLeg(_ svg: inout SVG, _ kind: Leg, far: Bool) {
        let (top, joint, hoof) = Self.leg(self, kind, far: far, bob: bob)
        let colour = far ? shade : coat
        // The fetlock bends the hoof a little forward of the cannon.
        let u = P.direction(BronzePeopleKit.degrees(from: joint, to: hoof))
        let fetlock = hoof - u * 2.4
        let a = P(-u.y, u.x)
        svg.line([top, joint], stroke: .colour(Ink.line), width: 5)
        svg.line([joint, fetlock], stroke: .colour(Ink.line), width: 3.5)
        svg.line([top, joint], stroke: .colour(colour), width: 3.2)
        svg.line([joint, fetlock], stroke: .colour(colour), width: 1.9)
        svg.circle(joint, 1.4, fill: .colour(colour))
        svg.polygon([fetlock - a * 1.4, fetlock + a * 1.6, hoof + a * 2.6 + u * 0.5, hoof - a * 1.6 + u * 0.5], fill: .colour(Ink.line))
    }

    func draw(_ svg: inout SVG, near: Bool) {
        drawLeg(&svg, .fore, far: true)
        drawLeg(&svg, .hind, far: true)
        let transform = "translate(\(num(origin.x)),\(num(origin.y + bob - pose.lift))) rotate(\(num(-pose.pitch)) \(num(Self.hindHip.x)) \(num(Self.hindHip.y)))"
        svg.raw("<g transform=\"\(transform)\">")
        // The tail, streaming back.
        let flow = pose.tail
        func tail(_ o: P) -> PathData {
            var p = PathData()
            p.move(P(-18.4, -41.4) + o)
            p.cubic(P(-24, -42 + flow * 4) + o, P(-29 - flow * 4, -35 + flow * 6) + o, P(-30 - flow * 8, -22 + flow * 8) + o)
            p.cubic(P(-27, -26 + flow * 6) + o, P(-23, -32 + flow * 3) + o, P(-18.6, -36.6) + o)
            p.close()
            return p
        }
        svg.path(tail(P(-0.6, 0.6)), fill: .colour(Ink.line))
        // The body.
        func barrel(_ o: P) -> PathData {
            var p = PathData()
            p.move(P(-19, -38) + o)
            p.cubic(P(-20.6, -46.4) + o, P(-10, -48.6) + o, P(0, -46.4) + o)
            p.cubic(P(8, -45.4) + o, P(14, -49) + o, P(19.4, -45) + o)
            p.cubic(P(23.4, -41) + o, P(22.4, -32) + o, P(16, -28.4) + o)
            p.cubic(P(8, -25.6) + o, P(-6, -26) + o, P(-13, -28.2) + o)
            p.cubic(P(-18, -29.8) + o, P(-20.4, -33) + o, P(-19, -38) + o)
            p.close()
            return p
        }
        svg.path(barrel(P(-0.8, 0.7)), fill: .colour(coat))
        // A shade along the belly and the haunch.
        svg.path("M-13,-29.6 C-6,-27.6 8,-27.4 15,-30 C10,-28.4 -6,-28.6 -13,-29.6 Z", fill: .colour(shade), opacity: 0.6)
        svg.path("M-16.6,-36 C-15.6,-41 -11,-43 -7.4,-41.6", stroke: .colour(shade), width: 1.2)
        svg.path(barrel(P(0, 0)), stroke: .colour(Ink.line), width: 1.6)
        // The neck and head, turned together about the neck's base.
        svg.raw("<g transform=\"rotate(\(num(pose.neck)) \(num(Self.neckBase.x)) \(num(Self.neckBase.y)))\">")
        func neck(_ o: P) -> PathData {
            var p = PathData()
            p.move(P(9.4, -46.4) + o)
            p.cubic(P(12.6, -56) + o, P(16.4, -64.4) + o, P(21.8, -68) + o)
            p.line(P(26.4, -57) + o)
            p.cubic(P(25, -50) + o, P(23.8, -44) + o, P(21.4, -37.8) + o)
            p.close()
            return p
        }
        svg.path(neck(P(-0.8, 0.7)), fill: .colour(coat))
        svg.path(neck(P(0, 0)), stroke: .colour(Ink.line), width: 1.6)
        // The mane, in tufts along the crest, lifted by the wind of the gallop.
        var mane = PathData()
        let crest: [P] = (0...7).map { i in
            let t = Double(i) / 7
            let a = P(21.8, -68), b = P(16.4, -64.4), c = P(12.6, -56), e = P(9.4, -46.4)
            let m = 1 - t
            return a * (m * m * m) + b * (3 * m * m * t) + c * (3 * m * t * t) + e * (t * t * t)
        }
        mane.move(crest[0])
        for (i, p) in crest.enumerated() {
            let out = P(-0.85, -0.53) * (2.6 + (i % 2 == 0 ? 1.8 : 0.2) + pose.mane * 1.4) + P(-pose.mane * 1.2, 0)
            mane.line(p + out)
        }
        for p in crest.reversed() { mane.line(p) }
        mane.close()
        svg.path(mane, fill: .colour(Ink.line))
        // The plume of the team's colour: three feathers fanned back from a bronze holder at the poll.
        let sway = pose.mane * 6
        for (i, angle) in [-18.0, -40.0, -62.0].enumerated() {
            svg.group(at: P(21.6, -69.2), turned: angle - sway * (0.6 + Double(i) * 0.3)) { svg in
                svg.ellipse(P(-0.5, -6.4), 2.3, 6, fill: .team)
                svg.ellipse(P(0, -7), 2.3, 6, fill: .none, stroke: .colour(Ink.line), width: 0.9)
                svg.path("M0,-1.6 L0,-11.4", stroke: .colour(Ink.line), width: 0.6, opacity: 0.7)
            }
        }
        svg.circle(P(21.6, -69.2), 1.4, fill: .colour(BronzePeopleInk.bronze), stroke: .colour(Ink.line), width: 0.7)
        // The head.
        // The far ear, behind the head.
        svg.path(pose.earBack ? "M21.6,-67.4 L16.6,-70.6 L21,-69.4 Z" : "M21.4,-67.6 L20.2,-73.2 L23.4,-68.8 Z",
                 fill: .colour(shade), stroke: .colour(Ink.line), width: 1)
        func skull(_ o: P) -> PathData {
            var p = PathData()
            p.move(P(21.4, -67.4) + o)
            p.cubic(P(26, -70.2) + o, P(32.4, -66) + o, P(38.6, -60.4) + o)
            p.cubic(P(41.6, -57.8) + o, P(41.4, -54) + o, P(38.4, -53.2) + o)
            if pose.mouthOpen { p.line(P(39.2, -51) + o); p.line(P(35.4, -52.4) + o) }
            p.cubic(P(34.6, -53.4) + o, P(32, -53.2) + o, P(29.4, -54.4) + o)
            p.cubic(P(25.2, -55.2) + o, P(23.4, -58.8) + o, P(23.6, -61.6) + o)
            p.cubic(P(23, -64) + o, P(21.8, -65.6) + o, P(21.4, -67.4) + o)
            p.close()
            return p
        }
        svg.path(skull(P(-0.6, 0.6)), fill: .colour(coat))
        // The cheek's roundness and the line of the nose.
        svg.path("M24.6,-60.4 C25.6,-57.4 28.2,-56 30.4,-56.4", stroke: .colour(shade), width: 1)
        svg.path(skull(P(0, 0)), stroke: .colour(Ink.line), width: 1.5)
        // The near ear, pricked, or laid back when the horse is roused.
        svg.path(pose.earBack ? "M23,-67.2 L18.2,-71 L22.6,-69.4 Z" : "M22.8,-67.6 L23.6,-73.6 L26.2,-68.8 Z",
                 fill: .colour(coat), stroke: .colour(Ink.line), width: 1.1)
        // The bridle: a cheek strap and a noseband, joined by a bronze disc.
        svg.path("M24.4,-66.4 L33.6,-57.8 M36.8,-61.6 L34.6,-55", stroke: .colour(Ink.line), width: 1.1)
        svg.circle(P(33.8, -57.9), 1.4, fill: .colour(BronzePeopleInk.bronze), stroke: .colour(Ink.line), width: 0.6)
        // The forelock.
        svg.path("M22.6,-68 q4,0.6 5.4,4.4 q-2.8,-1.6 -5.4,-2.4 Z", fill: .colour(Ink.line))
        if pose.blink {
            svg.path("M27.4,-63.6 h2.8", stroke: .colour(Ink.line), width: 1)
        } else {
            svg.circle(P(28.8, -63.4), 1.5, fill: .colour(Ink.eyeWhite), stroke: .colour(Ink.line), width: 0.7)
            svg.circle(P(29.2, -63.3), 0.75, fill: .colour(Ink.line))
        }
        svg.circle(P(38.9, -57.2), 0.65, fill: .colour(Ink.line))
        svg.raw("</g>")
        if near {
            // The breast strap, studded with bronze.
            svg.path("M11,-46.6 C16,-44 20,-40.6 21.6,-36.4", stroke: .colour(BronzePeopleInk.leather), width: 2)
            for p in [P(14.4, -44.6), P(18, -41.8), P(20.6, -38.6)] {
                svg.circle(p, 0.8, fill: .colour(BronzePeopleInk.bronzeLight), stroke: .colour(Ink.line), width: 0.4)
            }
        }
        svg.raw("</g>")
        drawLeg(&svg, .fore, far: false)
        drawLeg(&svg, .hind, far: false)
    }
}
