import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nav_session.dart';
import 'firestore_sync_provider.dart';
import 'household_provider.dart';

/// Streams the active collaborative navigation session for this household,
/// or null when no session is running.
final navSessionProvider = StreamProvider<NavSession?>((ref) {
  final hid = ref.watch(householdProvider);
  if (hid == null) return Stream.value(null);
  final svc = ref.watch(firestoreServiceProvider);
  return svc.navSessionStream(hid);
});
