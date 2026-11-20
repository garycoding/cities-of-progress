// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The armoured car

/// An early armoured car: a riveted hull of grey plate on a motor chassis, a
/// long armoured bonnet with louvred doors over the radiator and a brass lamp,
/// the driver's visor in the sloping front plate, mudguards and a running
/// board, four spoked wheels of bottle green with solid rubber tyres, and an exhaust
/// pipe at the tail. On the roof a small round turret carries a water-cooled
/// machine gun, its fluted jacket ending in a muzzle cone; the commander,
/// head and shoulders out of the hatch, wears a leather helmet with goggles
/// pushed up and a brick scarf, a clipped moustache and nose F. The team's
/// colour is on a roundel bordered in the light on the hull's side door and
/// on a pennant on a short staff at the tail.
///
/// Standing, the engine idles: the hull trembles on its springs, a little
/// exhaust drifts from the pipe, and the commander looks about and blinks;
/// walking, the wheels turn, the hull rides its springs, the exhaust puffs and
/// the pennant streams; fighting, the car stands and the gun fires in two
/// short bursts, each shot with its flash and a wisp of smoke, the spent cases
/// dropping onto the roof. The origin is on the ground midway between the
/// front and rear wheels.
struct IndustrialWarriorsArmouredCar: PersonLook {
    static let canvas = Canvas(minX: -82, minY: -88, width: 140, height: 94, pixelsPerUnit: Canvas.person.pixelsPerUnit)

    static let wheelRadius = 12.0
    static let rearAxle = P(-31, -12), frontAxle = P(31, -12)
    /// Where the far wheels are drawn, behind and above the near ones.
    static let far = P(3.6, -3.4)
    /// The wheels turn this many degrees a frame when moving: under half the
    /// 36 degrees between spokes, and five spokes in the 12 frames, so that the
    /// cycle repeats without a jump.
    static let turn = 15.0
    /// The ground the car covers in a frame of the walking pose.
    static let groundPerFrame = wheelRadius * turn * .pi / 180

    /// The machine gun: where its jacket leaves the turret, and its muzzle.
    static let gunRoot = P(1, -55.4)
    static let gunLength = 24.0

    /// The frames on which the gun fires: two bursts of three.
    static let shots: Set<Int> = [0, 1, 2, 6, 7, 8]

    // MARK: The rig

    /// The commander's figure, of which only the head and shoulders show.
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? { Self.commanderRig(pose, frame) }

    static func commanderRig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        var r = Moves.standing(pose == .standing ? frame : 0)
        r.backArm = Limb(30, 40); r.frontArm = Limb(40, 50)
        switch pose {
        case .standing:
            // He looks about: forward, then back over the tail, then forward again.
            r.headTilt = [0, -2, -4, -5, -5, -4, -2, 0, 2, 3, 2, 1][frame]
            r.mouth = .firm
        case .walking:
            r.headTilt = 2 + 0.8 * BronzePeopleKit.wave(frame, times: 2)
            r.mouth = .smile
        case .fighting:
            r.headTilt = shots.contains(frame) ? -2 : 1
            r.eyes = shots.contains(frame) ? .wide : .open
            r.mouth = frame == 0 || frame == 6 ? .shout : (shots.contains(frame) ? .open : .firm)
        default:
            return nil
        }
        return r
    }

    /// How far the hull rides up or down on its springs in a frame.
    static func ride(_ pose: SpritePose, _ frame: Int) -> Double {
        switch pose {
        case .walking: return 0.7 * sin(Double(frame) / 12 * 4 * .pi) + 0.3 * sin(Double(frame) / 12 * 6 * .pi + 1)
        case .fighting: return shots.contains(frame) ? (frame % 2 == 0 ? 0.35 : -0.2) : 0
        default: return frame % 2 == 0 ? 0.25 : -0.05
        }
    }

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        // The wheels roll forward as the car drives (a rolling wheel's angle falls).
        let spin = pose == .walking ? -Double(frame) * Self.turn : 0
        let ride = Self.ride(pose, frame)
        d.svg.ellipse(P(0, 0.2), 52, 4.2, fill: .colour("#000000"), opacity: 0.14)
        Self.exhaust(&d.svg, pose: pose, frame: frame, ride: ride)
        // The far wheels, behind the hull.
        Self.wheel(&d.svg, at: Self.rearAxle + Self.far, degrees: spin + 11, far: true)
        Self.wheel(&d.svg, at: Self.frontAxle + Self.far, degrees: spin + 23, far: true)
        // The pennant at the tail, then the hull and everything on it, riding its springs.
        let wave: Double
        switch pose {
        case .walking: wave = Double(frame) / 6
        case .fighting: wave = Double(frame) / 12
        default: wave = Double(frame) / 12
        }
        var body = Drawing(layer: d.svg.layer, rig: d.rig, phase: d.phase)
        body.svg = SVG(layer: d.svg.layer)
        body.banner(at: P(-45.4, -44), foot: -38, top: -66, wave: wave)
        let pennant = body.svg.body
        let layer = d.svg.layer, phase = d.phase
        d.svg.group(at: P(0, -ride)) { svg in
            svg.raw(pennant)
            Self.chassis(&svg)
            Self.commander(&svg, layer: layer, phase: phase, pose, frame)
            Self.turret(&svg, pose: pose, frame: frame)
            Self.hull(&svg)
            Self.mudguards(&svg)
        }
        // The near wheels.
        Self.wheel(&d.svg, at: Self.rearAxle, degrees: spin, far: false)
        Self.wheel(&d.svg, at: Self.frontAxle, degrees: spin + 13, far: false)
        if pose == .fighting { Self.burst(&d.svg, frame: frame, ride: ride) }
        if pose == .walking && frame % 6 == 2 {
            BronzePeopleProps.dust(&d.svg, at: Self.rearAxle + P(-12, -3), size: 0.8, opacity: 0.35)
        }
    }

    // MARK: The parts

    /// A wheel: ten bottle-green spokes, a bottle-green felloe, a solid rubber tyre and a brass hub cap.
    static func wheel(_ svg: inout SVG, at c: P, degrees: Double, far: Bool) {
        IndustrialWarriorsKit.wheel(&svg, at: c, radius: wheelRadius, degrees: degrees, spokes: 10,
                                    spoke: far ? IndustrialWarriorsInk.darkGreen : IndustrialWarriorsInk.green,
                                    felloe: far ? IndustrialWarriorsInk.darkGreen : IndustrialWarriorsInk.green,
                                    tyre: IndustrialWarriorsInk.rubber, tyreWidth: 3, far: far)
    }

    /// The chassis' frame under the hull, with the springs over the axles.
    static func chassis(_ svg: inout SVG) {
        IndustrialWarriorsKit.shape(&svg, [P(-50, -18), P(52, -18), P(52, -14.6), P(-50, -14.6)], fill: .colour(IndustrialWarriorsInk.darkSoot), width: 1)
        for axle in [rearAxle, frontAxle] {
            var spring = PathData()
            for i in 0..<3 {
                let y = -15.6 + Double(i) * 1.1
                spring.move(axle + P(-9 + Double(i) * 1.4, y + 12)); spring.quad(axle + P(0, y + 14.4), axle + P(9 - Double(i) * 1.4, y + 12))
            }
            svg.path(spring, stroke: .colour(Ink.line), width: 0.9)
        }
    }

    /// The hull: the fighting compartment with its sloping front and tail, the
    /// long bonnet with its louvred radiator doors, the driver's visor, the
    /// side door with the roundel, and rivets along every seam.
    static func hull(_ svg: inout SVG) {
        let plate = Paint.colour(IndustrialWarriorsInk.plate)
        // The bonnet, from the front plate to the radiator.
        let bonnet = [P(10, -36), P(46, -33.4), P(51.6, -31), P(51.6, -17), P(10, -17)]
        IndustrialWarriorsKit.shape(&svg, bonnet, fill: plate, width: 1.4)
        svg.line([P(11, -34.6), P(45.6, -32.2)], stroke: .colour(IndustrialWarriorsInk.plateLight), width: 0.9)
        // The bonnet's side louvres.
        var louvres = PathData()
        for i in 0..<6 {
            let x = 22 + Double(i) * 3.6
            louvres.move(P(x, -29)); louvres.line(P(x + 1.6, -22))
        }
        svg.path(louvres, stroke: .colour(Ink.line), width: 0.9)
        svg.path(louvres, stroke: .colour(IndustrialWarriorsInk.plateDark), width: 0.4)
        // The radiator's armoured doors at the front.
        IndustrialWarriorsKit.shape(&svg, [P(48.6, -31.6), P(53.4, -30.8), P(53.4, -18), P(48.6, -18)], fill: .colour(IndustrialWarriorsInk.plateDark), width: 1)
        for y in stride(from: -29.0, through: -20.0, by: 2.2) {
            svg.line([P(49.2, y), P(52.8, y + 0.4)], stroke: .colour(IndustrialWarriorsInk.plateLight), width: 0.6)
        }
        // The lamp on the bonnet's front corner.
        svg.circle(P(47, -36.4), 2.2, fill: .colour(IndustrialWarriorsInk.brass), stroke: .colour(Ink.line), width: 0.8)
        svg.circle(P(48, -36.4), 1, fill: .colour(IndustrialWarriorsInk.flashCore))
        // The fighting compartment: a sloping front plate with the visor, a flat
        // roof under the turret, and the tail sloping down to the chassis.
        let body = [P(-45, -44), P(4, -45), P(13.6, -36), P(13.6, -17), P(-48, -17), P(-52, -26), P(-50.6, -36)]
        IndustrialWarriorsKit.shape(&svg, body, fill: plate, width: 1.5)
        svg.line([P(-44, -42.8), P(3.4, -43.8)], stroke: .colour(IndustrialWarriorsInk.plateLight), width: 1)
        svg.line([P(4, -45), P(13.6, -36)], stroke: .colour(IndustrialWarriorsInk.plateLight), width: 0.8)
        // The seams between the plates.
        svg.line([P(-50.6, -36), P(13.6, -36)], stroke: .colour(Ink.line), width: 0.8)
        svg.line([P(-46, -24.6), P(13.6, -24.6)], stroke: .colour(Ink.line), width: 0.6, opacity: 0.5)
        // The driver's visor: a hinged flap over a slit, propped half open.
        IndustrialWarriorsKit.shape(&svg, [P(6.6, -42.2), P(11.6, -37.6), P(12.8, -39.4), P(8, -43.8)], fill: .colour(IndustrialWarriorsInk.plateDark), width: 0.9)
        svg.line([P(6.4, -40.6), P(11.4, -36.4)], stroke: .colour(Ink.line), width: 1.4)
        // The side door with its hinges and handle, and the roundel on it.
        IndustrialWarriorsKit.shape(&svg, [P(-17, -34.6), P(1, -34.6), P(1, -18.4), P(-17, -18.4)], fill: plate, width: 1)
        for y in [-31.6, -21.4] { svg.line([P(-18.6, y), P(-15.4, y)], stroke: .colour(Ink.line), width: 1.6) }
        svg.line([P(-1.6, -26.4), P(-1.6, -24)], stroke: .colour(Ink.line), width: 1.3)
        let c = P(-8, -26.6)
        svg.circle(c + P(-0.4, 0.4), 6.4, fill: .colour(IndustrialWarriorsInk.light))
        svg.circle(c, 6.4, fill: .none, stroke: .colour(Ink.line), width: 0.9)
        svg.circle(c + P(-0.4, 0.4), 4.3, fill: .team)
        svg.circle(c, 4.3, fill: .none, stroke: .colour(Ink.line), width: 0.7)
        // Rivets along the seams and the edges.
        var rivets: [P] = []
        for i in 0..<12 { rivets.append(P(-48 + Double(i) * 5.2, -38.2)) }
        for i in 0..<12 { rivets.append(P(-46.6 + Double(i) * 5.1, -19)) }
        for i in 0..<7 { rivets.append(P(12 + Double(i) * 5.6, -19)) }
        for i in 0..<6 { rivets.append(P(14 + Double(i) * 5.8, -31.6 + Double(i) * 0.42)) }
        for i in 0..<4 { rivets.append(P(11.6, -33.4 + Double(i) * 4.4)) }
        for p in rivets { svg.circle(p, 0.55, fill: .colour(IndustrialWarriorsInk.plateDark)) }
        // The exhaust pipe along the chassis to the tail.
        svg.line([P(-34, -15.6), P(-56, -16.4)], stroke: .colour(Ink.line), width: 2.4)
        svg.line([P(-34, -15.6), P(-56, -16.4)], stroke: .colour(IndustrialWarriorsInk.steelDark), width: 1.1)
    }

    /// The mudguards over the wheels and the running board between them.
    static func mudguards(_ svg: inout SVG) {
        let soot = Paint.colour(IndustrialWarriorsInk.darkSoot)
        for (axle, back, ahead) in [(rearAxle, -16.0, 15.0), (frontAxle, -15.0, 18.0)] {
            var guardPath = PathData()
            let r = wheelRadius + 2.4
            guardPath.move(axle + P(back, 2))
            guardPath.cubic(axle + P(back * 0.9, -r * 0.9), axle + P(ahead * 0.7, -r * 1.05), axle + P(ahead, -1))
            guardPath.line(axle + P(ahead - 1.6, 0))
            guardPath.cubic(axle + P(ahead * 0.62, -r * 0.82), axle + P(back * 0.78, -r * 0.72), axle + P(back + 1.8, 2))
            guardPath.close()
            svg.path(guardPath, fill: soot)
            svg.path(guardPath, stroke: .colour(Ink.line), width: 1.1)
        }
        // The running board, and a toolbox on it.
        IndustrialWarriorsKit.shape(&svg, [P(-16, -11.6), P(17, -11.6), P(17, -9.4), P(-16, -9.4)], fill: soot, width: 1)
        IndustrialWarriorsKit.shape(&svg, [P(4, -16.6), P(12.4, -16.6), P(12.4, -11.6), P(4, -11.6)], fill: .colour(IndustrialWarriorsInk.wood), width: 0.8)
        svg.line([P(5, -14.2), P(11.4, -14.2)], stroke: .colour(IndustrialWarriorsInk.darkWood), width: 0.6)
    }

    /// The turret: a short drum of plate on the roof with a flat top, riveted,
    /// its open hatch lid standing behind the commander, and the machine gun.
    static func turret(_ svg: inout SVG, pose: SpritePose, frame: Int) {
        let plate = Paint.colour(IndustrialWarriorsInk.plate)
        // The hatch lid, thrown open behind him.
        IndustrialWarriorsKit.shape(&svg, [P(-24.6, -62.4), P(-29.6, -71), P(-27.6, -72), P(-22.4, -63.2)], fill: .colour(IndustrialWarriorsInk.plateDark), width: 0.9)
        // The drum.
        let drum = [P(-27, -44.6), P(-27, -60.4), P(-23, -62.4), P(-1, -62.4), P(3, -60.4), P(3, -44.6)]
        IndustrialWarriorsKit.shape(&svg, drum, fill: plate, width: 1.4)
        svg.line([P(-26, -59.4), P(2, -59.4)], stroke: .colour(Ink.line), width: 0.7)
        svg.line([P(-23.4, -61.6), P(-1.4, -61.6)], stroke: .colour(IndustrialWarriorsInk.plateLight), width: 0.9)
        svg.line([P(-24.6, -57.6), P(-24.6, -46)], stroke: .colour(IndustrialWarriorsInk.plateLight), width: 0.8, opacity: 0.8)
        svg.line([P(0.6, -58), P(0.6, -46)], stroke: .colour(IndustrialWarriorsInk.plateDark), width: 1.2)
        for i in 0..<6 { svg.circle(P(-24 + Double(i) * 4.8, -47), 0.55, fill: .colour(IndustrialWarriorsInk.plateDark)) }
        for i in 0..<6 { svg.circle(P(-24 + Double(i) * 4.8, -57.4), 0.55, fill: .colour(IndustrialWarriorsInk.plateDark)) }
        // A vision slit at the turret's side.
        svg.line([P(-14, -53.6), P(-8, -53.6)], stroke: .colour(Ink.line), width: 1.3)
        // The gun's mantlet and the gun.
        IndustrialWarriorsKit.shape(&svg, [P(-1, -58.6), P(4.4, -58), P(5.2, -55.4), P(4.4, -52.8), P(-1, -52.2)], fill: .colour(IndustrialWarriorsInk.plateDark), width: 1)
        let kick = pose == .fighting && shots.contains(frame) ? -0.8 : 0
        machineGun(&svg, root: gunRoot + P(kick, 0))
    }

    /// The water-cooled machine gun: a fluted jacket, a cone at the muzzle,
    /// and the filler cap on top.
    static func machineGun(_ svg: inout SVG, root: P) {
        let end = root + P(gunLength - 4, 0)
        IndustrialWarriorsKit.shape(&svg, [root + P(0, -2.6), end + P(0, -2.6), end + P(0, 2.6), root + P(0, 2.6)], fill: .colour(IndustrialWarriorsInk.steel), width: 1.1)
        var flutes = PathData()
        for i in 0..<8 {
            let x = root.x + 2.4 + Double(i) * 2.2
            flutes.move(P(x, root.y - 2)); flutes.line(P(x, root.y + 2))
        }
        svg.path(flutes, stroke: .colour(IndustrialWarriorsInk.steelDark), width: 0.6)
        svg.line([root + P(1, -1.6), end + P(-1, -1.6)], stroke: .colour(IndustrialWarriorsInk.steelLight), width: 0.6)
        // The muzzle cone and the barrel's end.
        IndustrialWarriorsKit.shape(&svg, [end + P(0, -1.8), end + P(3, -1.2), end + P(3, 1.2), end + P(0, 1.8)], fill: .colour(IndustrialWarriorsInk.steelDark), width: 0.8)
        svg.line([end + P(3, 0), end + P(4.4, 0)], stroke: .colour(Ink.line), width: 1.6)
        // The filler cap.
        svg.polygon([root + P(5, -2.6), root + P(7.4, -2.6), root + P(7, -4), root + P(5.4, -4)], fill: .colour(IndustrialWarriorsInk.brass), stroke: .colour(Ink.line), width: 0.5)
    }

    /// The muzzle of the gun as drawn in a frame.
    static func muzzle(_ pose: SpritePose, _ frame: Int) -> P {
        let kick = pose == .fighting && shots.contains(frame) ? -0.8 : 0
        return gunRoot + P(gunLength + 0.4 + kick, 0)
    }

    /// The commander, head and shoulders out of the hatch: a figure drawn
    /// smaller than the crews on foot, whose body the turret hides.
    static func commander(_ svg: inout SVG, layer: Layer, phase: Double, _ pose: SpritePose, _ frame: Int) {
        guard let rig = commanderRig(pose, frame) else { return }
        var man = Drawing(layer: layer, rig: rig, phase: phase)
        // As `Drawing.figure` places a figure, without its shadow on the ground.
        man.svg.raw("<g transform=\"translate(0,\(num(man.bob))) rotate(\(num(rig.lean)) \(num(Drawing.hips.x)) \(num(Drawing.hips.y)))\">")
        do {
            var m = man
            // His shoulders in a bottle-green tunic, and the brick scarf at his throat.
            m.garment(colour: [P(-12.6, -46.4), P(9.6, -48.2), P(12, -36), P(-13, -36)],
                      outline: [P(-9.2, -47.4), P(9.2, -47.4), P(11.4, -36.4), P(-12.4, -36.4)], fill: .colour(IndustrialWarriorsInk.green))
            IndustrialWarriorsKit.shape(&m.svg, [m.up(P(-7, -50)), m.up(P(9, -50.2)), m.up(P(9.6, -46.6)), m.up(P(6, -44.4)), m.up(P(-7.4, -46.4))],
                                        fill: .colour(IndustrialWarriorsInk.brick), width: 0.9)
            let flutter = pose == .walking ? 1.2 * BronzePeopleKit.wave(frame, times: 2) : 0.3 * BronzePeopleKit.wave(frame)
            IndustrialWarriorsKit.shape(&m.svg, [m.up(P(-6, -48.6)), m.up(P(-15 - flutter, -46.6 + flutter * 0.5)), m.up(P(-14.4 - flutter, -44)), m.up(P(-6.6, -46))],
                                        fill: .colour(IndustrialWarriorsInk.brick), width: 0.8)
            m.head(nose: .bulb, hair: { _ in }, features: { m in
                // A clipped moustache.
                m.svg.path("M5.6,-54 q3,-1.2 6,-0.2 q0,1.6 -1.4,1.8 q-1.8,-0.8 -3,-0.2 q-1.4,0 -1.6,-1.4 Z",
                           fill: .colour(IndustrialWarriorsInk.hair), stroke: .colour(Ink.line), width: 0.5)
            }, brow: { m in
                m.svg.path("M2,-63.4 q3,-1.6 6.6,-0.6", stroke: .colour(Ink.line), width: 1.6)
            }, over: { m in
                Self.helmet(&m.svg)
            })
            man = m
        }
        man.svg.raw("</g>")
        // The figure, smaller than one on foot, its shoulders at the hatch's rim.
        let k = 0.86
        svg.raw("<g transform=\"translate(-12,-62) scale(\(num(k))) translate(0,52)\">")
        svg.raw(man.svg.body)
        svg.raw("</g>")
    }

    /// A leather helmet over the crown and ears, with goggles pushed up on the brow.
    static func helmet(_ svg: inout SVG) {
        BronzePeopleProps.shape(&svg, fill: .colour(IndustrialWarriorsInk.leather), width: 1.3) { o in
            var p = PathData()
            p.move(P(-11.6, -52) + o)
            p.cubic(P(-13.4, -62) + o, P(-10, -70.6) + o, P(-1, -71.4) + o)
            p.cubic(P(7, -71.6) + o, P(11, -67) + o, P(11.4, -62.6) + o)
            p.line(P(1, -63.6) + o)
            p.cubic(P(-3, -62) + o, P(-5, -58) + o, P(-4.6, -52.6) + o)
            p.close()
            return p
        }
        svg.path("M-8.4,-66 C-5,-69.4 2,-70.2 6.6,-67.6", stroke: .colour(IndustrialWarriorsInk.paleWood), width: 0.8, opacity: 0.8)
        // The seam over the crown, and the strap under the chin.
        svg.path("M-1,-71 C-4,-66 -6,-60 -6.4,-54", stroke: .colour(IndustrialWarriorsInk.darkLeather), width: 0.7)
        svg.path("M-5.2,-53 Q-1,-48.6 4,-48.4", stroke: .colour(Ink.line), width: 1)
        // The goggles: a strap round the helmet and two brass-rimmed lenses on the brow.
        svg.path("M-11.8,-62 C-6,-65 1,-66 6,-65.6", stroke: .colour(Ink.line), width: 1.6)
        for c in [P(4.8, -66.6), P(9.4, -65.4)] {
            svg.ellipse(c, 2.4, 2, fill: .colour(IndustrialWarriorsInk.brass), stroke: .colour(Ink.line), width: 0.7)
            svg.ellipse(c + P(0.2, 0), 1.4, 1.1, fill: .colour(IndustrialWarriorsInk.paleGreen))
            svg.circle(c + P(-0.3, -0.4), 0.4, fill: .colour(IndustrialWarriorsInk.light))
        }
    }

    // MARK: The exhaust and the burst

    /// Exhaust from the tail pipe: a puff now and then whilst the engine
    /// idles, a puff every four frames as the car drives, drifting back, rising
    /// and thinning.
    static func exhaust(_ svg: inout SVG, pose: SpritePose, frame: Int, ride: Double) {
        let pipe = P(-57, -16.6 - ride)
        let period = pose == .walking ? 4 : 6
        let life = pose == .walking ? 8 : 6
        for born in stride(from: 0, to: 12, by: period) {
            let age = (frame - born + 12) % 12
            guard age < life else { continue }
            let t = Double(age) / Double(life)
            let drift = pose == .walking ? 4.4 : 2.2
            let at = pipe + P(-1.6 - Double(age) * drift, -1.6 - Double(age) * 1.6)
            let r = 1.6 + t * 3.2
            IndustrialWarriorsKit.smoke(&svg, at: at, puffs: [(P(0, 0), r), (P(-r * 0.8, -r * 0.5), r * 0.75)], opacity: 0.75 * (1 - t),
                                        colour: IndustrialWarriorsInk.exhaust)
        }
    }

    /// The burst: on each shot a flash at the muzzle, a wisp of smoke, and a
    /// spent case dropping from the gun onto the roof.
    static func burst(_ svg: inout SVG, frame: Int, ride: Double) {
        let lift = P(0, -ride)
        if shots.contains(frame) {
            let m = muzzle(.fighting, frame) + lift
            let seed: Double = [0: 0.0, 1: 20, 2: 8, 6: 14, 7: 2, 8: 24][frame] ?? 0
            let size = frame % 6 == 1 ? 1.2 : 1
            IndustrialWarriorsKit.flash(&svg, at: m + P(1.2, 0), degrees: 90, length: 14 * size, girth: 4.6 * size, points: 10, seed: seed)
        }
        // The smoke of the burst, drifting up and back over the gun and thinning after it.
        for start in [0, 6] {
            let age = frame - start
            guard age >= 0 && age < 6 else { continue }
            let k = Double(age)
            let m = muzzle(.fighting, 3) + lift
            let puffs: [(P, Double)] = [(P(4 + k * 0.8, -1 - k * 1.6), 2 + k * 0.5), (P(8 + k * 0.4, -2.6 - k * 2), 1.6 + k * 0.5)]
            IndustrialWarriorsKit.smoke(&svg, at: m, puffs: age < 3 ? Array(puffs.prefix(age + 1)) : puffs, opacity: [0.7, 0.75, 0.7, 0.5, 0.32, 0.16][age] as Double)
        }
        // The cases fall below the gun's breech onto the roof.
        for start in [0, 6] {
            let age = frame - start
            guard age >= 1 && age <= 3 else { continue }
            let base = gunRoot + lift + P(4, 3)
            IndustrialWarriorsKit.spentCase(&svg, at: base + P(-Double(age) * 1.2, Double(age) * 1.6), degrees: Double(age) * 70, length: 2.4, width: 1)
            if age >= 2 { IndustrialWarriorsKit.spentCase(&svg, at: base + P(1.6 - Double(age - 1) * 1.2, Double(age - 1) * 1.6), degrees: Double(age) * 50, length: 2.4, width: 1) }
        }
    }
}
