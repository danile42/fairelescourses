import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/services/firestore_service.dart';

import '../helpers/hive_helper.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class _NullHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => null;
}

Supermarket _store(String id) => Supermarket(
  id: id,
  name: 'Store $id',
  rows: ['A', 'B'],
  cols: ['1', '2'],
  entrance: 'A1',
  exit: 'B2',
  cells: {},
);

ProviderContainer _makeContainer() {
  final mock = MockFirestoreService();
  when(() => mock.upsertShop(any(), any())).thenAnswer((_) async {});
  when(() => mock.deleteShop(any(), any())).thenAnswer((_) async {});
  return ProviderContainer(
    overrides: [
      householdProvider.overrideWith(() => _NullHouseholdNotifier()),
      firestoreServiceProvider.overrideWithValue(mock),
      currentUidProvider.overrideWith((ref) => null),
      firestoreSyncProvider.overrideWith((ref) {}),
    ],
  );
}

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    registerFallbackValue(
      Supermarket(
        id: '',
        name: '',
        rows: [],
        cols: [],
        entrance: '',
        exit: '',
        cells: {},
      ),
    );
    hiveDir = await setUpHive();
  });

  tearDownAll(() async {
    await tearDownHive(hiveDir);
  });

  setUp(() async {
    await clearHive();
  });

  group('SupermarketNotifier', () {
    test('starts empty', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      expect(container.read(supermarketsProvider), isEmpty);
    });

    test('add puts store in state and box', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('S1'));

      final state = container.read(supermarketsProvider);
      expect(state.length, 1);
      expect(state.first.id, 'S1');
    });

    test('add multiple stores accumulates state', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('S1'));
      await notifier.add(_store('S2'));

      expect(container.read(supermarketsProvider).length, 2);
    });

    test('update replaces existing store by id', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('S1'));
      final updated = _store('S1')..name = 'Updated Store';
      await notifier.update(updated);

      final state = container.read(supermarketsProvider);
      expect(state.length, 1);
      expect(state.first.name, 'Updated Store');
    });

    test('remove deletes store from state', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('S1'));
      await notifier.add(_store('S2'));
      await notifier.remove('S1');

      final state = container.read(supermarketsProvider);
      expect(state.length, 1);
      expect(state.first.id, 'S2');
    });

    test('remove non-existent id is a no-op', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('S1'));
      await notifier.remove('NOPE');

      expect(container.read(supermarketsProvider).length, 1);
    });

    test('syncFromRemote replaces all state with remote list', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('Local'));
      await notifier.syncFromRemote([_store('Remote1'), _store('Remote2')]);

      final state = container.read(supermarketsProvider);
      expect(state.map((s) => s.id), containsAll(['Remote1', 'Remote2']));
      expect(state.any((s) => s.id == 'Local'), isFalse);
    });

    test('syncFromRemote with empty list clears all stores', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('S1'));
      await notifier.syncFromRemote([]);

      expect(container.read(supermarketsProvider), isEmpty);
    });
  });
}
