// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Testing
@testable import GameCore

@Test func moduleIsPresent() {
    #expect(GameCoreModule.moduleName == "GameCore")
}
