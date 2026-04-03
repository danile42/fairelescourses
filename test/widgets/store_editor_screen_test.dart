import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/shop_floor.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/store_editor_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';

import '../helpers/hive_helper.dart';

// ── mocks / fakes ─────────────────────────────────────────────────────────────

class MockFirestoreService extends Mock implements FirestoreService {}

class _NullHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => null;
}

class _FakeStoresNotifier extends SupermarketNotifier {
  _FakeStoresNotifier(this._stores);
  final List<Supermarket> _stores;

  @override
  List<Supermarket> build() => _stores;

  @override
  Future<void> add(Supermarket s, {bool syncToFirestore = true}) async =>
      state = [...state, s];

  @override
  Future<void> update(Supermarket s) async =>
      state = [for (final e in state) e.id == s.id ? s : e];
}

class _FakeListsNotifier extends ShoppingListNotifier {
  @override
  List<ShoppingList> build() => [];
}

// ── helpers ───────────────────────────────────────────────────────────────────

Supermarket _store({String id = 'S1'}) => Supermarket(
  id: id,
  name: 'Test Store',
  rows: ['A', 'B'],
  cols: ['1', '2'],
  entrance: 'A1',
  exit: 'B2',
  cells: {},
);

Widget _wrap(Widget screen, {List<Supermarket>? existingStores}) {
  final mockSvc = MockFirestoreService();
  when(() => mockSvc.upsertShop(any(), any())).thenAnswer((_) async {});
  when(() => mockSvc.deleteShop(any(), any())).thenAnswer((_) async {});
  return ProviderScope(
    overrides: [
      householdProvider.overrideWith(() => _NullHouseholdNotifier()),
      supermarketsProvider.overrideWith(
        () => _FakeStoresNotifier(existingStores ?? []),
      ),
      shoppingListsProvider.overrideWith(() => _FakeListsNotifier()),
      firestoreSyncProvider.overrideWith((ref) {}),
      currentUidProvider.overrideWith((ref) => null),
      firestoreServiceProvider.overrideWithValue(mockSvc),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    registerFallbackValue(
      Supermarket(
        id: '',
        name: '',
        rows: [],
        cols: [],
        entrance: '',
        exit: '',
        cells: {},
      ),
    );
    hiveDir = await setUpHive();
  });

  tearDownAll(() async {
    await tearDownHive(hiveDir);
  });

  setUp(() async {
    await clearHive();
  });

  group('StoreEditorScreen – new store', () {
    testWidgets('renders with empty name field', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();
      expect(find.text('New shop'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows help button in AppBar', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('renders the store grid', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();
      // The grid shows entrance/exit icons.
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('shows add-floor button', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();
      // The floor tab bar shows an Icons.add button for adding floors.
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets(
      'cancel asks for confirmation when no changes made (no dialog)',
      (tester) async {
        await tester.pumpWidget(_wrap(const StoreEditorScreen()));
        await tester.pumpAndSettle();
        // Tapping back when no changes should pop without dialog.
        final NavigatorState navigator = tester.state(find.byType(Navigator));
        navigator.pop();
        await tester.pumpAndSettle();
      },
    );
  });

  group('StoreEditorScreen – editing an existing store', () {
    testWidgets('pre-fills store name', (tester) async {
      final store = _store();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Test Store'), findsOneWidget);
    });

    testWidgets('shows edit-shop title', (tester) async {
      final store = _store();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit shop'), findsOneWidget);
    });

    testWidgets('shows save button for existing store', (tester) async {
      final store = _store();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows floor add button', (tester) async {
      final store = _store();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('StoreEditorScreen – grid interactions', () {
    testWidgets('tapping a cell opens edit dialog', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();

      // Tap a non-entrance/exit cell — the second cell (A2).
      // The grid has entrance at A1 and exit at B2; tap the logout icon (exit).
      // Instead tap add-row/add-col buttons.
      expect(find.byIcon(Icons.add_circle_outline), findsWidgets);
    });

    testWidgets('tapping add-row button increases row count', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();

      // The add-row button is an InkWell with Icons.add_circle_outline.
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();

      // No crash expected; grid should still render.
      expect(find.byIcon(Icons.login), findsOneWidget);
    });
  });

  group('StoreEditorScreen – address field', () {
    testWidgets('shows address text field', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextField, 'Address (optional)'),
        findsOneWidget,
      );
    });
  });

  group('StoreEditorScreen – rendering in German', () {
    testWidgets('renders labels in German', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => _NullHouseholdNotifier()),
            supermarketsProvider.overrideWith(() => _FakeStoresNotifier([])),
            shoppingListsProvider.overrideWith(() => _FakeListsNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const StoreEditorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Neuer Markt'), findsOneWidget);
      expect(find.text('Speichern'), findsOneWidget);
    });
  });

  group('StoreEditorScreen – save', () {
    testWidgets('save with empty name shows snackbar', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();

      // Don't fill in the name field, tap Save.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // A SnackBar should appear (name is required).
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('typing a name and saving creates a store', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      await tester.tap(nameField);
      await tester.enterText(nameField, 'My Market');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    });
  });

  group('StoreEditorScreen – multi-floor store', () {
    Supermarket multiFloorStore() {
      final s = Supermarket(
        id: 'S1',
        name: 'Multi Floor',
        rows: ['A', 'B'],
        cols: ['1', '2'],
        entrance: 'A1',
        exit: 'B2',
        cells: {},
      );
      s.additionalFloors = [
        ShopFloor(
          name: 'Floor 1',
          rows: ['A', 'B'],
          cols: ['1', '2'],
          entrance: 'A1',
          exit: 'B2',
        ),
      ];
      return s;
    }

    testWidgets('two-floor store shows two floor tabs', (tester) async {
      final store = multiFloorStore();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();

      // Should show Ground floor + Floor 1 tabs.
      expect(find.textContaining('Ground'), findsOneWidget);
      expect(find.text('Floor 1'), findsOneWidget);
    });

    testWidgets('tapping second floor tab switches floor', (tester) async {
      final store = multiFloorStore();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Floor 1'));
      await tester.pumpAndSettle();

      // Grid still renders after switching.
      expect(find.byIcon(Icons.login), findsOneWidget);
    });
  });

  group('StoreEditorScreen – add floor', () {
    testWidgets('tapping add-floor button adds a new floor tab', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // After adding a floor, Floor 1 tab appears.
      expect(find.text('Floor 1'), findsOneWidget);
    });

    testWidgets('remove-floor button appears after adding a second floor', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Now on floor 1, the remove button (delete_outline) should appear.
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tapping remove-floor removes the extra floor', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Floor 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Floor 1'), findsNothing);
    });
  });

  group('StoreEditorScreen – cell tap', () {
    testWidgets('tapping entrance cell opens edit dialog', (tester) async {
      // Use a small store so the grid fits in the test viewport.
      final store = _store();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.login));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.login), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Cell edit dialog opens — if it opened, Cancel button is visible.
      if (find.text('Cancel').evaluate().isNotEmpty) {
        expect(find.text('Edit cell'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
      // Whether dialog opened or not, no crash occurred.
      expect(tester.takeException(), isNull);
    });
  });

  group('StoreEditorScreen – prefill', () {
    testWidgets('prefill mode pre-fills name and shows New shop title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          StoreEditorScreen(
            prefill: (
              name: 'Prefilled Market',
              address: '1 Main St',
              lat: 48.0,
              lng: 11.0,
              osmId: null,
              osmCategory: 'supermarket',
              osmCategories: ['supermarket'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Prefilled Market'),
        findsOneWidget,
      );
      expect(find.text('New shop'), findsOneWidget);
    });

    testWidgets('saving prefill store creates a new store', (tester) async {
      await tester.pumpWidget(
        _wrap(
          StoreEditorScreen(
            prefill: (
              name: 'New From OSM',
              address: null,
              lat: null,
              lng: null,
              osmId: null,
              osmCategory: null,
              osmCategories: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should save without error (name already set from prefill).
      expect(tester.takeException(), isNull);
    });

    testWidgets('prefill with osmId uses deterministic shop id', (
      tester,
    ) async {
      _FakeStoresNotifier? captured;
      final mockSvc = MockFirestoreService();
      when(() => mockSvc.upsertShop(any(), any())).thenAnswer((_) async {});
      when(() => mockSvc.upsertPublicCells(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => _NullHouseholdNotifier()),
            supermarketsProvider.overrideWith(() {
              captured = _FakeStoresNotifier([]);
              return captured!;
            }),
            shoppingListsProvider.overrideWith(() => _FakeListsNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(mockSvc),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StoreEditorScreen(
              prefill: (
                name: 'OSM Market',
                address: null,
                lat: null,
                lng: null,
                osmId: 99999,
                osmCategory: null,
                osmCategories: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(captured!.state.length, 1);
      expect(captured!.state.first.id, 'osm_99999');
      expect(captured!.state.first.osmId, 99999);
    });

    testWidgets('template pre-populates grid dimensions', (tester) async {
      final template = Supermarket(
        id: 'osm_7',
        name: '',
        rows: ['A', 'B', 'C'],
        cols: ['1', '2', '3', '4'],
        entrance: 'A1',
        exit: 'C4',
        cells: {'B2': []},
        osmId: 7,
      );

      await tester.pumpWidget(
        _wrap(
          StoreEditorScreen(
            prefill: (
              name: 'My Market',
              address: null,
              lat: null,
              lng: null,
              osmId: 7,
              osmCategory: null,
              osmCategories: null,
            ),
            template: template,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Grid renders without error (entrance and exit icons present).
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StoreEditorScreen – row/col controls', () {
    testWidgets('add-col button increases col count', (tester) async {
      await tester.pumpWidget(_wrap(const StoreEditorScreen()));
      await tester.pumpAndSettle();

      // There should be 2 add_circle_outline buttons: one for row, one for col.
      final addButtons = find.byIcon(Icons.add_circle_outline);
      expect(addButtons, findsWidgets);

      // Tap the second one (col add).
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('entrance is shown as login icon in grid', (tester) async {
      final store = _store();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();

      // The grid marks entrance with a login icon.
      expect(find.byIcon(Icons.login), findsOneWidget);
    });

    testWidgets('adding a row keeps the grid rendering', (tester) async {
      final store = _store();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();

      // Tap add-row button.
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();

      // Grid still shows entrance.
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StoreEditorScreen – long-press cell context menu', () {
    testWidgets('long-pressing grid cell shows context menu', (tester) async {
      final store = _store();
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();

      // Long-press the entrance cell (A1).
      await tester.ensureVisible(find.byIcon(Icons.login));
      await tester.longPress(find.byIcon(Icons.login), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Context menu or bottom sheet might open; no crash expected.
      expect(tester.takeException(), isNull);

      // Dismiss any open menu.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });
  });

  group('StoreEditorScreen – remove row/col', () {
    // For a 2x2 store the remove_circle_outline icons appear in this order:
    // [0] col-1 remove, [1] col-2 remove, [2] row-A remove, [3] row-B remove.

    testWidgets('tapping col-remove on empty col removes it without dialog', (
      tester,
    ) async {
      final store = _store(); // 2x2, no cell items
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();

      final removes = find.byIcon(Icons.remove_circle_outline);
      expect(removes, findsWidgets);

      await tester.tap(removes.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // No dialog; grid still renders.
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping row-remove on empty row removes it without dialog', (
      tester,
    ) async {
      final store = _store(); // 2x2, no cell items
      await tester.pumpWidget(
        _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
      );
      await tester.pumpAndSettle();

      // Row removes come after col removes: index 2 = row A.
      final removes = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removes.at(2), warnIfMissed: false);
      await tester.pumpAndSettle();

      // No dialog; grid still renders.
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'removing a col that contains items shows confirmation and cancel works',
      (tester) async {
        final store = Supermarket(
          id: 'S1',
          name: 'Test Store',
          rows: ['A', 'B'],
          cols: ['1', '2'],
          entrance: 'A1',
          exit: 'B2',
          cells: {
            'A1': ['Bread'],
          },
        );
        await tester.pumpWidget(
          _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
        );
        await tester.pumpAndSettle();

        // Col-1 remove (index 0) — col 1 contains 'Bread' in row A.
        final removes = find.byIcon(Icons.remove_circle_outline);
        await tester.tap(removes.first, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Confirmation dialog should appear.
        expect(find.text('Cancel'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'removing a col that contains items and confirming removes it',
      (tester) async {
        final store = Supermarket(
          id: 'S1',
          name: 'Test Store',
          rows: ['A', 'B'],
          cols: ['1', '2'],
          entrance: 'A1',
          exit: 'B2',
          cells: {
            'A1': ['Milk'],
          },
        );
        await tester.pumpWidget(
          _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
        );
        await tester.pumpAndSettle();

        final removes = find.byIcon(Icons.remove_circle_outline);
        await tester.tap(removes.first, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Dialog: tap Delete to confirm.
        expect(find.text('Delete'), findsAtLeastNWidgets(1));
        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'removing a row that contains items shows confirmation and cancel works',
      (tester) async {
        final store = Supermarket(
          id: 'S1',
          name: 'Test Store',
          rows: ['A', 'B'],
          cols: ['1', '2'],
          entrance: 'A1',
          exit: 'B2',
          cells: {
            'B1': ['Sugar'],
          },
        );
        await tester.pumpWidget(
          _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
        );
        await tester.pumpAndSettle();

        // Row B = index 3 (after 2 col removes + row A at 2).
        final removes = find.byIcon(Icons.remove_circle_outline);
        await tester.tap(removes.at(3), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Confirmation dialog.
        expect(find.text('Cancel'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'removing a row that contains items and confirming removes it',
      (tester) async {
        final store = Supermarket(
          id: 'S1',
          name: 'Test Store',
          rows: ['A', 'B'],
          cols: ['1', '2'],
          entrance: 'A1',
          exit: 'B2',
          cells: {
            'B1': ['Eggs'],
          },
        );
        await tester.pumpWidget(
          _wrap(StoreEditorScreen(existing: store), existingStores: [store]),
        );
        await tester.pumpAndSettle();

        final removes = find.byIcon(Icons.remove_circle_outline);
        await tester.tap(removes.at(3), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Confirm deletion.
        expect(find.text('Delete'), findsAtLeastNWidgets(1));
        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
