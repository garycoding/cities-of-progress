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
