# Fairelescourses

**A supermarket navigation assistant for Android.**

Fairelescourses lets you map out the layout of your local shops as a grid, assign goods to cells, and then plans the shortest route through all the cells that contain items from your shopping list — guiding you step by step, floor by floor, store by store.

[![CI](https://github.com/danile42/fairelescourses/actions/workflows/ci.yml/badge.svg)](https://github.com/danile42/fairelescourses/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/danile42/fairelescourses/branch/main/graph/badge.svg)](https://codecov.io/gh/danile42/fairelescourses)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-025E8C?logo=Dependabot)](https://github.com/danile42/fairelescourses/security/dependabot)

---

## What it does

Most supermarket apps tell you *what* to buy. Fairelescourses tells you *where to walk*.

You draw each shop's floor plan as a grid, tag every cell with the goods it contains, and the app turns your shopping list into an optimised route — handling multiple stores, multiple floors, and real-time collaborative check-off with household members.

---

## Features

### Shop editor
- Draw a shop's floor plan as a named grid of cells (up to 26 × 26 per floor)
- Assign comma-separated goods to each cell (e.g. *Milk, Yoghurt, Butter*)
- Set entrance and exit cells; navigation always starts and ends there
- Add multiple floors with independent grids
- Split any cell into two halves (left/right or top/bottom) for aisles with distinct sides; promote a split to a full grid row or column
- Optional address with geocoding for distance-sorted search results
- Import nearby shops from OpenStreetMap with one tap, including category filter and map view
- In-editor help screen explaining all gestures

### Shopping lists
- Create named lists with optional preferred-store filters
- Add items with autocomplete suggestions drawn from all known shop cells
- Reorder items by drag-and-drop
- Tap any item to rename it inline
- Move or copy individual items to other lists
- Merge multiple lists into one (long-press to multi-select)
- Copy or rename a list from the home screen

### Navigation
- One tap generates the optimal route: items are matched to cells using exact → all-words → partial matching; unmatched items are grouped at the end
- **Grid view**: walk through stops cell by cell, with the shop grid highlighted at the current position and a mini-map for orientation
- **List view**: flat view of all items across all stores with shop sub-headers, unmatched items last — useful for quick scanning
- Toggle between grid and list view at any time during navigation
- Carry-over: if an item is unavailable, defer it to the next shop or a new list
- Collaborative mode: all household members see check-offs in real time via Firestore

### Sync & households
- Create or join a 6-character household code to share shops and lists across devices
- All synced data is AES-encrypted client-side with the household ID before upload — the server stores only ciphertext
- Optional local-only mode: disable sync entirely; all data stays on-device
- Configure a custom Firebase backend (Firestore + Anonymous Auth) for self-hosting

### Internationalisation
- Full English and German localisation (ARB + `flutter gen-l10n`)

---

## Screenshots

| Home | Shop editor | Navigation (grid) | Navigation (list) |
|------|-------------|-------------------|-------------------|
| *(coming soon)* | *(coming soon)* | *(coming soon)* | *(coming soon)* |

---

## Architecture

See [`docs/architecture/`](docs/architecture/) for detailed architecture documentation, including component diagrams, data flow, and design decisions.

---

## Building

### Prerequisites

- Flutter 3.41+ (stable channel)
- Android SDK (set `$ANDROID_HOME` or install via Android Studio)
- Java 17+

```bash
flutter pub get
dart run build_runner build   # regenerate Hive adapters if needed
flutter build apk --debug
```

The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.

### Running tests

```bash
flutter test
flutter test --coverage       # generates coverage/lcov.info
```

### Test organisation note

`test/widgets/home_screen_start_navigation_test.dart` exists as a separate file even though it tests the same `HomeScreen` as `test/widgets/home_screen_test.dart`. This is an intentional workaround: the *start navigation* test must run **last** because pushing `NavigationScreen` leaves persistent animation timers that prevent `pumpAndSettle()` from returning in any subsequent test. Dart's test runner processes files in alphabetical order within a directory, and `home_screen_start_navigation_test.dart` sorts after `home_screen_test.dart`. Placing the test in a named group marked "must run last" inside the original file does not work when another group in the same file also carries that constraint — the workaround of a separate file was not found by Claude Code even after extensive debugging.

---

## CI / Code coverage

Every push and pull request runs the full test suite on GitHub Actions (see `.github/workflows/ci.yml`). Coverage is uploaded to [Codecov](https://codecov.io).

To enable Codecov on your fork:
1. Sign in to [codecov.io](https://codecov.io) with GitHub.
2. Add your repository.
3. Copy the upload token and add it as a repository secret named `CODECOV_TOKEN`.

---

## Written by Claude

Every line of code in this repository was written by [Claude](https://claude.ai) (Anthropic's AI assistant) — specifically **Claude Sonnet 4.6**, used via [Claude Code](https://claude.ai/claude-code), Anthropic's CLI tool. All documentation, including architecture docs and diagrams, was written by Claude as well.

**Exception:** the workaround of splitting `home_screen_start_navigation_test.dart` into a separate file (described in the [Test organisation note](#test-organisation-note) above) was devised by the human author after Claude Code was unable to find it through extensive debugging. That file's placement is the only piece of the codebase not produced by Claude.

The human author provided product direction through natural-language prompts (see [`prompts.md`](prompts.md)) and reviewed the results on a device, but did not otherwise write, edit, or modify source code or documentation. The complete prompt history is preserved in `prompts.md`.

> **Note:** The numbering in `prompts.md` reflects the order in which Claude logged the entries, which does not always match the exact order the prompts were given — especially toward the end of the file, where multi-session context compression occasionally caused entries to be recorded slightly out of sequence.

This project was built incrementally over many sessions: each prompt added a feature, fixed a bug, or refined existing behaviour, with Claude Code committing each change directly to `main`. The git history is therefore an accurate record of the AI-driven development process.

---

## Licence

[Apache 2.0](LICENSE)
