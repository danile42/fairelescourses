# Improvement Analysis

Generated: 2026-04-06

---

## UX Improvements

### 1. ~~No feedback when Firestore operations fail~~ ✓ DONE
`SupermarketNotifier` and `ShoppingListNotifier` now report errors to `syncErrorProvider`; `HomeScreen` watches that provider and shows a snackbar informing the user that changes were saved locally and will retry automatically.

---

### 2. No offline / sync-status indicator (MEDIUM)
The app syncs with Firestore but gives no persistent visual cue about:
- Whether sync is in progress
- Whether the device is offline
- Whether data is out of sync between household members

**Suggestion:** Add a small icon in the app bar (cloud = synced, spinner = syncing, exclamation = error, slash = offline).

---

### 3. ~~Household join shows no per-step progress~~ ✓ DONE
`_setHousehold` now updates a `_joiningStep` string at each stage ("Uploading shops…", "Uploading lists…", "Joining household…") shown below the Join button spinner.

---

### 4. ~~Firebase credentials form: validation is deferred, not inline~~ ✓ DONE
All five required fields are now marked with `*` in their label. The Apply button is disabled reactively whenever any required field is empty (listeners on all five controllers trigger a rebuild). Validation-on-submit is kept as a safety net.

---

### 5. ~~No loading indicator during geocoding~~ ✓ DONE
**File:** `lib/screens/sync_screen.dart`, lines 412–422

The geocode button now shows a `CircularProgressIndicator` and is disabled while `_settingHome` is true.

---

### 6. ~~Collaborative session cleanup gives no user feedback~~ ✓ DONE
`_finishTour` now awaits `deleteNavSession`. On failure a snackbar informs the host that the session couldn't be ended and will expire automatically in 24 hours (matching the server-side expiry logic). Navigation back to the home screen still proceeds.

---

### 7. In-memory navigation state lost on crash (MEDIUM)
**File:** `lib/screens/navigation_screen.dart`

Deferred items, carry-over items, and per-store checked state live only in memory. A crash mid-tour loses all of this. Persisting this state to Hive would let users resume a tour after an app restart.

---

### 8. ~~Item suggestions can produce duplicates~~ ✓ DONE
The add-item bar now receives a filtered suggestion list that excludes items already present in the list. The rename dialog keeps the full suggestion list so renaming to an existing name is still possible.

---

### 9. ~~Pending text-field input silently discarded on back navigation~~ ✓ DONE
**File:** `lib/screens/list_editor_screen.dart`, line 328

`canPop` now also checks `_pendingItemText`, so typing in the add-item field then pressing back triggers the unsaved-changes dialog.

---

## Bugs

### B1. ~~Force-unwrap of `currentUser!` in FirestoreService~~ ✓ DONE
Both `upsertShop` and `upsertNavSession` now use null-safe `?.uid` access with `'' ` as a fallback, preventing crashes when anonymous sign-in hasn't completed.

---

### B2. ~~A single corrupt document silently drops the entire `listsStream` batch~~ ✓ DONE
`listsStream` now wraps each document's decrypt+parse in a try/catch. Bad documents are skipped and logged via `debugPrint`; all healthy documents in the same snapshot are still delivered.

---

## Summary

| # | Category | Severity | Status |
|---|----------|----------|--------|
| B1 | Bug | High | ✓ Fixed |
| B2 | Bug | Medium | ✓ Fixed |
| 1 | UX | High | ✓ Fixed |
| 2 | UX | Medium | Open |
| 3 | UX | Medium | ✓ Fixed |
| 4 | UX | Medium | ✓ Fixed |
| 5 | UX | ~~Medium~~ | ✓ Fixed |
| 6 | UX | Medium | ✓ Fixed |
| 7 | UX | Medium | Open |
| 8 | UX | Low | ✓ Fixed |
| 9 | UX | ~~Low~~ | ✓ Fixed |
