import 'dart:io';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/nav_session.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/local_only_provider.dart';
import 'package:fairelescourses/providers/nav_session_provider.dart';
import 'package:fairelescourses/providers/nav_view_mode_provider.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/home_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/hive_helper.dart';

// ── mocks ────────────────────────────────────────────────────────────────────

class MockFirestoreService extends Mock implements FirestoreService {}

class _NullHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => null;
}

class _FakeListsNotifier extends ShoppingListNotifier {
  _FakeListsNotifier(this._lists);
  final List<ShoppingList> _lists;

  @override
  List<ShoppingList> build() => _lists;

  @override
  Future<void> remove(String id) async {
    state = [
      for (final e in state)
        if (e.id != id) e,
    ];
  }

  @override
  Future<void> copy(String listId) async {}
}

class _FakeStoresNotifier extends SupermarketNotifier {
  @override
  List<Supermarket> build() => [];
}

class _FakeStoresNotifierWith extends SupermarketNotifier {
  _FakeStoresNotifierWith(this._stores);
  final List<Supermarket> _stores;

  @override
  List<Supermarket> build() => _stores;

  @override
  Future<void> remove(String id) async {
    state = [
      for (final s in state)
        if (s.id != id) s,
    ];
  }
}

class _FakeNavViewModeNotifier extends NavViewModeNotifier {
  @override
  bool build() => false; // no Hive access
}

class _FakeLocalOnlyNotifier extends LocalOnlyNotifier {
  @override
  bool build() => false; // no Hive access
}

// ── helpers ──────────────────────────────────────────────────────────────────

ShoppingList _list(String id, String name) => ShoppingList(
  id: id,
  name: name,
  preferredStoreIds: [],
  items: [ShoppingItem(name: 'Milk')],
);

Widget _wrap({
  required List<ShoppingList> lists,
  NavSession? session,
  List<Supermarket>? stores,
}) {
  final mockSvc = MockFirestoreService();
  when(() => mockSvc.deleteNavSession(any())).thenAnswer((_) async {});
  when(() => mockSvc.upsertList(any(), any())).thenAnswer((_) async {});
  when(() => mockSvc.deleteList(any(), any())).thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      householdProvider.overrideWith(() => _NullHouseholdNotifier()),
      shoppingListsProvider.overrideWith(() => _FakeListsNotifier(lists)),
      if (stores != null)
        supermarketsProvider.overrideWith(() => _FakeStoresNotifierWith(stores))
      else
        supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
      navSessionProvider.overrideWith((ref) => Stream.value(session)),
      navViewModeProvider.overrideWith(() => _FakeNavViewModeNotifier()),
      localOnlyProvider.overrideWith(() => _FakeLocalOnlyNotifier()),
      firestoreSyncProvider.overrideWith((ref) {}),
      currentUidProvider.overrideWith((ref) => null),
      firestoreServiceProvider.overrideWithValue(mockSvc),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    ),
  );
}

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
      await tester.pumpWidget(_wrap(lists: [_list('L1', 'Groceries')]));
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
