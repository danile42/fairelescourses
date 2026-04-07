import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import 'firebase_app_provider.dart';
import 'household_provider.dart';
import 'local_only_provider.dart';
import 'supermarket_provider.dart';
import 'shopping_list_provider.dart';

/// The FirestoreService instance tied to the currently active Firebase app.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final app = ref.watch(firebaseAppProvider);
  return FirestoreService(app);
});

/// The UID of the currently signed-in user on the active Firebase app.
final currentUidProvider = Provider<String?>((ref) {
  final app = ref.watch(firebaseAppProvider);
  return FirebaseAuth.instanceFor(app: app).currentUser?.uid;
});

/// Watches the household ID and maintains Firestore real-time listeners.
/// Watch this provider in the root widget to activate syncing.
final firestoreSyncProvider = Provider<void>((ref) {
  final localOnly = ref.watch(localOnlyProvider);
  final hid = ref.watch(householdProvider);

  if (localOnly || hid == null) return;
  final svc = ref.watch(firestoreServiceProvider);

  final shopsSub = svc
      .shopsStream(hid)
      .listen(
        (shops) =>
            ref.read(supermarketsProvider.notifier).syncFromRemote(shops),
        onError:
            (
              _,
            ) {}, // network errors are non-fatal; Firestore uses offline cache
      );

  final listsSub = svc
      .listsStream(hid)
      .listen(
        (lists) =>
            ref.read(shoppingListsProvider.notifier).syncFromRemote(lists),
        onError: (_) {},
      );

  ref.onDispose(() {
    shopsSub.cancel();
    listsSub.cancel();
  });
});
