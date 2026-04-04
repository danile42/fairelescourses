import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/local_only_provider.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/services/firestore_service.dart';

import '../helpers/hive_helper.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class _NullHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => null;
}

class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => 'hh-test';
}

ProviderContainer _makeContainerWithHousehold() {
  final mock = MockFirestoreService();
  when(() => mock.upsertShop(any(), any())).thenAnswer((_) async {});
  when(() => mock.deleteShop(any(), any())).thenAnswer((_) async {});
  when(() => mock.upsertPublicCells(any())).thenAnswer((_) async {});
  return ProviderContainer(
    overrides: [
      householdProvider.overrideWith(() => _FakeHouseholdNotifier()),
      localOnlyProvider.overrideWith(() => _FalseLocalOnlyNotifier()),
      firestoreServiceProvider.overrideWithValue(mock),
      currentUidProvider.overrideWith((ref) => null),
      firestoreSyncProvider.overrideWith((ref) {}),
    ],
  );
}

class _FalseLocalOnlyNotifier extends LocalOnlyNotifier {
  @override
  bool build() => false;
}

class _TrueLocalOnlyNotifier extends LocalOnlyNotifier {
  @override
  bool build() => true;
}

Supermarket _store(String id, {int? osmId}) => Supermarket(
  id: id,
  name: 'Store $id',
  rows: ['A', 'B'],
  cols: ['1', '2'],
  entrance: 'A1',
  exit: 'B2',
  cells: {},
  osmId: osmId,
);

ProviderContainer _makeContainer({bool localOnly = false}) {
  final mock = MockFirestoreService();
  when(() => mock.upsertShop(any(), any())).thenAnswer((_) async {});
  when(() => mock.deleteShop(any(), any())).thenAnswer((_) async {});
  when(() => mock.upsertPublicCells(any())).thenAnswer((_) async {});
  return ProviderContainer(
    overrides: [
      householdProvider.overrideWith(() => _NullHouseholdNotifier()),
      localOnlyProvider.overrideWith(
        () => localOnly ? _TrueLocalOnlyNotifier() : _FalseLocalOnlyNotifier(),
      ),
      firestoreServiceProvider.overrideWithValue(mock),
      currentUidProvider.overrideWith((ref) => null),
      firestoreSyncProvider.overrideWith((ref) {}),
    ],
  );
}

MockFirestoreService _mockFrom(ProviderContainer c) =>
    c.read(firestoreServiceProvider) as MockFirestoreService;

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

    test('add with duplicate id replaces rather than appends', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('S1'));
      final updated = _store('S1')..name = 'Updated via add';
      await notifier.add(updated);

      final state = container.read(supermarketsProvider);
      expect(state.length, 1);
      expect(state.first.name, 'Updated via add');
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

  group('SupermarketNotifier – public cell sharing', () {
    test('add with osmId calls upsertPublicCells', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(supermarketsProvider.notifier)
          .add(_store('osm_1', osmId: 1));

      verify(() => _mockFrom(container).upsertPublicCells(any())).called(1);
    });

    test('update with osmId calls upsertPublicCells', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('osm_2', osmId: 2));
      clearInteractions(_mockFrom(container));

      await notifier.update(_store('osm_2', osmId: 2));

      verify(() => _mockFrom(container).upsertPublicCells(any())).called(1);
    });

    test('add without osmId does not call upsertPublicCells', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(supermarketsProvider.notifier)
          .add(_store('S1')); // no osmId

      verifyNever(() => _mockFrom(container).upsertPublicCells(any()));
    });

    test(
      'add with osmId in local-only mode does not call upsertPublicCells',
      () async {
        final container = _makeContainer(localOnly: true);
        addTearDown(container.dispose);

        await container
            .read(supermarketsProvider.notifier)
            .add(_store('osm_3', osmId: 3));

        verifyNever(() => _mockFrom(container).upsertPublicCells(any()));
      },
    );
  });

  group('SupermarketNotifier – syncFromRemote with household', () {
    test('preserves local-only shops instead of deleting them', () async {
      final container = _makeContainerWithHousehold();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('LocalShop'), syncToFirestore: false);
      clearInteractions(_mockFrom(container));

      await notifier.syncFromRemote([_store('RemoteShop')]);

      final state = container.read(supermarketsProvider);
      expect(
        state.any((s) => s.id == 'LocalShop'),
        isTrue,
        reason: 'local-only shop must be preserved',
      );
      expect(
        state.any((s) => s.id == 'RemoteShop'),
        isTrue,
        reason: 'remote shop must be added',
      );
    });

    test('re-uploads local-only shops to Firestore', () async {
      final container = _makeContainerWithHousehold();
      addTearDown(container.dispose);
      final notifier = container.read(supermarketsProvider.notifier);

      await notifier.add(_store('LocalShop'), syncToFirestore: false);
      clearInteractions(_mockFrom(container));

      await notifier.syncFromRemote([_store('RemoteShop')]);

      // Pump event queue so fire-and-forget upsertShop futures resolve.
      await Future<void>.delayed(Duration.zero);

      verify(
        () => _mockFrom(container).upsertShop('hh-test', any()),
      ).called(greaterThanOrEqualTo(1));
    });
  });

  group('SupermarketNotifier – syncToFirestore: false', () {
    test('add with syncToFirestore:false does not call upsertShop', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(supermarketsProvider.notifier)
          .add(_store('S1'), syncToFirestore: false);

      verifyNever(() => _mockFrom(container).upsertShop(any(), any()));
    });

    test(
      'add with osmId and syncToFirestore:false does not call upsertPublicCells',
      () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        await container
            .read(supermarketsProvider.notifier)
            .add(_store('osm_9', osmId: 9), syncToFirestore: false);

        verifyNever(() => _mockFrom(container).upsertPublicCells(any()));
      },
    );

    test('add with syncToFirestore:false still updates local state', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(supermarketsProvider.notifier)
          .add(_store('S1'), syncToFirestore: false);

      expect(container.read(supermarketsProvider).length, 1);
      expect(container.read(supermarketsProvider).first.id, 'S1');
    });
  });
}
