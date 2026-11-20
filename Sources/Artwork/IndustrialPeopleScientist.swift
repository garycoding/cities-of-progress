// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The scientist (scholar)

/// A scientist in a long laboratory coat of undyed drill to the knee, open at
/// the chest on a waistcoat of the team's colour, a winged collar and a bow tie
/// of the team's colour, bottle-green trousers; bald on the crown with ginger tufts and mutton-chop
/// whiskers, oval spectacles; nose B. He carries a conical flask by its neck
/// and his notebook under his arm; at work the flask simmers on a tripod over a
/// spirit lamp, and he writes his observations in the notebook, looking up
/// at the flask as its bubbles rise and its steam curls away.
struct IndustrialPeopleScientist: PersonLook {
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(14.6, -34 - r.lift * 0.5))
            r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(-9.6, -31.4 - r.lift * 0.5))
            r.headTilt = 3
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 19, kneeLift: 36, armSwing: 14)
            r.lean = 2
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(14.6, -33.6 + 0.6 * IndustrialPeopleKit.wave(frame, times: 2)))
            r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(-9.6, -31.4))
            return r
        case .working:
            return writing(frame)
        default:
            return nil
        }
    }

    // MARK: Writing

    /// The open notebook in the picture, held up in the far hand, and its turn.
    static let notebookAt = P(9.4, -35.4)
    static let notebookDegrees = -14.0
    /// The pencil's slope from the hand to its point.
    static let pencilDegrees = -34.0
    static let pencilLength = 6.4

    /// The frames on which he looks up at the flask rather than at his writing.
    static let looking: Set<Int> = [8, 9, 10]

    /// Where the pencil's point is in a frame, in the picture: along a line of
    /// the near page in small strokes, and lifted while he looks up.
    static func pencilPoint(_ frame: Int) -> P {
        let along: [Double] = [0.6, 1.2, 1.8, 2.3, 2.9, 3.4, 3.9, 4.3, 4.4, 4.2, 3.2, 1.6]
        let rise: [Double] = [0, 0.5, 0, 0.5, 0, 0.5, 0, 0.4, 1.6, 2, 1.8, 0.8]
        let local = P(1.4 + along[frame], -2.4 - rise[frame])
        return notebookAt + local.rotated(notebookDegrees, about: P(0, 0))
    }

    func writing(_ frame: Int) -> Rig {
        var r = Moves.standing(frame)
        r.lean = 5
        r.backArm = IndustrialPeopleKit.reach(front: false, r, to: Self.notebookAt + P(-2.6, 1.6))
        let hand = Self.pencilPoint(frame) - P.direction(Self.pencilDegrees) * Self.pencilLength
        r.frontArm = IndustrialPeopleKit.reach(front: true, r, to: hand)
        let up = Self.looking.contains(frame)
        r.headTilt = up ? -3 : 10
        r.eyes = frame == 11 ? .closed : (up ? .wide : .down)
        r.mouth = up ? .murmur : .firm
        return r
    }

    /// The tripod's place on the ground, the height of its ring, and the flask's height.
    static let tripodX = 30.0, ringHeight = 15.0, flaskHeight = 12.0

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        if pose == .working {
            IndustrialPeopleProps.burner(&d.svg, x: Self.tripodX, height: Self.ringHeight, flicker: IndustrialPeopleKit.wave(frame, 0, times: 2))
            IndustrialPeopleProps.conicalFlask(&d.svg, base: P(Self.tripodX, -Self.ringHeight - 0.8), height: Self.flaskHeight,
                                               boil: Double(frame) / 12)
            // Steam curling from the neck: each puff rises, swells, drifts back and thins; a new one follows at half the cycle.
            let mouth = P(Self.tripodX, -Self.ringHeight - 0.8 - Self.flaskHeight)
            for k in 0..<2 {
                let p = (Double(frame) / 12 + Double(k) / 2).truncatingRemainder(dividingBy: 1)
                let at = mouth + P(-p * 5 + 1.4 * sin(p * 2 * .pi), -3 - p * 17)
                Self.steam(&d.svg, at: at, size: 2.6 + p * 4.6, opacity: 1 - p * 0.8)
            }
        }
        d.figure { d in
            if pose != .working { IndustrialPeopleKit.arm(&d, front: false, fill: .colour(IndustrialPeopleInk.shadeLight), width: 4.4) }
            IndustrialPeopleKit.trousers(&d, colour: IndustrialPeopleInk.green, shade: IndustrialPeopleInk.darkGreen)
            Self.coat(&d, sway: sway)
            let hand = d.joints.frontHand
            switch pose {
            case .working:
                // The notebook open in the far hand before him, and the pencil in the near.
                IndustrialPeopleKit.arm(&d, front: false, fill: .colour(IndustrialPeopleInk.shadeLight), width: 4.4)
                IndustrialPeopleProps.notebook(&d.svg, at: IndustrialPeopleKit.body(Self.notebookAt, d.rig),
                                               degrees: Self.notebookDegrees - d.rig.lean, written: 0.72)
                d.hand(d.joints.backHand + P(-0.4, -0.4))
                IndustrialPeopleKit.arm(&d, front: true, fill: .colour(IndustrialPeopleInk.light), width: 4.4, cuff: IndustrialPeopleInk.shadeLight)
                IndustrialPeopleProps.pencil(&d.svg, at: hand, degrees: AlchemyPeopleKit.bodyDegrees(Self.pencilDegrees, d.rig), length: Self.pencilLength)
                d.hand(hand)
            default:
                // The notebook under his arm, and the flask held by its neck.
                IndustrialPeopleProps.shutNotebook(&d.svg, at: d.up(P(-12.4, -33.8)), degrees: 12)
                d.hand(d.joints.backHand)
                let swing = pose == .walking ? 4 * IndustrialPeopleKit.wave(frame, 0.15, times: 2) : 1.2 * IndustrialPeopleKit.wave(frame)
                d.svg.group(turned: swing, about: hand) { svg in
                    IndustrialPeopleProps.conicalFlask(&svg, base: hand + P(0, Self.flaskHeight - 1.6), height: Self.flaskHeight, boil: nil)
                }
                IndustrialPeopleKit.arm(&d, front: true, fill: .colour(IndustrialPeopleInk.light), width: 4.4, cuff: IndustrialPeopleInk.shadeLight)
            }
            d.head(nose: .button, behind: { d in
                // Ginger tufts standing out behind the ear.
                d.svg.path("M-10.2,-61.6 C-13.6,-61.4 -14.2,-58.6 -12.4,-57.4 C-13.8,-56 -13.2,-53.4 -10.8,-53.4 C-10,-55.6 -9.6,-58.6 -10.2,-61.6 Z",
                           fill: .colour(IndustrialPeopleInk.gingerHair), stroke: .colour(Ink.line), width: 0.9)
            }, hair: { d in
                // The fringe of hair round the back of the head, under a bald crown.
                d.svg.path("M-10.6,-62.6 C-11.6,-58.6 -11,-54.6 -9,-51.6 L-7.2,-52.6 C-8.6,-55.6 -8.8,-59 -8,-62 Z",
                           fill: .colour(IndustrialPeopleInk.gingerHair))
                // The shine on the crown.
                d.svg.path("M-4.6,-65.8 q2.6,-1.8 5.6,-1.4", stroke: .colour("#ffffff"), width: 1, opacity: 0.6)
            }, features: { d in
                // Mutton-chop whiskers, down the cheek to the jaw, the chin shaven.
                // Mutton-chop whiskers: a narrow band down from the ear, widening along the jaw; the chin shaven.
                d.svg.path("M-6.6,-59.8 C-6.6,-56.4 -5.6,-53 -3.4,-50.6 C-1.8,-49.2 0.6,-49 1.8,-50.4 C0,-51.4 -1.6,-53.2 -3,-55.4 "
                           + "C-3.6,-56.8 -4,-58.4 -4.2,-60 Z",
                           fill: .colour(IndustrialPeopleInk.gingerHair), stroke: .colour(Ink.line), width: 0.9)
                d.svg.path("M-5,-56 q0.4,1.8 1.4,3", stroke: .colour(IndustrialPeopleInk.darkBrick), width: 0.6, opacity: 0.8)
            }, brow: { d in
                d.svg.path("M1.4,-64.8 q3.6,-2.4 7.6,-0.6", stroke: .colour(IndustrialPeopleInk.gingerHair), width: 1.8)
            }, over: { d in
                // Oval spectacles of steel wire, the bridge to the nose and the side-piece to the ear.
                d.svg.ellipse(P(5, -59.8), 3.8, 3.2, fill: .colour("#ffffff"), opacity: 0.2)
                d.svg.ellipse(P(5, -59.8), 3.8, 3.2, fill: .none, stroke: .colour(Ink.line), width: 1)
                d.svg.path("M8.8,-60.4 q1.2,-0.8 2.2,-0.4", stroke: .colour(Ink.line), width: 0.9)
                d.svg.line([P(1.2, -60.2), P(-8.4, -59.6)], stroke: .colour(Ink.line), width: 0.8)
                d.svg.path("M2.8,-61.8 q1,-0.8 2.2,-0.9", stroke: .colour("#ffffff"), width: 0.8, opacity: 0.8)
            })
        }
    }

    /// The laboratory coat to the knee, open at the chest on the waistcoat,
    /// with the collar and the bow tie, a pocket with pencils in it.
    static func coat(_ d: inout Drawing, sway: Double) {
        let hemBack = P(-15.4 - sway * 1.4, -8.6), hemFront = P(14.6 - sway * 1.4, -8.6)
        func coatPath(_ o: P) -> PathData {
            var p = PathData()
            p.move(d.up(P(-9.2, -47.6)) + o)
            p.line(d.up(P(9.2, -47.6)) + o)
            p.cubic(d.up(P(11, -38)) + o, P(12.4, -24) + o, hemFront + o)
            p.line(hemBack + o)
            p.cubic(P(-13.6, -24) + o, d.up(P(-11.4, -38)) + o, d.up(P(-9.2, -47.6)) + o)
            p.close()
            return p
        }
        d.svg.path(coatPath(P(-0.8, 0.8)), fill: .colour(IndustrialPeopleInk.light))
        // The shade down the back, where the drill folds, and the folds below the waist.
        d.svg.polygon([P(-11.6, -40), P(-8.2, -40), P(-9.8, -9), hemBack + P(0.8, -0.4)].map(d.up), fill: .colour(IndustrialPeopleInk.shadeLight))
        var folds = PathData()
        for (top, bottom) in [(P(-3, -24), P(-4.6, -9)), (P(9.4, -24), P(10.6, -9))] {
            folds.move(top); folds.quad((top + bottom) * 0.5 + P(-1 - sway, 0), bottom + P(-sway, 0))
        }
        d.svg.path(folds, stroke: .colour(IndustrialPeopleInk.shadeLight), width: 1.1)
        // The waistcoat in the team's colour in the opening, its buttons, and the shirt's front above it.
        d.svg.polygon([P(0.4, -47.2), P(9.4, -47.2), P(11.2, -27), P(2.4, -26.4)].map(d.up), fill: .colour(Ink.eyeWhite))
        d.band([P(1, -43.4), P(10.2, -43.8), P(11.4, -24.4), P(2.4, -23.8)])
        var buttons = PathData()
        for i in 0..<4 { let y = -40.6 + Double(i) * 3.8; buttons.move(d.up(P(7.6 + Double(i) * 0.2, y))); buttons.line(d.up(P(7.8 + Double(i) * 0.2, y + 0.2))) }
        d.svg.path(buttons, stroke: .colour(Ink.line), width: 1.5)
        d.svg.line([d.up(P(1, -43.4)), d.up(P(10.2, -43.8))], stroke: .colour(Ink.line), width: 0.8)
        // The lapels of the coat over the edges of the opening.
        d.svg.polygon([P(-1, -47.4), P(2.6, -47.4), P(2.4, -42), P(1.6, -24), P(-0.4, -24)].map(d.up), fill: .colour(IndustrialPeopleInk.light),
                      stroke: .colour(Ink.line), width: 0.9)
        d.svg.line([d.up(P(2.4, -42)), d.up(P(0.6, -40.4))], stroke: .colour(Ink.line), width: 0.7)
        // The breast pocket with two pencils in it, and a hip pocket.
        d.svg.line([d.up(P(-5.6, -40.8)), d.up(P(-5.4, -44.6))], stroke: .colour(Ink.line), width: 1.7)
        d.svg.line([d.up(P(-5.6, -40.8)), d.up(P(-5.4, -44.6))], stroke: .colour(IndustrialPeopleInk.green), width: 0.8)
        d.svg.line([d.up(P(-3.8, -40.8)), d.up(P(-3.2, -43.8))], stroke: .colour(Ink.line), width: 1.7)
        d.svg.line([d.up(P(-3.8, -40.8)), d.up(P(-3.2, -43.8))], stroke: .colour(IndustrialPeopleInk.brick), width: 0.8)
        d.svg.polygon([P(-7.6, -41.6), P(-1.6, -41.6), P(-1.8, -37.4), P(-7.4, -37.4)].map(d.up), fill: .colour(IndustrialPeopleInk.light),
                      stroke: .colour(Ink.line), width: 0.8)
        d.svg.line([P(-9.4, -19.4), P(-2.8, -19.6)], stroke: .colour(Ink.line), width: 0.8)
        d.svg.path(coatPath(P(0, 0)), stroke: .colour(Ink.line), width: 1.8)
        // The coat's buttons below the opening.
        for y in [-20.6, -15.4] { d.svg.circle(P(2.6, y), 0.7, fill: .colour(IndustrialPeopleInk.paleSoot), stroke: .colour(Ink.line), width: 0.5) }
        d.svg.line([P(1.6, -24), P(1.6, -8.8)], stroke: .colour(Ink.line), width: 0.8)
        // The winged collar and the black bow tie.
        let lift = d.rig.lift
        d.svg.polygon([P(1.4, -48.6 - lift), P(9.2, -48.8 - lift), P(8.6, -46.2 - lift), P(2.4, -46 - lift)], fill: .colour(Ink.eyeWhite),
                      stroke: .colour(Ink.line), width: 0.8)
        let knot = P(6.2, -45.4 - lift)
        d.svg.polygon([knot + P(-3, -1.6), knot + P(-0.6, -0.3), knot + P(-0.6, 0.5), knot + P(-3, 1.8)], fill: .team,
                      stroke: .colour(Ink.line), width: 0.7)
        d.svg.polygon([knot + P(3, -1.6), knot + P(0.6, -0.3), knot + P(0.6, 0.5), knot + P(3, 1.8)], fill: .team,
                      stroke: .colour(Ink.line), width: 0.7)
        d.svg.circle(knot, 0.9, fill: .team, stroke: .colour(Ink.line), width: 0.6)
    }

    /// A puff of steam: round billows about `c`, `size` across, one outline round them all, thinning to `opacity`.
    static func steam(_ svg: inout SVG, at c: P, size: Double, opacity: Double) {
        let billows: [(P, Double)] = [(P(0, 0), 0.5), (P(-0.42, 0.22), 0.36), (P(0.44, 0.18), 0.38), (P(-0.12, -0.42), 0.34)]
        svg.raw("<g opacity=\"\(num(opacity))\">")
        for (offset, r) in billows {
            svg.circle(c + offset * size, r * size, fill: .colour(Ink.line), stroke: .colour(Ink.line), width: 1.3)
        }
        for (offset, r) in billows {
            svg.circle(c + offset * size + P(-0.3, 0.3), r * size, fill: .colour(IndustrialPeopleInk.steam))
        }
        svg.path("M\(num(c.x - size * 0.3)),\(num(c.y + size * 0.32)) q\(num(size * 0.3)),\(num(size * 0.18)) \(num(size * 0.6)),0",
                 stroke: .colour(IndustrialPeopleInk.shadeLight), width: 0.8)
        svg.raw("</g>")
    }
}
