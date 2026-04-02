# Prompts

This file contains every prompt given to Claude to build this project.
No source code was written by the human author — only the prompts below.

---

## Project origin

The project was bootstrapped with `flutter create fairelescourses` and then handed entirely to Claude Code (Claude Sonnet 4.6). All subsequent development — models, providers, services, screens, widgets, tests, localisation, CI — was produced by the AI in response to the prompts listed here.

---

## Prompt history

1. *(Initial project setup — exact prompt not recorded; covered Firebase sync, shop grid editor, shopping lists, navigation planning, and OSM shop discovery)*

2. Add Firebase sync, shop search, and location-based features.

3. Add OSM-powered nearby shop discovery.

4. Merge OSM results into location-based shop search.

5. Fix network requests and loading UX in location search.

6. Track parent-child relationship between shop definitions.

7. Add easter egg: 7 taps on the app title opens a feel-good screen.

8. Upgrade Firebase and other dependencies; pin share_plus to 10.x.

9. v0.6: map view, brand filter, OSM retry, easter egg i18n, dependency upgrades.

10. Add comprehensive test suite.

11. Add "Collect Later" during navigation — if an item isn't available at the current stop, the user can defer it to the next shop or move it to a new list.

12. Add copy/move options for unmatched items to a new list.

13. Allow moving items between lists in the list editor.

14. Add collaborative navigation mode — household members see checked items in real time.

15. Allow users to configure a custom Firebase instance at runtime.

16. Add list merge: long-press to multi-select lists, then merge into one.

17. Add multi-floor shop support and a carried-over item availability check.

18. Compact grid controls, inline row/col removal, rename any floor.

19. New floors inherit the previous floor's dimensions.

20. Disable map rotation on the OSM shop search map.

21. Open newly imported shop for item assignment when searching from unmatched items.

22. Store OSM category on import and apply category filter to known shops.

23. Pre-append focus items when editing shop cell goods.

24. Implement the following and commit after each point:
    1. Add an intermediate "all words match" tier to navigation item matching (between exact and partial).
    2. Remove the "Nearby Shops" feature from the home screen FAB.
    3. Add a local-storage-only mode (no Firebase sync) — toggle in the Sync screen.
    4. Add a help/intro screen shown on first start, with a help button in the home screen AppBar.

25. The setting for home location should be accessible in local-only mode. It is stored locally already, right?

26. In the info screen, use the same icons for navigation and sync as in the actual UI.

27. Instead of "Generate plan", use "Start navigation", with both navigation icons as on the list overview.

28. I'm in a household. Why are the collab buttons disabled? Does there need to be someone else in the household?
    *(This was a bug report. Claude diagnosed that the `singleNavActive` flag was only cleared when the navigation screen returned `true` — pressing back left it set permanently. Fixed by clearing it on any close.)*

29. List items should be editable.

30. The "Copy to new list" button should have the same color and style as the "Move to new list" button.

31. It should only be possible to join a household if not already joined to another household.

32. The "local storage only" switch should be directly above the elements it switches on or off — i.e., the home location should not be in-between.

33. Can you move the plus button for adding columns to the center-right of the grid — similar to the button for adding rows?

34. In navigation mode, I want to have two views which can be switched:
    1. The grid view (as now).
    2. List view, where items are just listed in navigation order. Unmatched items should come last.

35. In list view, all items should be visible in one list, regardless of which shop they are to be found in. The list should have sub-headers to indicate the shop.

36. Don't show the coordinate for the current item in grid navigation view — coordinates are no longer relevant in the UI.

37. When I write a new item for a list, but hit the back button before adding the item with the plus button, the warning about unsaved changes should still appear.

38. Add help screens for the shop editor and when the user starts to customize the Firebase instance — the latter should explain everything that needs to be set up in Firebase to serve as backend. There should be a warning when the user wants to customize the Firebase instance, that this is advanced territory, and if she really wants to continue.

39. Splitting cells in the shop editor is also useful to refine the layout by promoting the split across the whole column or row.

40. Name the app's package name explicitly in the Firebase help screen — users won't know it otherwise.

41. I want to put this project on GitHub. Please write a comprehensive readme that explains the purpose and content of the project, and how the app works (with screenshots). Add a section that explains that this was all written by you — not a single line of code was edited by myself. If you can, include all the prompts I gave you for this project (including this one) in a file "prompts.md". I also want the tests to run on GitHub, as far as possible. Can you also add code coverage measurement?

42. Push everything to this remote repo: https://github.com/danile42/fairelescourses.git I can enter credentials on the command line.

43. How can I give user and password directly on the command line?

44. Which configuration should I use in Codecov?

45. CI is failing during "Verify formatting" with this output: [dart format reported 39 changed files]. Error: Process completed with exit code 1.

46. Also, there is this warning: Node.js 20 actions are deprecated. The following actions are running on Node.js 20 and may not work as expected: actions/checkout@v4. [...]

47. CI fails on "Analyze" with this output: [33 issues including 3 errors referencing the removed OsmShopsScreen and 1 warning for unused _DimensionCounter].

48. Set the project's licence to Apache 2.0.

49. Add the latest prompts (including this one) to the prompts file.

50. Commit the latest changes. Then, add tests until you reach 50 per cent code coverage.

51. Commit the current state.

52. Add the latest prompts that are not already in prompts.md to that file (including this one). Then commit.

53. Verify formatting failed again on CI. Fix this, add this prompt to prompts.md, and commit.

54. "Analyze" in CI fails: [32 lint issues]. Fix these, add this prompt to prompts.md, and commit.

55. Implement the following, add tests, format, analyze, update prompts, and commit:
    - Allow to set a preferred navigation mode — grid or list — which displays this view by default (the other can still be selected, as now). This should be available in "local-only" mode, too.
    - In the help screen of the shop editor, mention that a shop can be modelled with a coarse grid first, which can later be refined (using splits).
    - Searching for shops by category (e.g. electronics) brings up all locally stored shops. Only those which are known to belong to this category should be listed. Also, if OSM allows one shop to belong to multiple categories, so should our data model.

56. Now add code coverage in 10 per cent badges. Ask me to continue after each 10 per cent.

57. Currently, the identity of a shop seems to be based only on its name. I observe that shops of the same name (brand) are listed as "Already known", even if they are in a totally different place. The location of a shop must be part of its identity. Make sure there are tests for these changes. Check coverage, update prompts.md, and commit.

58. You repeatedly stumbled upon a Hive adapter that was manually managed, not with something called build_runner. Can you fix that?

59. Shops with the same name are still listed as "known", even if they are in a different location.

60. [Emulator log with GoogleApiManager SecurityException and Firestore offline warning.] — Diagnosed as pre-existing emulator issues: SHA-1 debug fingerprint not registered in Firebase Console (causes GMS broker rejection and Firestore offline fallback). The userfaultfd warning is a harmless ART GC message. No code changes required.

61. Update prompts.md if needed, and commit.

62. [Tests were failing.] Check if all tests run now. If not, fix them, then commit (update prompts.md).
    - Fixed `overpass_service.dart`: include postcode in address even when city is absent.
    - Fixed `sync_screen.dart`: add "Disable local-only mode" title to the disable-confirmation dialog.

63. How could a tour for new users look like? → Yes, do B + C.
    - Option C: Converted `HelpScreen` from a scrollable list into a 4-page `PageView` stepper (Shops → Lists → Navigation → Sync/Data) with dot indicators and Next/Get started buttons.
    - Option B: Replaced plain-text empty states in the Lists and Shops tabs with rich `_EmptyState` widgets (icon, title, description, action buttons). Lists tab gets a "Create a list" button; Shops tab gets "Create a shop" and "Find a shop" buttons.

64. CI fails with formatting. Please fix that and commit as usual.

65. prompts.md updated?

66. Add a data privacy declaration in the project that I can link to from Play store. It should also contain the information about storage from the help screen.
    - Created `docs/privacy-policy.html`: covers local-only storage, optional Firebase household sync (end-to-end encrypted), anonymous Firebase auth, Overpass API queries, no personal data collected, deletion instructions, and contact link.

67. [Stashed test changes from an earlier session.] Unstash the test changes and make them all run without modifying production code.
    - Added `store_grid_test.dart`, `navigation_screen_test.dart`, `home_screen_test.dart`, `list_editor_screen_test.dart` widget tests; `supermarket_test.dart` model tests; `overpass_service_test.dart` service tests.
    - Fake notifiers (`_FakeNavViewModeNotifier`, `_FakeLocalOnlyNotifier`, `_FakeListsNotifier` with `remove()` override) prevent real Hive access in provider-dependent tests.
    - Tests that push `NavigationScreen` use bounded pumps (`pump()` + `pump(500ms)`) instead of `pumpAndSettle()` and are ordered last in each file to avoid persistent-animation interference.
    - Root cause of `tearDownAll` hang: `_startNav` writes to `Hive.box<String>('settings')` inside a `testWidgets` (FakeAsync) block; the flush never completes, so `Hive.close()` blocks indefinitely. Fix: cap `Hive.close()` at 5 s with `.timeout()` in `tearDownHive()` — safe because the temp dir is deleted immediately after.

68. Check that formatting is ok, update prompts.md (incl. this one), and commit.

69. Buttons on help screens are sometimes overlapped by OS menu bars. Move the buttons just below the text to avoid the overlap.
    - HelpScreen tour: moved dots + Next/Get-started button inside each page's scrollable content (below body text), removing the fixed-bottom strip.
    - ShopEditorHelpScreen / FirebaseHelpScreen: wrapped body in `SafeArea(top: false)` so the Close button clears the system bar even when content fits without scrolling.
    - Updated `help_screen_test.dart`: added `ensureVisible()` before tapping buttons that are now inside scrollable content.

70. CI analyze fails with 3 lint issues. Fix, format, update prompts.md, and commit.
    - `help_screen.dart`: `if (extra != null) extra!` → `?extra` (null-aware element, already fixed locally).
    - `navigation_screen_test.dart`: renamed local function `_emptyStorePlan` → `emptyStorePlan` (`no_leading_underscores_for_local_identifiers`).
    - `store_grid_test.dart`: added `expect(doubleTapped, 'A2')` to the double-tap test (`unused_local_variable`). Also fixed the double-tap simulation: pumped 50 ms between the two taps (Flutter's `kDoubleTapMinTime` is 40 ms, so a single frame at 16 ms was too short) and 200 ms after.

71. If no article from my list matches a shop, and I then assign an item to a shop, navigation is not offered. Only when an item is already assigned is navigation offered after assigning an unmatched item.
    - Root cause: `StoreEditorScreen._save()` called `notifier.update(store)` / `notifier.add(store)` without `await`. The Riverpod state update (`state = [...]`) only runs after Hive's async disk write, but `Navigator.pop` fires one frame later via `addPostFrameCallback`. When `_showShopPicker` in `NavigationScreen` reads `ref.read(supermarketsProvider)` right after the pop, the provider state is still stale → `_resolvedUnmatched` stays empty → "Generate Plan" never appears.
    - Fix: `await notifier.update/add(store)` in `_save()`, then `if (!mounted) return`.

72. When there is no list defined yet, the help message uses a different "play" button. Use the two buttons that are actually used when a list is present. Then: replace the incorrect button with the correct buttons, inside the sentence. Say "... tap <button single> or <button collab> ...".
    - Added `bodyWidget: Widget?` to `_EmptyState`; when provided it replaces the plain `Text(body)`.
    - Replaced `emptyListsBody` l10n key with `emptyListsBodyBefore` + `emptyListsBodyOr` + `emptyListsBodyAfter`.
    - Lists empty state uses a `Wrap` with both nav buttons (`_NavIcon` single + collaborative) always shown inline, with "or" / "oder" between them.

73. When I assign an item to a market cell, this should be visible for other users who have this market imported. Add tests for these changes, if there are not already.
    - Added `int? osmId` to `Supermarket` model (`@HiveField(16)`); regenerated Hive adapter via build_runner.
    - OSM-imported shops now get a deterministic ID `"osm_{osmId}"` instead of a random UUID, so household members who independently import the same OSM shop share one Firestore document.
    - Added `public_shops/{osmId}` Firestore collection: stores the cell layout (rows, cols, entrance, exit, cells) of any shop with an OSM node ID.
    - `SupermarketNotifier.add/update()`: when `s.osmId != null` and not in local-only mode, also writes to `public_shops`.
    - `StoreEditorScreen`: new `template: Supermarket?` parameter pre-populates the grid for new shops; `prefill` gains `int? osmId`.
    - `ShopSearchScreen._createFromOsm()`: fetches `public_shops/{osmId}` before opening the editor; pre-populated grid shown to the user, who can refine and save (writing back to the public collection).
    - Tests: `osmId` serialization roundtrip in `supermarket_test.dart`; `upsertPublicCells` called/not-called based on `osmId` and local-only mode in `supermarket_provider_test.dart`; deterministic shop ID and template pre-population in `store_editor_screen_test.dart`. Fixed existing prefill tests to include the new `osmId` field.

74. When I found a shop in shop search and either imported it or already had it imported, I want to be able to open it in the editor by simple tap.
    - Firestore results (list view): tapping a card that shows "In your list" now opens `StoreEditorScreen` for the locally-known shop.
    - OSM results (list view): tapping a card that shows "Already defined" now opens `StoreEditorScreen` for the nearest local match.
    - Map view sheets: the disabled "Already defined" / "In your list" button is replaced with an active "Edit shop" `FilledButton` in both Firestore and OSM bottom sheets.
    - Extracted `findLocalByOsm(lat, lng, stores)` as a public top-level function (alongside `isKnownOsm`/`isKnownFirestore`); `isKnownOsm` now delegates to it.
    - Tests: 5 new unit tests for `findLocalByOsm` in `shop_search_screen_test.dart`.

75. Now I see the same shop 3 times in the results: 1. with a green check mark. 2. with "in your list" and 3. with "import". It should be there only once.
    - Root cause: `byLocation` mode has three sections (local "Your shops" with green check, Firestore "In your list", OSM "Import") with no cross-section deduplication.
    - Fix: computed `localIds` from `filteredLocalStores`; filtered `filteredFirestore` to exclude shops whose ID is already in `localIds`; filtered `filteredOsm` to exclude OSM results where `findLocalByOsm` returns a match (i.e. a local shop exists at the same location).
    - Also made local shop cards tappable (opens `StoreEditorScreen`) for consistency with Firestore and OSM cards.

76. Now I still see it two times: 1. with a green check mark. 2. with "import". What is the expected use case or result if I hit "import" now? Does it make sense to show it two times?
    - Root cause: proximity-based deduplication (`findLocalByOsm`) fails when the local shop has no GPS coordinates (e.g. created manually). The OSM card still shows "Import" even though the shop is already local.
    - Fix: extended `_findLocalByOsm` to also match by `osmId` (fallback after proximity check). Extended `filteredOsm` filter to suppress OSM results where any local shop has the same `osmId`. Both changes together ensure a shop imported from OSM is always suppressed in the OSM section regardless of whether coordinates are stored.

77. It is not fixed: I deleted my local shop, then hit "import" on the found shop in search, and it is immediately displayed twice (with green check mark and with "import").
    - Root cause 1 (lat/lng discarded on import): `_save()` in `StoreEditorScreen` computed `alreadyGeocoded` as `addressText == prefillAddress`. When the OSM shop has no address, `prefillAddress` is `null` and `addressText` is `""`, so `"" == null` evaluates to `false` in Dart, `alreadyGeocoded` is false, and the `else if (addressText.isEmpty)` branch sets `lat = lng = null` — discarding the OSM coordinates. Fixed by changing to `addressText == (prefillAddress ?? '')`, so an empty address field is correctly treated as matching a null prefill address.
    - Root cause 2 (filter timing): even with the osmId-based filter in `filteredOsm`, a race between Riverpod state propagation and the Flutter rebuild cycle can cause the OSM card to show one more frame. Fixed by explicitly calling `setState(() { _osmResults.removeWhere((r) => r.osmId == osm.osmId); })` after `_createFromOsm` returns (only when the shop is now confirmed in local stores), in both the list-view card and the map-view sheet.
