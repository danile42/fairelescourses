# Improvement Analysis

Generated: 2026-04-06

---

## UX Improvements

### 2. No offline / sync-status indicator (MEDIUM)
The app syncs with Firestore but gives no persistent visual cue about:
- Whether sync is in progress
- Whether the device is offline
- Whether data is out of sync between household members

**Suggestion:** Add a small icon in the app bar (cloud = synced, spinner = syncing, exclamation = error, slash = offline).

---

### 7. In-memory navigation state lost on crash (MEDIUM)
**File:** `lib/screens/navigation_screen.dart`

Deferred items, carry-over items, and per-store checked state live only in memory. A crash mid-tour loses all of this. Persisting this state to Hive would let users resume a tour after an app restart.

---

## Summary

| # | Category | Severity | Status |
|---|----------|----------|--------|
| 2 | UX | Medium | Open |
| 7 | UX | Medium | Open |
