// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// The peaceful sectors in their Alchemy-age looks wear the dress of the late
// Middle Ages and the first modern centuries in the age's colours, each with a
// nose of its own (docs/art-style.md, "Noses") different from his Iron and
// Bronze stages', and move on the shared skeleton. The team's colour is where
// the earlier ages put it for the same sector, and never beside the age's wine
// or gilt, so that Rome's red and Angkor's orange stay distinct from them: the
// craftsman's sash, the alchemist's stole, the gunsmith's cap, and the banker's
// doublet between the fur of his gown.

// MARK: - The craftsman (worker)

/// A joiner in a smock of undyed linen smocked across the chest in teal, the
/// team's sash at his waist, a half apron of teal canvas with a chisel in its
/// pocket, a soft wine-coloured cap, brown sideburns and a carpenter's pencil
/// behind his ear; nose C. He carries his tool-tote, the mallet in it among the
/// saw and the square; at work he sets it down and carves an oak block on his bench,
/// the chisel in one hand and the mallet tapping it home with the other, two
/// blows to the cycle and shavings flying at each; fighting, he swings the mallet.
struct AlchemyPeopleCraftsman: PersonLook {
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            r.frontArm = Limb(12 + r.lift, -4)
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 23, kneeLift: 44, armSwing: 26)
            r.frontArm = Limb(8 + 9 * BronzePeopleKit.wave(frame, 0.5), -5)
            return r
        case .working:
            return carving(frame)
        case .fighting:
            return swing(frame)
        default:
            return nil
        }
    }

    // MARK: Carving

    /// The lean over the bench, rocking a little into each blow; the second
    /// blow of the cycle is the lighter, so that the two halves differ.
    static let carvingLean: [Double] = [26, 25.4, 25, 24.8, 25.6, 27, 25.8, 25.3, 25, 24.9, 25.5, 26.7]
    /// The frames on which the mallet meets the chisel.
    static let strikes: Set<Int> = [5, 11]
    /// The mallet's direction in the picture through the cycle: lifted by the
    /// wrist, brought down, and checked as it strikes.
    static let malletDegrees: [Double] = [102, 106, 109, 111, 106, 98, 101, 104, 107, 108, 104, 98]
    /// How far the mallet hand rises above its striking place.
    static let malletRise: [Double] = [0.8, 1.6, 2.2, 2.6, 1.4, 0, 0.6, 1.3, 1.8, 2.1, 1.1, 0]

    /// The chisel in the picture: its butt, its direction, and its length.
    static let chiselButt = P(30, -36)
    static let chiselDegrees = 20.0
    static let chiselLength = 12.0
    /// The mallet's handle at work, long enough to reach the chisel from the far hand.
    static let malletHaft = 14.0
    /// Its head, smaller than the one he carries, so that it clears his face as it rises.
    static let malletHead = 0.78
    /// Where the front hand grips the chisel: on its handle, below the butt.
    static var chiselGrip: P { chiselButt + P.direction(chiselDegrees) * 3 }
    /// The point that bites the oak, where the block's top lies.
    static var chiselTip: P { AlchemyPeopleProps.chiselTip(butt: chiselButt, degrees: chiselDegrees, length: chiselLength) }
    /// The bench's top above the ground, and its ends.
    static let benchTop = 18.0, benchLeft = 24.0, benchRight = 52.0

    /// Where the back hand holds the mallet in a frame, in the picture: so that
    /// the mallet's face, at its direction, meets the chisel's butt on the strike.
    static func malletHand(_ frame: Int) -> P {
        let strike = chiselButt - AlchemyPeopleProps.malletFace(at: P(0, 0), degrees: malletDegrees[5], haft: malletHaft, head: malletHead)
        return strike + P(-malletRise[frame] * 0.4, -malletRise[frame])
    }

    func carving(_ frame: Int) -> Rig {
        var r = Rig()
        r.backLeg = Limb(-12, 5); r.frontLeg = Limb(14, 8)
        r.lean = Self.carvingLean[frame]
        r.frontArm = AlchemyPeopleKit.reach(front: true, r, to: Self.chiselGrip)
        r.backArm = AlchemyPeopleKit.reach(front: false, r, to: Self.malletHand(frame), elbowUp: true)
        r.eyes = .down
        r.mouth = Self.strikes.contains(frame) ? .firm : .smile
        r.headTilt = -8
        return r
    }

    // MARK: Fighting

    func swing(_ frame: Int) -> Rig {
        let (angle, landing) = Moves.blow(frame, ready: 70, raised: 176, struck: 52)
        var r = Rig()
        r.frontArm = Limb(angle, -12)
        r.backArm = Limb(36 - (angle - 70) * 0.3, 26)
        r.backLeg = Limb(-16, 6)
        r.frontLeg = frame >= 6 && frame <= 9 ? Limb(22, 14) : Limb(13, 8)
        r.lean = frame < 6 ? -4 : (frame <= 9 ? 10 : 3)
        r.mouth = frame >= 6 && frame <= 8 ? .shout : .firm
        r.eyes = landing ? .wide : .open
        return r
    }

    /// Where the tote stands while he works or fights: on the ground behind him.
    static let toteDown = P(-24, -10.6)

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        if pose == .working || pose == .fighting {
            d.svg.ellipse(Self.toteDown + P(0.4, 10.8), 9, 2, fill: .colour("#000000"), opacity: 0.13)
            AlchemyPeopleProps.tote(&d.svg, handle: Self.toteDown, swing: 0)
        }
        if pose == .working {
            AlchemyPeopleProps.bench(&d.svg, left: Self.benchLeft, right: Self.benchRight, top: Self.benchTop)
            AlchemyPeopleProps.block(&d.svg, left: Self.benchLeft + 4, right: Self.benchRight - 3, top: Self.benchTop,
                                     height: -Self.chiselTip.y - Self.benchTop)
        }
        d.figure { d in
            let carving = pose == .working
            if !carving { d.arm(front: false) }
            d.legs()
            Self.smock(&d, sway: sway)
            if carving {
                // The far arm reaches across him to the mallet.
                let hand = d.joints.backHand
                let degrees = AlchemyPeopleKit.bodyDegrees(Self.malletDegrees[frame], d.rig)
                d.arm(front: false)
                AlchemyPeopleProps.mallet(&d.svg, at: hand, degrees: degrees, haft: Self.malletHaft, head: Self.malletHead)
                let butt = AlchemyPeopleKit.body(Self.chiselButt, d.rig)
                AlchemyPeopleProps.chisel(&d.svg, butt: butt, degrees: AlchemyPeopleKit.bodyDegrees(Self.chiselDegrees, d.rig),
                                          length: Self.chiselLength)
                let tip = AlchemyPeopleKit.body(Self.chiselTip, d.rig)
                if Self.strikes.contains(frame) {
                    AlchemyPeopleProps.shavings(&d.svg, at: tip + P(1, -1), spread: 0)
                    d.burst(at: butt + P(0, -1.6), from: 120, to: 240, size: 0.7)
                } else if Self.strikes.contains((frame + 11) % 12) {
                    AlchemyPeopleProps.shavings(&d.svg, at: tip + P(1, -1), spread: 1)
                }
            }
            switch pose {
            case .standing, .walking:
                let hand = d.joints.frontHand
                let swing = pose == .walking ? 7 * BronzePeopleKit.wave(frame, 0.62) : 1.2 * BronzePeopleKit.wave(frame, 0.2)
                AlchemyPeopleProps.tote(&d.svg, handle: hand, swing: swing - d.rig.lean)
            case .fighting:
                let hand = d.joints.frontHand
                let degrees = d.rig.frontArm.upper - 4
                AlchemyPeopleProps.mallet(&d.svg, at: hand, degrees: degrees, haft: 12)
                if frame == 7 { d.swish(around: d.joints.frontShoulder, radius: 26, from: 165, to: 75) }
                if frame == 8 { d.impact(at: AlchemyPeopleProps.malletFace(at: hand, degrees: degrees, haft: 12), size: 0.9) }
            default:
                break
            }
            d.arm(front: true)
            d.head(nose: .hook, hair: { d in
                // Brown hair at the nape, and a sideburn down the cheek.
                d.svg.path("M-11.2,-61.4 C-12.8,-56.6 -11.6,-52 -7.8,-50.4 C-8.6,-52.4 -8.2,-54.2 -7.2,-55.6 C-8.8,-56.6 -8.8,-58.8 -7.6,-60.6 Z",
                           fill: .colour(AlchemyPeopleInk.brownHair))
                d.svg.path("M-7.4,-62.4 C-6.4,-60 -6.2,-57.4 -6.8,-54.6 C-5.4,-55.6 -4.6,-58 -4.8,-61 Z",
                           fill: .colour(AlchemyPeopleInk.brownHair))
                // A carpenter's pencil tucked behind his ear, its point forward.
                d.svg.line([P(-14.6, -55.6), P(-7.6, -63.4)], stroke: .colour(Ink.line), width: 2.4)
                d.svg.line([P(-14.3, -55.9), P(-8.4, -62.5)], stroke: .colour(AlchemyPeopleInk.paleGilt), width: 1.1)
            }, brow: { d in
                d.svg.path("M1.6,-63.4 q3.2,-1.8 6.8,-0.4", stroke: .colour(AlchemyPeopleInk.brownHair), width: 1.9)
            }, over: { d in
                Self.cap(&d)
            })
        }
    }

    /// The smock, the sash, and the half apron over it.
    static func smock(_ d: inout Drawing, sway: Double) {
        let hemBack = P(-15.4 - sway * 1.2, -13), hemFront = P(14 - sway * 1.2, -13)
        d.garment(colour: [P(-10.4, -46.4), P(9.4, -48), hemFront + P(1.4, 1.6), hemBack + P(-1, 1.4)],
                  outline: [P(-8.6, -47), P(8.6, -47), hemFront, hemBack], fill: .colour(AlchemyPeopleInk.light)) { d in
            // A shade down the back, where the linen folds.
            d.svg.polygon([P(-11.6, -40), P(-8, -40), P(-9.6, -14), hemBack + P(0.6, -0.4)].map(d.up),
                          fill: .colour(AlchemyPeopleInk.shadeLight))
            // The smocking: rows of teal stitches gathering the chest.
            var stitching = PathData()
            for (row, y) in [-43.6, -41.4, -39.2].enumerated() {
                var x = -7.6 + (row % 2 == 0 ? 0 : 1)
                var up = true
                stitching.move(d.up(P(x, y)))
                while x + 2 <= 8 {
                    x += 2; up.toggle()
                    stitching.line(d.up(P(x, y + (up ? 0 : 1.1))))
                }
            }
            d.svg.path(stitching, stroke: .colour(AlchemyPeopleInk.teal), width: 0.8)
            // The neck's opening and its tie.
            d.svg.path("M4.6,\(num(-47 - d.rig.lift)) l0.8,4.4", stroke: .colour(Ink.line), width: 0.8)
            // The sash, in the team's colour, edged in the smock's own linen.
            d.band([P(-13, -32.6), P(12.6, -33.4), P(13.2, -27.4), P(-13.6, -26.6)])
            d.svg.line([d.up(P(-13, -32.6)), d.up(P(12.6, -33.4))], stroke: .colour(Ink.line), width: 0.9)
            d.svg.line([P(-13.6, -26.6), P(13.2, -27.4)], stroke: .colour(Ink.line), width: 0.9)
        }
        // The half apron of teal canvas, from the sash to the knee, its pocket holding a chisel.
        let apronHem = (P(-2.6 - sway * 1.2, -6.4), P(16.4 - sway * 1.4, -7.4))
        let apron = [P(-3.4, -27.4), P(13.2, -27.6), apronHem.1, apronHem.0]
        d.svg.polygon(apron.map { $0 + P(-0.7, 0.6) }, fill: .colour(AlchemyPeopleInk.teal))
        d.svg.line([P(-2.2, -25.4), apronHem.0 + P(1, -1.2)], stroke: .colour(AlchemyPeopleInk.darkTeal), width: 0.9)
        d.svg.line([P(5.6, -26.6), (apronHem.0 + apronHem.1) * 0.5 + P(0, -1.4)], stroke: .colour(AlchemyPeopleInk.darkTeal), width: 0.9)
        // The chisel's handle above the pocket, and the pocket.
        d.svg.line([P(11.2, -25.6), P(10.6, -20.4)], stroke: .colour(Ink.line), width: 2.6)
        d.svg.line([P(11.2, -25.6), P(10.6, -20.4)], stroke: .colour(AlchemyPeopleInk.paleGilt), width: 1.3)
        BronzePeopleProps.shape(&d.svg, [P(6.6, -22), P(14, -22.4), P(14.6, -15.6), P(7.2, -15.2)], fill: .colour(AlchemyPeopleInk.darkTeal),
                                width: 0.9)
        var stitch = PathData()
        for i in 0..<5 { let x = 7.6 + Double(i) * 1.5; stitch.move(P(x, -21.2)); stitch.line(P(x + 0.7, -21.3)) }
        d.svg.path(stitch, stroke: .colour(AlchemyPeopleInk.paleTeal), width: 0.7)
        d.svg.polygon(apron, fill: .none, stroke: .colour(Ink.line), width: 1.3)
        // The knot of the sash, and its ends falling at the back hip.
        d.svg.ellipse(d.up(P(-11.8, -29.8)), 2, 2.6, fill: .team, stroke: .colour(Ink.line), width: 0.9)
        for (dx, length) in [(0.0, 8.6), (2.0, 6.8)] {
            let top = P(-12.6 + dx * 0.4, -28)
            let end = top + P(-1.8 - sway * 2 + dx * 0.4, length)
            d.svg.polygon([top + P(-1.1, 0), top + P(1.1, 0), end + P(0.9, 0), end + P(-0.9, 0)], fill: .team,
                          stroke: .colour(Ink.line), width: 0.9)
        }
    }

    /// A soft cap of wine-coloured wool, its crown slouched toward the back, on a rolled band.
    static func cap(_ d: inout Drawing) {
        BronzePeopleProps.shape(&d.svg, fill: .colour(AlchemyPeopleInk.wine), width: 1.5) { o in
            var p = PathData()
            p.move(P(-11.4, -62) + o)
            p.cubic(P(-17.4, -66) + o, P(-14, -76.4) + o, P(-3, -76) + o)
            p.cubic(P(5.6, -75.6) + o, P(10.8, -71) + o, P(10.4, -65.6) + o)
            p.cubic(P(3, -67.6) + o, P(-5, -66.4) + o, P(-11.4, -62) + o)
            p.close()
            return p
        }
        // The folds of the slouch.
        d.svg.path("M-12.6,-66.6 q3.4,-1.6 6.4,-0.4 M-6,-73.4 q3,1.4 4.2,4", stroke: .colour(AlchemyPeopleInk.darkWine), width: 1)
        // The rolled band.
        d.svg.path("M10.4,-65.2 C3,-67.8 -5,-66.6 -11.6,-62.2", stroke: .colour(Ink.line), width: 3.6)
        d.svg.path("M10.4,-65.2 C3,-67.8 -5,-66.6 -11.6,-62.2", stroke: .colour(AlchemyPeopleInk.paleWine), width: 2)
    }
}
