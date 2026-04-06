# Improvement Analysis

Generated: 2026-04-06

---

## UX Improvements

### 1. No feedback when Firestore operations fail (HIGH)
All `.ignore()` calls mean users receive no toast, snackbar, or error dialog when syncing fails. In a household-sharing app this can cause silent data loss. Each write should have a `.catchError` that shows a snackbar with a retry action.

---

### 2. No offline / sync-status indicator (MEDIUM)
The app syncs with Firestore but gives no persistent visual cue about:
- Whether sync is in progress
- Whether the device is offline
- Whether data is out of sync between household members

**Suggestion:** Add a small icon in the app bar (cloud = synced, spinner = syncing, exclamation = error, slash = offline).

---

### 3. Household join shows no per-step progress (MEDIUM)
**File:** `lib/screens/sync_screen.dart`, lines 111–121

`_setHousehold` uploads shops, then lists, then sets the ID — but the UI just shows a generic spinner. Users have no idea how far along the operation is or whether it has stalled.

**Suggestion:** Show step labels ("Uploading shops… Uploading lists… Joining…") or a linear progress bar.

---

### 4. Firebase credentials form: validation is deferred, not inline (MEDIUM)
**File:** `lib/screens/sync_screen.dart`, lines 155–244

Fields aren't validated until the user submits. There's no indication of which fields are required, no field-level error messages, and the submit button stays enabled regardless of completeness.

**Suggestions:**
- Mark required fields with an asterisk
- Show inline validation as the user types
- Disable the submit button until all required fields are non-empty

---

### 5. ~~No loading indicator during geocoding~~ ✓ DONE
**File:** `lib/screens/sync_screen.dart`, lines 412–422

The geocode button now shows a `CircularProgressIndicator` and is disabled while `_settingHome` is true.

---

### 6. Collaborative session cleanup gives no user feedback (MEDIUM)
**File:** `lib/screens/navigation_screen.dart`, lines 287–295

`deleteNavSession` is fire-and-forget. If it fails, guests remain stuck on the "join session" banner. A snackbar confirming "Session ended" (or offering a retry on failure) would prevent confusion.

---

### 7. In-memory navigation state lost on crash (MEDIUM)
**File:** `lib/screens/navigation_screen.dart`

Deferred items, carry-over items, and per-store checked state live only in memory. A crash mid-tour loses all of this. Persisting this state to Hive would let users resume a tour after an app restart.

---

### 8. Item suggestions can produce duplicates (LOW)
**File:** `lib/screens/list_editor_screen.dart`, lines 262–269

Autocomplete suggestions include items already in the list, making it easy to accidentally add duplicates. Filtering out already-present items (or highlighting them as "already added") would reduce friction.

---

### 9. ~~Pending text-field input silently discarded on back navigation~~ ✓ DONE
**File:** `lib/screens/list_editor_screen.dart`, line 328

`canPop` now also checks `_pendingItemText`, so typing in the add-item field then pressing back triggers the unsaved-changes dialog.

---

## Bugs

### B1. Force-unwrap of `currentUser!` in FirestoreService (HIGH)
**File:** `lib/services/firestore_service.dart`, lines 70 and 229

Two methods force-unwrap `_auth.currentUser!.uid` without a null check:

- `upsertShop` (line 70): `s.ownerUid ?? _auth.currentUser!.uid` — crashes if `ownerUid` is null and anonymous sign-in hasn't completed.
- `upsertNavSession` (line 229): `'startedBy': _auth.currentUser!.uid` — crashes unconditionally if `currentUser` is null.

Anonymous sign-in is awaited in `main()`, but if it fails or is skipped (e.g., a future code path, network error at startup, or local-only mode edge case), these will throw an unhandled null dereference.

**Fix:** Null-check `currentUser` before access; use a fallback UID or bail out gracefully.

---

### B2. A single corrupt document silently drops the entire `listsStream` batch (MEDIUM)
**File:** `lib/services/firestore_service.dart`, lines 256–264

```dart
Stream<List<ShoppingList>> listsStream(String hid) =>
    _lists(hid).snapshots().map(
      (snap) => snap.docs
          .map((d) => ShoppingList.fromMap(_decrypt(hid, d.data()['d'] as String)))
          .toList(),
    );
```

The inner `.map()` over `snap.docs` is synchronous inside the stream `map` operator. If `_decrypt` throws for any single document (null `d` field, corrupted base64, wrong key, malformed JSON), the exception propagates as a stream error for the **entire snapshot event**. The subscriber in `firestoreSyncProvider` swallows it with `onError: (_) {}`, so no lists are updated — all household list data silently disappears from the UI for that sync cycle. If the corrupt document is never cleaned up, every subsequent sync event fails the same way.

**Fix:** Wrap the per-document `fromMap(_decrypt(...))` in a try/catch and skip individual bad documents rather than failing the whole batch.

---

## Summary

| # | Category | Severity | Location |
|---|----------|----------|----------|
| B1 | Bug | High | `firestore_service.dart:70,229` |
| B2 | Bug | Medium | `firestore_service.dart:256` |
| 1 | UX | High | App-wide |
| 2 | UX | Medium | App-wide |
| 3 | UX | Medium | `sync_screen.dart:111` |
| 4 | UX | Medium | `sync_screen.dart:155` |
| 5 | UX | ~~Medium~~ | ~~`sync_screen.dart:59`~~ ✓ |
| 6 | UX | Medium | `navigation_screen.dart:304` |
| 7 | UX | Medium | `navigation_screen.dart` |
| 8 | UX | Low | `list_editor_screen.dart:622` |
| 9 | UX | ~~Low~~ | ~~`list_editor_screen.dart:271`~~ ✓ |
