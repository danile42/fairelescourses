import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_list.dart';
import 'firestore_sync_provider.dart';
import 'household_provider.dart';
import 'sync_error_provider.dart';

const _boxName = 'shopping_lists';
const _deletedListsBoxName = 'deleted_list_ids';

final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  return Hive.box<ShoppingList>(_boxName);
});

final deletedListIdsBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(_deletedListsBoxName);
});

final shoppingListsProvider =
    NotifierProvider<ShoppingListNotifier, List<ShoppingList>>(
      ShoppingListNotifier.new,
    );

class ShoppingListNotifier extends Notifier<List<ShoppingList>> {
  late Box<ShoppingList> _box;
  late Box<String> _deletedBox;

  @override
  List<ShoppingList> build() {
    _box = ref.watch(shoppingListBoxProvider);
    _deletedBox = ref.watch(deletedListIdsBoxProvider);
    return _box.values.toList();
  }

  String? get _hid => ref.read(householdProvider);

  void _sync() => state = _box.values.toList();

  Future<void> add(ShoppingList l) async {
    await _box.put(l.id, l);
    _sync();
    final hid = _hid;
    if (hid != null) {
      ref.read(firestoreServiceProvider).upsertList(hid, l).catchError((
        Object e,
      ) {
        debugPrint('Firestore upsertList error: $e');
        ref.read(syncErrorProvider.notifier).report(e.toString());
      }).ignore();
    }
  }

  Future<void> update(ShoppingList l) async {
    await _box.put(l.id, l);
    _sync();
    final hid = _hid;
    if (hid != null) {
      ref.read(firestoreServiceProvider).upsertList(hid, l).catchError((
        Object e,
      ) {
        debugPrint('Firestore upsertList error: $e');
        ref.read(syncErrorProvider.notifier).report(e.toString());
      }).ignore();
    }
  }

  Future<void> remove(String id) async {
    final hid = _hid;
    if (hid != null) {
      // Attempt to delete from Firestore first to ensure it's removed from the
      // remote state before deleting locally. This prevents syncFromRemote from
      // re-adding the list if Firestore still has it.
      try {
        await ref.read(firestoreServiceProvider).deleteList(hid, id);
      } catch (e) {
        debugPrint('Firestore deleteList error: $e');
        ref.read(syncErrorProvider.notifier).report(e.toString());
        rethrow;
      }
    }
    // Track the deletion in a separate store so syncFromRemote knows not to restore it.
    // This handles the case where deletion succeeds locally but Firestore push fails,
    // or where another user modifies the list between deletion and sync.
    await _deletedBox.put(id, id);
    // Only delete locally after confirming remote deletion (or if not in household)
    await _box.delete(id);
    _sync();
  }

  Future<void> toggleItem(String listId, int index) async {
    final list = _box.get(listId);
    if (list == null) return;
    final items = list.items.toList();
    if (index < 0 || index >= items.length) return;
    items[index] = items[index].copyWith(checked: !items[index].checked);
    final updated = list.copyWith(items: items);
    await _box.put(listId, updated);
    _sync();
    final hid = _hid;
    if (hid != null) {
      ref.read(firestoreServiceProvider).upsertList(hid, updated).ignore();
    }
  }

  /// Toggle a list item by name (case-insensitive). Used by collaborative navigation.
  Future<void> toggleItemByName(String listId, String name) async {
    final list = _box.get(listId);
    if (list == null) return;
    final idx = list.items.indexWhere(
      (i) => i.name.toLowerCase() == name.toLowerCase(),
    );
    if (idx < 0) return;
    await toggleItem(listId, idx);
  }

  /// Called by the Firestore sync listener. Merges remote state into Hive and memory.
  ///
  /// Local lists not present in the remote snapshot are re-uploaded rather than
  /// deleted, so a list created locally while offline (or whose initial upload
  /// failed) is not silently lost on the next sync event.
  ///
  /// However, lists that have been explicitly deleted by the user are NOT restored,
  /// even if they appear in the remote state. Tracked deletions are cleared after
  /// each sync to allow list recreation if the user explicitly adds them back.
  Future<void> syncFromRemote(List<ShoppingList> remote) async {
    final remoteIds = remote.map((l) => l.id).toSet();
    final deletedIds = _deletedBox.values.toSet();

    for (final l in remote) {
      // Don't restore deleted lists
      if (!deletedIds.contains(l.id)) {
        await _box.put(l.id, l);
      }
    }
    final hid = _hid;

    for (final key in _box.keys.toList()) {
      if (!remoteIds.contains(key)) {
        if (hid != null) {
          final local = _box.get(key as String);
          if (local != null) {
            // Re-upload local-only item instead of deleting it.
            ref
                .read(firestoreServiceProvider)
                .upsertList(hid, local)
                .catchError(
                  (Object e) =>
                      debugPrint('Firestore re-upload upsertList error: $e'),
                )
                .ignore();
          }
        } else {
          await _box.delete(key);
        }
      }
    }
    // Clear deletion tracking after sync completes to allow recreation if needed
    await _deletedBox.clear();
    _sync();
  }

  /// Merge [ids] into [targetId]: combine all items (deduplicated by name,
  /// unchecked wins), keep the target list's name and preferred stores,
  /// then delete all other selected lists.
  Future<void> merge(List<String> ids, String targetId) async {
    final selected = state.where((l) => ids.contains(l.id)).toList();
    final target = selected.firstWhere((l) => l.id == targetId);

    // Merge items; for duplicate names, unchecked wins.
    final merged = <String, ShoppingItem>{};
    for (final list in selected) {
      for (final item in list.items) {
        final key = item.name.toLowerCase();
        if (!merged.containsKey(key)) {
          merged[key] = item;
        } else if (!item.checked) {
          merged[key] = merged[key]!.copyWith(checked: false);
        }
      }
    }

    final mergedList = target.copyWith(items: merged.values.toList());
    await update(mergedList);
    for (final id in ids) {
      if (id != targetId) await remove(id);
    }
  }

  Future<void> copy(String listId) async {
    final list = _box.get(listId);
    if (list == null) return;
    final items = list.items.map((i) => i.copyWith(checked: false)).toList();
    final duplicate = ShoppingList(
      id: const Uuid().v4(),
      name: list.name,
      preferredStoreIds: list.preferredStoreIds,
      items: items,
    );
    await add(duplicate);
  }

  Future<void> uncheckAll(String listId) async {
    final list = _box.get(listId);
    if (list == null) return;
    final items = list.items.map((i) => i.copyWith(checked: false)).toList();
    final updated = list.copyWith(items: items);
    await _box.put(listId, updated);
    _sync();
    final hid = _hid;
    if (hid != null) {
      ref.read(firestoreServiceProvider).upsertList(hid, updated).ignore();
    }
  }

  /// Upload all local lists to Firestore (called when joining a household).
  Future<void> uploadAll(String hid) async {
    final svc = ref.read(firestoreServiceProvider);
    for (final l in state) {
      await svc.upsertList(hid, l);
    }
  }
}
