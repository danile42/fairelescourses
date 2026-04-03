import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/supermarket.dart';
import 'firestore_sync_provider.dart';
import 'household_provider.dart';
import 'local_only_provider.dart';

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
      ref.read(firestoreServiceProvider).upsertShop(hid, s).ignore();
    }
    if (s.osmId != null && !ref.read(localOnlyProvider)) {
      ref.read(firestoreServiceProvider).upsertPublicCells(s).ignore();
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
      ref.read(firestoreServiceProvider).upsertShop(hid, s).ignore();
    }
    if (s.osmId != null && !ref.read(localOnlyProvider)) {
      ref.read(firestoreServiceProvider).upsertPublicCells(s).ignore();
    }
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    state = state.where((s) => s.id != id).toList();
    final hid = _hid;
    if (hid != null) {
      ref.read(firestoreServiceProvider).deleteShop(hid, id).ignore();
    }
  }

  /// Called by the Firestore sync listener. Replaces state with remote data.
  Future<void> syncFromRemote(List<Supermarket> remote) async {
    final remoteIds = remote.map((s) => s.id).toSet();
    for (final s in remote) {
      await _box.put(s.id, s);
    }
    for (final key in _box.keys.toList()) {
      if (!remoteIds.contains(key)) await _box.delete(key);
    }
    state = remote;
  }

  /// Upload all local shops to Firestore (called when joining a household).
  Future<void> uploadAll(String hid) async {
    final svc = ref.read(firestoreServiceProvider);
    for (final s in state) {
      await svc.upsertShop(hid, s);
    }
  }
}
