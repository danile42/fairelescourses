import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/nav_session.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/models/shop_floor.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/nav_session_provider.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/home_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';

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
        supermarketsProvider
            .overrideWith(() => _FakeStoresNotifierWith(stores))
      else
        supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
      navSessionProvider.overrideWith((ref) => Stream.value(session)),
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
  });

  group('HomeScreen list tab', () {
    testWidgets('renders list names', (tester) async {
      await tester.pumpWidget(
        _wrap(lists: [_list('L1', 'Groceries'), _list('L2', 'Hardware')]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Hardware'), findsOneWidget);
    });

    testWidgets('shows empty-state message when no lists', (tester) async {
      await tester.pumpWidget(_wrap(lists: []));
      await tester.pumpAndSettle();
      expect(find.textContaining('No shopping lists'), findsOneWidget);
    });

    testWidgets('delete menu item is enabled when no active session',
        (tester) async {
      await tester.pumpWidget(_wrap(lists: [_list('L1', 'Groceries')]));
      await tester.pumpAndSettle();

      // Open the PopupMenu for the list card.
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // When enabled, the code passes style: null to the Text widget.
      expect(find.text('Delete'), findsOneWidget);
      final deleteText = tester.widget<Text>(find.text('Delete'));
      expect(deleteText.style?.color, isNot(Colors.grey));
    });

    testWidgets('delete menu item is disabled when session is active for that list',
        (tester) async {
      const session = NavSession(listId: 'L1', startedBy: 'uid-1');
      await tester.pumpWidget(
        _wrap(lists: [_list('L1', 'Groceries')], session: session),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // When disabled, the code explicitly sets TextStyle(color: Colors.grey).
      expect(find.text('Delete'), findsOneWidget);
      final deleteText = tester.widget<Text>(find.text('Delete'));
      expect(deleteText.style?.color, Colors.grey);
    });

    testWidgets('delete is enabled for a list that is NOT the active session',
        (tester) async {
      // Session is on L1, but we have L1 and L2 — only L1's delete should be disabled.
      const session = NavSession(listId: 'L1', startedBy: 'uid-1');
      await tester.pumpWidget(
        _wrap(
          lists: [_list('L1', 'Groceries'), _list('L2', 'Hardware')],
          session: session,
        ),
      );
      await tester.pumpAndSettle();

      // Open popup for the second list card (Hardware / L2).
      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();

      // L2 is not the active session list, so delete should be enabled (style: null).
      expect(find.text('Delete'), findsOneWidget);
      final deleteText = tester.widget<Text>(find.text('Delete'));
      expect(deleteText.style?.color, isNot(Colors.grey));
    });
  });

  group('HomeScreen shops tab', () {
    Supermarket _makeStore({int extraFloors = 0}) {
      final s = Supermarket(
        id: 'store-1',
        name: 'Test Market',
        rows: ['A', 'B', 'C'],
        cols: ['1', '2', '3'],
        entrance: 'A1',
        exit: 'C3',
        cells: {},
      );
      if (extraFloors > 0) {
        s.additionalFloors = List.generate(
          extraFloors,
          (i) => ShopFloor(
            name: '',
            rows: ['A', 'B'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'B2',
          ),
        );
      }
      return s;
    }

    testWidgets('single-floor store shows grid size without floor count',
        (tester) async {
      await tester.pumpWidget(_wrap(lists: [], stores: [_makeStore()]));
      await tester.pumpAndSettle();

      // Navigate to the Shops tab.
      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      expect(find.text('3×3'), findsOneWidget);
      expect(find.textContaining('floors'), findsNothing);
    });

    testWidgets('multi-floor store shows floor count in subtitle',
        (tester) async {
      await tester.pumpWidget(
          _wrap(lists: [], stores: [_makeStore(extraFloors: 1)]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      // "3×3  •  2 floors"
      expect(find.textContaining('2 floors'), findsOneWidget);
    });

    testWidgets('three-floor store shows correct count', (tester) async {
      await tester.pumpWidget(
          _wrap(lists: [], stores: [_makeStore(extraFloors: 2)]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      expect(find.textContaining('3 floors'), findsOneWidget);
    });
  });
}
