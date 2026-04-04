import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:fairelescourses/providers/tour_provider.dart';

import '../helpers/hive_helper.dart';

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

  group('TourStepNotifier', () {
    test('starts at 0 when tour has not been seen', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(tourStepProvider), 0);
    });

    test('starts at -1 when tour has already been seen', () async {
      await Hive.box<String>('settings').put(tourIntroKey, 'true');
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(tourStepProvider), -1);
    });

    test('advance() increments from the matching step', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(tourStepProvider.notifier).advance(0);
      expect(c.read(tourStepProvider), 1);
    });

    test('advance() is a no-op when called with the wrong step', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(tourStepProvider.notifier).advance(1); // state is 0
      expect(c.read(tourStepProvider), 0);
    });

    test('advance() chains correctly: 0 → 1 → 2', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(tourStepProvider.notifier).advance(0);
      c.read(tourStepProvider.notifier).advance(1);
      expect(c.read(tourStepProvider), 2);
    });

    test('complete() sets state to -1 and persists to Hive', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(tourStepProvider.notifier).complete();
      expect(c.read(tourStepProvider), -1);
      expect(Hive.box<String>('settings').get(tourIntroKey), 'true');
    });

    test('advance() after complete() does nothing', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(tourStepProvider.notifier).complete();
      c.read(tourStepProvider.notifier).advance(0);
      expect(c.read(tourStepProvider), -1);
    });
  });

  group('TourFabExpandedNotifier', () {
    test('initial value is false', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(tourFabExpandedProvider), false);
    });

    test('set(true) updates state', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(tourFabExpandedProvider.notifier).set(true);
      expect(c.read(tourFabExpandedProvider), true);
    });

    test('set(false) reverts state', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(tourFabExpandedProvider.notifier).set(true);
      c.read(tourFabExpandedProvider.notifier).set(false);
      expect(c.read(tourFabExpandedProvider), false);
    });
  });

  group('celebrationTriggerProvider', () {
    test('initial value is 0', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(celebrationTriggerProvider), 0);
    });

    test('trigger() increments', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(celebrationTriggerProvider.notifier).trigger();
      expect(c.read(celebrationTriggerProvider), 1);
    });

    test('trigger() can be called multiple times', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(celebrationTriggerProvider.notifier).trigger();
      c.read(celebrationTriggerProvider.notifier).trigger();
      c.read(celebrationTriggerProvider.notifier).trigger();
      expect(c.read(celebrationTriggerProvider), 3);
    });
  });
}
