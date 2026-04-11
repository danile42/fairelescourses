import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nav_session.dart';
import 'firestore_sync_provider.dart';
import 'household_provider.dart';

class LocallyDismissedNavSessionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void markFinished(String listId) => state = listId;

  void clear() => state = null;
}

/// Streams the active collaborative navigation session for this household,
/// or null when no session is running.
final navSessionProvider = StreamProvider<NavSession?>((ref) {
  final hid = ref.watch(householdProvider);
  if (hid == null) return Stream.value(null);
  final svc = ref.watch(firestoreServiceProvider);
  return svc.navSessionStream(hid);
});

/// Stores the list id of a collaborative navigation session that the local
/// user has just finished, so the home UI can hide stale "active" state until
/// Firestore propagates the deletion.
final locallyDismissedNavSessionListIdProvider =
    NotifierProvider<LocallyDismissedNavSessionNotifier, String?>(
      LocallyDismissedNavSessionNotifier.new,
    );
