# Improvement Analysis

Generated: 2026-04-04

---

## Potential Bugs

### 1. Duplicate `mounted` check (HIGH)
**File:** `lib/screens/navigation_screen.dart`, lines 417–418

```dart
if (!mounted) return;
if (!mounted) return;  // duplicate
```

Copy-paste error. No functional impact, but signals a code review gap.

---

### 2. Inconsistent item-matching logic across Supermarket and ShopFloor (MEDIUM)
**Files:** `lib/models/supermarket.dart` (lines 182–280), `lib/models/shop_floor.dart` (lines 59–76)

`Supermarket.findCellWithFloor()` uses a 3-pass strategy (exact → all-words → substring), but `ShopFloor.findCell()` only does a plain substring match. Users may get different search results when navigating individual floors vs. the full store.

**Fix:** Extract the 3-pass logic into a shared utility and use it in both places.

---

### 3. Fire-and-forget Firestore writes silently swallow errors (MEDIUM)
**Files:** `lib/providers/shopping_list_provider.dart` (lines 37, 46, 55, 69, 145), `lib/providers/supermarket_provider.dart` (lines 42, 45, 57, 60, 69), `lib/screens/home_screen.dart` (line 504), `lib/screens/navigation_screen.dart` (lines 288, 293)

```dart
ref.read(firestoreServiceProvider).upsertList(hid, updated).ignore();
```

`.ignore()` discards network, permission, and auth errors. Users may believe data is synced when it actually failed.

---

### 4. Empty catch blocks in Firebase initialization (MEDIUM)
**Files:** `lib/providers/firebase_app_provider.dart` (lines 19, 64, 83), `lib/models/firebase_credentials.dart` (line 55)

Silent failures make it impossible to diagnose production issues. At minimum, errors should be logged.

---

### 5. No bounds check in `toggleItem` (MEDIUM)
**File:** `lib/providers/shopping_list_provider.dart`, lines 59–71

```dart
items[index] = items[index].copyWith(...);  // no bounds check
```

If the list is modified between the time the index is obtained and this method executes (e.g., in a collaborative session), an `IndexError` will crash the app.

---

### 6. Orphaned collaborative navigation sessions (MEDIUM)
**File:** `lib/screens/navigation_screen.dart`, lines 89–98 (session creation) and 287–295 (deletion)

The host creates a session in `initState` and deletes it in `_finishTour()`. If the host force-quits or crashes before finishing, the Firestore document is never deleted and guests see the session as active indefinitely.

**Fix:** Add a server-side TTL (e.g., Cloud Function or Firestore TTL policy) to auto-expire sessions older than 24 hours.

---

### 7. No sync conflict resolution — remote overwrites local (MEDIUM)
**Files:** `lib/providers/shopping_list_provider.dart` (lines 85–94), `lib/providers/supermarket_provider.dart` (lines 74–83)

`syncFromRemote` replaces local state wholesale with remote data. A locally added list that a household member doesn't have will be silently deleted on sync with no warning or recovery path.

---

## UX Improvements

### 8. No feedback when Firestore operations fail (HIGH)
All `.ignore()` calls mean users receive no toast, snackbar, or error dialog when syncing fails. In a household-sharing app this can cause silent data loss. Each write should have a `.catchError` that shows a snackbar with a retry action.

---

### 9. No offline / sync-status indicator (MEDIUM)
The app syncs with Firestore but gives no persistent visual cue about:
- Whether sync is in progress
- Whether the device is offline
- Whether data is out of sync between household members

**Suggestion:** Add a small icon in the app bar (cloud = synced, spinner = syncing, exclamation = error, slash = offline).

---

### 10. Household join shows no per-step progress (MEDIUM)
**File:** `lib/screens/sync_screen.dart`, lines 111–121

`_setHousehold` uploads shops, then lists, then sets the ID — but the UI just shows a generic spinner. Users have no idea how far along the operation is or whether it has stalled.

**Suggestion:** Show step labels ("Uploading shops… Uploading lists… Joining…") or a linear progress bar.

---

### 11. Firebase credentials form: validation is deferred, not inline (MEDIUM)
**File:** `lib/screens/sync_screen.dart`, lines 155–244

Fields aren't validated until the user submits. There's no indication of which fields are required, no field-level error messages, and the submit button stays enabled regardless of completeness.

**Suggestions:**
- Mark required fields with an asterisk
- Show inline validation as the user types
- Disable the submit button until all required fields are non-empty

---

### 12. No loading indicator during geocoding (MEDIUM)
**File:** `lib/screens/sync_screen.dart`, lines 59–81

`_settingHome` is set to `true` during geocoding but nothing in the UI reflects this. Geocoding can take 2–5 seconds; users will tap the button again thinking it didn't respond.

**Fix:** Show a `CircularProgressIndicator` or replace the button label with "Searching…" while `_settingHome` is true.

---

### 13. Collaborative session cleanup gives no user feedback (MEDIUM)
**File:** `lib/screens/navigation_screen.dart`, lines 287–295

`deleteNavSession` is fire-and-forget. If it fails, guests remain stuck on the "join session" banner. A snackbar confirming "Session ended" (or offering a retry on failure) would prevent confusion.

---

### 14. In-memory navigation state lost on crash (MEDIUM)
**File:** `lib/screens/navigation_screen.dart`

Deferred items, carry-over items, and per-store checked state live only in memory. A crash mid-tour loses all of this. Persisting this state to Hive would let users resume a tour after an app restart.

---

### 15. Item suggestions can produce duplicates (LOW)
**File:** `lib/screens/list_editor_screen.dart`, lines 262–269

Autocomplete suggestions include items already in the list, making it easy to accidentally add duplicates. Filtering out already-present items (or highlighting them as "already added") would reduce friction.

---

### 16. Pending text-field input silently discarded on back navigation (LOW)
**File:** `lib/screens/list_editor_screen.dart`, lines 271–283

`PopScope` guards against navigating away with `_dirty` state, but text currently typed in the add-item field (tracked by `_pendingItemText`) is silently discarded if the user presses back. Either include pending text in the dirty check or commit it automatically.

---

## Summary

| # | Category | Severity | Location |
|---|----------|----------|----------|
| 1 | Bug | High | `navigation_screen.dart:417` |
| 2 | Bug | Medium | `supermarket.dart` / `shop_floor.dart` |
| 3 | Bug | Medium | Multiple providers + screens |
| 4 | Bug | Medium | `firebase_app_provider.dart`, `firebase_credentials.dart` |
| 5 | Bug | Medium | `shopping_list_provider.dart:59` |
| 6 | Bug | Medium | `navigation_screen.dart:89,287` |
| 7 | Bug | Medium | `shopping_list_provider.dart:85`, `supermarket_provider.dart:74` |
| 8 | UX | High | App-wide |
| 9 | UX | Medium | App-wide |
| 10 | UX | Medium | `sync_screen.dart:111` |
| 11 | UX | Medium | `sync_screen.dart:155` |
| 12 | UX | Medium | `sync_screen.dart:59` |
| 13 | UX | Medium | `navigation_screen.dart:287` |
| 14 | UX | Medium | `navigation_screen.dart` |
| 15 | UX | Low | `list_editor_screen.dart:262` |
| 16 | UX | Low | `list_editor_screen.dart:271` |
