// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

@testable import Artwork
import GameCore
import CoreGraphics
import Foundation
import Testing

/// The combined source draws every key the Iron age needs, each from the batch
/// approved for it rather than from an earlier batch or a placeholder.
@Test func everyKeyThroughTheIronAgeComesFromItsApprovedBatch() {
    let all = GameSprites()
    let iron: [any SpriteSource] = [IronOldBuildingSprites(), IronNewBuildingSprites(), IronPeopleSprites(), IronWarriorSprites()]
    var missing: [SpriteKey] = []
    var wrong: [SpriteKey] = []
    // A warfighter at work is drawn standing (`SpriteCache`), so its working pose need not be drawn.
    let keys = SpriteKey.required(through: .iron).filter { key in
        if case .unit(let kind, _) = key.subject, kind.isWarfighter, key.pose == .working { return false }
        return true
    }
    for key in keys {
        guard let image = all.sprite(key) else { missing.append(key); continue }
        let isIron: Bool = {
            switch key.subject {
            case .unit(_, let age), .building(_, let age): return age == .iron
            case .site(let kind): return kind == .iron
            default: return false
            }
        }()
        if isIron, let own = iron.lazy.compactMap({ $0.sprite(key) }).first, !sameImage(own, image) { wrong.append(key) }
    }
    #expect(missing.isEmpty, "\(missing.prefix(5))")
    #expect(wrong.isEmpty, "\(wrong.prefix(5))")
}

private func sameImage(_ a: SpriteImage, _ b: SpriteImage) -> Bool {
    a.base.width == b.base.width && a.base.height == b.base.height && a.anchor == b.anchor
        && (a.base.dataProvider?.data as Data?) == (b.base.dataProvider?.data as Data?)
}
