// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// MARK: - The banker (merchant)

/// A portly banker in a long gown of wine, its collar, its short puffed
/// sleeves, its hem and the edges of its opening faced with marten fur, the
/// doublet beneath in the team's colour, showing at the chest and the forearm, a flat bonnet of black velvet with a gilt brooch, brown
/// hair cut level at the neck, a clean-shaven double chin, and a gilt ring on
/// his finger; nose B. He carries his ledger under his arm, a purse at his
/// belt; at work a strongbox stands open at his feet, the ledger open in his
/// far hand, and he counts coin from his palm into it, one coin falling after
/// another, murmuring the count.
struct AlchemyPeopleBanker: PersonLook {
    func rig(_ pose: SpritePose, _ frame: Int) -> Rig? {
        switch pose {
        case .standing:
            var r = Moves.standing(frame)
            // The thumb in his belt, the other arm keeping the ledger.
            r.frontArm = BronzePeopleKit.reach(BronzePeopleKit.frontShoulder(r), P(10.6, -27.6))
            r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(-10, -30.4 - r.lift * 0.5))
            r.mouth = .smile
            return r
        case .walking:
            var r = Moves.walking(frame, stride: 17, kneeLift: 32, armSwing: 18)
            r.lean = -1
            r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(-10, -30.4))
            r.mouth = .smile
            return r
        case .working:
            return counting(frame)
        default:
            return nil
        }
    }

    // MARK: Counting

    /// The frames on which a coin leaves his hand, and how many frames it falls.
    static let releases = [1, 7]
    static let fall = 4

    /// The counting hand over the box: it tips a coin off with each release and settles again.
    static func countingHand(_ frame: Int) -> P {
        let tip: [Double] = [0, 1.2, 0.4, 0, 0, -0.4, 0, 1.2, 0.4, 0, 0, -0.4]
        return P(17.6 + tip[frame] * 0.6, -31.4 + tip[frame])
    }

    func counting(_ frame: Int) -> Rig {
        var r = Moves.standing(frame)
        r.lean = 6
        r.frontArm = AlchemyPeopleKit.reach(front: true, r, to: Self.countingHand(frame))
        r.backArm = BronzePeopleKit.reach(BronzePeopleKit.backShoulder(r), P(4.6, -33.4))
        r.headTilt = 9
        r.eyes = frame == 11 ? .closed : .down
        r.mouth = [Mouth.murmur, .open, .murmur, .smile, .murmur, .murmur, .murmur, .open, .murmur, .smile, .murmur, .smile][frame]
        return r
    }

    /// The strongbox at his feet: its left edge, width and height.
    static let boxLeft = 12.6, boxWidth = 17.0, boxHeight = 9.0

    /// Where a falling coin is in a frame, and how it is turned; nil when no coin is in the air.
    static func fallingCoin(_ frame: Int) -> (at: P, face: Double)? {
        for release in releases {
            let k = (frame - release + 12) % 12
            guard k < fall else { continue }
            let start = countingHand(release) + P(1.4, 2.4)
            let end = P(boxLeft + boxWidth * 0.5 + 1, -boxHeight - 3.6)
            let t = Double(k + 1) / Double(fall)
            return (P(mix(start.x, end.x, t), mix(start.y, end.y, t * t)), cos(Double(k) * 1.3))
        }
        return nil
    }

    // MARK: Drawing

    func draw(_ d: inout Drawing, _ pose: SpritePose, _ frame: Int) {
        let sway = d.rig.sway
        if pose == .working {
            AlchemyPeopleProps.strongbox(&d.svg, left: Self.boxLeft, width: Self.boxWidth, height: Self.boxHeight)
            if let coin = Self.fallingCoin(frame) {
                AlchemyPeopleProps.coin(&d.svg, at: coin.at, face: coin.face, radius: 2)
            }
            // The chink as a coin lands in the heap.
            if Self.releases.contains((frame - Self.fall + 12) % 12) {
                let heap = P(Self.boxLeft + Self.boxWidth * 0.5 + 1, -Self.boxHeight - 5)
                d.svg.path("M\(num(heap.x - 4)),\(num(heap.y - 1)) l-1.6,-1.6 M\(num(heap.x)),\(num(heap.y - 2.6)) l0,-2.2 "
                           + "M\(num(heap.x + 4)),\(num(heap.y - 1)) l1.6,-1.6", stroke: .colour(Ink.line), width: 1)
            }
        }
        d.figure { d in
            d.arm(front: false)
            d.legs()
            Self.gown(&d, sway: sway, pose: pose, frame: frame)
            // The ledger: under his arm, or open in his far hand while he counts.
            if pose == .working {
                AlchemyPeopleProps.ledger(&d.svg, at: d.joints.backHand + P(1.4, -0.6), degrees: -14, ribbon: 0.3 * BronzePeopleKit.wave(frame))
                d.hand(d.joints.backHand)
            } else {
                AlchemyPeopleProps.book(&d.svg, at: d.up(P(-12.8, -34.6)), degrees: 10, cover: AlchemyPeopleInk.darkWine, width: 8.4, height: 12.4)
                d.hand(d.joints.backHand)
            }
            Self.sleeve(&d)
            let hand = d.joints.frontHand
            if pose == .working {
                // The coins still to be counted, in a short stack on his palm.
                let left = 3 - [0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2][frame]
                for i in 0..<max(left, 1) {
                    AlchemyPeopleProps.coin(&d.svg, at: hand + P(1.6, -1.2 - Double(i) * 1.1), face: 0.35, radius: 2)
                }
            }
            d.hand(hand)
            // The gilt ring.
            d.svg.circle(hand + P(0.8, 0.6), 0.7, fill: .colour(AlchemyPeopleInk.gilt), stroke: .colour(Ink.line), width: 0.5)
            d.head(nose: .button, behind: { d in
                // His hair, cut level at the neck below the bonnet.
                d.svg.path("M-12,-63 C-13.4,-58 -13,-53.2 -11.6,-50 L-6.4,-50.6 C-7.6,-54 -7.4,-58 -6,-62 Z",
                           fill: .colour(AlchemyPeopleInk.brownHair), stroke: .colour(Ink.line), width: 1)
            }, hair: { d in
                d.svg.path("M-10.8,-63.2 C-11.8,-58.6 -11.2,-54.4 -9.6,-51 L-7.4,-51.6 C-8.6,-55 -8.4,-59 -7.2,-62.6 Z",
                           fill: .colour(AlchemyPeopleInk.brownHair))
            }, features: { d in
                // A double chin, and a dimple of the smile.
                d.svg.path("M-1.6,-48.6 q5,3.6 10.6,0.4", stroke: .colour(Ink.line), width: 1.1)
                d.svg.path("M10.6,-52.6 q0.8,0.4 0.8,1.2", stroke: .colour(Ink.line), width: 0.8)
            }, brow: { d in
                d.svg.path("M2.2,-64 q3,-1.6 6.2,-0.6", stroke: .colour(AlchemyPeopleInk.brownHair), width: 1.5)
            }, over: { d in
                Self.bonnet(&d)
            })
        }
    }

    /// The gown, its fur, the doublet between, the belt and the purse.
    static func gown(_ d: inout Drawing, sway: Double, pose: SpritePose, frame: Int) {
        let hemBack = P(-17.6 - sway * 1.4, -7.4), hemFront = P(17 - sway * 1.4, -7.4)
        func gownPath(_ o: P) -> PathData {
            var p = PathData()
            p.move(d.up(P(-9.6, -47.4)) + o)
            p.line(d.up(P(9.4, -47.4)) + o)
            p.cubic(d.up(P(16.4, -41)) + o, P(20.4, -27) + o, hemFront + o)
            p.line(hemBack + o)
            p.cubic(P(-16.4, -24) + o, d.up(P(-14.6, -40)) + o, d.up(P(-9.6, -47.4)) + o)
            p.close()
            return p
        }
        d.svg.path(gownPath(P(-0.8, 0.8)), fill: .colour(AlchemyPeopleInk.wine))
        // The folds of the gown, falling from the belt.
        var folds = PathData()
        for (top, bottom) in [(P(-9, -24), P(-11.6, -8)), (P(-3, -24), P(-4, -8)), (P(11, -24), P(12.4, -8))] {
            folds.move(top); folds.quad((top + bottom) * 0.5 + P(-1 - sway, 0), bottom + P(-sway, 0))
        }
        d.svg.path(folds, stroke: .colour(AlchemyPeopleInk.darkWine), width: 1.1)
        // The doublet in the team's colour, showing between the fur at the chest; its buttons.
        d.band([P(-2, -46.8), P(10.6, -46.8), P(13.4, -26.6), P(-2, -26.6)])
        var buttons = PathData()
        for i in 0..<4 { let y = -43 + Double(i) * 4.2; buttons.move(d.up(P(4.6, y))); buttons.line(d.up(P(4.8, y + 0.2))) }
        d.svg.path(buttons, stroke: .colour(Ink.line), width: 1.5)
        d.svg.line([d.up(P(3.4, -46.4)), P(3.6, -27)], stroke: .colour(Ink.line), width: 0.8)
        // The fur: down the near edge of the opening to the hem, along the front edge, and the collar over the shoulders.
        Self.fur(&d, [P(-5, -46.4), P(-1.6, -46.4), P(-1.8, -26), P(-1.2, -8), P(-5 - sway * 0.6, -8)].map { $0.y < -20 ? d.up($0) : $0 })
        Self.fur(&d, [P(10.8, -46), P(14, -40.6), P(15.8, -26.4), P(13.2, -26.6)].map(d.up))
        Self.fur(&d, [P(-11.4, -48), P(-1.4, -48.8), P(-1.6, -45), P(-12.8, -43.4)].map(d.up))
        // The fur along the hem.
        Self.fur(&d, [hemBack + P(0.4, -3), hemFront + P(-0.4, -3), hemFront, hemBack])
        d.svg.path(gownPath(P(0, 0)), stroke: .colour(Ink.line), width: 1.8)
        // The belt of black leather across him, and the purse hanging from it.
        d.svg.polygon([P(-15, -28.4), P(16.6, -28.4), P(16.8, -25.4), P(-15.2, -25.4)], fill: .colour(AlchemyPeopleInk.velvet),
                      stroke: .colour(Ink.line), width: 0.9)
        d.svg.path(BronzePeopleProps.rounded(P(8.4, -26.9), width: 3, height: 3.4, radius: 0.6, degrees: 0, shift: P(0, 0)),
                   stroke: .colour(AlchemyPeopleInk.gilt), width: 0.9)
        let purseSwing = pose == .walking ? 8 * BronzePeopleKit.wave(frame, 0.3) : 0
        AlchemyPeopleProps.purse(&d.svg, at: P(-6.4, -25.6), swing: purseSwing)
    }

    /// A strip of marten fur along `points`: brown, its tips picked out in short pale strokes.
    static func fur(_ d: inout Drawing, _ points: [P]) {
        d.svg.polygon(points.map { $0 + P(-0.5, 0.5) }, fill: .colour(AlchemyPeopleInk.fur))
        var tips = PathData()
        for (a, b) in zip(points, points.dropFirst() + [points[0]]) {
            let along = b - a
            let length = BronzePeopleKit.length(along)
            guard length > 2 else { continue }
            var s = 1.2
            while s < length - 0.8 {
                let c = a + along * (s / length)
                tips.move(c); tips.line(c + P(0.5, 1.2))
                s += 2.6
            }
        }
        d.svg.path(tips, stroke: .colour(AlchemyPeopleInk.paleFur), width: 0.8)
        d.svg.polygon(points, fill: .none, stroke: .colour(Ink.line), width: 1)
    }

    /// The front arm's sleeves: the gown's short sleeve puffed with fur on
    /// the upper arm, and the doublet's sleeve below it in the team's colour,
    /// ending in a linen cuff.
    static func sleeve(_ d: inout Drawing) {
        let shoulder = d.joints.frontShoulder, elbow = d.joints.frontElbow, hand = d.joints.frontHand
        let along = hand - elbow
        let length = max(BronzePeopleKit.length(along), 0.01)
        let u = along * (1 / length), a = P(-u.y, u.x)
        let wrist = elbow + u * (length - 1.8)
        // The doublet's sleeve, close on the forearm.
        let forearm = [elbow + a * 2.2 - u * 1, elbow - a * 2.2 - u * 1, wrist - a * 1.8, wrist + a * 1.8]
        d.svg.polygon(forearm, fill: .team, stroke: .colour(Ink.line), width: 1.1)
        // The linen cuff.
        d.svg.polygon([wrist + a * 2.2, wrist - a * 2.2, wrist - a * 2 + u * 1.4, wrist + a * 2 + u * 1.4], fill: .colour(AlchemyPeopleInk.light),
                      stroke: .colour(Ink.line), width: 0.8)
        // The puffed upper sleeve of fur.
        let upper = elbow - shoulder
        let ul = max(BronzePeopleKit.length(upper), 0.01)
        let uu = upper * (1 / ul), ua = P(-uu.y, uu.x)
        let middle = shoulder + uu * (ul * 0.5)
        var puff: [P] = []
        for i in 0...10 {
            let t = Double(i) / 10 * .pi
            puff.append(middle + uu * (-cos(t) * (ul * 0.5 + 1.2)) + ua * (sin(t) * 4.2))
        }
        for i in 0...10 {
            let t = Double(i) / 10 * .pi
            puff.append(middle + uu * (cos(t) * (ul * 0.5 + 1.2)) - ua * (sin(t) * 3.8))
        }
        Self.fur(&d, puff)
        d.svg.line([middle - ua * 3.4, middle + ua * 3.8], stroke: .colour(AlchemyPeopleInk.darkFur), width: 0.9)
    }

    /// A flat bonnet of black velvet, its broad brim turned up at the side, a gilt brooch on it.
    static func bonnet(_ d: inout Drawing) {
        BronzePeopleProps.shape(&d.svg, fill: .colour(AlchemyPeopleInk.velvet), width: 1.5) { o in
            var p = PathData()
            p.move(P(-9.6, -65.6) + o)
            p.cubic(P(-10, -72) + o, P(8.6, -73.6) + o, P(9.4, -66.6) + o)
            p.close()
            return p
        }
        BronzePeopleProps.shape(&d.svg, fill: .colour(AlchemyPeopleInk.velvet), width: 1.5) { o in
            var p = PathData()
            p.move(P(-15.4, -63.6) + o)
            p.cubic(P(-12, -68.6) + o, P(10, -70.6) + o, P(16.4, -66.4) + o)
            p.cubic(P(15.4, -63.8) + o, P(10, -64.2) + o, P(1, -64.4) + o)
            p.cubic(P(-7, -64.2) + o, P(-12, -62) + o, P(-15.4, -63.6) + o)
            p.close()
            return p
        }
        // The velvet's sheen, and the brooch.
        d.svg.path("M-11,-65.8 q8,-3.4 22,-1.2", stroke: .colour(AlchemyPeopleInk.velvetSheen), width: 0.9)
        d.svg.path("M-4,-71 q4,-1.4 8,-0.4", stroke: .colour(AlchemyPeopleInk.velvetSheen), width: 0.8)
        d.svg.circle(P(-8.6, -67.4), 1.6, fill: .colour(AlchemyPeopleInk.gilt), stroke: .colour(Ink.line), width: 0.8)
        d.svg.circle(P(-8.6, -67.4), 0.5, fill: .colour(AlchemyPeopleInk.paleGilt))
    }
}
