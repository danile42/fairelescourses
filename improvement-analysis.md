# Improvement Analysis

Generated: 2026-04-07

---

## Potential Bugs & Architectural Issues

### 1. Firebase Initialization Race Conditions
In `lib/main.dart`, the default Firebase app is initialized, followed by an asynchronous call to `initActiveFirebaseApp()` which may initialize a custom app.
- **Risk**: `FirebaseAppNotifier.build` might execute before the custom app is ready, returning the default app instance. This can lead to a state where the UI shows the default app while the background processes eventually switch to the custom one, causing inconsistent data or multiple anonymous sign-ins.
- **Recommendation**: Ensure `initActiveFirebaseApp()` completes before the app's `ProviderScope` is built, or handle the transition more robustly in `FirebaseAppNotifier`.

### 2. Household Joining & Data Integrity
The joining process in `lib/screens/sync_screen.dart` (`_setHousehold`) uploads local data *before* setting the household ID.
- **Risk**: If the upload succeeds but `setId` fails (e.g., due to a crash), local data is pushed to a household that the user hasn't successfully joined.
- **Risk**: The "re-upload local items" logic in `ShoppingListNotifier.syncFromRemote` and `SupermarketNotifier.syncFromRemote` can cause deleted items to reappear (resurrection). If User A deletes a list while offline, and User B (who has the list) syncs, User A might re-download it. If User A joins a household, their local shops/lists are merged, which is intended, but lacks a mechanism to resolve conflicts or deletions.

### 3. Collaborative Navigation Desync
`NavigationScreen` manages a large amount of local state (`_checkedPerStore`, `_checkedUnmatched`) that it manually synchronizes with the `shoppingListsProvider`.
- **Risk**: In collaborative mode, updates from other users might conflict with local state, especially if the local state hasn't been updated to reflect the latest remote changes before the user interacts with it.
- **Recommendation**: Refactor `NavigationScreen` to rely more directly on the provider state or implement a more robust merging strategy for collaborative updates.

### 4. Memory Leaks in Search
`ShopSearchScreen` creates a `Timer` for debouncing but might not always cancel it correctly if multiple rapid changes occur, although `dispose` does cancel it.
- **Risk**: In `_onChanged`, `_debounce?.cancel()` is called, but if `_search` is already running, it continues. Firestore searches are not aborted.
- **Recommendation**: Use a `CancelableOperation` or check for `mounted` more strictly in all async callbacks.

### 5. Stale Navigation Sessions
`FirestoreService.navSessionStream` filters out sessions older than 24 hours from the stream, but they are never deleted from Firestore.
- **Risk**: Orphaned session documents will accumulate in the `nav` subcollection over time.
- **Recommendation**: Implement a cleanup trigger or handle deletion of old sessions more proactively.

### 6. Local-Only Mode Transition
Switching to local-only mode clears the household ID but doesn't explicitly stop any active Firebase listeners until the next app restart or provider refresh.
- **Risk**: Background sync might briefly continue after enabling local-only mode.
- **Recommendation**: Ensure all sync listeners are immediately terminated when `localOnlyProvider` changes to true.
