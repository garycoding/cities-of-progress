// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore

/// The people of the Bronze age, drawn in the Cartoon Modern style of
/// docs/art-style.md on the jointed figure every age shares (Figure.swift).
///
/// The four peaceful sectors take the look of their owner's age, and the
/// warfighters keep the look of their own (`SpriteSubject.of(_:ownerAge:)`), so
/// this source supplies `SpriteSubject.unit(kind, .bronze)` for the herder
/// (worker), the scribe (scholar), the mason (engineer), the trader (merchant),
/// the spearman, the archer and the chariot, in every pose that the artwork's
/// checklist (`SpriteKey.required(through: .bronze)`) lists for them, each a
/// cycle of 12 frames (`SpriteKey.frame` 0 to 11). The checklist lists a working
/// pose for every kind; the warfighters never work, so theirs is their standing
/// cycle. Every other key returns nil.
///
/// Each call draws its picture afresh, in about a millisecond, and the same key
/// always gives the same pixels. Nothing is kept here: the drawing keeps what it
/// is given (`SpriteCache` in MapDrawing).
public struct BronzePeopleSprites: SpriteSource {
    /// The poses this source supplies, each at frame 0.
    public let poses: [SpriteKey]
    private let supplied: Set<SpriteKey>

    public init(catalogue: Catalogue = .standard) {
        poses = SpriteKey.required(through: .bronze, catalogue: catalogue).filter { key in
            guard case .unit(let kind, .bronze) = key.subject else { return false }
            return BronzePeopleLooks.look(kind) != nil
        }
        supplied = Set(poses)
    }

    /// Every key this source supplies: each pose at each of its frames.
    public var keys: [SpriteKey] {
        poses.flatMap { pose in (0..<SpriteKey.framesPerPose).map { SpriteKey(pose.subject, pose.pose, frame: $0) } }
    }

    public func sprite(_ key: SpriteKey) -> SpriteImage? {
        guard (0..<SpriteKey.framesPerPose).contains(key.frame),
              supplied.contains(SpriteKey(key.subject, key.pose, frame: 0)),
              case .unit(let kind, _) = key.subject,
              let look = BronzePeopleLooks.look(kind) else { return nil }
        let canvas = BronzePeopleLooks.canvas(kind)
        return look.render(key.pose, frame: key.frame, canvas: canvas)?.sprite(anchor: canvas.anchor)
    }
}

/// Which look draws each kind, and on what canvas.
enum BronzePeopleLooks {
    static func look(_ kind: UnitKind) -> (any PersonLook)? {
        switch kind {
        case .worker: BronzePeopleHerder()
        case .scholar: BronzePeopleScribe()
        case .engineer: BronzePeopleMason()
        case .merchant: BronzePeopleTrader()
        case .spearman: BronzePeopleSpearman()
        case .archer: BronzePeopleArcher()
        case .chariot: BronzePeopleChariot()
        case .founder, .clubman, .slinger, .swordsman, .horseman, .catapult, .knight, .musketeer, .cannon: nil
        }
    }

    /// The person's canvas, widened forward for the warfighters, whose spear
    /// thrust and arrow in flight reach beyond it, and the chariot's own.
    static func canvas(_ kind: UnitKind) -> Canvas {
        switch kind {
        case .spearman, .archer: wide
        case .chariot: BronzePeopleChariot.canvas
        default: .person
        }
    }

    /// `Canvas.person` with 24 more units in front: 150 by 135 pixels.
    static let wide = Canvas(minX: -36, minY: -102, width: 120, height: 108, pixelsPerUnit: Canvas.person.pixelsPerUnit)
}
