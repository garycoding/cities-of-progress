// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The rifleman

/// A rifleman: a peaked cap of soot with a band of the team's colour between
/// piping of the light, a brass badge and a black leather peak; short hair, a
/// walrus moustache and nose A. A bottle-green tunic with brass buttons, a brick
/// collar and cuffs, brick trousers, soot puttees and boots; a buff belt with
/// two cartridge pouches, and a canvas haversack on a strap from the shoulder.
/// He carries a bolt-action rifle with a bayonet fixed and a sling beneath.
/// Standing, he stands at the order, the rifle's butt by his foot; walking, he
/// carries it at the trail; fighting, he stands and aims, fires with a flash
/// and a wisp of smoke, works the bolt (up, back, the spent case flying, home
/// and down) and fires again: two shots in every cycle, where the musketeer
/// fires one and spends the rest reloading.
struct IndustrialWarriorsRifleman: PersonLook {
    /// The person's canvas, carried forward for the bayonet's reach and the flash.
    static let canvas = Canvas(minX: -36, minY: -102, width: 140, height: 108, pixelsPerUnit: Canvas.person.pixelsPerUnit)

    /// The rifle from butt to muzzle, and the bayonet's blade beyond it.
    static let rifle = 48.0
    static let blade = 15.0

    // MARK: The drill

    /// The bolt: home and turned down, lifted, or drawn back.
    enum Bolt { case home, lifted, back }

    /// One frame of the fight, in the picture's units: where the butt is and
    /// which way the rifle points, where each hand holds, and the bolt.
    struct Drill {
        var lean: Double
        var backLeg = Limb(-14, 6), frontLeg = Limb(14, 10)
        var butt: P
        var degrees: Double
        /// How far along the rifle the near hand holds the fore-end; nil when it works the bolt.
        var nearAlong: Double?
        var farAlong = 7.0
        var bolt = Bolt.home
        var eyes = Eyes.open
        var mouth = Mouth.firm
        var headTilt = 8.0
    }

    /// The two shots of the cycle: aim, fire, recover, and the bolt worked.
    static let drill: [Drill] = {
        let aim = Drill(lean: 5, butt: P(3.8, -45.4), degrees: 90.4, nearAlong: 20.5)
        var fire = Drill(lean: 2.4, butt: P(2.3, -45.9), degrees: 94.6, nearAlong: 20.5, eyes: .closed, headTilt: 5)
        fire.backLeg = Limb(-15, 7); fire.frontLeg = Limb(13, 11)
        let recover = Drill(lean: 3.8, butt: P(2.9, -45.8), degrees: 92.4, nearAlong: 20.5, eyes: .wide, headTilt: 6.5)
        let lift = Drill(lean: 4.4, butt: P(3.4, -45.6), degrees: 91.2, bolt: .lifted, eyes: .down, headTilt: 6)
        let back = Drill(lean: 4.2, butt: P(3.2, -45.6), degrees: 91.4, bolt: .back, eyes: .down, headTilt: 6)
        let home = Drill(lean: 4.8, butt: P(3.6, -45.5), degrees: 90.8, bolt: .home, headTilt: 7)
        return [aim, fire, recover, lift, back, home, aim, fire, recover, lift, back, home]
    }()

    /// The frames on which he fires.
    static let shots = [1, 7]

    /// The rifle's direction as a unit vector, and the side its belly faces.
    static func axes(_ degrees: Double) -> (u: P, a: P) {
        let u = P.direction(degrees)
        return (u, P(-u.y, u.x))
    }

    /// The muzzle of a rifle whose butt is at `butt`, pointing along `degrees`.
    static func muzzle(butt: P, degrees: Double) -> P {
        let (u, a) = axes(degrees)
        return butt + u * rifle - a * 0.8
    }

    /// The bolt handle's knob, where the hand takes it.
    static func knob(butt: P, degrees: Double, bolt: Bolt) -> P {
        let (u, a) = axes(degrees)
        switch bolt {
        case .home: return butt + u * 16.8 + a * 2.4
        case .lifted: return butt + u * 16.4 - a * 3.4
        case .back: return butt + u * 12.4 - a * 3.4
        }
    }

    /// The hands' places in the picture for a frame of the fight.
    static func hands(_ s: Drill) -> (near: P, far: P) {
        let (u, _) = axes(s.degrees)
        let near = s.nearAlong.map { s.butt + u * $0 } ?? knob(butt: s.butt, degrees: s.degrees, bolt: s.bolt)
        return (near, s.butt + u * s.farAlong)
    }

    // MARK: The poses

    /// Standing at the order: the butt on the ground by his near foot.
    static let standingButt = P(15.4, -1.4), standingDegrees = 178.6

    /// The rifle at the trail whilst walking: its direction and where the hand holds it.
    static func trail(_ frame: Int) -> (degrees: Double, along: Double) {
        (96 + 3 * BronzePeopleKit.wave(frame), 22)
    }

    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.backLeg = Limb(-5, 4); r.frontLeg = Limb(6, 4)
            r.mouth = .firm
            let u = P.direction(Self.standingDegrees)
            r.frontArm = IndustrialWarriorsKit.reach(r, front: true, to: Self.standingButt + u * (30.6 + r.lift * 0.4))
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
            r.frontArm = IndustrialWarriorsKit.reach(r, front: true, to: near)
            r.backArm = IndustrialWarriorsKit.reach(r, front: false, to: far)
            return r
        default:
            return nil
        }
    }

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = pose == .walking ? d.rig.sway : 0
        let fight = pose == .fighting ? Self.drill[frame] : nil
        let worldOpen = IndustrialWarriorsKit.worldOpen(d)
        let farHand = d.world(d.joints.backHand), nearHand = d.world(d.joints.frontHand)
        d.figure { d in
            IndustrialWarriorsKit.sleeve(&d, front: false, colour: IndustrialWarriorsInk.darkGreen, cuff: IndustrialWarriorsInk.darkBrick)
            IndustrialWarriorsKit.legs(&d, trousers: IndustrialWarriorsInk.brick, darkTrousers: IndustrialWarriorsInk.darkBrick)
            IndustrialWarriorsKit.tunic(&d, colour: IndustrialWarriorsInk.green, dark: IndustrialWarriorsInk.darkGreen, pale: IndustrialWarriorsInk.paleGreen,
                                        collar: IndustrialWarriorsInk.brick, swing: sway)
            Self.kit(&d, pose: pose, frame: frame, sway: sway)
            // The rifle, placed in the picture.
            d.svg.raw(worldOpen)
            switch pose {
            case .standing:
                Self.rifle(&d.svg, butt: Self.standingButt, degrees: Self.standingDegrees, bolt: .home)
            case .walking:
                let t = Self.trail(frame)
                Self.rifle(&d.svg, butt: nearHand - P.direction(t.degrees) * t.along, degrees: t.degrees, bolt: .home)
            default:
                if let s = fight {
                    Self.rifle(&d.svg, butt: s.butt, degrees: s.degrees, bolt: s.bolt)
                    d.hand(farHand)
                }
            }
            d.svg.raw("</g>")
            IndustrialWarriorsKit.sleeve(&d, front: true, colour: IndustrialWarriorsInk.green, cuff: IndustrialWarriorsInk.brick)
            Self.head(&d)
        }
        if let s = fight { Self.shot(&d.svg, frame: frame, drill: s) }
    }

    /// The belt, the pouches and the haversack on its strap.
    static func kit(_ d: inout Drawing, pose: SpritePose, frame: Int, sway: Double) {
        // The haversack's strap, from the near shoulder across to the far hip.
        let from = d.up(P(6.6, -47.2)), to = d.up(P(-11.6, -26))
        let across = P.direction(BronzePeopleKit.degrees(from: from, to: to) + 90) * 1.1
        IndustrialWarriorsKit.shape(&d.svg, [from + across, to + across, to - across, from - across], fill: .colour(IndustrialWarriorsInk.darkBuff), width: 0.8)
        IndustrialWarriorsKit.belt(&d)
        // The haversack at the far hip, swinging a little with the stride.
        let swing = pose == .walking ? -1.4 * sway : 0.2 * BronzePeopleKit.wave(frame)
        let bag = [P(-16.4, -27.6), P(-8.6, -27.8), P(-8.4 + swing * 0.5, -18.6), P(-9.4 + swing, -17.2), P(-15.6 + swing, -17.4), P(-16.8 + swing * 0.5, -19)]
        IndustrialWarriorsKit.shape(&d.svg, bag, fill: .colour(IndustrialWarriorsInk.canvas), width: 0.9)
        d.svg.polygon([P(-16.4, -27.6), P(-8.6, -27.8), P(-8.6, -23.4), P(-12.6, -22.4), P(-16.6, -23.4)], fill: .colour(IndustrialWarriorsInk.paleBuff),
                      stroke: .colour(Ink.line), width: 0.6)
        d.svg.line([P(-12.6, -22.6), P(-12.6, -21)], stroke: .colour(IndustrialWarriorsInk.darkBuff), width: 0.8)
        // Two cartridge pouches on the belt's front.
        IndustrialWarriorsKit.pouch(&d.svg, at: d.up(P(0.8, -28.6)), width: 4.8, height: 5.4)
        IndustrialWarriorsKit.pouch(&d.svg, at: d.up(P(6, -28.6)), width: 4.6, height: 5.4)
    }

    /// The head: short hair, a walrus moustache, nose A, and the peaked cap.
    static func head(_ d: inout Drawing) {
        d.head(nose: .curve, hair: { d in
            // Short hair behind the ear and a sideburn before it.
            d.svg.path("M-11,-62 C-11.6,-58 -11.2,-55 -9.8,-52.6 L-8.4,-55.6 C-8.6,-58.6 -8.4,-61 -7.6,-63 Z", fill: .colour(IndustrialWarriorsInk.hair))
            d.svg.path("M-5.6,-63 C-5.4,-59.6 -5.2,-57.6 -4.4,-56 L-3.2,-57 C-3.6,-59 -3.6,-61.6 -3.6,-63.4 Z", fill: .colour(IndustrialWarriorsInk.hair))
        }, features: { d in
            // A walrus moustache drooping past the mouth's corners.
            d.svg.path("M4.2,-54.6 q4,-2.2 8.6,-0.2 q0.6,2.8 -0.8,4.2 q-1.6,-2.2 -3.8,-2 q-2.4,0.2 -3.8,1.8 q-1.2,-1.8 -0.2,-3.8 Z",
                       fill: .colour(IndustrialWarriorsInk.hair), stroke: .colour(Ink.line), width: 0.5)
        }, brow: { d in
            d.svg.path("M1.8,-63.6 q3.2,-0.6 6.6,0.6", stroke: .colour(Ink.line), width: 1.6)
        }, over: { d in
            IndustrialWarriorsKit.peakedCap(&d.svg)
        })
    }

    // MARK: The rifle

    /// The rifle: a walnut stock to the muzzle with a steel butt plate, the
    /// receiver and the bolt, a box magazine and trigger guard, two barrel
    /// bands, the barrel's end with its foresight, the sling beneath, and the
    /// bayonet fixed under the muzzle.
    static func rifle(_ svg: inout SVG, butt: P, degrees: Double, bolt: Bolt) {
        let (u, a) = axes(degrees)
        func at(_ t: Double, _ s: Double) -> P { butt + u * t + a * s }
        // The sling, hanging slack beneath.
        var sling = PathData()
        sling.move(at(5.4, 3.2)); sling.quad(at(18, 7.2), at(30, 1.6))
        svg.path(sling, stroke: .colour(Ink.line), width: 1.7)
        svg.path(sling, stroke: .colour(IndustrialWarriorsInk.darkBuff), width: 0.8)
        // The bayonet: its blade under the muzzle, the crossguard and the ring.
        let base = at(rifle - 3, 1.6), tip = at(rifle + blade, 1.3)
        IndustrialWarriorsKit.shape(&svg, [base - a * 0.5, at(rifle + blade - 3.4, 0.9), tip, at(rifle + blade - 3.4, 2.1), base + a * 0.7],
                                    fill: .colour(IndustrialWarriorsInk.steelLight), width: 0.8)
        svg.line([at(rifle - 1, 1.6), at(rifle + blade - 5, 1.5)], stroke: .colour(IndustrialWarriorsInk.steel), width: 0.4)
        svg.line([at(rifle - 3.2, -0.6), at(rifle - 3.2, 2.8)], stroke: .colour(Ink.line), width: 1.3)
        // The barrel.
        svg.line([at(14, -0.8), at(rifle, -0.8)], stroke: .colour(Ink.line), width: 2.3)
        svg.line([at(14.4, -0.8), at(rifle - 0.3, -0.8)], stroke: .colour(IndustrialWarriorsInk.steel), width: 1.2)
        svg.line([at(rifle - 0.4, -1.6), at(rifle - 1, -2.2)], stroke: .colour(Ink.line), width: 0.9)
        // The stock, from the butt to the fore-end's nose.
        let stock = [at(0, -1.9), at(9, -1), at(13, -0.6), at(41, -0.6), at(41.8, 0.3), at(41, 1.4), at(19, 1.6), at(13.4, 1.6), at(10, 1.8),
                     at(4.6, 3), at(0.4, 3.7)]
        IndustrialWarriorsKit.shape(&svg, stock, fill: .colour(IndustrialWarriorsInk.wood), width: 0.9)
        svg.line([at(1.4, 2.4), at(8.4, 0.8)], stroke: .colour(IndustrialWarriorsInk.darkWood), width: 0.6)
        // The upper handguard.
        svg.line([at(20, -0.9), at(38, -0.9)], stroke: .colour(IndustrialWarriorsInk.darkWood), width: 1)
        // The butt plate.
        svg.line([at(0, -1.9), at(0.4, 3.7)], stroke: .colour(IndustrialWarriorsInk.steelDark), width: 1.2)
        // The bands, with the sling's swivels.
        for t in [26.0, 38.0] {
            svg.line([at(t, -1.6), at(t, 1.8)], stroke: .colour(Ink.line), width: 1.3)
            svg.line([at(t, -1.4), at(t, 1.6)], stroke: .colour(IndustrialWarriorsInk.steelLight), width: 0.5)
        }
        // The magazine and the trigger guard.
        svg.polygon([at(14.6, 1.4), at(18.6, 1.4), at(18.2, 3.8), at(15, 3.8)], fill: .colour(IndustrialWarriorsInk.steelDark), stroke: .colour(Ink.line), width: 0.6)
        var guardPath = PathData()
        guardPath.move(at(10.6, 1.7)); guardPath.quad(at(11.4, 4.6), at(14.4, 1.8))
        svg.path(guardPath, stroke: .colour(Ink.line), width: 0.8)
        svg.line([at(12.4, 1.8), at(12, 3.2)], stroke: .colour(Ink.line), width: 0.6)
        // The receiver.
        svg.polygon([at(12.6, -1.9), at(19.6, -1.6), at(19.6, 0.4), at(12.6, 0.4)], fill: .colour(IndustrialWarriorsInk.steel), stroke: .colour(Ink.line), width: 0.7)
        // The bolt: its body along the receiver's top (drawn back when open) and its handle.
        let start = bolt == .back ? 8.6 : 12.8
        svg.line([at(start, -1.2), at(start + 6.4, -1.2)], stroke: .colour(Ink.line), width: 1.9)
        svg.line([at(start + 0.2, -1.2), at(start + 6.2, -1.2)], stroke: .colour(IndustrialWarriorsInk.steelLight), width: 0.9)
        let knob = Self.knob(butt: butt, degrees: degrees, bolt: bolt)
        let root = at(start + 4, -1)
        svg.line([root, knob], stroke: .colour(Ink.line), width: 1.3)
        svg.line([root, knob], stroke: .colour(IndustrialWarriorsInk.steelLight), width: 0.5)
        svg.circle(knob, 1, fill: .colour(IndustrialWarriorsInk.steel), stroke: .colour(Ink.line), width: 0.6)
        // The foresight.
        svg.line([at(rifle - 1.4, -1.4), at(rifle - 1.4, -2.6)], stroke: .colour(Ink.line), width: 0.9)
    }

    // MARK: The shot

    /// The flash at the muzzle and a wisp of smoke that drifts forward and
    /// thins; the spent case flying from the open bolt.
    static func shot(_ svg: inout SVG, frame: Int, drill s: Drill) {
        for fired in shots {
            let age = (frame - fired + 12) % 12
            guard age < 4 else { continue }
            let f = drill[fired]
            let origin = muzzle(butt: f.butt, degrees: f.degrees)
            let u = P.direction(f.degrees)
            if age == 0 {
                IndustrialWarriorsKit.flash(&svg, at: origin + u * 1.4, degrees: f.degrees, length: 12, girth: 4.2, seed: fired == 1 ? 0 : 15)
            }
            // A small smokeless-powder puff, rising and drifting forward.
            let k = Double(age)
            let puffs: [(P, Double)] = [(P(2, 0), 2.2), (P(4.8, -1.2), 2.8), (P(7.8, 0.2), 2.5), (P(10.2, -1.4), 2)]
            let moved = puffs.map { (p, r) in (P(p.x * (1 + k * 0.3) + k * 1.6, p.y - k * (1.2 + p.x * 0.1)), r * (0.85 + k * 0.3)) }
            IndustrialWarriorsKit.smoke(&svg, at: origin + u * (age == 0 ? 5 : 2), puffs: age == 0 ? Array(moved.prefix(2)) : moved,
                                        opacity: [0.9, 0.8, 0.55, 0.3][age])
        }
        // The spent case, thrown up and back from the receiver as the bolt comes back.
        for (thrown, spin) in [(4, 0), (5, 1), (10, 0), (11, 1)] where frame == thrown {
            let (u, a) = axes(s.degrees)
            let port = s.butt + u * 16 - a * 2
            let p = spin == 0 ? port + P(-1.6, -4.6) : port + P(-6.4, -9)
            IndustrialWarriorsKit.spentCase(&svg, at: p, degrees: spin == 0 ? -40 : 70)
        }
    }
}
