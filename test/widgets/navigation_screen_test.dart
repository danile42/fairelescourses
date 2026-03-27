import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/navigation_plan.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/navigation_screen.dart';

// ── fake notifiers ────────────────────────────────────────────────────────────

class _FakeListsNotifier extends ShoppingListNotifier {
  _FakeListsNotifier(this._items);
  final List<ShoppingItem> _items;

  @override
  List<ShoppingList> build() => [
        ShoppingList(
          id: _listId,
          name: 'Test',
          preferredStoreIds: [],
          items: _items,
        ),
      ];
}

class _FakeStoresNotifier extends SupermarketNotifier {
  @override
  List<Supermarket> build() => [];
}

// ── helpers ───────────────────────────────────────────────────────────────────

const _listId = 'nav-test-list';

NavigationPlan _singleStorePlan(List<String> items) => NavigationPlan(
      storePlans: [
        StorePlan(
          storeId: 's1',
          storeName: 'TestMart',
          stops: [NavigationStop(cell: 'A1', items: items)],
          unmatched: [],
        ),
      ],
      globalUnmatched: [],
    );

NavigationPlan _twoStorePlan({
  required List<String> store1Items,
  required List<String> store2Items,
}) =>
    NavigationPlan(
      storePlans: [
        StorePlan(
          storeId: 's1',
          storeName: 'Store One',
          stops: [NavigationStop(cell: 'A1', items: store1Items)],
          unmatched: [],
        ),
        StorePlan(
          storeId: 's2',
          storeName: 'Store Two',
          stops: [NavigationStop(cell: 'B1', items: store2Items)],
          unmatched: [],
        ),
      ],
      globalUnmatched: [],
    );

/// Wraps [NavigationScreen] with minimal provider overrides.
/// [listItems] defaults to all plan items unchecked.
Widget _wrap(NavigationPlan plan, {List<ShoppingItem>? listItems}) {
  final items = listItems ??
      plan.storePlans
          .expand((s) => s.stops)
          .expand((stop) => stop.items)
          .map((name) => ShoppingItem(name: name))
          .toList();
  return ProviderScope(
    overrides: [
      shoppingListsProvider.overrideWith(() => _FakeListsNotifier(items)),
      supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NavigationScreen(plan: plan, listId: _listId),
    ),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('NavigationScreen – collect later', () {
    // ── Button visibility ────────────────────────────────────────────────────

    testWidgets('schedule icon shown for each unchecked item', (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.schedule), findsNWidgets(2));
    });

    testWidgets('schedule icon absent for pre-checked items', (tester) async {
      final plan = _singleStorePlan(['Milk', 'Bread']);
      await tester.pumpWidget(_wrap(plan, listItems: [
        ShoppingItem(name: 'Milk', checked: true),
        ShoppingItem(name: 'Bread'),
      ]));
      await tester.pumpAndSettle();
      // 'Milk' is already checked — only 'Bread' gets a schedule button
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    // ── Bottom sheet content ─────────────────────────────────────────────────

    testWidgets('single store: bottom sheet shows only new-list option',
        (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule).first);
      await tester.pumpAndSettle();

      // "Add to new list" is visible; no "Try at next shop"
      expect(find.byIcon(Icons.playlist_add), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsNothing);
    });

    testWidgets('multi-store: bottom sheet includes next store name',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_twoStorePlan(store1Items: ['Milk'], store2Items: ['Bread'])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.skip_next), findsOneWidget);
      expect(find.textContaining('Store Two'), findsWidgets);
    });

    // ── Defer to new list ────────────────────────────────────────────────────

    testWidgets('defer to new list: item shows playlist_add icon and undo',
        (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule).first); // open for 'Milk'
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.playlist_add));   // choose new list
      await tester.pumpAndSettle();

      // 'Milk' now shows playlist_add + undo; 'Bread' still has schedule button
      expect(find.byIcon(Icons.playlist_add), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget); // 'Bread' unaffected
    });

    testWidgets('undo deferred-to-new-list item restores schedule button',
        (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule), findsNWidgets(2));
      expect(find.byIcon(Icons.undo), findsNothing);
      expect(find.byIcon(Icons.playlist_add), findsNothing);
    });

    // ── Defer to next shop ───────────────────────────────────────────────────

    testWidgets('defer to next shop: item shows skip_next icon and undo',
        (tester) async {
      // Two items at store 1 so the list view stays open after deferring one
      await tester.pumpWidget(
        _wrap(_twoStorePlan(
            store1Items: ['Milk', 'Bread'], store2Items: ['Cheese'])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule).first); // open for 'Milk'
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.skip_next));       // "Try at Store Two"
      await tester.pumpAndSettle();

      // 'Milk' deferred: skip_next + undo; 'Bread' still normal: schedule
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('undo deferred-to-next-shop item restores schedule button',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_twoStorePlan(
            store1Items: ['Milk', 'Bread'], store2Items: ['Cheese'])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      // Both items unchecked and not deferred → 2 schedule buttons
      expect(find.byIcon(Icons.schedule), findsNWidgets(2));
      expect(find.byIcon(Icons.undo), findsNothing);
    });

    // ── Done view triggered by deferral ──────────────────────────────────────

    testWidgets('deferring the only item triggers done view', (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets(
        'done view (non-last store) shows deferred-to-next-shop info box',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_twoStorePlan(store1Items: ['Milk'], store2Items: ['Bread'])),
      );
      await tester.pumpAndSettle();

      // Defer 'Milk' to next shop → all of store 1 handled → done view
      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.textContaining('next shop'), findsOneWidget);
      expect(find.text('• Milk'), findsOneWidget);
    });

    testWidgets('done view (last store) shows deferred-to-new-list section',
        (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      // Purple section lists the deferred item
      expect(find.text('• Milk'), findsOneWidget);
    });

    // ── Carry-over to next store ─────────────────────────────────────────────

    testWidgets(
        'advancing past a store puts deferred items in carried-over section',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_twoStorePlan(store1Items: ['Milk'], store2Items: ['Bread'])),
      );
      await tester.pumpAndSettle();

      // Defer 'Milk' to next shop → done view for Store One
      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      // Tap "Next shop" to advance to Store Two
      await tester.tap(find.text('Next shop'));
      await tester.pumpAndSettle();

      // "From Store One" section with 'Milk' and history icon
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.text('From Store One'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('carried-over item has its own schedule button in next store',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_twoStorePlan(store1Items: ['Milk'], store2Items: ['Bread'])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next shop'));
      await tester.pumpAndSettle();

      // 'Milk' (carried over) + 'Bread' (normal stop) each have a schedule button
      expect(find.byIcon(Icons.schedule), findsNWidgets(2));
    });
  });
}
