// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Testing
import GameCore
@testable import Artwork

@Test func emptySourceHasNoSprites() {
    let source = EmptySpriteSource()
    for key in SpriteKey.required(through: .bronze) { #expect(source.sprite(key) == nil) }
}
