import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fairelescourses/providers/local_only_provider.dart';

import '../helpers/hive_helper.dart';

ProviderContainer _makeContainer() => ProviderContainer();

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

  group('LocalOnlyNotifier', () {
    test('defaults to false when no value stored', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      expect(container.read(localOnlyProvider), isFalse);
    });

    test('set(true) updates state to true', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(localOnlyProvider.notifier).set(true);

      expect(container.read(localOnlyProvider), isTrue);
    });

    test('set(false) updates state to false', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(localOnlyProvider.notifier).set(true);
      await container.read(localOnlyProvider.notifier).set(false);

      expect(container.read(localOnlyProvider), isFalse);
    });

    test('persists value to Hive', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(localOnlyProvider.notifier).set(true);

      // A new container reads from Hive and should see the persisted value.
      final container2 = _makeContainer();
      addTearDown(container2.dispose);
      expect(container2.read(localOnlyProvider), isTrue);
    });
  });
}
