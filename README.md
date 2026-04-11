# Fairelescourses [/fɛʁ le kuʁs/]

**A supermarket navigation assistant for Android.**

Fairelescourses maps your local shops as a grid, assigns goods to cells, and plans the shortest route through the store for your shopping list — guiding you step by step, store by store.

[![CI](https://github.com/danile42/fairelescourses/actions/workflows/ci.yml/badge.svg)](https://github.com/danile42/fairelescourses/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/danile42/fairelescourses/branch/main/graph/badge.svg)](https://codecov.io/gh/danile42/fairelescourses)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-025E8C?logo=Dependabot)](https://github.com/danile42/fairelescourses/security/dependabot)

---

For a full feature walkthrough see the **[User guide](docs/user-guide.md)**.
For technical details see the **[Architecture docs](docs/architecture/)**.

---

## Building

### Prerequisites

- Flutter 3.41.5+ (stable channel)
- Dart 3.11.3+ (comes with Flutter)
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

Several tests live in dedicated files rather than in the main `*_test.dart` file for their screen. This is an intentional workaround for a Flutter testing constraint: certain interactions leave persistent animation tickers running after a test completes, preventing `pumpAndSettle()` from returning in any subsequent test in the same file. Moving such tests to their own file gives each an isolated `WidgetTester` with no prior ticker state.

---

## CI / Code coverage

Every push and pull request runs the full test suite on GitHub Actions (see `.github/workflows/ci.yml`). Coverage is uploaded to [Codecov](https://codecov.io).

To enable Codecov on your fork:
1. Sign in to [codecov.io](https://codecov.io) with GitHub.
2. Add your repository.
3. Copy the upload token and add it as a repository secret named `CODECOV_TOKEN`.

---

## Written by LLMs

Almost every line of code in this repository was written by LLM assistants — specifically **Claude Sonnet 4.6** (used via [Claude Code](https://claude.ai/claude-code)), **Junie** (JetBrains' LLM agent), and **GitHub Copilot**. All documentation, including architecture docs and diagrams, was written by these LLM tools as well.

The human author provided product direction through natural-language prompts (see [`prompts.md`](prompts.md)) and reviewed the results on a device, but did not otherwise write, edit, or modify source code or documentation. The complete prompt history is preserved in `prompts.md`, with each entry marked to indicate which LLM handled it.

**Exceptions:** Two pieces of the codebase were not produced by an LLM:
1. The workaround of placing the start-navigation test in a separate file (`test/widgets/home_screen_start_navigation_test.dart`) was devised by the human author after Claude Code was unable to find the solution through extensive debugging.
2. Manual removal of a redundant `[J]` marker from `prompts.md` — GitHub Copilot was unable to locate it programmatically despite multiple attempts.

> **Note:** The numbering in `prompts.md` reflects the order in which the LLM logged the entries, which does not always match the exact order the prompts were given — especially toward the end of the file, where multi-session context compression occasionally caused entries to be recorded slightly out of sequence.

This project was built incrementally over many sessions: each prompt added a feature, fixed a bug, or refined existing behaviour, with the LLM tool committing each change directly to `main`. The git history is therefore an accurate record of the LLM-driven development process.

---

## Licence

[Apache 2.0](LICENSE)
