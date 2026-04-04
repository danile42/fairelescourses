import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:fairelescourses/providers/seed_color_provider.dart';

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

  group('SeedColorNotifier', () {
    test('returns defaultSeedColor when nothing is stored', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(seedColorProvider), equals(defaultSeedColor));
    });

    test('reads a stored hex color on build', () async {
      const color = Color(0xFF1A2B3C);
      await Hive.box<String>('settings').put('seedColor', '${color.value}');
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(seedColorProvider), equals(color));
    });

    test('set() updates state and persists to Hive', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      const color = Color(0xFFABCDEF);
      await c.read(seedColorProvider.notifier).set(color);
      expect(c.read(seedColorProvider), equals(color));
      expect(Hive.box<String>('settings').get('seedColor'), '${color.value}');
    });

    test('reset() restores defaultSeedColor and removes the key', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(seedColorProvider.notifier).set(Colors.red);
      await c.read(seedColorProvider.notifier).reset();
      expect(c.read(seedColorProvider), equals(defaultSeedColor));
      expect(Hive.box<String>('settings').get('seedColor'), isNull);
    });

    test('successive set() calls update state correctly', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(seedColorProvider.notifier).set(Colors.blue);
      await c.read(seedColorProvider.notifier).set(Colors.green);
      expect(c.read(seedColorProvider), equals(Colors.green));
    });
  });
}
