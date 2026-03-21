import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/supermarket.dart';
import '../services/firestore_service.dart';
import 'household_provider.dart';

const _boxName = 'supermarkets';

final supermarketBoxProvider = Provider<Box<Supermarket>>((ref) {
  return Hive.box<Supermarket>(_boxName);
});

final supermarketsProvider =
    StateNotifierProvider<SupermarketNotifier, List<Supermarket>>((ref) {
  final box = ref.watch(supermarketBoxProvider);
  return SupermarketNotifier(box, ref);
});

class SupermarketNotifier extends StateNotifier<List<Supermarket>> {
  final Box<Supermarket> _box;
  final Ref _ref;

  SupermarketNotifier(this._box, this._ref) : super(_box.values.toList());

  String? get _hid => _ref.read(householdProvider);

  Future<void> add(Supermarket s) async {
    s.ownerUid = FirebaseAuth.instance.currentUser?.uid;
    await _box.put(s.id, s);
    state = [...state, s];
    final hid = _hid;
    if (hid != null) FirestoreService.upsertShop(hid, s).ignore();
  }

  Future<void> update(Supermarket s) async {
    // Preserve ownerUid from existing state entry if not set
    s.ownerUid ??= state.where((e) => e.id == s.id).firstOrNull?.ownerUid
        ?? FirebaseAuth.instance.currentUser?.uid;
    await _box.put(s.id, s);
    state = [for (final e in state) e.id == s.id ? s : e];
    final hid = _hid;
    if (hid != null) FirestoreService.upsertShop(hid, s).ignore();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    state = state.where((s) => s.id != id).toList();
    final hid = _hid;
    if (hid != null) FirestoreService.deleteShop(hid, id).ignore();
  }

  /// Called by the Firestore sync listener. Replaces state with remote data,
  /// preserving ownerUid (which is not stored in Hive).
  Future<void> syncFromRemote(List<Supermarket> remote) async {
    final remoteIds = remote.map((s) => s.id).toSet();
    for (final s in remote) {
      await _box.put(s.id, s);
    }
    for (final key in _box.keys.toList()) {
      if (!remoteIds.contains(key)) await _box.delete(key);
    }
    state = remote; // set directly to keep ownerUid from Firestore metadata
  }

  /// Upload all local shops to Firestore (called when joining a household).
  Future<void> uploadAll(String hid) async {
    for (final s in state) {
      await FirestoreService.upsertShop(hid, s);
    }
  }
}
