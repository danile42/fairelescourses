import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/supermarket.dart';
import 'firestore_sync_provider.dart';
import 'household_provider.dart';
import 'local_only_provider.dart';
import 'sync_error_provider.dart';

const _boxName = 'supermarkets';

final supermarketBoxProvider = Provider<Box<Supermarket>>((ref) {
  return Hive.box<Supermarket>(_boxName);
});

final supermarketsProvider =
    NotifierProvider<SupermarketNotifier, List<Supermarket>>(
      SupermarketNotifier.new,
    );

class SupermarketNotifier extends Notifier<List<Supermarket>> {
  late Box<Supermarket> _box;

  /// Shop IDs that have returned PERMISSION_DENIED on a re-upload attempt.
  /// Skipped in subsequent syncFromRemote calls — PERMISSION_DENIED is permanent
  /// (the document is owned by another user), so retrying is pointless.
  final _permissionDeniedIds = <String>{};

  @override
  List<Supermarket> build() {
    _box = ref.watch(supermarketBoxProvider);
    return _box.values.toList();
  }

  String? get _hid => ref.read(householdProvider);

  Future<void> add(Supermarket s, {bool syncToFirestore = true}) async {
    s.ownerUid = ref.read(currentUidProvider);
    await _box.put(s.id, s);
    // Upsert: replace in-place if the id already exists, otherwise append.
    if (state.any((e) => e.id == s.id)) {
      state = [for (final e in state) e.id == s.id ? s : e];
    } else {
      state = [...state, s];
    }
    if (!syncToFirestore) return;
    final hid = _hid;
    if (hid != null) {
      ref.read(firestoreServiceProvider).upsertShop(hid, s).catchError((
        Object e,
      ) {
        debugPrint('Firestore upsertShop error: $e');
        ref.read(syncErrorProvider.notifier).report(e.toString());
      }).ignore();
    }
    if (s.osmId != null && !ref.read(localOnlyProvider)) {
      ref
          .read(firestoreServiceProvider)
          .upsertPublicCells(s)
          .catchError(
            (Object e) => debugPrint('Firestore upsertPublicCells error: $e'),
          )
          .ignore();
    }
  }

  Future<void> update(Supermarket s) async {
    s.ownerUid ??=
        state.where((e) => e.id == s.id).firstOrNull?.ownerUid ??
        ref.read(currentUidProvider);
    await _box.put(s.id, s);
    state = [for (final e in state) e.id == s.id ? s : e];
    final hid = _hid;
    if (hid != null) {
      ref.read(firestoreServiceProvider).upsertShop(hid, s).catchError((
        Object e,
      ) {
        debugPrint('Firestore upsertShop error: $e');
        ref.read(syncErrorProvider.notifier).report(e.toString());
      }).ignore();
    }
    if (s.osmId != null && !ref.read(localOnlyProvider)) {
      ref
          .read(firestoreServiceProvider)
          .upsertPublicCells(s)
          .catchError(
            (Object e) => debugPrint('Firestore upsertPublicCells error: $e'),
          )
          .ignore();
    }
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    state = state.where((s) => s.id != id).toList();
    final hid = _hid;
    if (hid != null) {
      ref.read(firestoreServiceProvider).deleteShop(hid, id).catchError((
        Object e,
      ) {
        debugPrint('Firestore deleteShop error: $e');
        ref.read(syncErrorProvider.notifier).report(e.toString());
      }).ignore();
    }
  }

  /// Called by the Firestore sync listener. Merges remote state into Hive and memory.
  ///
  /// Local shops not present in the remote snapshot are re-uploaded rather than
  /// deleted, so a shop created locally while offline (or whose initial upload
  /// failed) is not silently lost on the next sync event.
  Future<void> syncFromRemote(List<Supermarket> remote) async {
    final remoteIds = remote.map((s) => s.id).toSet();
    for (final s in remote) {
      await _box.put(s.id, s);
    }
    final hid = _hid;
    for (final key in _box.keys.toList()) {
      if (!remoteIds.contains(key)) {
        if (hid != null) {
          if (_permissionDeniedIds.contains(key)) continue;
          final local = _box.get(key as String);
          if (local != null) {
            // Re-upload local-only shop instead of deleting it.
            ref
                .read(firestoreServiceProvider)
                .upsertShop(hid, local)
                .catchError((Object e) {
                  if (e.toString().contains('permission-denied')) {
                    // Document owned by another user — never retry.
                    _permissionDeniedIds.add(local.id);
                  } else {
                    debugPrint('Firestore re-upload upsertShop error: $e');
                  }
                })
                .ignore();
          }
        } else {
          await _box.delete(key);
        }
      }
    }
    state = _box.values.toList();
  }

  /// Upload all local shops to Firestore (called when joining a household).
  Future<void> uploadAll(String hid) async {
    final svc = ref.read(firestoreServiceProvider);
    for (final s in state) {
      await svc.upsertShop(hid, s);
    }
  }
}
