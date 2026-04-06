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

  group('ListEditorScreen – German item popup menu', () {
    testWidgets('popup menu in German shows moveToList and rename', (
      tester,
    ) async {
      final list1 = _list(id: 'L1', name: 'Einkauf');
      final list2 = _list(id: 'L2', name: 'Hardware', items: []);
      final mockSvc = MockFirestoreService();
      when(() => mockSvc.upsertList(any(), any())).thenAnswer((_) async {});
      when(() => mockSvc.deleteList(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => _NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(
              () => _FakeListsNotifier([list1, list2]),
            ),
            supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
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
            home: ListEditorScreen(list: list1, isNew: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Covers app_localizations_de.dart lines 636 and 645.
      expect(find.text('In Liste verschieben'), findsOneWidget);
      expect(find.text('Umbenennen'), findsOneWidget);

      // Dismiss popup — ignore overflow errors from the menu rendering.
      tester.takeException();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });
  });
}
