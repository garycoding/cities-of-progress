// SPDX-FileCopyrightText: 2026 Gary Frattarola <garyf@parkviewlab.ai>
// SPDX-License-Identifier: AGPL-3.0-or-later

import AppKit
import SwiftUI

/// The app: one window, which shows the new-match screen until a match starts
/// and then the match.
@main
struct CitiesOfProgressApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var game = GameController()

    var body: some Scene {
        WindowGroup("Cities of Progress") {
            RootView(game: game)
                .frame(minWidth: 1100, minHeight: 720)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Match") { game.endMatch() }
                    .keyboardShortcut("n")
                Button("Open Match…") { game.open() }
                    .keyboardShortcut("o")
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save Match…") { game.save() }
                    .keyboardShortcut("s")
                    .disabled(game.match == nil)
            }
        }
    }
}

/// Makes the app a regular one, with a Dock icon and a menu bar, when it is run
/// straight from the package (`swift run`) as well as from its bundle.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
