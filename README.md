# Cities of Progress

A co-operative real-time strategy game for macOS. One to three people on the same LAN lead their civilizations, as allies, through seven ages from Stone to AI against computer players.

## Status

Version 0.1.0 is in development; nothing is playable yet. The first milestone is one person on one Mac playing the Stone and Bronze ages against one computer player. Later milestones bring play over the LAN, the remaining five ages, saving and resuming, and three levels of difficulty.

It is a personal project, written in Swift for macOS on Apple silicon, and its source is published under the AGPL. No built app is distributed.

## Building and running

The game is one Swift package. With Xcode installed:

```bash
swift build
swift test
```

How the app bundle is assembled and started is documented here once that step of the work is done.

## Documents

- [`docs/requirements.md`](docs/requirements.md): what the game must do.
- [`docs/design.md`](docs/design.md): how it is built, and the decisions made so far.
- [`docs/decisions.md`](docs/decisions.md): the dated rulings, including each departure from the ParkviewLab handbook.
- [`docs/in-flight_ideas.md`](docs/in-flight_ideas.md): ideas not yet decided.

## Contributing

See [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md). The code and the artwork are licensed under AGPL-3.0-or-later, and the documents under CC-BY-4.0; see [`LICENSING.md`](LICENSING.md).

## Releasing

Releases follow the tag-driven flow of the [ParkviewLab handbook](https://github.com/ParkviewLab/handbook/blob/main/docs/releases.md). There has been none yet.

---
<sub>© 2026 Gary Frattarola · Licensed under [CC-BY-4.0](LICENSES/CC-BY-4.0.txt)</sub>
