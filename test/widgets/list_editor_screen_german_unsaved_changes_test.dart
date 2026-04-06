import 'dart:io';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/nav_session_provider.dart';
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

  group('ListEditorScreen – German unsaved changes dialog', () {
    testWidgets('unsaved changes dialog shows German strings', (tester) async {
      final mockSvc = MockFirestoreService();
      when(() => mockSvc.upsertList(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => _NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(
              () => _FakeListsNotifier([_list()]),
            ),
            supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(mockSvc),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ListEditorScreen(list: _list(), isNew: false),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Make a change to mark dirty.
      await tester.enterText(find.byType(TextField).last, 'Butter');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // In German locale the back button tooltip is 'Zurück', so pageBack() fails.
      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();

      // Covers app_localizations_de.dart lines 294, 297, 300.
      expect(find.text('Verwerfen'), findsOneWidget);
      expect(find.text('Weiter bearbeiten'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Verwerfen'));
      await tester.pumpAndSettle();
    });
  });
}
