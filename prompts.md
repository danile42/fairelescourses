# Prompts

This file contains every prompt given to the LLM tools to build this project.
No source code was written by the human author — only the prompts below. **Exception:** the workaround of placing the start-navigation test in a separate file (`test/widgets/home_screen_start_navigation_test.dart`) was devised by the human author after Claude Code was unable to find the solution through extensive debugging. That file's placement is the only piece of the codebase not produced by an LLM.

---

## Project origin

The project was bootstrapped with `flutter create fairelescourses` and then handed to LLM assistants — specifically Claude Code (Claude Sonnet 4.6) and Junie (JetBrains' LLM agent). All subsequent development — models, providers, services, screens, widgets, tests, localisation, CI — was produced by these LLM tools in response to the prompts listed here.

---

## Prompt history

> **Note:** Prompts marked with **[J]** were handled by Junie (JetBrains' LLM agent); all others were handled by Claude Code (Claude Sonnet 4.6).

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

77. It is not fixed: I deleted my local shop, then hit "import" on the found shop in search, and it is immediately displayed twice (with green check mark and with "import"). [Addressed in prompt 78.]

78. This did not help: I can import a shop multiple times, adding one entry after another with a green check mark in the search results. [Addressed in prompt 79.]

79. I still see the same behaviour: first one entry with "import", after click on that, a new entry with green check mark appears, and this can be repeated endlessly. I still think there should be no state with green check mark — only either "import" or "in your list". [Addressed in prompts 79–80.]

80. After the first "import" of a not-yet-local shop, it is not shown as "In your list". Also, I can still import it multiple times — the multiple entries no longer appear in the search results list (good), but they are in the local shops list. Import should not be possible for a shop that is already local.
    - Root cause (architectural): the "Your shops" section in byLocation mode showed ALL locally stored shops matching the selected category, completely independent of the OSM/Firestore results. This created unavoidable duplicates and the "endless import" loop because each import added a new green-check entry while sibling OSM nodes for the same shop remained.
    - Fix: removed the `filteredLocalStores` display section entirely from `_buildResults`. Each shop now appears exactly once: Firestore results show "In your list" if already local, OSM results show "Already defined" if already local. The separate green-check section is gone.
    - Also retained from earlier: `notifier.add()` upsert (no duplicate state entries); OSM lat/lng preservation in `StoreEditorScreen._save()` so `findLocalByOsm` can suppress sibling OSM nodes.

80. After the first "import" of a not-yet-local shop, it is not shown as "In your list". Also, I can still import it multiple times — the multiple entries no longer appear in the search results list (good), but they are in the local shops list. Import should not be possible for a shop that is already local.
    - Root cause 1 (card disappeared instead of updating): the `removeWhere` calls in the Import button handler removed the OsmShop from `_osmResults` immediately after import, so the card vanished instead of switching to "Already defined". Removed the `removeWhere` calls — the card now stays in the list and `_buildOsmCard` renders it as "Already defined" once `_findLocalByOsm` finds a match.
    - Root cause 2 (sibling OSM nodes still showed "Import"): `filteredOsm` was filtering out any OSM result whose location matched a local store, which prevented sibling nodes from showing "Already defined". Removed those two filter conditions; `_buildOsmCard` now handles the "already local" display for all nearby siblings via `_findLocalByOsm` (proximity + osmId).
    - Combined effect: after import, every OSM result at that location (node, way, relation) switches to "Already defined" with a tap-to-edit action; the Import button is gone for all of them.

81. The issue still exists: I find a shop in search which I don't have locally. I click "import" — the card does not change; I would have expected that it switches to "In your list". If I hit the button multiple times, the shop is imported multiple times.
    - Root cause: `_import()` created the local copy with `id: _uuid.v4()` (a fresh UUID), not `source.id`. So `_buildFirestoreCard`'s check `stores.where((s) => s.id == shop.id)` never found the local copy (IDs didn't match), `known` stayed false, the "Import" button remained, and every click added yet another UUID entry. The `parentId: source.id` field was set but never read anywhere.
    - Fix: changed to `id: source.id` (and `osmId: source.osmId`) so the local copy has the same ID as the community shop. The existing `notifier.add()` upsert then also prevents duplicates on repeated clicks.

82. It looks better now: after click on "Import", I briefly see "In your list", but the import seems to fail — Firestore PERMISSION_DENIED on `shops/{uuid}`.
    - Root cause: `notifier.add()` always calls `upsertShop(hid, s)` which tries to write the community shop back to Firestore. The current user doesn't own that document, so the write fails. The Firestore SDK optimistically applies the write to its local cache (showing "In your list" briefly), then reverts on server rejection, firing the snapshot listener which calls `syncFromRemote` and wipes the local import.
    - Fix: added `syncToFirestore` flag (default `true`) to `notifier.add()`. `_import()` passes `syncToFirestore: false` — the shop is already in Firestore, so no write-back is needed.

83. Good, that seems to work now. Add tests for these changes, if you didn't already. Then format, update prompts.md, and commit.
    - Added tests to `test/providers/supermarket_provider_test.dart`:
      - `add with duplicate id replaces rather than appends` (upsert behaviour)
      - Group `SupermarketNotifier – syncToFirestore: false` with 3 tests: `syncToFirestore:false` skips `upsertShop`, skips `upsertPublicCells`, but still updates local state.
    - Updated `_FakeStoresNotifier.add()` in `store_editor_screen_test.dart` to match the new `{bool syncToFirestore = true}` parameter.

84. In list edit mode, list items should not be checkable — only in navigation mode. In navigation mode, unmatched items should also be checkable (with the assign-to-store button still present).
    - list_editor_screen: `onChanged: null` on each Checkbox; removed unused `_toggleItem`.
    - navigation_screen: added `_checkedUnmatched` set and `_toggleUnmatched` method; all three unmatched-item sections (no-store, grid view, DoneView) now show a Checkbox + strikethrough alongside the Assign-to-shop button; `_syncCheckedFromList` restores checked state on restart; added `checkedUnmatched`/`onToggleUnmatched` parameters to `_DoneView`.

85. Move the Start-shopping / Start-navigation buttons higher to avoid overlap by OS navigation bar.
    - Used `MediaQuery.of(context).padding.bottom` added to the 12 px fixed bottom padding.

86. Prepend navigation buttons with "Start shopping:" label in list editor (two-button row only).
    - Added `startShopping` / `"Einkaufen starten:"` l10n strings; prepended as a `Text` widget in the `showTwo` Row.

87. Add 5-second cooldown on OSM retry button after a search failure.
    - Added `_retryTimer` / `_retrySecondsLeft`; `_startRetryCountdown(5)` is called from both OSM catch blocks; retry button is disabled and shows "Retry (N)" during cooldown.

88. Add tests for the recent changes, format, update prompts.md, and commit.
    - list_editor_screen_test: fixed "checkbox toggles item checked state" → now asserts `onChanged` is null for all checkboxes in edit mode.
    - navigation_screen_test: fixed `'• Cheese'`/`'• Butter'` text assertions (bullet prefix removed when checkbox was added); added group `NavigationScreen – unmatched item checkboxes` with 4 tests (show checkboxes, tap to check, tap to uncheck, list-view variant).

89. Add two user settings: select a menu color and reset all local data.
    - New `seedColorProvider` (Hive-backed, key `seedColor`, default `0xFF2E7D32`); `FairelesCourses` changed to `ConsumerWidget` to watch it live.
    - `sync_screen.dart`: added `_ColorPicker` widget with 8 preset swatches and `_resetLocalData()` with confirmation dialog that clears all Hive boxes and invalidates all providers.
    - l10n: added `menuColorTitle`, `resetLocalDataTitle`, `resetLocalDataConfirm`, `resetLocalDataDone` in en + de.
    - sync_screen_test: added `ensureVisible` before Switch taps that scroll off-screen with the new content.

90. Replace the sync button with a config (settings) button.
    - AppBar icon changed from `Icons.sync` to `Icons.settings_outlined` (always white, no conditional dimming).
    - l10n: `syncTitle` renamed to `configTitle` ("Sync" → "Settings" / "Synchronisierung" → "Einstellungen").
    - SyncScreen AppBar title updated to `configTitle`.
    - Tests: sync icon finder updated to `settings_outlined`; German title assertion updated to "Einstellungen".

101. Show tour hint banners inside editor screens; fix "store" → "shop" wording.
    - New `TourHintBanner` widget (lib/widgets/tour_hint_banner.dart): slim primaryContainer bar at the bottom of an editor screen; only shown when `tourStepProvider == visibleOnStep`; includes a school icon, the hint message, and a Skip button.
    - `StoreEditorScreen`: shows banner on step 0 ("Give your shop a name, tap any cell and enter a product, then tap Save.") via `bottomNavigationBar`.
    - `ListEditorScreen`: shows banner on step 1 ("Give your list a name and add at least one item, then tap Save.") via `bottomNavigationBar`.
    - l10n: fixed `tourStep1Title` "Create a store" → "Create a shop"; simplified `tourStep1Body`; added `tourShopEditorHint` and `tourListEditorHint` in EN + DE.

105. Delay tour celebration until the Finish button is pressed in NavigationScreen.
    - Added `celebrationTriggerProvider` (int counter) to tour_provider.dart; `CelebrationOverlay` now watches this instead of `tourStepProvider`, firing whenever the counter increments.
    - `_launchNavigation` captures `isTourFinalStep` before calling `complete()`. In the `.then()` callback, if `isTourFinalStep && result == true` (Finish was pressed, not Back), it calls `celebrationTriggerProvider.notifier.trigger()`.
    - Skipping the tour or pressing Back during navigation no longer triggers the celebration.

104. Show confetti celebration when the intro tour completes.
    - New `CelebrationOverlay` widget (lib/widgets/celebration_overlay.dart): `ConsumerStatefulWidget` with `SingleTickerProviderStateMixin`; watches `tourStepProvider` via `listenManual` and triggers when transitioning from any step ≥ 0 to -1.
    - Manages an `OverlayEntry` with a 3.8-second `AnimationController`; entry is inserted on start and removed when the animation completes.
    - 72 randomly generated particles (circles and rectangles) with staggered start delays, individual fall speeds, horizontal drift, sine-wave wobble, and rotation; drawn by `_ConfettiPainter` using `Canvas.save/restore` + `Canvas.rotate`.
    - A centred card with `celebrationTitle` / `celebrationBody` scales in elastically, holds, then fades out before the global fade-out ends.
    - Everything is wrapped in `IgnorePointer` so the UI below remains fully interactive.
    - l10n: added `celebrationTitle` ("You're all set!" / "Alles bereit!") and `celebrationBody` ("Happy shopping!" / "Viel Spaß beim Einkaufen!") in EN + DE.

103. Fix tour spotlight misplaced (too far left) when returning to HomeScreen.
    - Root cause: `didPopNext` was listening to `ModalRoute.animation` (HomeScreen's *primary* animation, which is always `completed`), so `_scheduleRead` fired immediately while the sub-screen was still sliding away.
    - Fix: listen to `secondaryAnimation` instead — it transitions `completed → dismissed` as the sub-screen pops. `_scheduleRead` is now only called once `secondaryAnimation.status == AnimationStatus.dismissed`, when all widgets are at their final on-screen positions.

101. Fix tour spotlight re-appearing on sub-screens and misplaced after return.
    - Added `bool _routeIsCurrent = true` field to `_TourSpotlightState`.
    - `didPushNext` sets `_routeIsCurrent = false` before clearing the entry.
    - `didPopNext` sets `_routeIsCurrent = true` before calling `_scheduleRead`.
    - `_scheduleRead` guards entry creation/insertion with `if (!_routeIsCurrent) return` after computing `_targetRect`, so provider change callbacks that fire while a sub-screen is open (e.g. step 0→1 on shop save) no longer inject the overlay into the editor screen, and the FAB position is only read after the home screen is fully restored.

100. Hide tour spotlight when another screen is pushed on top of HomeScreen.
    - Added `tourRouteObserver` (RouteObserver<ModalRoute<void>>) in tour_provider.dart; registered in MaterialApp.navigatorObservers.
    - `_TourSpotlightState` now mixes in `RouteAware`: subscribes in `didChangeDependencies`, unsubscribes in `dispose`.
    - `didPushNext`: removes OverlayEntry (overlay hidden while sub-screen is open, step state preserved).
    - `didPopNext`: calls `_scheduleRead()` to re-show and re-position the spotlight on return.

99. Fix tour spotlight hidden by expanded FAB: shift spotlight to the mini button.
    - Added `tourNewShopKey` and `tourNewListKey` GlobalKeys; applied to `_MiniButton` widgets (added `super.key` to `_MiniButton` constructor).
    - Added `tourFabExpandedProvider` (NotifierProvider<bool>) in tour_provider.dart; `_HomeFabState` updates it on expand/collapse and when a mini button is tapped.
    - `TourSpotlight` adds a second `listenManual` subscription to `tourFabExpandedProvider`; when the FAB expands on step 0/1, `_scheduleRead` re-fires and the spotlight moves to `tourNewShopKey` / `tourNewListKey`.

98. Upgrade interactive tour to a spotlight overlay pointing at actual buttons.
    - `TourSpotlight` (ConsumerStatefulWidget, tour_spotlight.dart) manages a full-screen `OverlayEntry`: dark scrim with a circular cutout over the target button, white ring border, and a floating callout card with step dots + skip button.
    - Two global keys exported from tour_spotlight.dart: `tourFabKey` (applied to the FAB) and `tourPlayKey` (applied to the first list's play button when `i == 0`).
    - Uses `ref.listenManual` + `addPostFrameCallback` with retry (up to 15 frames) to locate the target RenderBox after navigation transitions.
    - Callout positions itself above or below the spotlight circle depending on screen position.
    - `TourCard` widget removed (replaced by the callout inside the overlay).

97. Replace first-start help screen with an interactive 3-step tour.
    - `TourStepNotifier` (NotifierProvider<int>) in tour_provider.dart: initialises from Hive (`introSeen`); -1 = inactive, 0/1/2 = current step; `advance(fromStep)` guards idempotency; `complete()` persists to Hive and sets -1.
    - `TourCard` widget (lib/widgets/tour_card.dart): animated step-dot progress indicator, icon + title + body for each step, "Skip tour" button; shown at bottom of HomeScreen body column; disappears when step == -1.
    - HomeScreen: removed old `initState` intro logic; `ref.listen` on `supermarketsProvider` (advance 0→1) and `shoppingListsProvider` (advance 1→2); `_launchNavigation` calls `complete()` to advance step 2 and persist.
    - The existing `HelpScreen` remains accessible via the (?) button at all times.
    - l10n: added `tourSkip`, `tourStep1Title/Body`, `tourStep2Title/Body`, `tourStep3Title/Body` in EN + DE.

96. De-highlight the navigation start cell once the user checks off their first item.
    - `isCurrent` (primaryContainer / navigation-arrow highlight) is now suppressed in both the grid card view and the mini-map as soon as `_lastCheckedCell` is set.
    - This ensures only the 3×3 neighbourhood of the last checked-off item is visible; the "start of route" cell no longer competes with it.

95. Change adjacency highlight to 3×3 neighbourhood (Chebyshev distance).
    - Added `ShopFloor.isNeighbour(a, b)` — true when Chebyshev distance == 1 (|Δrow| ≤ 1 && |Δcol| ≤ 1, excluding self); covers all 8 surrounding cells.
    - `_isAdjacentCell` in navigation_screen and the adjacency set in mini_map now use `isNeighbour` instead of `distance == 1`.

94. Fix app icon in title: declare asset in pubspec.yaml and prevent Row overflow.
    - Added `assets/icon.png` under `flutter: assets:` in pubspec.yaml (was only declared for flutter_launcher_icons, not as a bundle asset).
    - Wrapped title `Text` in `Flexible` with `TextOverflow.ellipsis` to prevent the Row from overflowing the AppBar.

93. In the mini-map grid, highlight cells adjacent to the last checked-off item using the same logic as the list/card views.
    - Added `lastCheckedCell` / `lastCheckedFloor` parameters to `MiniMap`.
    - Pre-compute `adjacentCells` set using `ShopFloor.distance() == 1` (same floor, non-done stops only).
    - Adjacent cells get `secondaryContainer` background, applied after stop colour but before the current-cell override.
    - `NavigationScreen` passes `_lastCheckedCell` / `_lastCheckedFloor` to `MiniMap`.

92. During navigation, highlight items in cells directly adjacent to the last checked-off item's cell.
    - Added `_lastCheckedCell` / `_lastCheckedFloor` state; set in `_toggleItem` when an item is checked (not unchecked) by scanning the store plan stops.
    - Added `_isAdjacentCell(cell, floor)` helper using `ShopFloor.distance()` (Manhattan distance == 1, same floor) against `_lastCheckedCell`.
    - Grid view: adjacent (non-current, non-done) stop cards get `secondaryContainer` background alongside the existing `primaryContainer` for the current stop.
    - List view: `_buildItemRow` gains a `highlighted` flag; adjacent items are wrapped in a semi-transparent `secondaryContainer` `ColoredBox` (45% opacity). List iteration changed from `expand` to nested `for` loops to carry stop context per item.

106. Analyze the architecture of the project and write documentation including diagrams (with PlantUML) to enable future developers to understand the project. Write this in a directory docs/architecture as markdown files.
    - Created `docs/architecture/README.md`: high-level overview, tech stack table, directory layout, top-level component diagram.
    - Created `docs/architecture/data-models.md`: PlantUML class diagram for all models (Supermarket, ShopFloor, ShoppingList, NavigationPlan, NavSession, FirebaseCredentials) with field/method details.
    - Created `docs/architecture/state-management.md`: Riverpod provider graph, full provider reference table, startup lifecycle diagram, dual-write and Firestore sync patterns, tour state machine.
    - Created `docs/architecture/screens-navigation.md`: screen hierarchy diagram, push/pop navigation map, per-screen description, simplified widget tree diagram.
    - Created `docs/architecture/services.md`: service component diagram, FirestoreService (auth, encryption, Firestore schema, methods), NavigationPlanner algorithm flowchart, NominatimService, OverpassService.
    - Created `docs/architecture/persistence.md`: storage architecture diagram, Hive box layout, settings key reference, full Firestore document schema, data consistency model.
    - Created `docs/architecture/key-flows.md`: PlantUML sequence diagrams for create-shop-and-navigate, collaborative navigation, search-and-import, join-household, and navigation planning algorithm.

109. Convert the architecture diagrams from PlantUML to Mermaid so they render directly on GitHub.

110. Do not use title case in the docs — use regular sentence case even in headings.
    - Applied to `docs/user-guide.md`: converted all 27 headings from title case to sentence case.

111. Add automated dependency updates via Dependabot (weekly PRs for pub packages and GitHub Actions).
    - Created `.github/dependabot.yml` with two update targets: `pub` (pubspec.yaml) and `github-actions` (.github/workflows/).

108. Create end-user documentation with Mermaid diagrams covering all features; written to docs/user-guide.md.
    - Eight sections covering quick-start tour, home screen, shop grid editor (cells, splits, floors), shopping lists, navigation, shop search, household sync, and settings.
    - Six Mermaid diagrams: quick-start flow, home screen structure, multi-floor tab navigation, full navigation session flow, planning a shopping trip (sequence), joining a household (sequence), and the 3-pass item-matching flowchart.

107. Analyze the project for potential bugs and UX improvements; write findings to improvement-analysis.md.

91. Add `osmCategoryLabel` tests to overpass_service_test.dart.
    - New group `osmCategoryLabel – localised strings` using `AppLocalizationsEn()` directly.
    - Tests: every category key resolves to a non-empty string, spot-checks for supermarket/pharmacy/bakery, unknown key returns key itself, all 18 categories produce distinct labels.

130. Remove the "find shops online" 4th tour step — online search is now the default.
    - Reverted _launchNavigation to complete() + celebration trigger on navigation success (step 2 is again the final step).
    - Removed the supermarketsProvider step-3 completion listener.
    - tour_spotlight.dart: back to 3 dots, removed step-3 key/fab-sub/switch cases.
    - Removed TourHintBanner (visibleOnStep: 3) from ShopSearchScreen and its now-unused import.
    - Removed tourStep4Title/tourStep4Body from both ARBs and regenerated l10n.
    - Removed step-3 comment from tour_provider.dart.

129. Show introductory help screen before the interactive tour starts on first launch.
    - Added helpSeenKey = 'helpSeen' constant to tour_provider.dart.
    - _HomeScreenState.initState: if helpSeen is not set and tourStepProvider >= 0, marks helpSeen immediately (so force-quit doesn't re-show it) then pushes HelpScreen.
    - TourSpotlight naturally suppresses itself while HelpScreen is on top (via existing didPushNext); reappears at step 0 once the user taps "Get started" and the route is popped.

128. Fix tour spotlight circle misplaced "a little too high" at step 1 (Create a shopping list).
    - Root cause: tourNewShopKey/tourNewListKey were on the _MiniButton StatelessWidget, so findRenderObject() returned the full Row (label + FAB). The Row is much wider than tall, so spotRadius = max(row_width, row_height) / 2 + 20 produced a large circle extending upward into the "New shop" area.
    - Fix: moved the GlobalKeys to the FloatingActionButton.small inside _MiniButton (via new fabKey parameter). Now the spotlight targets the 40×40 FAB bounding box, producing a tight, correctly-centred circle.

127. "New shop" always opens shop search; "Create from scratch" only offered when search returns no results.
    - Removed the tourStep == 3 condition — "New shop" FAB unconditionally opens ShopSearchScreen.
    - ShopSearchScreen: when search has been performed and both Firestore and OSM return nothing (and no brand filter is active), shows a "New shop" OutlinedButton to open StoreEditorScreen from scratch.

126. Correct the tour: keep the original 3 steps, add a new step 4 after navigation that guides the user to find shops online.
    - Reverted tourStep1Title/tourStep1Body to original ("Create a shop" / "Tap + and choose 'New shop'.") in both locales.
    - Added tourStep4Title/tourStep4Body in EN and DE for the new online-search step.
    - `_launchNavigation`: changed `complete()` → `advance(2)` so navigation advances to step 3 instead of ending the tour.
    - Added supermarketsProvider listener in HomeScreen: when on step 3 and a new shop is added, calls `complete()` and triggers celebration.
    - "New shop" FAB button: opens ShopSearchScreen on tourStep == 3 (was 0); `TourHintBanner` in ShopSearchScreen now shows on step 3.
    - `TourSpotlight`: extended to 4 dots; step 3 mapped to tourNewShopKey (same as step 0); fab-sub update guard includes step 3; switch statements cover step 3 → tourStep4Title/Body.

126. Fix flutter analyze warnings: replace deprecated Color.value with toARGB32(), remove unused key parameter from private _MiniButton widget, rename underscore-prefixed local functions in tests.

125. Add online shop search as the first step of the intro tour.
    - Tour step 0 now opens ShopSearchScreen (instead of StoreEditorScreen) when the user taps 'New shop' during the tour.
    - TourHintBanner added to ShopSearchScreen explaining that searching by location is faster than creating a shop manually.
    - Updated tourStep1Title/tourStep1Body in both locales (EN/DE) to "Find a shop" / "search for shops online".
    - New l10n key tourShopSearchHint added in both locales.

121. Add tests for improvement-analysis fixes #2, #5, and #7.
    - `supermarket_test.dart`: 9 new tests in `ShopFloor.findCell – 3-pass matching` covering exact, all-words, and substring passes, subcell matching, and pass-priority ordering.
    - `shopping_list_provider_test.dart`: 2 new tests for `toggleItem` out-of-bounds guard; 2 new tests in `syncFromRemote with household` verifying local-only list preservation and re-upload.
    - `supermarket_provider_test.dart`: 2 new tests in `syncFromRemote with household` verifying local-only shop preservation and re-upload.

122. Check that the first 7 problems in improvement-analysis.md have been fixed, and if so, remove them from the file.
    - Verified fixes #1–5 and #7 in source (duplicate mounted check, 3-pass matching, Firestore error logging, Firebase catch blocks, toggleItem bounds check, syncFromRemote conflict resolution). Fix #6 (orphaned session TTL) not yet implemented — no TTL field or expiry logic found.
    - Removed fixed items #1–5 and #7 from improvement-analysis.md; renumbered remaining 10 items (#6 → #1, UX #8–16 → #2–10); updated summary table.

124. Remove the now-fixed orphaned-session entry from improvement-analysis.md and renumber remaining items 1–9.

123. Update prompts.md and commit.

120. Preserve local-only items in syncFromRemote instead of silently deleting them (improvement-analysis #7).
    - shopping_list_provider: re-uploads local-only lists to Firestore instead of deleting them when they're absent from the remote snapshot.
    - supermarket_provider: same for shops.
    - When not in a household (no hid), local-only items are still cleaned up as before.

119. Auto-expire orphaned collaborative navigation sessions older than 24 hours (improvement-analysis #6).
    - Added `startedAt` field to NavSession model.
    - navSessionStream() now returns null for sessions where startedAt is >24h ago, so guests see no active session banner for host-crashed sessions.

118. Add bounds check to toggleItem to prevent IndexError in concurrent collaborative sessions (improvement-analysis #5).
    - Added `if (index < 0 || index >= items.length) return;` before the index access.

117. Add debugPrint logging to empty catch blocks in Firebase initialization (improvement-analysis #4).
    - firebase_app_provider.dart: logged in build(), clearCustomFirebaseCredentials(), _initNamedApp(), and loadSavedFirebaseCredentials().
    - firebase_credentials.dart: logged parse failure in fromGoogleServicesJson().

122. Add iOS platform support: scaffold ios/ via flutter create --platforms=ios, register iOS app in Firebase and regenerate firebase_options.dart via flutterfire configure, enable iOS launcher icons in pubspec.yaml and regenerate them.

121. Add Dependabot badge to README.md alongside the CI and Codecov badges.

120. Replace the Architecture section in README.md with a link to the detailed architecture docs. Extend the "Written by Claude" note to cover all documentation and diagrams as well.

116. Log errors from fire-and-forget Firestore writes instead of silently discarding them (improvement-analysis #3).
    - Replaced `.ignore()` with `.catchError((Object e) => debugPrint(...)).ignore()` on all upsertList, deleteList, upsertShop, deleteShop, upsertPublicCells, upsertNavSession, and deleteNavSession calls.
    - Added `import 'package:flutter/foundation.dart'` to the two provider files.

115. Align ShopFloor.findCell() with Supermarket's 3-pass matching strategy (improvement-analysis #2).
    - Replaced plain substring match with exact → all-words → substring passes so individual-floor searches return the same quality matches as full-store searches.

114. Fix duplicate `mounted` check in navigation_screen.dart (improvement-analysis #1).
    - Removed the second redundant `if (!mounted) return;` at line 417.

113. Fix dart formatting failures in CI and add a git pre-commit hook to prevent future occurrences.
    - Ran `dart format lib/ test/` to reformat 4 test files.
    - Created `.git/hooks/pre-commit` running `dart format --output=none --set-exit-if-changed lib/ test/` to block unformatted commits.

112. Add tests to reach 65% line coverage.
    - Coverage raised from 63.6% → 65.02% (3717/5717 lines), 484 tests total.
    - `list_editor_screen_test.dart`: deselect-store-chip test (covers `ids.remove` else-branch); German locale tests for preferred shops + empty list (`preferredShops`, `noItemsInList`), item popup menu (`moveToList`, `rename`), and unsaved-changes dialog (`unsavedChanges`, `discardChanges`, `keepEditing`).
    - `home_screen_test.dart`: German FAB expansion test (`newList`); German delete-shop confirmation dialog (`deleteConfirm`, `yes`, `no`).
    - `store_editor_screen_test.dart`: German "edit existing shop" test (`editShop`).
    - Key fixes: used `find.byTooltip('Zurück')` instead of `pageBack()` in German locale (back button tooltip is locale-dependent); discarded overflow exception from popup menu render with `tester.takeException()` before asserting `isNull`.

117. Implement independent of the other active session - after each feature, run the full commit procedure:
    - When I am in navigation mode and someone else adds items to the list, I want to be notified, the list and navigation should be updated.
    - Put the initial help slides on one screen again.
    - Remove mentions of the intro tour from the user documentation.
    - Shop search by item should find only-local shops, too - not only shops defined in a household.
    - Feature 1: Added `_plan` mutable state (initialized from `widget.plan`) and `_knownItemNames` set in `NavigationScreen`. The `shoppingListsProvider` listener now always runs (not just in collaborative mode), detects newly added unchecked items that weren't in the original plan, and stores them in `_newItems`. A `MaterialBanner` appears at the top of the navigation body when `_newItems` is non-empty, offering "Dismiss" and "Update route" buttons. `_refreshPlan()` replans with the current list, resizes `_checkedPerStore`, restores checked state via `_syncCheckedFromList`, and clears the banner. New l10n strings: `navListUpdated` (with `n` placeholder), `navUpdateRoute`.
    - Feature 2: Replaced the `PageView` (4 swipeable slides with dot indicators and Next buttons) in `HelpScreen` with a single `SingleChildScrollView` containing all 4 sections stacked vertically using a new `_HelpSection` widget (icon in circle + title + body in a row layout). The data-storage section and Close button are placed at the bottom. Removed the now-unused `_TourPage` class. `HelpScreen` simplified from `StatefulWidget` to `StatelessWidget`.
    - Feature 3: Removed all intro-tour references from `docs/user-guide.md`. Section 1 (Quick start): replaced the three-step tour flowchart and "spotlight / Skip tour" description with a plain numbered list (create shop → create list → tap play). Section 5.7 (Finishing a trip): removed the confetti/onboarding-tour bullet point.
    - Feature 4: In `shop_search_screen.dart`'s `_search()`, the `byItem` branch now also filters `supermarketsProvider` for local shops whose `cells` or `subcells` contain a goods entry exactly matching the query (case-insensitive, trimmed). Local matches not already in the Firestore results (deduped by shop ID) are prepended to `_firestoreResults`, so they appear in the same list and use the same card/import UI.
166. Extract test workaround note into README, fix CI failures, and clean up code duplication between home-screen test files.
    - README: Added a "Test organisation note" under "Running tests" explaining why `home_screen_start_navigation_test.dart` exists as a separate file and crediting the workaround to the human author (Claude Code didn't find it).
    - CI fix: Updated the three failing `HelpScreen` group tests in `help_screen_test.dart` to match the current single-scrollable-screen implementation instead of the removed multi-page/wizard design. Tests now check for "Get started" (EN) and "Los geht's" (DE) buttons and treat tapping it as a pop rather than a page-through sequence.
    - Deduplication: Extracted mocks and helpers that were duplicated in both `home_screen_test.dart` and `home_screen_start_navigation_test.dart` into the already-existing shared helper `test/helpers/home_screen_helpers.dart`. Both test files now import that helper; all private classes (`_NullHouseholdNotifier`, `_FakeListsNotifier`, etc.) and the `_list`/`_wrap` top-level functions were removed and replaced with the public equivalents (`NullHouseholdNotifier`, `FakeListsNotifier`, `makeList`, `wrapHomeScreen`, …).
167. Reorganise shop search modes: By location first, By item second; drop By name.
    - Dropped the "By name" search mode entirely (Firestore full-text name search, its OSM fallback, and the corresponding ARB strings `searchByName` and `searchShopsHint`).
    - Reordered the segmented button to "By location | By item" (was "By name | By item | By location").
    - Default mode is now "By location" (was "By name").
    - Empty state for "By location" keeps the "Create shop" fallback button.
    - Empty state for "By item" now shows an advisory text ("No shops found. Try searching by location…") instead of a create button. New ARB key: `searchByItemNoResults`.
    - Tests updated to match: removed the "By name search" test group and all byName-related assertions; added "By item no results shows advisory text" test; updated default-mode and tab-switching tests.

168. Users want to assign items to categories, and be able to assign categories (alternative to items) to shop cells. Navigation should find items by matching items or categories. How could this be done? What are the implications for existing data? Implement this!
    - Added `String? category` field (`@HiveField(2)`) to `ShoppingItem`; updated Hive adapter, `copyWith`, `toMap`, `fromMap`.
    - Extended `Supermarket.findCell` / `findCellWithFloor` with an optional `{String? category}` parameter; extracted internal 3-pass logic into `_findCellByQuery` so the same passes run for category as a fallback when the item name yields no match.
    - Updated `NavigationPlanner` to carry `ShoppingItem` objects through `storeItems` / `_buildRoute` and pass `category:` to all cell lookups.
    - Updated the list editor: edit-item dialog now has a second field for category; category is shown as a grey subtitle in each list tile.
    - Added `itemCategory` / `itemCategoryHint` ARB keys (EN + DE) and regenerated l10n.
    - 5 new navigation-planner tests covering category matching, name-over-category priority, null category, no-match, and same-category grouping. All 504 tests pass.
168. Fix CI analyze failure: remove unnecessary null-aware operator in list_editor_screen.dart line 245 (`newName?.trim()` → `newName.trim()`).

169. Fix infinite Firestore re-upload loop: app was hammering `shops/osm_XXXXXXX` with `PERMISSION_DENIED` retries on every sync event. Root cause: `syncFromRemote` re-uploads local-only shops missing from the remote snapshot, but community-imported OSM shops (saved with `syncToFirestore: false`) can never be written back because the Firestore document is owned by another user. Fix: track PERMISSION_DENIED shop IDs in `_permissionDeniedIds` set on `SupermarketNotifier`; skip those IDs on all subsequent `syncFromRemote` calls within the session.

171. When I enter an item in a list and press "Save" without pressing "+" first, there should be the dialog asking me if I want to save the changes.
    - The AppBar Save button now checks `_pendingItemText` before saving. If true, `_confirmUnsaved()` is shown; "Save" in the dialog proceeds with `_save()`, anything else (keep editing or dismiss) stays in the editor.

174. Tests are failing. Fix them and run the full commit procedure. Then check which tests don't finish, and consider moving them to separate test files as a workaround.
    - Root cause: `item_categories` Hive box (opened in `main()` since prompt 170) was missing from `test/helpers/hive_helper.dart`. Added it to both `setUpHive()` (openBox) and `clearHive()` (clear).
    - Identified a hanging test (`ListEditorScreen – German unsaved changes dialog`) that never terminates; extracted it to its own file as a workaround (see below).

173. Fix bug B2 (improvement-analysis.md): wrap per-document decrypt in try/catch in listsStream so a single corrupt document no longer silently drops the entire snapshot batch.
    - Added `package:flutter/foundation.dart` import (provides `debugPrint`; made `dart:typed_data` redundant, so removed it).
    - Changed the synchronous `.map(...).toList()` to an explicit for-loop with a per-document try/catch: bad documents are skipped and logged via `debugPrint`; all healthy documents in the same snapshot are still delivered.

172. Fix bug B1 (improvement-analysis.md): replace force-unwrap `_auth.currentUser!.uid` with null-safe access in FirestoreService.
    - `upsertShop` line 70: `_auth.currentUser!.uid` → `_auth.currentUser?.uid` (ownerUid stays null when auth hasn't completed, preserving the "anyone can edit" fallback).
    - `upsertNavSession` line 229: `_auth.currentUser!.uid` → `_auth.currentUser?.uid ?? ''` (empty string won't match any real UID, so no guest is incorrectly elevated to host).

170. Remember the mapping of categories to items locally, and pre-fill the category when an item is entered in the future.
    - Opened a new Hive box `item_categories` (`Box<String>`, key: lowercased item name, value: category) in `main.dart`.
    - `_addItem`: looks up the remembered category for the item name and passes it to `ShoppingItem(...)` on creation.
    - `_editItem` open: pre-fills the category field with `item.category ?? _lookupCategory(item.name)`.
    - `_editItem` autocomplete `onSelected`: uses the looked-up category for the newly selected name (falls back to the current field value).
    - `_editItem` confirm: saves the name→category mapping via `_saveCategory(trimmed, newCategory)` before updating state.

175. [J] Extract these three test cases to separate test classes: deselect store chip, German preferred shops, German item popup menu.
176. [J] Move "`unsaved changes dialog shows German strings`" to a separate file, too.
177. [J] Move "`tapping Start navigation opens NavigationScreen`" to a separate file, too.
178. [J] Verify that all the extracted tests work.
179. [J] Add all the extracted test files to Git. Update prompts.md with the prompts I gave you for these changes. Make sure formatting is correct, then commit.
180. [J] The readme currently mentions that all code (with one exception) was written by Claude Code. Mention that you did some work, too.
181. [J] Say "LLMs" instead of "AI". Update prompts.md, and commit.
182. [J] Mark those prompts that relate to you, and mention that in the readme.
183. [J] dart format fails in CI - fix that, update prompts.md, and commit.
184. [J] Actually, you processed all prompts starting from line 528 in prompts.md. Update that.
185. [J] CI fails in analyze: fix unused_element and unused_element_parameter warnings. Update prompts.md and commit.
186. [J] Now dart format fails in CI. Fix that.

187. Generalize the "Test organisation note" in the README to say several tests were extracted to separate files, without mentioning that the human invented the workaround at that location.

188. Add a /finish-feature skill file at .claude/commands/finish-feature.md with the post-feature checklist (analyze, test, format, update prompts.md, commit).

189. Commit outstanding README changes (Junie had simplified the intro and restructured the top of the file).

188. When an item is entered, but not yet added to a list: when I then save (either directly or via the dialog that appears if I try to go back), the entered item should be added to the list before saving.
    - Added `GlobalKey<_AddItemBarState> _barKey` to `_ListEditorScreenState` and passed it to `_AddItemBar` (added `super.key` to its constructor).
    - Added `submitCurrent()` to `_AddItemBarState`: calls `_submit(_autoCtrl?.text ?? '')`, which synchronously adds the item via `onAdd` then clears the field on the next frame.
    - `_save()` now calls `_barKey.currentState?.submitCurrent()` before building the updated list, so any pending text is flushed into `_items` first.
    - Simplified the AppBar Save button: was showing the unsaved-changes dialog when `_pendingItemText` was true; now always calls `_save()` directly (pending text is added automatically).
    - The back-navigation dialog path (`onPopInvokedWithResult` → `_confirmUnsaved` → Save) already called `_save()`, so it gains the same behaviour for free.

190. Update user doc and architecture docs according to the current state of the project. Keep the description in readme minimal and point to either user doc or architecture doc for details.
    - README: replaced the long features list with a two-line summary + pointers to `docs/user-guide.md` and `docs/architecture/`; kept build/test/CI/LLM attribution sections.
    - `docs/user-guide.md`: bumped version to 0.9.25; added item category and auto-add-on-save to §4.1; updated §4.2 (Rename now edits category too); replaced 3-mode shop search diagram with 2-mode (By location + By item, no By name); updated item-matching appendix flowchart to show the category-fallback pass.
    - `docs/architecture/data-models.md`: added `category String?` to `ShoppingItem`; expanded model notes to explain dual role of category (display + matching fallback) and the `item_categories` Hive box.
    - `docs/architecture/persistence.md`: added `item_categories` box to the Hive boxes table.
    - `docs/architecture/screens-navigation.md`: updated ListEditorScreen to document auto-add-on-save and category pre-fill; updated ShopSearchScreen to 2 modes.
    - `docs/architecture/services.md`: updated NavigationPlanner algorithm diagram to include the category-based fallback search.
    - `docs/architecture/key-flows.md`: updated item matching flowchart (§5) to include category-fallback branch.

191. Start a new branch and fix the problems described in improvement-analysis.md.
    - Branch: `fix/improvement-analysis`.
    - #1 (Firestore error feedback): Added `sync_error_provider.dart` — a `NotifierProvider<SyncErrorNotifier, String?>` that providers write to on Firestore failure. `supermarket_provider` and `shopping_list_provider` report errors via `ref.read(syncErrorProvider.notifier).report(...)` in their `add`/`update`/`remove` catchError handlers. `HomeScreen` listens with `ref.listen` and shows a `SnackBar` with `l.syncError`, then clears the state.
    - #3 (household join progress): `_setHousehold` in `sync_screen.dart` is now async and sets `_joiningStep` (a new `String?` state variable) at each stage ("Uploading shops…", "Uploading lists…", "Joining household…"). The step label is displayed below the spinner when non-null.
    - #4 (Firebase form validation): Added `_firebaseFieldsComplete` getter checking all 5 field controllers are non-empty. `initState` registers `_onFirebaseFieldChanged` listeners on all 5 controllers. The Apply button is disabled when `!_pasteJsonMode && !_firebaseFieldsComplete`. `_field()` helper appends ` *` to the label.
    - #6 (session cleanup feedback): `_finishTour` made `async`; it now `await`s `deleteNavSession` inside a try/catch. On failure it shows a `SnackBar` with `l.sessionEndFailed` (session auto-expires in 24 h) before calling `Navigator.pop`.
    - #8 (duplicate suggestions): `addBarSuggestions` in `list_editor_screen.dart` filters out names already present in `_items` (case-insensitive). The rename dialog still receives the full `suggestions` list.
    - B1/B2: Marked ✓ DONE in `improvement-analysis.md` (already implemented in prior commits).
    - l10n: Added 5 new strings to `app_en.arb` and `app_de.arb`: `joiningStepUploadingShops`, `joiningStepUploadingLists`, `joiningStepJoining`, `syncError`, `sessionEndFailed`.

192. Fix the remaining two open issues from improvement-analysis.md on branch `fix/remaining-improvements`.
    - #2 (offline indicator): Added `connectivity_plus: ^6.0.0` to pubspec.yaml. New `lib/providers/connectivity_provider.dart` exposes `isOfflineProvider` (a `StreamProvider<bool>`) backed by `Connectivity().onConnectivityChanged`. `HomeScreen` watches it and shows a `cloud_off` icon with tooltip in the app bar when offline. l10n: `offlineIndicator` string added in EN and DE.
    - #7 (nav state persistence): `_NavigationScreenState` now mixes in `WidgetsBindingObserver`. On `AppLifecycleState.paused` or `.detached`, `_saveNavState()` writes `_storeIndex`, `_deferNextShop`, `_forNewList`, `_carriedOverItems`, and `_carriedFromStoreName` as JSON to the Hive settings box under key `navState_<listId>`. On `initState`, `_restoreNavState()` reads this back (only for non-collaborative tours). `_finishTour()` calls `_clearNavState()` to remove the saved state. Checked item progress was already persisted via shopping list toggles.
    - Test fix: `navigation_screen_test.dart` lacked Hive setup; added `setUpAll`/`tearDownAll`/`setUp(clearHive)` using the shared `hive_helper.dart`. `home_screen_helpers.dart` overrides `isOfflineProvider` with `Stream.value(false)` to avoid the `MissingPluginException` from the connectivity platform channel in tests.
    - Closed `improvement-analysis.md`: all issues resolved.
