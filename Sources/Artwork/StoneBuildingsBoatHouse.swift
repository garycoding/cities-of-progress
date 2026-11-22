// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import GameCore

// The boat house of the Stone age (ruled 2026-11-21): a shelter of thatch on
// wooden piles at the water's edge. A deck of poles stands on the piles; on
// it a ridged roof of thatch, open at its end, shelters a dugout canoe whose
// bow shows under the gable. The deck's front board is painted in the team's
// colour with a zigzag, and the team's pennant flies from the gable. A short
// landing stage runs from the open end to the edge of the footprint, with a
// mooring post at its end; fish hang to dry on a rack, and reeds grow at the
// footprint's corners. The footprint lies on land and the water may lie
// beside any of its edges, so the stage reads as the way down to it. Under
// construction: the piles and part of the deck, the rafters of the roof tied
// to the ridge pole with the pennant on them, sheaves of thatch, and a log
// being hollowed into a canoe, an adze left in it.

/// The boat house's measurements, about the centre of its footprint (2 by 2):
/// distances in tiles along the map's axes, heights in points.
private enum Shed {
    /// The deck: its extent and height.
    static let x0 = -0.8, x1 = 0.4, y0 = -0.56, y1 = 0.44, deck = 7.0
    /// The roof: its ridge runs along x over `ridgeY`; its eaves overhang the deck.
    static let roofX0 = -0.86, roofX1 = 0.44, ridgeY = -0.06, ridge = 50.0
    static let eaveReach = 0.62, eave = 23.0
    /// The landing stage, from the open end to the footprint's edge.
    static let stageX1 = 0.96, stageY0 = -0.2, stageY1 = 0.12, stage = 5.5
}

private func spot(_ x: Double, _ y: Double, _ h: Double = 0) -> P { StoneBuildingsSketch.at(x, y, h) }

extension StoneBuildingsSketch {
    mutating func boatHouse(complete: Bool) {
        earth(2)
        reeds(at: spot(-0.82, 0.86), turn: 0)
        reeds(at: spot(0.86, -0.84), turn: 1)
        if complete {
            shed()
            fishRack(at: spot(-0.42, 0.84))
        } else {
            shedFrame()
        }
    }

    // MARK: The complete boat house

    private mutating func shed() {
        let (x0, x1, y0, y1, deck) = (Shed.x0, Shed.x1, Shed.y0, Shed.y1, Shed.deck)
        // The roof's shadow on the ground, to the right, and the shade under the deck.
        shadow(StoneBuildingsOutline([spot(x0 + 0.1, y0 - 0.1), spot(x1 + 0.22, y0 - 0.1), spot(x1 + 0.22, y1 + 0.12),
                                      spot(x0 + 0.1, y1 + 0.12)]), opacity: 0.18)
        // The piles behind, in the shade under the deck.
        for (x, y) in [(x0, y0), (x1, y0), (-0.2, y0)] { pile(x, y, top: deck, colour: Ink.handle) }
        stage()
        deckBoards()
        // The open end of the shed, and what shows through it.
        let gable = [spot(x1, y1, deck), spot(x1, y0, deck), spot(Shed.roofX1, Shed.ridgeY - Shed.eaveReach, Shed.eave),
                     spot(Shed.roofX1, Shed.ridgeY, Shed.ridge), spot(Shed.roofX1, Shed.ridgeY + Shed.eaveReach, Shed.eave)]
        colour(gable, .colour(StoneBuildingsInk.hollow), shift: P(0, 0))
        // The far posts, and the canoe resting on the deck, its bow out under the gable.
        for x in [x0 + 0.04, -0.2] { pole(spot(x, y0 + 0.04, deck), spot(x, y0 + 0.04, Shed.eave + 3), width: 2.4, colour: Ink.handle) }
        restingCanoe(from: -0.62, to: 0.62, y: -0.08, h: deck + 0.5)
        paddleLeaning(at: spot(x1 - 0.06, y0 + 0.1, deck))
        // The posts at the open end, and the tie beam across under the gable.
        for y in [y0 + 0.04, y1 - 0.04] { pole(spot(x1, y, deck - 0.5), spot(x1, y, Shed.eave + 1.5), width: 2.6) }
        pole(spot(x1, y0 - 0.08, Shed.eave), spot(x1, y1 + 0.1, Shed.eave), width: 2.2)
        // The near posts, under the eaves.
        for x in [x0 + 0.04, -0.2] { pole(spot(x, y1 - 0.04, deck - 0.5), spot(x, y1 - 0.04, Shed.eave + 1.5), width: 2.6) }
        deckEdges()
        roof()
        // The piles in front of the deck's faces.
        for (x, y) in [(x0, y1), (-0.2, y1), (x1, y1), (x1, -0.06)] { pile(x, y, top: deck, colour: Ink.wood) }
        mooringPost(at: spot(Shed.stageX1 - 0.03, Shed.stageY1 + 0.02))
    }

    /// A pile from below the ground up to `top`, with a lashing under the deck.
    private mutating func pile(_ x: Double, _ y: Double, top: Double, colour: String) {
        pole(spot(x, y, -1), spot(x, y, top + 0.5), width: 3, colour: colour)
        stroke([spot(x, y, top - 1.6) + P(-1.6, 0), spot(x, y, top - 1.6) + P(1.6, 0)], width: 1, colour: Ink.darkHide)
    }

    /// The deck's top: poles laid across it, side by side, in the light under the roof.
    private mutating func deckBoards() {
        let (x0, x1, y0, y1, h) = (Shed.x0, Shed.x1, Shed.y0, Shed.y1, Shed.deck)
        shape([spot(x0, y0, h), spot(x1, y0, h), spot(x1, y1, h), spot(x0, y1, h)], .colour(StoneBuildingsInk.woodEnd), line: 1)
        for x in stride(from: x0 + 0.1, to: x1, by: 0.1) {
            stroke([spot(x, y0 + 0.02, h), spot(x, y1 - 0.02, h)], width: 0.6, colour: Ink.wood)
        }
    }

    /// The deck's two faces toward the viewer: the long one painted in the
    /// team's colour with a zigzag in the light colour, the end one in shade.
    private mutating func deckEdges() {
        let (x0, x1, y0, y1, h) = (Shed.x0, Shed.x1, Shed.y0, Shed.y1, Shed.deck)
        let low = h - 4.4
        let front = [spot(x0, y1, low), spot(x1, y1, low), spot(x1, y1, h), spot(x0, y1, h)]
        colour(front, .team, shift: StoneBuildingsSketch.nudge)
        zigzag(StoneBuildingsSketch.points(from: spot(x0 + 0.04, y1, low + 1.1), to: spot(x1 - 0.04, y1, low + 1.1), count: 14),
               tooth: P(0, -2.2), width: 1, colour: Ink.light)
        stroke(StoneBuildingsOutline(front), width: 1.1)
        shape([spot(x1, y1, low), spot(x1, y0, low), spot(x1, y0, h), spot(x1, y1, h)], .colour(Ink.wood), line: 1.1,
              shift: StoneBuildingsSketch.nudge)
        colour([spot(x1, y1, low), spot(x1, y0, low), spot(x1, y0, h), spot(x1, y1, h)], .colour(Ink.line), shift: P(0, 0),
               opacity: 0.18)
        // The ends of the deck's poles along the end face.
        for y in stride(from: y1 - 0.08, to: y0, by: -0.1) {
            svg.ellipse(spot(x1, y, h - 1.4), 1.3, 1.1, fill: .colour(StoneBuildingsInk.woodEnd), stroke: .colour(Ink.line), width: 0.6)
        }
    }

    /// The ridged roof of thatch: the near slope lit, the open gable's edge
    /// in shade, the courses in rows of scallops, the eaves' ragged ends, the
    /// bound roll along the ridge, and the pennant at the gable's peak.
    private mutating func roof() {
        let (rx0, rx1, ry, reach) = (Shed.roofX0, Shed.roofX1, Shed.ridgeY, Shed.eaveReach)
        let near = ry + reach, far = ry - reach
        let lip = 3.2
        // The thickness of the thatch along the near eaves and up the gable's edge.
        shape([spot(rx0, near, Shed.eave), spot(rx1, near, Shed.eave), spot(rx1, near, Shed.eave - lip), spot(rx0, near, Shed.eave - lip)],
              .colour(StoneBuildingsInk.thatchDeep), line: 1.1)
        let barge = [spot(rx1, far, Shed.eave), spot(rx1, ry, Shed.ridge), spot(rx1, near, Shed.eave)]
        shape(barge + [spot(rx1, near, Shed.eave - lip), spot(rx1 + 0.03, ry, Shed.ridge - lip), spot(rx1, far, Shed.eave - lip)],
              .colour(StoneBuildingsInk.thatchShade), line: 1.1)
        // The near slope, and its courses.
        let slope = [spot(rx0, near, Shed.eave), spot(rx1, near, Shed.eave), spot(rx1, ry, Shed.ridge), spot(rx0, ry, Shed.ridge)]
        shape(slope, .colour(Ink.hide))
        // The slope darkens a little toward the far end, away from the light.
        colour([spot(rx0, near, Shed.eave), spot(rx0 + 0.3, near, Shed.eave), spot(rx0 + 0.3, ry, Shed.ridge), spot(rx0, ry, Shed.ridge)],
               .colour(StoneBuildingsInk.thatchShade), shift: P(0, 0), opacity: 0.45)
        for f in [0.22, 0.44, 0.66, 0.86] {
            let y = ry + reach * f, h = Shed.ridge - (Shed.ridge - Shed.eave) * f
            let row = StoneBuildingsSketch.points(from: spot(rx0 + 0.04, y, h), to: spot(rx1 - 0.04, y, h), count: 13)
            scallops(row, width: 0.9, opacity: 0.85) { _ in P(-0.25, 1.1) }
        }
        stroke(StoneBuildingsOutline(slope), width: 1.2)
        // The straw ends along the eaves.
        let edge = StoneBuildingsSketch.points(from: spot(rx0, near, Shed.eave - lip), to: spot(rx1, near, Shed.eave - lip), count: 15)
        scallops(edge, width: 1) { _ in P(0, 0.9) }
        // The roll of thatch bound along the ridge.
        let roll = [spot(rx0 - 0.03, ry, Shed.ridge + 2.2), spot(rx1 + 0.03, ry, Shed.ridge + 2.2), spot(rx1 + 0.03, ry, Shed.ridge - 1.4),
                    spot(rx0 - 0.03, ry, Shed.ridge - 1.4)]
        shape(roll, .colour(StoneBuildingsInk.thatchShade), line: 1.1, shift: StoneBuildingsSketch.nudge)
        for x in stride(from: rx0 + 0.12, to: rx1, by: 0.26) {
            stroke([spot(x, ry, Shed.ridge + 2.2), spot(x, ry, Shed.ridge - 1.4)], width: 1.5, colour: Ink.darkHide)
        }
        // Crossed poles over the gable's peak, the pennant tied to them.
        let peak = spot(rx1, ry, Shed.ridge)
        pole(peak + P(-1, 2), peak + P(-6, -9), width: 2, colour: Ink.wood)
        pole(peak + P(1, 2), peak + P(6, -9), width: 2, colour: Ink.wood)
        pennant(at: peak + P(0, 1), height: 26)
    }

    /// A dugout canoe resting on the deck along the map's x axis, from `from`
    /// to `to` tiles at `y`, its bottom `h` points up: the near side of the
    /// hull, the hollow seen over its near gunwale, and its raised ends.
    private mutating func restingCanoe(from x0: Double, to x1: Double, y: Double, h: Double) {
        let steps = 12
        /// The hull's half width in tiles, and its gunwale's height, at a fraction along it.
        func beam(_ t: Double) -> Double { 0.13 * pow(sin(t * .pi), 0.6) }
        func gunwale(_ t: Double) -> Double { 7.5 + 3 * pow(abs(2 * t - 1), 3) }
        let ts = (0...steps).map { Double($0) / Double(steps) }
        func x(_ t: Double) -> Double { x0 + (x1 - x0) * t }
        let nearRim = ts.map { spot(x($0), y + beam($0), h + gunwale($0)) }
        let farRim = ts.map { spot(x($0), y - beam($0), h + gunwale($0)) }
        let keel = ts.map { spot(x($0), y + beam($0) * 0.55, h + (1 - sin($0 * .pi)) * 4) }
        // The hull's near side, from the near gunwale down to the keel.
        shape(StoneBuildingsOutline(nearRim + keel.reversed()), .colour(Ink.wood), line: 1.1)
        // The hollow, between the gunwales.
        shape(StoneBuildingsOutline(farRim + nearRim.reversed()), .colour(StoneBuildingsInk.hollow), line: 1,
              shift: P(0, 0))
        colour(StoneBuildingsOutline(farRim + farRim.reversed().map { $0 + P(0, 2.4) }), .colour(Ink.handle), shift: P(0, 0))
        // The adze marks along its side, and a light along its gunwale.
        for t in [0.3, 0.45, 0.6, 0.75] {
            stroke([spot(x(t), y + beam(t), h + gunwale(t) - 2), spot(x(t) + 0.04, y + beam(t), h + gunwale(t) - 4.2)],
                   width: 0.7, colour: Ink.handle)
        }
        stroke(nearRim.map { $0 + P(0, 1) }, width: 0.8, colour: StoneBuildingsInk.woodEnd)
    }

    /// A paddle leaning on a post at the open end, its leaf-shaped blade down.
    private mutating func paddleLeaning(at foot: P) {
        let top = foot + P(5, -24)
        pole(foot + P(1.4, -7), top, width: 1.6, colour: Ink.handle, line: 0.8)
        var blade = StoneBuildingsOutline()
        let a = foot + P(1.8, -7.6)
        blade.move(a)
        blade.quad(foot + P(-2.4, -3.4), foot + P(-0.4, 0.4))
        blade.quad(foot + P(3.6, -2.6), a)
        blade.close()
        shape(blade, .colour(Ink.wood), line: 0.9, shift: StoneBuildingsSketch.nudge)
        shape([top + P(-2.2, -0.6), top + P(2.2, 0.6), top + P(1.8, 1.8), top + P(-2.6, 0.6)], .colour(Ink.handle), line: 0.8,
              shift: StoneBuildingsSketch.nudge)
    }

    /// The landing stage: poles laid across two stringers on four piles, running
    /// from the open end of the shed to the footprint's edge.
    private mutating func stage() {
        let (sx0, sx1, sy0, sy1, h) = (Shed.x1 - 0.02, Shed.stageX1, Shed.stageY0, Shed.stageY1, Shed.stage)
        shadow(StoneBuildingsOutline([spot(sx0, sy0 - 0.04), spot(sx1 + 0.06, sy0 - 0.04), spot(sx1 + 0.06, sy1 + 0.06),
                                      spot(sx0, sy1 + 0.06)]), opacity: 0.14)
        for (x, y) in [(sx1 - 0.03, sy0 + 0.02), (0.68, sy0 + 0.02)] { pole(spot(x, y, -1), spot(x, y, h), width: 2.6, colour: Ink.handle) }
        // The stringers, then the poles across them.
        pole(spot(sx0, sy0 + 0.03, h - 1.2), spot(sx1, sy0 + 0.03, h - 1.2), width: 2, colour: Ink.handle)
        pole(spot(sx0, sy1 - 0.03, h - 1.2), spot(sx1, sy1 - 0.03, h - 1.2), width: 2, colour: Ink.handle)
        for x in stride(from: sx0 + 0.03, through: sx1 - 0.02, by: 0.072) {
            pole(spot(x, sy0 - 0.02, h), spot(x, sy1 + 0.02, h), width: 2.4, colour: Ink.wood, line: 0.8)
        }
        for (x, y) in [(sx1 - 0.03, sy1 - 0.02), (0.68, sy1 - 0.02)] { pole(spot(x, y, -1), spot(x, y, h - 1), width: 2.6, colour: Ink.wood) }
    }

    /// The mooring post at the stage's end, a rope coiled round its head.
    private mutating func mooringPost(at foot: P) {
        pole(foot + P(0, 1), foot - P(0, 15), width: 3, colour: Ink.wood)
        svg.ellipse(foot - P(0, 15), 1.5, 0.8, fill: .colour(StoneBuildingsInk.woodEnd), stroke: .colour(Ink.line), width: 0.7)
        for k in 0..<3 {
            let y = 11.5 - Double(k) * 1.4
            svg.ellipse(foot - P(0, y), 2.6, 0.9, fill: .none, stroke: .colour(StoneBuildingsInk.straw), width: 1.1)
        }
        stroke([foot - P(-2.2, 10.2), foot + P(3.6, -4), foot + P(4.4, -0.6)], width: 0.9, colour: StoneBuildingsInk.straw)
    }

    /// A rack of two forked posts and a bar, with fish hung from it to dry.
    private mutating func fishRack(at foot: P) {
        moved(to: foot) { s in
            let along = P(16, -8), up = P(0, -19)
            s.shadow(StoneBuildingsSketch.lump(along * 0.5 + P(2, 1), 11, 3))
            s.pole(P(0, 1), up + P(0, -1), width: 2.2)
            s.pole(along + P(0, 1), along + up + P(0, -1), width: 2.2)
            s.pole(up - P(1.5, -0.8), along + up + P(1.5, -0.8), width: 1.8, colour: Ink.handle)
            for k in 0..<4 {
                let t = (Double(k) + 0.6) / 4.2
                let hang = up + along * t + P(0, 1)
                s.stroke([hang, hang + P(0, 2.4)], width: 0.6)
                s.hungFish(at: hang + P(0, 2.4), length: 8 - Double(k % 2) * 1.4)
            }
        }
    }

    /// A fish hung by its tail: a pale body darker along its back, with an eye.
    private mutating func hungFish(at top: P, length: Double) {
        var body = StoneBuildingsOutline()
        body.move(top + P(-1.6, -0.6))
        body.line(top + P(0, 1.4))
        body.line(top + P(1.6, -0.6))
        body.quad(top + P(1.2, 2.6), top + P(1.8, length * 0.55))
        body.quad(top + P(1.2, length), top + P(0, length + 0.6))
        body.quad(top + P(-1.2, length), top + P(-1.8, length * 0.55))
        body.quad(top + P(-1.2, 2.6), top + P(-1.6, -0.6))
        body.close()
        shape(body, .colour(Ink.light), line: 0.8, shift: StoneBuildingsSketch.nudge)
        colour([top + P(0.4, 2.2), top + P(1.6, length * 0.55), top + P(0.6, length - 0.4)], .colour(Ink.ground),
               shift: P(0, 0), opacity: 0.9)
        svg.circle(top + P(-0.2, length - 1.4), 0.5, fill: .colour(Ink.line))
    }

    /// A clump of reeds at the water's edge: blades of moss and two seed heads.
    private mutating func reeds(at foot: P, turn: Int) {
        moved(to: foot) { s in
            s.shadow(StoneBuildingsSketch.lump(P(0.5, 0.4), 7, 2.2))
            let blades: [(Double, Double)] = turn == 0
                ? [(-4.5, -9), (-2, -14), (0.5, -11), (3, -15), (5, -8)]
                : [(-4, -11), (-1.5, -15), (1.5, -10), (4, -13)]
            for (i, (x, h)) in blades.enumerated() {
                var d = PathData()
                d.move(P(x * 0.4 - 0.8, 0.4))
                d.quad(P(x * 0.7, h * 0.5), P(x, h))
                d.quad(P(x * 0.7 + 0.6, h * 0.5), P(x * 0.4 + 0.8, 0.4))
                d.close()
                s.svg.path(d, fill: .colour(i % 2 == 0 ? Ink.moss : Ink.darkMoss), stroke: .colour(Ink.line), width: 0.6)
            }
            for (x, h) in turn == 0 ? [(-1.0, -17.0), (2.4, -18.5)] : [(0.0, -18.0)] {
                s.stroke([P(x * 0.4, 0), P(x, h + 3)], width: 0.7, colour: Ink.darkMoss)
                s.svg.ellipse(P(x, h + 1), 1.2, 2.6, fill: .colour(Ink.darkHide), stroke: .colour(Ink.line), width: 0.6)
            }
        }
    }

    // MARK: Under construction

    /// The boat house being built: the piles and part of the deck, the roof's
    /// rafters tied to the ridge pole, sheaves of thatch, and a log being hollowed.
    private mutating func shedFrame() {
        let (x0, x1, y0, y1, deck) = (Shed.x0, Shed.x1, Shed.y0, Shed.y1, Shed.deck)
        let (rx0, rx1, ry, reach) = (Shed.roofX0 + 0.04, Shed.roofX1 - 0.04, Shed.ridgeY, Shed.eaveReach - 0.08)
        shadow(StoneBuildingsOutline([spot(x0 + 0.1, y0), spot(x1 + 0.16, y0), spot(x1 + 0.16, y1 + 0.08), spot(x0 + 0.1, y1 + 0.08)]),
               opacity: 0.12)
        for (x, y) in [(x0, y0), (x1, y0), (-0.2, y0)] { pile(x, y, top: deck, colour: Ink.handle) }
        // The bearers, and the deck's poles laid over half of them.
        pole(spot(x0, y0, deck - 1), spot(x0, y1, deck - 1), width: 2.4, colour: Ink.handle)
        pole(spot(-0.2, y0, deck - 1), spot(-0.2, y1, deck - 1), width: 2.4, colour: Ink.handle)
        pole(spot(x1, y0, deck - 1), spot(x1, y1, deck - 1), width: 2.4, colour: Ink.handle)
        shape([spot(x0, y0, deck), spot(-0.14, y0, deck), spot(-0.14, y1, deck), spot(x0, y1, deck)], .colour(StoneBuildingsInk.woodEnd),
              line: 1)
        for x in stride(from: x0 + 0.1, to: -0.14, by: 0.1) {
            stroke([spot(x, y0 + 0.02, deck), spot(x, y1 - 0.02, deck)], width: 0.6, colour: Ink.wood)
        }
        // The rafters in pairs, crossed over the ridge pole, the far ones first.
        let pairs = stride(from: rx0, through: rx1 + 0.001, by: (rx1 - rx0) / 3).map { $0 }
        for x in pairs { pole(spot(x, ry - reach, deck), spot(x, ry, Shed.ridge + 3), width: 2.2, colour: Ink.handle) }
        pole(spot(rx0 - 0.05, ry, Shed.ridge), spot(rx1 + 0.05, ry, Shed.ridge), width: 2.6)
        for x in pairs {
            pole(spot(x, ry + reach, deck), spot(x, ry, Shed.ridge + 3), width: 2.2)
            stroke([spot(x, ry, Shed.ridge) + P(-2, -1), spot(x, ry, Shed.ridge) + P(2, 1)], width: 1.6, colour: Ink.darkHide)
        }
        // The front board, already painted.
        let low = deck - 4.4
        let front = [spot(x0, y1, low), spot(x1, y1, low), spot(x1, y1, deck), spot(x0, y1, deck)]
        colour(front, .team, shift: StoneBuildingsSketch.nudge)
        stroke(StoneBuildingsOutline(front), width: 1.1)
        for (x, y) in [(x0, y1), (-0.2, y1), (x1, y1)] { pile(x, y, top: deck, colour: Ink.wood) }
        pennant(at: spot(rx1, ry, Shed.ridge + 3), height: 22)
        // The stage's piles, set, with no deck on them yet.
        for (x, y) in [(Shed.stageX1 - 0.03, Shed.stageY0 + 0.02), (0.68, Shed.stageY0 + 0.02), (Shed.stageX1 - 0.03, Shed.stageY1 - 0.02),
                       (0.68, Shed.stageY1 - 0.02)] {
            pole(spot(x, y, -1), spot(x, y, Shed.stage), width: 2.6, colour: Ink.wood)
        }
        sheaves(at: spot(-0.3, 0.82))
        logBeingHollowed(at: spot(0.62, 0.58))
    }

    /// A log on two chocks, half hollowed into a canoe, chips about it and an adze left standing in it.
    private mutating func logBeingHollowed(at foot: P) {
        moved(to: foot) { s in
            let along = StoneBuildingsSketch.unit(P(32, -16))
            s.shadow(StoneBuildingsSketch.lump(along * 2 + P(1, 1), 17, 4.6))
            for k in [-9.0, 9.0] {
                s.shape([along * k + P(-3, 0.6), along * k + P(3, -0.6), along * k + P(3, -3), along * k + P(-3, -1.8)],
                        .colour(Ink.handle), line: 0.8, shift: StoneBuildingsSketch.nudge)
            }
            s.log(end: along * -13 + P(0, -6), toward: along, length: 27, radius: 4.4)
            // The hollow begun along its top, and the chips.
            var hollow = StoneBuildingsOutline()
            let a = along * -6 + P(0, -9.2), b = along * 8 + P(0, -9.2)
            hollow.move(a)
            hollow.quad((a + b) * 0.5 + P(0, -1.8), b)
            hollow.quad((a + b) * 0.5 + P(0, 1.8), a)
            hollow.close()
            s.colour(hollow, .colour(StoneBuildingsInk.woodEnd), shift: P(0, 0))
            s.stroke(hollow, width: 0.8)
            for c in [P(-12, 2), P(-7, 3.4), P(6, 2.6), P(12, 1), P(2, 4)] {
                s.shape([c + P(-1.2, 0.4), c + P(0.2, -0.8), c + P(1.4, 0.2), c + P(0, 0.9)], .colour(StoneBuildingsInk.straw),
                        line: 0.5, shift: P(0, 0))
            }
            // The adze: a haft standing from the hollow, its stone blade bound across it.
            let base = along * 3 + P(0, -9.6)
            s.pole(base, base + P(4, -13), width: 1.8, colour: Ink.handle, line: 0.8)
            s.shape([base + P(-1.2, 0.6), base + P(-4.6, 1.6), base + P(-4, -0.4), base + P(-0.6, -1.6)], .colour(Ink.stone),
                    line: 0.8, shift: StoneBuildingsSketch.nudge)
            s.stroke([base + P(-0.4, -1.4), base + P(0.8, 0.6)], width: 1.3, colour: Ink.darkHide)
        }
    }
}
