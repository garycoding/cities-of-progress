# Decisions

A dated record of the rulings that shape Cities of Progress, and of each place where the repository departs from the [ParkviewLab handbook](https://github.com/ParkviewLab/handbook/tree/main), which it otherwise follows in full. The requirements are in [`requirements.md`](requirements.md) and the design in [`design.md`](design.md).

## Departures from the handbook

- **Merging (2026-11-18).** For all of the work toward the first final release, the AI session that carries out the plan merges each pull request into `develop`, once its checks have passed and the session has verified the work against the plan's acceptance checks. The handbook makes each such merge the user's. Tagging and cutting a release are not merging and each still needs the user's explicit go-ahead.
- **The release question (2026-11-18).** The question whether to cut a release is asked once, when the first playable version is assembled and has been played, and not after each merge into `develop`.
- **Implementation by parallel agents in one repository (2026-11-18).** The modules are implemented by agents working in parallel, each in its own worktree and branch. The handbook's default is that a session implements a single repository itself; the user asked for as much parallel work as possible.
- **Swift checks (2026-11-18).** The handbook has no Swift tooling page. The required checks are `reuse` and the version guard, as in every repository, and `swift-test` (`swift build` and `swift test` on a GitHub macOS machine), described in [`CONTRIBUTING.md`](CONTRIBUTING.md).
- **The version file (2026-11-18).** The package has no version field, so the version lives in `VERSION.txt`, as the handbook gives for a repository without a package manifest. It carries the development marker of a code repository (`0.1.0.dev0`), which the release drops.
- **Artwork's licence (2026-11-18).** The handbook has no bucket for a game's artwork. It is licensed with the code, under AGPL-3.0-or-later, wherever it lies, including the drawings in `docs/art/`; see [`LICENSING.md`](../LICENSING.md).
- **No Xcode project (2026-11-18).** The app is assembled from the Swift package by a script, so that agents working in parallel never edit a shared project file.

## Rulings

- **Repository (2026-11-18).** Public from the start, under the garycoding account, following the handbook in full.
- **Licence (2026-11-18).** AGPL-3.0-or-later for the code and the artwork; CC-BY-4.0 for the documents.
- **Artwork (2026-11-18).** A style guide comes first and is ruled on by the user; the artwork is then drawn in batches, and the user rules on every batch before it is merged. The large triangular noses of the first examples are not to be used.
- **Northstar (2026-11-18).** Neither a northstar nor an HTML twin for now; the material for one is in [`in-flight_ideas.md`](in-flight_ideas.md).
- The design rulings (Swift and macOS only, two-dimensional sprites with SpriteKit, one Mac running each match, the Cartoon Modern art style) are recorded in [`design.md`](design.md).

## Verifications (2026-11-18)

Step 2 of the plan tested the design's riskiest assumptions with a throwaway app, before anything was built on them.

- **An app without an Xcode project: passed.** `scripts/make-app.sh` assembles a bundle from the Swift package and signs it ad hoc. It opens through Launch Services on the Mac that built it.
- **Bonjour on the LAN: passed on one Mac.** Two copies advertising and browsing `_citiesprogress._tcp` through the Network framework found each other within a second. The bundle declares `NSLocalNetworkUsageDescription` and `NSBonjourServices`.
- **SpriteKit with 1,200 moving sprites: passed.** Frames arrived every 16.7 ms (95th percentile 17.7 ms) on a 60 Hz display. That is the display's limit, so it shows the drawing fits within a frame, not how much room is left; later checks count dropped frames at 60 Hz.
- **Swift 6 language mode: passed.** A simulation of value types on an actor, with SpriteKit and SwiftUI on the main actor, compiled with no errors or warnings.
- **The art without a browser: passed, with one change of method.** macOS draws the Cartoon Modern SVGs itself (`NSImage`), colour out of register with the line included, but drops the SVG's `feTurbulence` grain. Core Image adds the grain afterwards. Sprites are therefore written as SVG files, drawn by macOS, and grained by Core Image.
- **An unsigned app on a second Mac: passed (2026-11-18).** The ad-hoc signed trial app, copied to a second MacBook on the same LAN, started there and drew its 1,200 sprites. With a copy running on each Mac, each listed the other through Bonjour (`_citiesprogress._tcp`), and this Mac resolved the other's service to its host and port. A ping between the two took about 400 ms a round trip at the time, which is slow for a home network; it does not affect discovery and is to be measured again when play across the LAN is built.
- **The GitHub runner** (`macos-26`) has Xcode 26.6 and Swift 6.3.3; the package needs Swift 6.0 or later.
