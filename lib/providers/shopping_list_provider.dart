import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';
import 'firestore_sync_provider.dart';
import 'household_provider.dart';

const _boxName = 'shopping_lists';

final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  return Hive.box<ShoppingList>(_boxName);
});

final shoppingListsProvider =
    NotifierProvider<ShoppingListNotifier, List<ShoppingList>>(ShoppingListNotifier.new);

class ShoppingListNotifier extends Notifier<List<ShoppingList>> {
  late Box<ShoppingList> _box;

  @override
  List<ShoppingList> build() {
    _box = ref.watch(shoppingListBoxProvider);
    return _box.values.toList();
  }

  String? get _hid => ref.read(householdProvider);

  void _sync() => state = _box.values.toList();

  Future<void> add(ShoppingList l) async {
    await _box.put(l.id, l);
    _sync();
    final hid = _hid;
    if (hid != null) ref.read(firestoreServiceProvider).upsertList(hid, l).ignore();
  }

  Future<void> update(ShoppingList l) async {
    await _box.put(l.id, l);
    _sync();
    final hid = _hid;
    if (hid != null) ref.read(firestoreServiceProvider).upsertList(hid, l).ignore();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    _sync();
    final hid = _hid;
    if (hid != null) ref.read(firestoreServiceProvider).deleteList(hid, id).ignore();
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
    if (hid != null) ref.read(firestoreServiceProvider).upsertList(hid, updated).ignore();
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
    final svc = ref.read(firestoreServiceProvider);
    for (final l in state) {
      await svc.upsertList(hid, l);
    }
  }
}
