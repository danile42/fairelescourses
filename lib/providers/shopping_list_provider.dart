import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';
import '../services/firestore_service.dart';
import 'household_provider.dart';

const _boxName = 'shopping_lists';

final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  return Hive.box<ShoppingList>(_boxName);
});

final shoppingListsProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingList>>((ref) {
  final box = ref.watch(shoppingListBoxProvider);
  return ShoppingListNotifier(box, ref);
});

class ShoppingListNotifier extends StateNotifier<List<ShoppingList>> {
  final Box<ShoppingList> _box;
  final Ref _ref;

  ShoppingListNotifier(this._box, this._ref) : super(_box.values.toList());

  String? get _hid => _ref.read(householdProvider);

  void _sync() => state = _box.values.toList();

  Future<void> add(ShoppingList l) async {
    await _box.put(l.id, l);
    _sync();
    final hid = _hid;
    if (hid != null) FirestoreService.upsertList(hid, l).ignore();
  }

  Future<void> update(ShoppingList l) async {
    await _box.put(l.id, l);
    _sync();
    final hid = _hid;
    if (hid != null) FirestoreService.upsertList(hid, l).ignore();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    _sync();
    final hid = _hid;
    if (hid != null) FirestoreService.deleteList(hid, id).ignore();
  }

  Future<void> toggleItem(String listId, int index) async {
    final list = _box.get(listId);
    if (list == null) return;
    final items = list.items.toList();
    items[index] = items[index].copyWith(checked: !items[index].checked);
    final updated = list.copyWith(items: items);
    await _box.put(listId, updated);
    _sync();
    final hid = _hid;
    if (hid != null) FirestoreService.upsertList(hid, updated).ignore();
  }

  /// Called by the Firestore sync listener. Merges remote state into Hive and memory.
  Future<void> syncFromRemote(List<ShoppingList> remote) async {
    final remoteIds = remote.map((l) => l.id).toSet();
    for (final l in remote) {
      await _box.put(l.id, l);
    }
    for (final key in _box.keys.toList()) {
      if (!remoteIds.contains(key)) await _box.delete(key);
    }
    _sync();
  }

  /// Upload all local lists to Firestore (called when joining a household).
  Future<void> uploadAll(String hid) async {
    for (final l in state) {
      await FirestoreService.upsertList(hid, l);
    }
  }
}
