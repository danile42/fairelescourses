import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fairelescourses/providers/home_location_provider.dart';

import '../helpers/hive_helper.dart';

ProviderContainer makeContainer() =>
    ProviderContainer();

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await setUpHive();
  });

  tearDownAll(() async {
    await tearDownHive(hiveDir);
  });

  setUp(() async {
    await clearHive();
  });

  group('HomeLocationNotifier', () {
    test('initial state is null when settings box is empty', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      expect(container.read(homeLocationProvider), isNull);
    });

    test('set stores location in state', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container
          .read(homeLocationProvider.notifier)
          .set('Berlin', 52.52, 13.40);
      final loc = container.read(homeLocationProvider);
      expect(loc, isNotNull);
      expect(loc!.address, 'Berlin');
      expect(loc.lat, closeTo(52.52, 1e-6));
      expect(loc.lng, closeTo(13.40, 1e-6));
    });

    test('clear resets state to null', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container
          .read(homeLocationProvider.notifier)
          .set('Berlin', 52.52, 13.40);
      await container.read(homeLocationProvider.notifier).clear();
      expect(container.read(homeLocationProvider), isNull);
    });

    test('set then new container reads persisted value', () async {
      final container1 = makeContainer();
      await container1
          .read(homeLocationProvider.notifier)
          .set('Munich', 48.14, 11.58);
      container1.dispose();

      // A new container reading the same Hive box sees the value.
      final container2 = makeContainer();
      addTearDown(container2.dispose);
      final loc = container2.read(homeLocationProvider);
      expect(loc?.address, 'Munich');
      expect(loc?.lat, closeTo(48.14, 1e-6));
    });

    test('clear then new container reads null', () async {
      final container1 = makeContainer();
      await container1
          .read(homeLocationProvider.notifier)
          .set('Paris', 48.85, 2.35);
      await container1.read(homeLocationProvider.notifier).clear();
      container1.dispose();

      final container2 = makeContainer();
      addTearDown(container2.dispose);
      expect(container2.read(homeLocationProvider), isNull);
    });
  });
}
