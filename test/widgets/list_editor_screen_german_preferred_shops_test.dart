import 'dart:io';

import 'package:fairelescourses/l10n/app_localizations.dart';
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
  bool build() => false;
}

class _FakeLocalOnlyNotifier extends LocalOnlyNotifier {
  @override
  bool build() => false;
}

class _FakeStoresNotifierWith extends SupermarketNotifier {
  _FakeStoresNotifierWith(this._stores);
  final List<Supermarket> _stores;

  @override
  List<Supermarket> build() => _stores;
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

  group('ListEditorScreen – German preferred shops and empty list', () {
    testWidgets('shows preferredShops and noItemsInList strings in German', (
      tester,
    ) async {
      final store = Supermarket(
        id: 's1',
        name: 'Rewe',
        rows: ['A'],
        cols: ['1'],
        entrance: 'A1',
        exit: 'A1',
        cells: {},
      );
      final mockSvc = MockFirestoreService();
      when(() => mockSvc.upsertList(any(), any())).thenAnswer((_) async {});
      when(() => mockSvc.deleteList(any(), any())).thenAnswer((_) async {});

      final emptyList = _list(items: []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => _NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(
              () => _FakeListsNotifier([emptyList]),
            ),
            supermarketsProvider.overrideWith(
              () => _FakeStoresNotifierWith([store]),
            ),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            navViewModeProvider.overrideWith(() => _FakeNavViewModeNotifier()),
            localOnlyProvider.overrideWith(() => _FakeLocalOnlyNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(mockSvc),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ListEditorScreen(list: emptyList, isNew: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Covers app_localizations_de.dart lines 179 and 182.
      expect(find.text('Bevorzugte Märkte (optional)'), findsOneWidget);
      expect(find.textContaining('Noch keine Artikel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
