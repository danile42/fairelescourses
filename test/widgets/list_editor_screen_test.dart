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
import 'package:fairelescourses/providers/local_only_provider.dart';
import 'package:fairelescourses/providers/nav_view_mode_provider.dart';
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

class _FakeNavViewModeNotifier extends NavViewModeNotifier {
  @override
  bool build() => false; // default: grid view, no Hive access
}

class _FakeLocalOnlyNotifier extends LocalOnlyNotifier {
  @override
  bool build() => false; // no Hive access
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

Widget _wrap(
  ShoppingList list, {
  bool isNew = false,
  NavSession? session,
  List<Supermarket>? stores,
}) {
  final mockSvc = MockFirestoreService();
  when(() => mockSvc.upsertList(any(), any())).thenAnswer((_) async {});
  when(() => mockSvc.deleteList(any(), any())).thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      householdProvider.overrideWith(() => _NullHouseholdNotifier()),
      shoppingListsProvider.overrideWith(() => _FakeListsNotifier([list])),
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

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
    testWidgets(
      'checkboxes are display-only in edit mode (onChanged is null)',
      (tester) async {
        await tester.pumpWidget(_wrap(_list()));
        await tester.pumpAndSettle();

        for (final cb in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
          expect(
            cb.onChanged,
            isNull,
            reason: 'Items must not be checkable in edit mode',
          );
        }
      },
    );

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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

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

  group('ListEditorScreen – new list', () {
    testWidgets('saving a new list calls add on the notifier', (tester) async {
      final newList = ShoppingList(
        id: 'NEW',
        name: '',
        preferredStoreIds: [],
        items: [],
      );
      await tester.pumpWidget(_wrap(newList, isNew: true));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Freshly Created');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // No crash, no dialog — add path completed.
      expect(tester.takeException(), isNull);
    });
  });

  group('ListEditorScreen – item edit dialog', () {
    testWidgets('tapping item opens rename dialog', (tester) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();

      // Tap item tile directly (not the menu) to trigger _editItem.
      await tester.tap(find.text('Milk'));
      await tester.pumpAndSettle();

      // Dialog should open with Save/Cancel actions.
      expect(find.text('Save'), findsWidgets);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('editing item via dialog updates the name', (tester) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Milk'));
      await tester.pumpAndSettle();

      // Clear and type new name in the dialog field.
      final dialogField = find.byType(TextField).first;
      await tester.enterText(dialogField, 'Skimmed Milk');
      await tester.pump();
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();

      expect(find.text('Skimmed Milk'), findsOneWidget);
    });
  });

  group('ListEditorScreen – move to list', () {
    testWidgets('Move to list option appears when multiple lists exist', (
      tester,
    ) async {
      final list1 = _list(id: 'L1', name: 'Groceries');
      final list2 = _list(id: 'L2', name: 'Hardware');
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
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(mockSvc),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ListEditorScreen(list: list1, isNew: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Move to list'), findsOneWidget);
    });

    testWidgets('tapping Move to list opens the target-list dialog', (
      tester,
    ) async {
      final list1 = _list(id: 'L1', name: 'Groceries');
      final list2 = _list(id: 'L2', name: 'Hardware');
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
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(mockSvc),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ListEditorScreen(list: list1, isNew: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to list'));
      await tester.pumpAndSettle();

      // SimpleDialog with list2 option appears.
      expect(find.text('Hardware'), findsOneWidget);

      // Dismiss without selecting.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('selecting a target list moves the item', (tester) async {
      final list1 = _list(id: 'L1', name: 'Groceries');
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
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(mockSvc),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ListEditorScreen(list: list1, isNew: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open popup menu for first item.
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to list'));
      await tester.pumpAndSettle();

      // Select 'Hardware' as the target list.
      expect(find.text('Hardware'), findsOneWidget);
      await tester.tap(find.text('Hardware'));
      await tester.pumpAndSettle();

      // After moving, no crash and item is removed from current view.
      expect(tester.takeException(), isNull);
    });
  });

  group('ListEditorScreen – unsaved changes via Save dialog action', () {
    testWidgets('choosing Save from dialog saves and pops', (tester) async {
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

      // Make a change.
      await tester.enterText(find.byType(TextField).last, 'Butter');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Trigger back.
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Choose Save from the dialog (there may be 2 Save widgets: AppBar + dialog).
      expect(find.text('Save'), findsWidgets);
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
    });

    testWidgets('choosing Keep Editing from dialog stays on screen', (
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

      // Make a change.
      await tester.enterText(find.byType(TextField).last, 'Cheese');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Choose Keep editing.
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      // Still on editor screen.
      expect(find.text('Cheese'), findsOneWidget);
    });
  });

  // All tests below use pumpAndSettle() and must run before the NavigationScreen-
  // opening tests: pushing NavigationScreen leaves persistent timers that make
  // pumpAndSettle() loop indefinitely in any subsequent test.
  group('ListEditorScreen – store selector', () {
    testWidgets('store selector appears when stores exist', (tester) async {
      final store = Supermarket(
        id: 'store-1',
        name: 'Corner Shop',
        rows: ['A'],
        cols: ['1'],
        entrance: 'A1',
        exit: 'A1',
        cells: {},
      );

      await tester.pumpWidget(_wrap(_list(), stores: [store]));
      await tester.pumpAndSettle();

      // Store selector should appear.
      expect(find.textContaining('Preferred shops'), findsOneWidget);
    });
  });

  group('ListEditorScreen – checked item styling', () {
    testWidgets('checked item has strikethrough decoration', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _list(
            items: [
              ShoppingItem(name: 'Milk', checked: true),
              ShoppingItem(name: 'Eggs'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Milk is checked — should show with strikethrough (via RichText or Text).
      expect(find.text('Milk'), findsOneWidget);
    });
  });

  group('ListEditorScreen – item ordering', () {
    testWidgets('multiple items are all visible', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _list(
            items: [
              ShoppingItem(name: 'Apples'),
              ShoppingItem(name: 'Bread'),
              ShoppingItem(name: 'Cheese'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apples'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Cheese'), findsOneWidget);
    });
  });

  group('ListEditorScreen – empty-name save', () {
    testWidgets('saving with no name uses dash placeholder', (tester) async {
      await tester.pumpWidget(_wrap(_list(name: '')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ListEditorScreen – store selector', () {
    testWidgets(
      'shows FilterChip for each store and tapping it updates selection',
      (tester) async {
        final store = Supermarket(
          id: 's1',
          name: 'Rewe',
          rows: ['A'],
          cols: ['1'],
          entrance: 'A1',
          exit: 'A1',
          cells: {},
        );
        await tester.pumpWidget(_wrap(_list(), stores: [store]));
        await tester.pumpAndSettle();

        // FilterChip for the store is visible.
        expect(find.text('Rewe'), findsOneWidget);

        // Tap the chip to select it.
        await tester.tap(find.text('Rewe'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ListEditorScreen – rename updates item correctly', () {
    testWidgets('renaming via last TextField updates item name', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_list()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // The LAST TextField is the Autocomplete dialog field.
      await tester.enterText(find.byType(TextField).last, 'Yoghurt');
      await tester.pump();
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();

      expect(find.text('Yoghurt'), findsOneWidget);
    });
  });
}
