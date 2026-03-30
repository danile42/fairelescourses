import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fairelescourses/providers/nav_view_mode_provider.dart';

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

  group('NavViewModeNotifier', () {
    test('defaults to false (grid view) when no value stored', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      expect(container.read(navViewModeProvider), isFalse);
    });

    test('set(true) updates state to list view', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(navViewModeProvider.notifier).set(true);

      expect(container.read(navViewModeProvider), isTrue);
    });

    test('set(false) updates state to grid view', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(navViewModeProvider.notifier).set(true);
      await container.read(navViewModeProvider.notifier).set(false);

      expect(container.read(navViewModeProvider), isFalse);
    });

    test('persists list-view preference to Hive', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(navViewModeProvider.notifier).set(true);

      final container2 = _makeContainer();
      addTearDown(container2.dispose);
      expect(container2.read(navViewModeProvider), isTrue);
    });

    test('persists grid-view preference to Hive', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(navViewModeProvider.notifier).set(true);
      await container.read(navViewModeProvider.notifier).set(false);

      final container2 = _makeContainer();
      addTearDown(container2.dispose);
      expect(container2.read(navViewModeProvider), isFalse);
    });
  });
}
