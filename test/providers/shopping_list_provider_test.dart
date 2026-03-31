import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/services/firestore_service.dart';

import '../helpers/hive_helper.dart';

// ── mocks ────────────────────────────────────────────────────────────────────

class MockFirestoreService extends Mock implements FirestoreService {}

// ── helpers ──────────────────────────────────────────────────────────────────

ProviderContainer makeContainer(Box<ShoppingList> box) {
  final mock = MockFirestoreService();
  // Stub out any Firestore calls so they silently succeed.
  when(() => mock.upsertList(any(), any())).thenAnswer((_) async {});
  when(() => mock.deleteList(any(), any())).thenAnswer((_) async {});

  return ProviderContainer(
    overrides: [
      shoppingListBoxProvider.overrideWithValue(box),
      // No household → Firestore calls are skipped by the notifier itself.
      householdProvider.overrideWith(() => _NullHouseholdNotifier()),
      firestoreServiceProvider.overrideWithValue(mock),
    ],
  );
}

class _NullHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => null;
}

ShoppingList makeList(String id, List<String> itemNames) => ShoppingList(
  id: id,
  name: 'List $id',
  preferredStoreIds: [],
  items: itemNames.map((n) => ShoppingItem(name: n)).toList(),
);

// ── tests ────────────────────────────────────────────────────────────────────

void main() {
  late Directory hiveDir;
  late Box<ShoppingList> box;

  setUpAll(() async {
    registerFallbackValue(
      ShoppingList(id: '', name: '', preferredStoreIds: [], items: []),
    );
    hiveDir = await setUpHive();
  });

  tearDownAll(() async {
    await tearDownHive(hiveDir);
  });

  setUp(() async {
    await clearHive();
    box = Hive.box<ShoppingList>('shopping_lists');
  });

  group('ShoppingListNotifier', () {
    test('initial state reflects box contents', () async {
      await box.put('L1', makeList('L1', ['Milk']));
      final container = makeContainer(box);
      addTearDown(container.dispose);
      expect(container.read(shoppingListsProvider).length, 1);
    });

    test('add puts list in state', () async {
      final container = makeContainer(box);
      addTearDown(container.dispose);
      await container
          .read(shoppingListsProvider.notifier)
          .add(makeList('L1', ['Milk']));
      expect(container.read(shoppingListsProvider).length, 1);
      expect(container.read(shoppingListsProvider).first.id, 'L1');
    });

    test('remove deletes list from state', () async {
      await box.put('L1', makeList('L1', ['Milk']));
      final container = makeContainer(box);
      addTearDown(container.dispose);
      await container.read(shoppingListsProvider.notifier).remove('L1');
      expect(container.read(shoppingListsProvider), isEmpty);
    });

    test('update replaces list in state', () async {
      final original = makeList('L1', ['Milk']);
      await box.put('L1', original);
      final container = makeContainer(box);
      addTearDown(container.dispose);
      final updated = original.copyWith(name: 'Renamed');
      await container.read(shoppingListsProvider.notifier).update(updated);
      expect(container.read(shoppingListsProvider).first.name, 'Renamed');
    });

    test('toggleItem flips checked state', () async {
      final list = makeList('L1', ['Milk', 'Bread']);
      await box.put('L1', list);
      final container = makeContainer(box);
      addTearDown(container.dispose);
      await container.read(shoppingListsProvider.notifier).toggleItem('L1', 0);
      final state = container.read(shoppingListsProvider);
      expect(state.first.items[0].checked, isTrue);
      expect(state.first.items[1].checked, isFalse);
    });

    test('toggleItem twice restores original state', () async {
      final list = makeList('L1', ['Milk']);
      await box.put('L1', list);
      final container = makeContainer(box);
      addTearDown(container.dispose);
      final notifier = container.read(shoppingListsProvider.notifier);
      await notifier.toggleItem('L1', 0);
      await notifier.toggleItem('L1', 0);
      expect(
        container.read(shoppingListsProvider).first.items[0].checked,
        isFalse,
      );
    });

    test('toggleItemByName is case-insensitive', () async {
      final list = makeList('L1', ['Whole Milk']);
      await box.put('L1', list);
      final container = makeContainer(box);
      addTearDown(container.dispose);
      await container
          .read(shoppingListsProvider.notifier)
          .toggleItemByName('L1', 'whole milk');
      expect(
        container.read(shoppingListsProvider).first.items[0].checked,
        isTrue,
      );
    });

    test('toggleItemByName with unknown name does nothing', () async {
      final list = makeList('L1', ['Milk']);
      await box.put('L1', list);
      final container = makeContainer(box);
      addTearDown(container.dispose);
      await container
          .read(shoppingListsProvider.notifier)
          .toggleItemByName('L1', 'Fish');
      expect(
        container.read(shoppingListsProvider).first.items[0].checked,
        isFalse,
      );
    });

    test('uncheckAll unchecks every item', () async {
      final list = ShoppingList(
        id: 'L1',
        name: 'Test',
        preferredStoreIds: [],
        items: [
          ShoppingItem(name: 'Milk', checked: true),
          ShoppingItem(name: 'Bread', checked: true),
        ],
      );
      await box.put('L1', list);
      final container = makeContainer(box);
      addTearDown(container.dispose);
      await container.read(shoppingListsProvider.notifier).uncheckAll('L1');
      final items = container.read(shoppingListsProvider).first.items;
      expect(items.every((i) => !i.checked), isTrue);
    });

    test(
      'copy creates new list with same name and all items unchecked',
      () async {
        final list = ShoppingList(
          id: 'L1',
          name: 'Original',
          preferredStoreIds: ['s1'],
          items: [
            ShoppingItem(name: 'Milk', checked: true),
            ShoppingItem(name: 'Bread'),
          ],
        );
        await box.put('L1', list);
        final container = makeContainer(box);
        addTearDown(container.dispose);
        await container.read(shoppingListsProvider.notifier).copy('L1');
        final all = container.read(shoppingListsProvider);
        expect(all.length, 2);
        final copy = all.firstWhere((l) => l.id != 'L1');
        expect(copy.name, 'Original');
        expect(copy.preferredStoreIds, ['s1']);
        expect(copy.items.every((i) => !i.checked), isTrue);
        expect(copy.id, isNot('L1'));
      },
    );

    test('merge combines items and removes other lists', () async {
      final l1 = ShoppingList(
        id: 'L1',
        name: 'Target',
        preferredStoreIds: [],
        items: [ShoppingItem(name: 'Milk', checked: true)],
      );
      final l2 = ShoppingList(
        id: 'L2',
        name: 'Source',
        preferredStoreIds: [],
        items: [
          ShoppingItem(name: 'Milk'), // duplicate, unchecked wins
          ShoppingItem(name: 'Bread'),
        ],
      );
      await box.put('L1', l1);
      await box.put('L2', l2);
      final container = makeContainer(box);
      addTearDown(container.dispose);
      await container.read(shoppingListsProvider.notifier).merge([
        'L1',
        'L2',
      ], 'L1');
      final all = container.read(shoppingListsProvider);
      expect(all.length, 1);
      expect(all.first.id, 'L1');
      final milkItem = all.first.items.firstWhere(
        (i) => i.name.toLowerCase() == 'milk',
      );
      expect(milkItem.checked, isFalse); // unchecked wins
      expect(all.first.items.any((i) => i.name == 'Bread'), isTrue);
    });

    test('syncFromRemote replaces local state with remote', () async {
      await box.put('local-only', makeList('local-only', ['Old']));
      final container = makeContainer(box);
      addTearDown(container.dispose);
      final remote = [
        makeList('remote-1', ['New']),
      ];
      await container
          .read(shoppingListsProvider.notifier)
          .syncFromRemote(remote);
      final all = container.read(shoppingListsProvider);
      expect(all.length, 1);
      expect(all.first.id, 'remote-1');
    });
  });
}
