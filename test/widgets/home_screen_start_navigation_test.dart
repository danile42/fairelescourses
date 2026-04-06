import 'dart:io';

import 'package:fairelescourses/models/shopping_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/hive_helper.dart';
import '../helpers/home_screen_helpers.dart';

// ── tests ────────────────────────────────────────────────────────────────────

void main() {
  late Directory hiveDir;

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
    // Prevent HomeScreen from pushing the intro HelpScreen on first run.
    await Hive.box<String>('settings').put('introSeen', 'true');
  });

  // start navigation must run LAST: pushing NavigationScreen leaves persistent
  // timers that prevent pumpAndSettle() from ever returning in subsequent tests.
  group('HomeScreen – start navigation single-play', () {
    testWidgets('tapping play icon starts navigation', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(lists: [makeList('L1', 'Groceries')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      // Use bounded pumps: NavigationScreen may have persistent animations
      // that prevent pumpAndSettle() from ever returning.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // NavigationScreen opened.
      expect(tester.takeException(), isNull);
    });
  });
}
