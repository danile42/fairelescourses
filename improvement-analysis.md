# Improvement Analysis

Generated: 2026-04-08

---

## Resolved Issues

### 1. Firebase Initialization Race Conditions (Fixed)
- **Status**: Resolved. `main.dart` now initializes the active Firebase app before calling `runApp`, and `FirebaseAppNotifier` handles existing instances correctly.
- **Verification**: `main.dart` lines 34–46 ensure that the app is initialized before the UI starts building.

### 2. Household Joining & Data Integrity (Fixed)
- **Status**: Resolved. `sync_screen.dart` has been updated to set the household ID before attempting to upload local data. Additionally, "resurrection" of deleted items in `syncFromRemote` has been addressed.
- **Verification**: `_setHousehold` in `lib/screens/sync_screen.dart` reordered operations.

### 3. Memory Leaks in Search (Fixed)
- **Status**: Resolved. `ShopSearchScreen` now cancels timers in `dispose` and uses `mounted` checks in async callbacks.
- **Verification**: `lib/screens/shop_search_screen.dart` contains `_debounce?.cancel()` in `dispose` and `if (!mounted) return` in `_search`.

### 4. Stale Navigation Sessions (Fixed)
- **Status**: Resolved. `FirestoreService.navSessionStream` now proactively deletes sessions older than 24 hours from Firestore.
- **Verification**: `lib/services/firestore_service.dart` line 297.

### 5. Local-Only Mode Transition (Fixed)
- **Status**: Resolved. `firestoreSyncProvider` watches `localOnlyProvider` and immediately cancels all Firestore listeners when it changes to true.
- **Verification**: `lib/providers/firestore_sync_provider.dart` line 25.

---

## Potential Bugs & Architectural Issues (Remaining)

### 1. Collaborative Navigation State Sync
`NavigationScreen` still manages a large amount of local state (`_checkedPerStore`, `_checkedUnmatched`, `_deferNextShop`) which it manually synchronizes with the `shoppingListsProvider`.
- **Risk**: While `_syncCheckedFromList` is now used to keep the checked state in sync with remote updates, there is still a risk of race conditions or state desync for complex operations like "collect later" or multi-floor navigation where local state is modified before (or without) a provider update.
- **Recommendation**: Continue refactoring `NavigationScreen` to move more state (like current floor, deferred items) into Riverpod providers that can be more easily kept in sync with the source of truth.

### 2. OSM Search Rate Limiting
`ShopSearchScreen` allows rapid searches which could trigger Overpass API rate limiting.
- **Risk**: Repeated searches in a short window might lead to temporary bans for the user's IP.
- **Recommendation**: Implement a more robust client-side rate limiter or exponential backoff for Overpass queries beyond simple debouncing.
