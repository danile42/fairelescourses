import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/household_event.dart';
import 'firestore_sync_provider.dart';
import 'household_provider.dart';

/// Streams the latest household events used for in-app notifications.
final householdEventsProvider = StreamProvider<List<HouseholdEvent>>((ref) {
  final hid = ref.watch(householdProvider);
  if (hid == null) return Stream.value(const <HouseholdEvent>[]);
  final svc = ref.watch(firestoreServiceProvider);
  return svc.householdEventsStream(hid);
});
