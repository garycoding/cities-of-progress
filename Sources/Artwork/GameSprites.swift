// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import GameCore

/// All the game's artwork as one source: each approved batch answers the keys
/// it draws, and the first answer wins. The drawing shows its placeholder for a
/// key that no batch answers.
public final class GameSprites: SpriteSource {
    private let batches: [any SpriteSource]

    public init(catalogue: Catalogue = .standard) {
        batches = [
            CartoonSprites(catalogue: catalogue),
            TerrainSprites(),
            StoneBuildingSprites(),
        ]
    }

    public func sprite(_ key: SpriteKey) -> SpriteImage? {
        for batch in batches {
            if let sprite = batch.sprite(key) { return sprite }
        }
        return nil
    }
}
