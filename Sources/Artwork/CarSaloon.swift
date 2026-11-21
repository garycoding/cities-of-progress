// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

/// The colours of the car. It belongs to no age, so it keeps to no age's
/// palette: a gloss black body whose shape is carried by cool highlights,
/// very dark blue glass with a sheen, grey aero wheels on dark tyres. The line
/// is the one every picture shares (`Ink.line`), and the team's colour is a
/// wide stripe along the bonnet edged in the light (`Ink.light`), clear of the
/// black, so that even Tonga's near-black reads against the body.
enum CarInk {
    /// The body's gloss black, a charcoal just off black so that the line and
    /// the darker shades still read on it.
    static let body = "#25262c"
    /// The reflection of the sky along the doors, above the swage line.
    static let bodySheen = "#353841"
    /// The shade of the lower body and the sills, turned from the light.
    static let bodyShade = "#18181c"
    /// The cuts of the doors and the bonnet, darker than the body.
    static let seam = "#0f0f12"
    /// The soft highlights that give the black its shape.
    static let highlight = "#b4bfcd"
    static let glint = "#f2f5f8"
    /// The glass: a very dark blue, its sheen and the dark pillars between the panes.
    static let glass = "#1d2633"
    static let glassSheen = "#7d90a6"
    static let pillar = "#0c0d10"
    /// The slim lamps: the head lamps' clear lens and light, the tail lamp's red.
    static let lens = "#d8e2e6"
    static let lamp = "#fbf6e6"
    static let tail = "#8e2a30"
    static let tailLit = "#d0565a"
    /// The tyres, and the aero wheels' grey faces and dark vents.
    static let tyre = "#1d1c1f"
    static let tyreSheen = "#6b6870"
    static let wheel = "#868c93"
    static let wheelLight = "#b5bbc1"
    static let wheelDark = "#575c63"
    static let vent = "#1f2125"
}

/// The car: a low, smooth four-door saloon whose single line runs from the
/// short nose over the bonnet, up the raked windscreen, over a dark glass roof
/// and down the fastback to a short boot with a small lip. Four doors with
/// flush handles, a wing mirror, slim head and tail lamps, a closed nose with
/// a slim intake (it is electric, and has no grille and no exhaust), and aero
/// wheels with five curved vents on dark tyres. No badge, name or wordmark is
/// drawn anywhere. The team's colour is a wide stripe along the bonnet from
/// the windscreen to the nose, edged in the light (ruled 2026-11-21).
///
/// Standing (and working, the car parked), it stands still; walking, it
/// drives: the wheels turn forward and the body rides lightly on its springs.
/// The origin is on the ground midway between the front and rear wheels.
enum CarSaloon {
    /// A little longer than the Industrial armoured car's hull and much lower.
    static let canvas = Canvas(minX: -62, minY: -42, width: 124, height: 46, pixelsPerUnit: Canvas.person.pixelsPerUnit)

    static let wheelRadius = 10.0
    static let rearAxle = P(-33, -10), frontAxle = P(33, -10)
    /// The radius of the wheel arches cut in the body.
    static let archRadius = 12.6
    /// The height of the body's lower edge above the ground.
    static let sill = -6.8
    /// The wheels turn this many degrees a frame when driving: a third of the
    /// 72 degrees between the vents, so that they plainly turn forward, and
    /// four vents' turn in the 12 frames, so that the cycle repeats without a jump.
    static let turn = 24.0
    /// The ground the car covers in a frame of the walking pose.
    static let groundPerFrame = wheelRadius * turn * .pi / 180

    /// The pose drawn for a key's pose: working is the car parked, drawn as standing.
    static func drawn(_ pose: SpritePose) -> SpritePose? {
        switch pose {
        case .standing, .working: .standing
        case .walking: .walking
        default: nil
        }
    }

    /// How far the body rides up on its springs in a frame of a pose.
    static func ride(_ pose: SpritePose, _ frame: Int) -> Double {
        guard pose == .walking else { return 0 }
        let t = Double(frame) / 12
        return 0.45 * sin(t * 4 * .pi) + 0.2 * sin(t * 6 * .pi + 0.8)
    }

    /// A frame of a pose (`standing` or `walking`) drawn as a sprite's picture
    /// and mask, grained alike, on `canvas` or another scale of it.
    static func render(_ pose: SpritePose, frame: Int, canvas: Canvas = CarSaloon.canvas) -> Rendered? {
        guard let pose = drawn(pose) else { return nil }
        return Raster.render(on: canvas) { svg in draw(&svg, pose, frame) }
    }

    // MARK: Drawing

    static func draw(_ svg: inout SVG, _ pose: SpritePose, _ frame: Int) {
        // The wheels roll forward as the car drives (a rolling wheel's angle falls).
        let spin = pose == .walking ? -Double(frame) * turn : 0
        let ride = Self.ride(pose, frame)
        svg.ellipse(P(1, 0.2), 57, 3.8, fill: .colour("#000000"), opacity: 0.16)
        // The body, riding its springs.
        svg.group(at: P(0, -ride)) { svg in
            wells(&svg)
            body(&svg)
            glasshouse(&svg)
            doors(&svg)
            lamps(&svg)
        }
        // The near wheels.
        wheel(&svg, at: rearAxle, degrees: spin)
        wheel(&svg, at: frontAxle, degrees: spin + 31)
        if pose == .walking && frame % 6 == 3 {
            BronzePeopleProps.dust(&svg, at: rearAxle + P(-13, -2.4), size: 0.6, opacity: 0.25)
        }
    }

    // MARK: The body

    /// The body's outline, moved by `o`: the sill with its two arches, the
    /// nose, and the one curve over the bonnet, the glass and the boot.
    static func outline(_ o: P) -> PathData {
        var p = PathData()
        let lift = sill - rearAxle.y
        let edge = sqrt(archRadius * archRadius - lift * lift)
        let low = atan2(lift, edge)
        p.move(P(-51, sill) + o)
        p.line(P(rearAxle.x - edge, sill) + o)
        arc(&p, centre: rearAxle + o, radius: archRadius, from: .pi - low, to: 2 * .pi + low)
        p.line(P(frontAxle.x - edge, sill) + o)
        arc(&p, centre: frontAxle + o, radius: archRadius, from: .pi - low, to: 2 * .pi + low)
        p.line(P(51, sill) + o)
        // The nose, rounded and closed, up to the bonnet's far edge.
        p.cubic(P(54.6, sill) + o, P(56.6, -10) + o, P(56.6, -13) + o)
        p.cubic(P(56.8, -16.6) + o, P(57.6, -21.6) + o, farEdge(1) + o)
        // The bonnet's far edge, rising to the windscreen: the bonnet is seen
        // a little from above, as the map is, so that its top shows.
        p.cubic(P(42, -28.8) + o, P(26, -30.6) + o, farEdge(0) + o)
        // The windscreen, raked back into the roof.
        p.cubic(P(9.4, -31.4) + o, P(5, -33.4) + o, P(-1, -33.8) + o)
        // The roof, arching over the cabin.
        p.cubic(P(-9, -34.6) + o, P(-19, -34) + o, P(-25, -32.2) + o)
        // The fastback, down to the short boot and its lip.
        p.cubic(P(-33, -29.8) + o, P(-40, -26.6) + o, P(-45.5, -25) + o)
        p.cubic(P(-49, -24.4) + o, P(-52.6, -24.4) + o, P(-55, -24) + o)
        // The tail, rounded under to the bumper.
        p.cubic(P(-56.4, -22.4) + o, P(-56.8, -18) + o, P(-56.4, -13) + o)
        p.cubic(P(-56, -9) + o, P(-54.6, sill) + o, P(-51, sill) + o)
        p.close()
        return p
    }

    /// The dark wells inside the wheel arches, seen round the tyres.
    static func wells(_ svg: inout SVG) {
        let lift = sill - rearAxle.y
        let low = atan2(lift, sqrt(archRadius * archRadius - lift * lift))
        for axle in [rearAxle, frontAxle] {
            var well = PathData()
            arc(&well, centre: axle, radius: archRadius - 0.3, from: .pi - low, to: 2 * .pi + low, start: true)
            well.close()
            svg.path(well, fill: .colour(CarInk.seam))
        }
    }

    /// The black body: its colour out of register with the line, the sky's
    /// reflection along the doors, the shade of the lower body, and the
    /// highlights that carry its shape on dark ground.
    static func body(_ svg: inout SVG) {
        let ink = Paint.colour(Ink.line)
        let shift = P(-0.7, 0.6)
        svg.raw("<clipPath id=\"car-body\"><path d=\"\(outline(shift).text)\"/></clipPath>")
        svg.path(outline(shift), fill: .colour(CarInk.body))
        svg.raw("<g clip-path=\"url(#car-body)\">")
        // The sky in the doors and wings, above the swage line that runs the
        // body's length, and the shade below it, darkening to the sills.
        var sheen = PathData()
        sheen.move(P(54, -17.2)); sheen.cubic(P(30, -19.6), P(-20, -20.6), P(-57, -21.4))
        sheen.line(P(-57, -16.6)); sheen.cubic(P(-20, -15.6), P(20, -15), P(57, -13.6)); sheen.close()
        svg.path(sheen, fill: .colour(CarInk.bodySheen))
        var shade = PathData()
        shade.move(P(-58, -11.4)); shade.cubic(P(-20, -11), P(20, -10.6), P(58, -9.6))
        shade.line(P(58, 0)); shade.line(P(-58, 0)); shade.close()
        svg.path(shade, fill: .colour(CarInk.bodyShade))
        stripe(&svg)
        svg.raw("</g>")
        svg.path(outline(P(0, 0)), stroke: ink, width: 1.3)
        // The swage line, a crisp highlight from the front wing to the tail.
        var swage = PathData()
        swage.move(P(52, -16.6)); swage.cubic(P(30, -19.2), P(-20, -20.4), P(-55.4, -21.2))
        svg.path(swage, stroke: .colour(CarInk.highlight), width: 0.8, opacity: 0.75)
        // The light along the shoulder over the rear wheel.
        var shoulder = PathData()
        shoulder.move(P(-40, -25.6)); shoulder.cubic(P(-45, -24.6), P(-50, -24.2), P(-53.8, -23.6))
        svg.path(shoulder, stroke: .colour(CarInk.highlight), width: 1.2, opacity: 0.5)
        // The light along the roof's crown, brightest over the cabin.
        var crown = PathData()
        crown.move(P(10.6, -30.8)); crown.cubic(P(6, -32.8), P(-2, -33.2), P(-8, -33.4))
        crown.cubic(P(-15, -33.4), P(-21, -32.4), P(-27, -30.6))
        svg.path(crown, stroke: .colour(CarInk.highlight), width: 0.8, opacity: 0.6)
        svg.path("M2,-33.1 C-2,-33.5 -6,-33.6 -10,-33.5", stroke: .colour(CarInk.glint), width: 0.7, opacity: 0.7)
        // The light catching each wheel arch's lip.
        for axle in [rearAxle, frontAxle] {
            var lip = PathData()
            arc(&lip, centre: axle, radius: archRadius - 0.9, from: 1.18 * .pi, to: 1.62 * .pi, start: true)
            svg.path(lip, stroke: .colour(CarInk.highlight), width: 0.7, opacity: 0.45)
        }
        // The slim intake low in the closed nose, and the diffuser under the tail.
        svg.path("M50.6,-9 C52.6,-8.6 54.6,-8.8 55.6,-9.6", stroke: .colour(CarInk.seam), width: 1.5)
        svg.path("M-55.2,-9.6 C-53.6,-8.4 -51.4,-8.2 -48,-8.2", stroke: .colour(CarInk.seam), width: 1.3)
    }

    /// A point of a cubic curve.
    static func cubic(_ a: P, _ b: P, _ c: P, _ d: P, _ t: Double) -> P {
        let u = 1 - t
        return a * (u * u * u) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t * t * t)
    }

    /// A point of the bonnet's near edge, the crease along the top of the
    /// front wing, from the foot of the windscreen (`t` 0) to the nose (`t` 1).
    static func nearEdge(_ t: Double) -> P { cubic(P(20, -24.6), P(30, -23.4), P(44, -21.6), P(53.8, -18.4), t) }

    /// A point of the bonnet's far edge, the outline over it, from the
    /// windscreen (`t` 0) to the nose (`t` 1).
    static func farEdge(_ t: Double) -> P { cubic(P(13.4, -29.6), P(26, -30.6), P(42, -28.8), P(55.6, -24.4), t) }

    /// The stripe in the team's colour (ruled 2026-11-21): a wide band over
    /// the bonnet's top from the windscreen to the nose, filling the top
    /// between the far edge and the crease, and edged along both and across
    /// the windscreen's foot in the light, so that it stands clear of the
    /// black. Drawn inside the body's clip, so that the nose rounds it off;
    /// the glass, drawn after, covers it behind the windscreen's foot.
    static func stripe(_ svg: inout SVG) {
        let steps = 16
        let ts = (0...steps).map { Double($0) / Double(steps) }
        let ahead = 60.0
        let crease = ts.map(nearEdge) + [P(57.4, -18)]
        var band = ts.map { farEdge($0) + P(0, -2) }
        band.append(P(ahead, farEdge(1).y - 2)); band.append(P(ahead, crease.last!.y))
        band += crease.reversed()
        band.append(cowl.top + P(-2, -2))
        svg.polygon(band, fill: .team)
        // The light edges: along the far edge, along the crease, and across the windscreen's foot.
        svg.line(ts.map { farEdge($0) + P(0.1, 1.05) } + [P(57.2, -23.2)], stroke: .colour(Ink.light), width: 0.9)
        svg.line(crease.map { $0 + P(0, -0.6) }, stroke: .colour(Ink.light), width: 1.1)
        svg.line([cowl.foot + P(-0.2, -0.9), cowl.top + P(1.2, 0.2)], stroke: .colour(Ink.light), width: 1)
        // The crease itself, a fine line with the light of the wing under it.
        svg.line(crease, stroke: .colour(Ink.line), width: 0.6)
        svg.line(crease.map { $0 + P(0, 0.6) }, stroke: .colour(CarInk.highlight), width: 0.5, opacity: 0.6)
    }

    /// The foot of the windscreen, seen across the bonnet's top: from the near
    /// side, where the side glass begins, to the far edge.
    static let cowl = (foot: P(19.2, -24.9), top: P(13.4, -29.6))

    /// The glass: the windscreen's edge, the side windows and the rear glass in
    /// one dark sweep under the roof, divided by the dark pillars, with a sheen.
    static func glasshouse(_ svg: inout SVG) {
        var glass = PathData()
        glass.move(cowl.foot)
        glass.line(cowl.top + P(-0.3, 0.3))
        glass.cubic(P(9, -31.2), P(5, -32.4), P(-1, -32.7))
        glass.cubic(P(-9, -33.4), P(-18.4, -32.8), P(-24.2, -31.1))
        glass.cubic(P(-31, -29), P(-36.4, -27.4), P(-41.4, -26))
        glass.cubic(P(-30, -25.9), P(0, -25.2), cowl.foot)
        glass.close()
        svg.raw("<clipPath id=\"car-glass\"><path d=\"\(glass.text)\"/></clipPath>")
        svg.path(glass, fill: .colour(CarInk.glass))
        svg.raw("<g clip-path=\"url(#car-glass)\">")
        // The sheen: two slanting streaks of light across the panes, and the
        // glass roof's reflection along its top.
        svg.polygon([P(10, -24), P(15, -24), P(5, -36), P(0, -36)], fill: .colour(CarInk.glassSheen), opacity: 0.45)
        svg.polygon([P(16.4, -24), P(17.8, -24), P(7.8, -36), P(6.4, -36)], fill: .colour(CarInk.glassSheen), opacity: 0.3)
        svg.polygon([P(-21, -24), P(-18.2, -24), P(-26, -36), P(-28.8, -36)], fill: .colour(CarInk.glassSheen), opacity: 0.26)
        var roof = PathData()
        roof.move(P(10, -30.2)); roof.cubic(P(3, -32.4), P(-12, -33), P(-26, -30.6))
        svg.path(roof, stroke: .colour(CarInk.glassSheen), width: 0.9, opacity: 0.55)
        // The pillars between the front and rear doors' panes, and before the rear quarter's.
        svg.polygon([P(-4.2, -24), P(-1.6, -24), P(-3.4, -36), P(-6, -36)], fill: .colour(CarInk.pillar))
        svg.polygon([P(-29.6, -24), P(-28.4, -24), P(-30.4, -36), P(-31.6, -36)], fill: .colour(CarInk.pillar))
        svg.raw("</g>")
        svg.path(glass, stroke: .colour(Ink.line), width: 0.9)
        // The thin dark rail where the glass meets the body.
        var belt = PathData()
        belt.move(P(-41, -25.9)); belt.cubic(P(-30, -25.8), P(0, -25.1), cowl.foot)
        svg.path(belt, stroke: .colour(CarInk.seam), width: 0.8)
        // The wing mirror on its stalk at the foot of the windscreen.
        BronzePeopleProps.shape(&svg, fill: .colour(CarInk.body), width: 0.8) { o in
            var m = PathData()
            m.move(P(10.6, -25.2) + o); m.cubic(P(10.4, -27.4) + o, P(12.6, -28.4) + o, P(15.4, -27.8) + o)
            m.cubic(P(16.6, -27.4) + o, P(16.6, -25.4) + o, P(15, -25) + o)
            m.close()
            return m
        }
        svg.path("M11.6,-26.8 C12.6,-27.7 14,-27.9 15.2,-27.5", stroke: .colour(CarInk.highlight), width: 0.6, opacity: 0.6)
    }

    /// The doors' cuts, their flush handles, the bonnet's shut line and the
    /// small camera on the front wing.
    static func doors(_ svg: inout SVG) {
        var cuts = PathData()
        // The front door's leading edge, behind the front wheel, and the cut between the doors.
        cuts.move(P(17.4, -24.6)); cuts.cubic(P(17.2, -19), P(18.4, -14), P(20.8, -11.4))
        cuts.move(P(-3.6, -25.3)); cuts.line(P(-4.6, -8.2))
        // The rear door's trailing edge, curving round the rear wheel's arch.
        cuts.move(P(-29.6, -25.8)); cuts.cubic(P(-28, -23.4), P(-25.8, -21.4), P(-23.4, -20.4))
        // The doors' foot above the sill.
        cuts.move(P(-21, -8.6)); cuts.cubic(P(-8, -8.4), P(8, -8.4), P(20.4, -8.8))
        // The boot's shut line (the bonnet's lies on its top, out of sight).
        cuts.move(P(-42.6, -25.4)); cuts.cubic(P(-45, -23.4), P(-48, -22.4), P(-52, -22))
        svg.path(cuts, stroke: .colour(CarInk.seam), width: 0.75)
        var edges = PathData()
        edges.move(P(17.9, -24.4)); edges.cubic(P(17.7, -19), P(18.9, -14.2), P(21.2, -11.8))
        edges.move(P(-3, -25.2)); edges.line(P(-4, -8.4))
        svg.path(edges, stroke: .colour(CarInk.highlight), width: 0.35, opacity: 0.4)
        // The flush handles, set into the doors just under the swage line.
        for x in [7.6, -17.6] {
            let handle = BronzePeopleProps.rounded(P(x, -21.9), width: 5, height: 1.3, radius: 0.6, degrees: -0.6, shift: P(0, 0))
            svg.path(handle, fill: .colour(CarInk.bodySheen), stroke: .colour(CarInk.seam), width: 0.5)
            svg.line([P(x - 2, -22.3), P(x + 2, -22.35)], stroke: .colour(CarInk.highlight), width: 0.4, opacity: 0.7)
        }
        // The side camera on the front wing.
        svg.path(BronzePeopleProps.rounded(P(24.6, -18.4), width: 2.2, height: 1, radius: 0.4, degrees: -4, shift: P(0, 0)),
                 fill: .colour(CarInk.seam))
    }

    /// The slim head lamp swept back under the bonnet's crease, and the slim tail lamp
    /// along the boot's edge.
    static func lamps(_ svg: inout SVG) {
        var head = PathData()
        head.move(P(56.4, -16.4)); head.cubic(P(54, -17.2), P(51, -18.4), P(47.6, -19.2))
        head.cubic(P(47.4, -18.4), P(48, -17.8), P(48.6, -17.6)); head.cubic(P(51.4, -17), P(53.8, -15.8), P(56.2, -14.6))
        head.close()
        svg.path(head, fill: .colour(CarInk.lens), stroke: .colour(Ink.line), width: 0.6)
        svg.path("M55.4,-15.6 C53.2,-16.4 50.8,-17.4 48.6,-18.2", stroke: .colour(CarInk.lamp), width: 0.6)
        var tail = PathData()
        tail.move(P(-55.6, -22.6)); tail.cubic(P(-53.4, -23), P(-50.4, -23.2), P(-47.6, -23.6))
        tail.cubic(P(-47.4, -22.6), P(-47.6, -22), P(-48.4, -21.8)); tail.cubic(P(-51, -21.4), P(-53.6, -21.2), P(-55.8, -20.6))
        tail.close()
        svg.path(tail, fill: .colour(CarInk.tail), stroke: .colour(Ink.line), width: 0.6)
        svg.path("M-55,-21.8 C-53,-22.2 -50.6,-22.4 -48.6,-22.7", stroke: .colour(CarInk.tailLit), width: 0.5)
        // A small reflector low on the tail.
        svg.line([P(-56, -12.6), P(-55.6, -10.6)], stroke: .colour(CarInk.tail), width: 0.8)
    }

    // MARK: The wheels

    /// An aero wheel: a dark tyre with a sheen on its sidewall, a grey disc
    /// with five curved vents turned by `degrees`, and a plain centre cap.
    static func wheel(_ svg: inout SVG, at c: P, degrees: Double) {
        let ink = Paint.colour(Ink.line)
        let r = wheelRadius, disc = 6.9
        svg.circle(c, r, fill: .colour(CarInk.tyre), stroke: ink, width: 1.1)
        var sidewall = PathData()
        arc(&sidewall, centre: c, radius: r - 1.4, from: 1.05 * .pi, to: 1.42 * .pi, start: true)
        svg.path(sidewall, stroke: .colour(CarInk.tyreSheen), width: 0.9, opacity: 0.8)
        svg.circle(c, disc, fill: .colour(CarInk.wheel), stroke: ink, width: 0.8)
        svg.circle(c, disc - 1.3, fill: .colour(CarInk.wheelLight), opacity: 0.55)
        // The vents: each a crescent swept back from the rim toward the cap.
        for i in 0..<5 {
            let a = degrees + Double(i) * 72
            func at(_ along: Double, _ radius: Double) -> P { c + P.direction(a + along) * radius }
            var vent = PathData()
            vent.move(at(0, disc - 1))
            vent.quad(at(10, disc - 0.2), at(26, disc - 1.2))
            vent.quad(at(16, 4.4), at(-4, 3.2))
            vent.quad(at(-2, 5), at(0, disc - 1))
            vent.close()
            svg.path(vent, fill: .colour(CarInk.vent), stroke: ink, width: 0.4)
        }
        svg.circle(c, 2.3, fill: .colour(CarInk.wheelDark), stroke: ink, width: 0.6)
        svg.circle(c + P(-0.6, -0.6), 0.6, fill: .colour(CarInk.wheelLight), opacity: 0.8)
    }

    // MARK: Geometry

    /// A circular arc appended to `p` as cubic curves, at the angles in
    /// radians (measured from the right, clockwise on the screen, as `y`
    /// runs downward), starting a new subpath when `start` is true.
    static func arc(_ p: inout PathData, centre c: P, radius r: Double, from a0: Double, to a1: Double, start: Bool = false) {
        func at(_ a: Double) -> P { c + P(cos(a), sin(a)) * r }
        func tangent(_ a: Double) -> P { P(-sin(a), cos(a)) }
        let segments = max(1, Int((abs(a1 - a0) / (.pi / 2)).rounded(.up)))
        let step = (a1 - a0) / Double(segments)
        let k = 4.0 / 3.0 * tan(step / 4) * r
        if start { p.move(at(a0)) } else { p.line(at(a0)) }
        for i in 0..<segments {
            let a = a0 + Double(i) * step, b = a + step
            p.cubic(at(a) + tangent(a) * k, at(b) - tangent(b) * k, at(b))
        }
    }
}
