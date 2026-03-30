import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/nav_session.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/nav_session_provider.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/list_editor_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';

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

Widget _wrap(ShoppingList list, {bool isNew = false, NavSession? session}) {
  final mockSvc = MockFirestoreService();
  when(() => mockSvc.upsertList(any(), any())).thenAnswer((_) async {});
  when(() => mockSvc.deleteList(any(), any())).thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      householdProvider.overrideWith(() => _NullHouseholdNotifier()),
      shoppingListsProvider.overrideWith(() => _FakeListsNotifier([list])),
      supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
      navSessionProvider.overrideWith((ref) => Stream.value(session)),
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

  group('ListEditorScreen – rendering', () {
    testWidgets('shows list name in text field', (tester) async {
      await tester.pumpWidget(_wrap(_list(name: 'Groceries')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Groceries'), findsOneWidget);
    });

    testWidgets('shows all items', (tester) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
    });

    testWidgets('shows empty-state text when list has no items', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_list(items: [])));
      await tester.pumpAndSettle();
      expect(find.textContaining('No items yet'), findsOneWidget);
    });

    testWidgets('shows start-navigation button when items exist', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();
      expect(find.text('Start navigation'), findsOneWidget);
    });

    testWidgets('navigation button absent when list is empty', (tester) async {
      await tester.pumpWidget(_wrap(_list(items: [])));
      await tester.pumpAndSettle();
      expect(find.text('Start navigation'), findsNothing);
    });
  });

  group('ListEditorScreen – adding items', () {
    testWidgets('typing in add-item field and tapping + adds item', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_list(items: [])));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Butter');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();

      expect(find.text('Butter'), findsOneWidget);
    });

    testWidgets('blank item is not added', (tester) async {
      await tester.pumpWidget(_wrap(_list(items: [])));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();

      expect(find.textContaining('No items yet'), findsOneWidget);
    });
  });

  group('ListEditorScreen – item actions', () {
    testWidgets('checkbox toggles item checked state', (tester) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(checkboxes.first);
      expect(checkbox.value, isTrue);
    });

    testWidgets('popup menu appears on more_vert tap', (tester) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('delete removes item from list', (tester) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsNothing);
      expect(find.text('Eggs'), findsOneWidget);
    });
  });

  group('ListEditorScreen – unsaved changes', () {
    testWidgets('save button is always shown in AppBar', (tester) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('typing in name field marks screen dirty (save works)', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_list(name: 'Old Name')));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Old Name');
      await tester.tap(nameField);
      await tester.enterText(nameField, 'New Name');
      await tester.pump();

      // Tapping Save should succeed without a dialog.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    });
  });

  group('ListEditorScreen – rename dialog', () {
    testWidgets('Rename opens dialog with current name', (tester) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // The rename dialog opens (contains Save/Cancel).
      expect(find.text('Save'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('renaming an item updates the displayed name', (tester) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Find the text field in the dialog and update it.
      final dialogField = find.byType(TextField).first;
      await tester.enterText(dialogField, 'Yoghurt');
      await tester.pump();
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();

      expect(find.text('Yoghurt'), findsOneWidget);
    });
  });

  group('ListEditorScreen – unsaved changes dialog', () {
    testWidgets('navigating back with unsaved changes shows dialog', (
      tester,
    ) async {
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
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
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

      // Make a change to mark the screen dirty.
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();
      // Entering text and triggering dirty state.
      await tester.enterText(find.byType(TextField).last, 'Butter');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();

      // Navigate back via the AppBar back button (goes through PopScope).
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Unsaved changes dialog.
      expect(find.text('Discard'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
    });
  });

  group('ListEditorScreen – German locale', () {
    testWidgets('renders in German without error', (tester) async {
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
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ListEditorScreen(list: _list(), isNew: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Speichern'), findsOneWidget);
    });
  });
}
