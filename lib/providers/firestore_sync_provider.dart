import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import 'household_provider.dart';
import 'supermarket_provider.dart';
import 'shopping_list_provider.dart';

/// Watches the household ID and maintains Firestore real-time listeners.
/// Watch this provider in the root widget to activate syncing.
final firestoreSyncProvider = Provider<void>((ref) {
  final hid = ref.watch(householdProvider);
  if (hid == null) return;

  final shopsSub = FirestoreService.shopsStream(hid).listen(
    (shops) => ref.read(supermarketsProvider.notifier).syncFromRemote(shops),
    onError: (_) {}, // network errors are non-fatal; Firestore uses offline cache
  );

  final listsSub = FirestoreService.listsStream(hid).listen(
    (lists) => ref.read(shoppingListsProvider.notifier).syncFromRemote(lists),
    onError: (_) {},
  );

  ref.onDispose(() {
    shopsSub.cancel();
    listsSub.cancel();
  });
});
