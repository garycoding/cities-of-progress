// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import Artwork
import GameCore
import GameInterface
import MapDrawing
import SwiftUI

/// The window's content: the new-match screen, or the match.
struct RootView: View {
    let game: GameController

    var body: some View {
        Group {
            if let match = game.match {
                MatchScreen(match: match, sprites: game.sprites, onNewMatch: { game.endMatch() })
                    .id(ObjectIdentifier(match))
            } else {
                NewMatchView(model: NewMatchModel(maxPlayers: 6), onStart: { game.start($0) })
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert("Cities of Progress", isPresented: Binding(get: { game.problem != nil }, set: { if !$0 { game.problem = nil } })) {
            Button("OK") { game.problem = nil }
        } message: {
            Text(game.problem ?? "")
        }
    }
}

/// A match on screen: the interface's panels around the map.
struct MatchScreen: View {
    let match: Match
    let sprites: any SpriteSource
    let onNewMatch: () -> Void

    var body: some View {
        GameHUD(session: match.session, sprites: sprites, onMatchOver: onNewMatch) {
            MapView(session: match.session, sprites: sprites)
        }
    }
}
