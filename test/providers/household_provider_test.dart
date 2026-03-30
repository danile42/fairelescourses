import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fairelescourses/providers/household_provider.dart';

import '../helpers/hive_helper.dart';

ProviderContainer makeContainer() => ProviderContainer();

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

  group('HouseholdNotifier', () {
    test('initial state is null when settings box is empty', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      expect(c.read(householdProvider), isNull);
    });

    test('setId updates state', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(householdProvider.notifier).setId('ABC123');
      expect(c.read(householdProvider), 'ABC123');
    });

    test('setId normalizes to uppercase', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(householdProvider.notifier).setId('abc123');
      expect(c.read(householdProvider), 'ABC123');
    });

    test('clear resets state to null', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(householdProvider.notifier).setId('XYZ999');
      await c.read(householdProvider.notifier).clear();
      expect(c.read(householdProvider), isNull);
    });

    test('setId persists across containers', () async {
      final c1 = makeContainer();
      await c1.read(householdProvider.notifier).setId('PER123');
      c1.dispose();

      final c2 = makeContainer();
      addTearDown(c2.dispose);
      expect(c2.read(householdProvider), 'PER123');
    });

    test('generateId returns 6-character alphanumeric string', () {
      final id = HouseholdNotifier.generateId();
      expect(id.length, 6);
      expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(id), isTrue);
    });
  });
}
