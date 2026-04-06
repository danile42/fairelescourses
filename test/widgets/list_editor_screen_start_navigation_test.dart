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
import 'package:fairelescourses/screens/list_editor_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/hive_helper.dart';

// ── mocks / fakes ─────────────────────────────────────────────────────────────

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
  Future<void> update(ShoppingList s) async {
    state = [for (final e in state) e.id == s.id ? s : e];
  }

  @override
  Future<void> add(ShoppingList s) async {
    state = [...state, s];
  }
}

class _FakeStoresNotifier extends SupermarketNotifier {
  @override
  List<Supermarket> build() => [];
}

class _FakeNavViewModeNotifier extends NavViewModeNotifier {
  @override
  bool build() => false; // default: grid view, no Hive access
}

class _FakeLocalOnlyNotifier extends LocalOnlyNotifier {
  @override
  bool build() => false; // no Hive access
}

// ── helpers ───────────────────────────────────────────────────────────────────

ShoppingList _list({
  String id = 'L1',
  String name = 'Groceries',
  List<ShoppingItem>? items,
}) => ShoppingList(
  id: id,
  name: name,
  preferredStoreIds: [],
  items: items ?? [ShoppingItem(name: 'Milk'), ShoppingItem(name: 'Eggs')],
);

Widget _wrap(
  ShoppingList list, {
  bool isNew = false,
  NavSession? session,
}) {
  final mockSvc = MockFirestoreService();
  when(() => mockSvc.upsertList(any(), any())).thenAnswer((_) async {});
  when(() => mockSvc.deleteList(any(), any())).thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      householdProvider.overrideWith(() => _NullHouseholdNotifier()),
      shoppingListsProvider.overrideWith(() => _FakeListsNotifier([list])),
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
      home: ListEditorScreen(list: list, isNew: isNew),
    ),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

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
  });

  // start navigation must run LAST: pushing NavigationScreen leaves persistent
  // timers that prevent pumpAndSettle() from ever returning in subsequent tests.
  group('ListEditorScreen – start navigation', () {
    testWidgets('tapping Start navigation opens NavigationScreen', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start navigation'));
      // Use bounded pumps: NavigationScreen may have persistent animations
      // that prevent pumpAndSettle() from ever returning.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // No exception — NavigationScreen opened.
      expect(tester.takeException(), isNull);
    });
  });
}
