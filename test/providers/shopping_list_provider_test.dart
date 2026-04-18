import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/household_event.dart';
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
  when(
    () => mock.addHouseholdEvent(any(), any(), listId: any(named: 'listId')),
  ).thenAnswer((_) async {});

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

class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => 'hh-test';
}

ProviderContainer makeContainerWithHousehold(
  Box<ShoppingList> box,
  MockFirestoreService mock,
) => ProviderContainer(
  overrides: [
    shoppingListBoxProvider.overrideWithValue(box),
    householdProvider.overrideWith(() => _FakeHouseholdNotifier()),
    firestoreServiceProvider.overrideWithValue(mock),
  ],
);

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
    registerFallbackValue(HouseholdEventType.listUpdated);
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

    test(
      'syncFromRemote replaces local state with remote when not in household',
      () async {
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
      },
    );

    test('toggleItem with out-of-bounds index is a no-op', () async {
      final list = makeList('L1', ['Milk']);
      await box.put('L1', list);
      final container = makeContainer(box);
      addTearDown(container.dispose);
      // index 1 is beyond the single item at index 0
      await container.read(shoppingListsProvider.notifier).toggleItem('L1', 1);
      expect(
        container.read(shoppingListsProvider).first.items[0].checked,
        isFalse,
      );
    });

    test('toggleItem with negative index is a no-op', () async {
      final list = makeList('L1', ['Milk']);
      await box.put('L1', list);
      final container = makeContainer(box);
      addTearDown(container.dispose);
      await container.read(shoppingListsProvider.notifier).toggleItem('L1', -1);
      expect(
        container.read(shoppingListsProvider).first.items[0].checked,
        isFalse,
      );
    });
  });

  group('ShoppingListNotifier – syncFromRemote with household', () {
    test('preserves local-only lists instead of deleting them', () async {
      await box.put('local-only', makeList('local-only', ['Offline Item']));
      final mock = MockFirestoreService();
      when(() => mock.upsertList(any(), any())).thenAnswer((_) async {});
      when(() => mock.deleteList(any(), any())).thenAnswer((_) async {});
      when(
        () =>
            mock.addHouseholdEvent(any(), any(), listId: any(named: 'listId')),
      ).thenAnswer((_) async {});
      final container = makeContainerWithHousehold(box, mock);
      addTearDown(container.dispose);

      await container.read(shoppingListsProvider.notifier).syncFromRemote([
        makeList('remote-1', ['Remote Item']),
      ]);

      final all = container.read(shoppingListsProvider);
      expect(
        all.any((l) => l.id == 'local-only'),
        isTrue,
        reason: 'local-only list must be preserved',
      );
      expect(
        all.any((l) => l.id == 'remote-1'),
        isTrue,
        reason: 'remote list must be added',
      );
    });

    test('re-uploads local-only lists to Firestore', () async {
      await box.put('local-only', makeList('local-only', ['Offline Item']));
      final mock = MockFirestoreService();
      when(() => mock.upsertList(any(), any())).thenAnswer((_) async {});
      when(() => mock.deleteList(any(), any())).thenAnswer((_) async {});
      when(
        () =>
            mock.addHouseholdEvent(any(), any(), listId: any(named: 'listId')),
      ).thenAnswer((_) async {});
      final container = makeContainerWithHousehold(box, mock);
      addTearDown(container.dispose);

      await container.read(shoppingListsProvider.notifier).syncFromRemote([
        makeList('remote-1', ['Remote Item']),
      ]);

      // Pump the event queue so fire-and-forget upsertList futures resolve.
      await Future<void>.delayed(Duration.zero);

      verify(
        () => mock.upsertList('hh-test', any()),
      ).called(greaterThanOrEqualTo(1));
    });

    test('does not restore lists that are tombstoned in remote', () async {
      // Pre-populate a local copy of the list that was deleted on another device.
      await box.put('deleted-list', makeList('deleted-list', ['Item']));
      final mock = MockFirestoreService();
      when(() => mock.upsertList(any(), any())).thenAnswer((_) async {});
      when(() => mock.deleteList(any(), any())).thenAnswer((_) async {});
      when(
        () =>
            mock.addHouseholdEvent(any(), any(), listId: any(named: 'listId')),
      ).thenAnswer((_) async {});
      final container = makeContainerWithHousehold(box, mock);
      addTearDown(container.dispose);

      // Remote sends a tombstone (deleted: true) for 'deleted-list'.
      final tombstone = ShoppingList(
        id: 'deleted-list',
        name: '',
        preferredStoreIds: [],
        items: [],
        deleted: true,
      );
      await container.read(shoppingListsProvider.notifier).syncFromRemote([
        tombstone,
        makeList('remote-1', ['Remote Item']),
      ]);

      final all = container.read(shoppingListsProvider);
      expect(
        all.any((l) => l.id == 'deleted-list'),
        isFalse,
        reason: 'tombstoned list must be removed locally',
      );
      expect(
        all.any((l) => l.id == 'remote-1'),
        isTrue,
        reason: 'non-deleted remote lists must still be added',
      );
    });

    test('does not re-upload tombstoned lists', () async {
      final mock = MockFirestoreService();
      when(() => mock.upsertList(any(), any())).thenAnswer((_) async {});
      when(() => mock.deleteList(any(), any())).thenAnswer((_) async {});
      when(
        () =>
            mock.addHouseholdEvent(any(), any(), listId: any(named: 'listId')),
      ).thenAnswer((_) async {});
      final container = makeContainerWithHousehold(box, mock);
      addTearDown(container.dispose);

      // Remote sends only a tombstone – no local copy exists.
      final tombstone = ShoppingList(
        id: 'gone',
        name: '',
        preferredStoreIds: [],
        items: [],
        deleted: true,
      );
      await container.read(shoppingListsProvider.notifier).syncFromRemote([
        tombstone,
      ]);

      await Future<void>.delayed(Duration.zero);

      // upsertList must never be called for the tombstone.
      verifyNever(() => mock.upsertList('hh-test', any()));
    });

    test(
      'tombstone persists across multiple syncs without reappearing',
      () async {
        await box.put('deleted-list', makeList('deleted-list', ['Item']));
        final mock = MockFirestoreService();
        when(() => mock.upsertList(any(), any())).thenAnswer((_) async {});
        when(() => mock.deleteList(any(), any())).thenAnswer((_) async {});
        when(
          () => mock.addHouseholdEvent(
            any(),
            any(),
            listId: any(named: 'listId'),
          ),
        ).thenAnswer((_) async {});
        final container = makeContainerWithHousehold(box, mock);
        addTearDown(container.dispose);

        final tombstone = ShoppingList(
          id: 'deleted-list',
          name: '',
          preferredStoreIds: [],
          items: [],
          deleted: true,
        );

        // First sync removes the local copy.
        await container.read(shoppingListsProvider.notifier).syncFromRemote([
          tombstone,
        ]);
        // Second sync (tombstone still in remote) – should not re-add it.
        await container.read(shoppingListsProvider.notifier).syncFromRemote([
          tombstone,
        ]);

        final all = container.read(shoppingListsProvider);
        expect(
          all.any((l) => l.id == 'deleted-list'),
          isFalse,
          reason: 'tombstoned list must stay gone across multiple syncs',
        );
      },
    );
  });
}
