# Fairelescourses

**A supermarket navigation assistant for Android.**

Fairelescourses lets you map out the layout of your local shops as a grid, assign goods to cells, and then plans the shortest route through all the cells that contain items from your shopping list — guiding you step by step, floor by floor, store by store.

[![CI](https://github.com/danile42/fairelescourses/actions/workflows/ci.yml/badge.svg)](https://github.com/danile42/fairelescourses/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/danile42/fairelescourses/branch/main/graph/badge.svg)](https://codecov.io/gh/danile42/fairelescourses)

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

```
lib/
├── main.dart                  # App entry point; Firebase init; Hive setup
├── firebase_options.dart      # Generated Firebase config (built-in instance)
├── models/                    # Plain Dart data classes + Hive adapters
│   ├── supermarket.dart       # Shop model; findCellWithFloor(); split helpers
│   ├── shopping_list.dart     # List + ShoppingItem models
│   ├── navigation_plan.dart   # NavigationPlan / StorePlan / NavigationStop
│   ├── shop_floor.dart        # Additional-floor data
│   ├── nav_session.dart       # Collaborative session state
│   └── firebase_credentials.dart
├── providers/                 # Riverpod NotifierProviders
│   ├── supermarket_provider.dart
│   ├── shopping_list_provider.dart
│   ├── household_provider.dart
│   ├── firestore_sync_provider.dart
│   ├── home_location_provider.dart
│   ├── local_only_provider.dart
│   ├── nav_session_provider.dart
│   └── firebase_app_provider.dart
├── services/
│   ├── navigation_planner.dart  # Route planning (nearest-neighbour heuristic)
│   ├── firestore_service.dart   # Encrypted Firestore read/write
│   ├── nominatim_service.dart   # Geocoding via Nominatim
│   └── overpass_service.dart    # OSM shop discovery via Overpass API
├── screens/
│   ├── home_screen.dart
│   ├── list_editor_screen.dart
│   ├── store_editor_screen.dart
│   ├── navigation_screen.dart
│   ├── sync_screen.dart
│   ├── shop_search_screen.dart
│   └── help_screen.dart        # General, shop-editor, and Firebase help
└── widgets/
    └── store_grid.dart         # Interactive grid widget with split-cell support
```

**State management:** Riverpod 2 (`NotifierProvider`, `StreamProvider`)
**Persistence:** Hive 2 (local), Firestore (cloud, encrypted)
**Routing:** `Navigator.push` / `PopScope` (no named routes)

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

---

## CI / Code coverage

Every push and pull request runs the full test suite on GitHub Actions (see `.github/workflows/ci.yml`). Coverage is uploaded to [Codecov](https://codecov.io).

To enable Codecov on your fork:
1. Sign in to [codecov.io](https://codecov.io) with GitHub.
2. Add your repository.
3. Copy the upload token and add it as a repository secret named `CODECOV_TOKEN`.

---

## Written by Claude

Every line of code in this repository was written by [Claude](https://claude.ai) (Anthropic's AI assistant) — specifically **Claude Sonnet 4.6**, used via [Claude Code](https://claude.ai/claude-code), Anthropic's CLI tool.

The human author provided product direction through natural-language prompts (see [`prompts.md`](prompts.md)) and reviewed the results on a device, but did not write, edit, or modify a single line of source code. The complete prompt history is preserved in `prompts.md`.

This project was built incrementally over many sessions: each prompt added a feature, fixed a bug, or refined existing behaviour, with Claude Code committing each change directly to `main`. The git history is therefore an accurate record of the AI-driven development process.

---

## Licence

MIT
