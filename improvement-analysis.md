# Improvement Analysis

Generated: 2026-04-04

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

### 5. No loading indicator during geocoding (MEDIUM)
**File:** `lib/screens/sync_screen.dart`, lines 59–81

`_settingHome` is set to `true` during geocoding but nothing in the UI reflects this. Geocoding can take 2–5 seconds; users will tap the button again thinking it didn't respond.

**Fix:** Show a `CircularProgressIndicator` or replace the button label with "Searching…" while `_settingHome` is true.

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

### 9. Pending text-field input silently discarded on back navigation (LOW)
**File:** `lib/screens/list_editor_screen.dart`, lines 271–283

`PopScope` guards against navigating away with `_dirty` state, but text currently typed in the add-item field (tracked by `_pendingItemText`) is silently discarded if the user presses back. Either include pending text in the dirty check or commit it automatically.

---

## Summary

| # | Category | Severity | Location |
|---|----------|----------|----------|
| 1 | UX | High | App-wide |
| 2 | UX | Medium | App-wide |
| 3 | UX | Medium | `sync_screen.dart:111` |
| 4 | UX | Medium | `sync_screen.dart:155` |
| 5 | UX | Medium | `sync_screen.dart:59` |
| 6 | UX | Medium | `navigation_screen.dart:287` |
| 7 | UX | Medium | `navigation_screen.dart` |
| 8 | UX | Low | `list_editor_screen.dart:262` |
| 9 | UX | Low | `list_editor_screen.dart:271` |
