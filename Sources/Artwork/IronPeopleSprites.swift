// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore

/// The four peaceful sectors in their Iron-age looks, drawn in the Cartoon
/// Modern style of docs/art-style.md on the jointed figure every age shares
/// (Figure.swift).
///
/// A peaceful sector takes the look of its owner's age
/// (`SpriteSubject.of(_:ownerAge:)`), so this source supplies
/// `SpriteSubject.unit(kind, .iron)` for the farmer (worker), the philosopher
/// (scholar), the siege engineer (engineer) and the caravan trader (merchant),
/// in every pose that the artwork's checklist (`SpriteKey.required(through:)`)
/// lists for them: standing, walking and working, and fighting for the two that
/// can attack. Each pose is a cycle of 12 frames (`SpriteKey.frame` 0 to 11).
/// Every other key returns nil.
///
/// Each call draws its picture afresh, and the same key always gives the same
/// pixels. Nothing is kept here: the drawing keeps what it is given
/// (`SpriteCache` in MapDrawing).
public struct IronPeopleSprites: SpriteSource {
    /// The poses this source supplies, each at frame 0.
    public let poses: [SpriteKey]
    private let supplied: Set<SpriteKey>

    public init(catalogue: Catalogue = .standard) {
        poses = SpriteKey.required(through: .iron, catalogue: catalogue).filter { key in
            guard case .unit(let kind, .iron) = key.subject else { return false }
            return IronPeopleLooks.look(kind) != nil
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
              let look = IronPeopleLooks.look(kind) else { return nil }
        let canvas = IronPeopleLooks.canvas(kind)
        return look.render(key.pose, frame: key.frame, canvas: canvas)?.sprite(anchor: canvas.anchor)
    }
}

/// Which look draws each kind, and on what canvas.
enum IronPeopleLooks {
    static func look(_ kind: UnitKind) -> (any PersonLook)? {
        switch kind {
        case .worker: IronPeopleFarmer()
        case .scholar: IronPeoplePhilosopher()
        case .engineer: IronPeopleEngineer()
        case .merchant: IronPeopleTrader()
        case .founder, .clubman, .slinger, .spearman, .archer, .chariot, .swordsman, .horseman, .catapult, .knight, .musketeer, .cannon, .rifleman, .fieldGun, .armouredCar: nil
        }
    }

    /// The person's canvas, and the trader's own, which reaches back for his donkey.
    static func canvas(_ kind: UnitKind) -> Canvas {
        kind == .merchant ? IronPeopleTrader.canvas : .person
    }
}
