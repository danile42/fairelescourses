import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/navigation_plan.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/nav_view_mode_provider.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/navigation_screen.dart';

// ── fake notifiers ────────────────────────────────────────────────────────────

class _FakeNavViewModeNotifier extends NavViewModeNotifier {
  @override
  bool build() => false; // default: grid view
}

class _FakeNavViewModeListNotifier extends NavViewModeNotifier {
  @override
  bool build() => true; // prefer list view
}

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

  @override
  Future<void> add(ShoppingList l) async => state = [...state, l];

  @override
  Future<void> update(ShoppingList l) async =>
      state = [for (final e in state) e.id == l.id ? l : e];

  @override
  Future<void> uncheckAll(String listId) async {
    state = [
      for (final l in state)
        if (l.id == listId)
          l.copyWith(
            items: l.items.map((i) => i.copyWith(checked: false)).toList(),
          )
        else
          l,
    ];
  }
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
}) => NavigationPlan(
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
/// [stores] is used by the screen for availability checks on carried-over items.
Widget _wrap(
  NavigationPlan plan, {
  List<ShoppingItem>? listItems,
  List<Supermarket>? stores,
}) {
  final items =
      listItems ??
      plan.storePlans
          .expand((s) => s.stops)
          .expand((stop) => stop.items)
          .map((name) => ShoppingItem(name: name))
          .toList();
  return ProviderScope(
    overrides: [
      navViewModeProvider.overrideWith(() => _FakeNavViewModeNotifier()),
      shoppingListsProvider.overrideWith(() => _FakeListsNotifier(items)),
      if (stores != null)
        supermarketsProvider.overrideWith(() => _FakeStoresNotifierWith(stores))
      else
        supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NavigationScreen(plan: plan, listId: _listId),
    ),
  );
}

Supermarket _storeWithItems(
  String id,
  String name,
  Map<String, List<String>> cells,
) => Supermarket(
  id: id,
  name: name,
  rows: ['A', 'B'],
  cols: ['1', '2'],
  entrance: 'A1',
  exit: 'B2',
  cells: cells,
);

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
      await tester.pumpWidget(
        _wrap(
          plan,
          listItems: [
            ShoppingItem(name: 'Milk', checked: true),
            ShoppingItem(name: 'Bread'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      // 'Milk' is already checked — only 'Bread' gets a schedule button
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    // ── Bottom sheet content ─────────────────────────────────────────────────

    testWidgets('single store: bottom sheet shows only new-list option', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule).first);
      await tester.pumpAndSettle();

      // "Add to new list" is visible; no "Try at next shop"
      expect(find.byIcon(Icons.playlist_add), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsNothing);
    });

    testWidgets('multi-store: bottom sheet includes next store name', (
      tester,
    ) async {
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

    testWidgets('defer to new list: item shows playlist_add icon and undo', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule).first); // open for 'Milk'
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.playlist_add)); // choose new list
      await tester.pumpAndSettle();

      // 'Milk' now shows playlist_add + undo; 'Bread' still has schedule button
      expect(find.byIcon(Icons.playlist_add), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget); // 'Bread' unaffected
    });

    testWidgets('undo deferred-to-new-list item restores schedule button', (
      tester,
    ) async {
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

    testWidgets('defer to next shop: item shows skip_next icon and undo', (
      tester,
    ) async {
      // Two items at store 1 so the list view stays open after deferring one
      await tester.pumpWidget(
        _wrap(
          _twoStorePlan(
            store1Items: ['Milk', 'Bread'],
            store2Items: ['Cheese'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.schedule).first); // open for 'Milk'
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.skip_next)); // "Try at Store Two"
      await tester.pumpAndSettle();

      // 'Milk' deferred: skip_next + undo; 'Bread' still normal: schedule
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('undo deferred-to-next-shop item restores schedule button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _twoStorePlan(
            store1Items: ['Milk', 'Bread'],
            store2Items: ['Cheese'],
          ),
        ),
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
      },
    );

    testWidgets('done view (last store) shows deferred-to-new-list section', (
      tester,
    ) async {
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
      },
    );

    testWidgets('carried-over item has its own schedule button in next store', (
      tester,
    ) async {
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

  // ── Floor headers ──────────────────────────────────────────────────────────

  group('NavigationScreen – floor headers', () {
    NavigationPlan multiFloorPlan() => NavigationPlan(
      storePlans: [
        StorePlan(
          storeId: 's1',
          storeName: 'FloorMart',
          stops: [
            NavigationStop(cell: 'A1', items: ['Milk'], floor: 0),
            NavigationStop(cell: 'B1', items: ['Electronics'], floor: 1),
          ],
          unmatched: [],
        ),
      ],
      globalUnmatched: [],
    );

    testWidgets('floor header with stairs icon appears before floor-1 stop', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(multiFloorPlan()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stairs), findsOneWidget);
    });

    testWidgets('floor header shows "Floor 1" label', (tester) async {
      await tester.pumpWidget(_wrap(multiFloorPlan()));
      await tester.pumpAndSettle();
      // The floor label appears in both the header divider and the stop badge.
      expect(find.text('Floor 1'), findsAtLeastNWidgets(1));
    });

    testWidgets('no floor header when all stops are on floor 0', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stairs), findsNothing);
    });
  });

  // ── Carried-over item availability ────────────────────────────────────────

  group('NavigationScreen – carried-over item availability', () {
    // Helper: defer 'Milk' from store 1 and advance to store 2.
    Future<void> deferAndAdvance(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.schedule).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next shop'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'carried-over item available in next store has enabled checkbox',
      (tester) async {
        final plan = _twoStorePlan(
          store1Items: ['Milk'],
          store2Items: ['Bread'],
        );
        // Store Two stocks Milk — carried-over 'Milk' should be collectable.
        final stores = [
          _storeWithItems('s1', 'Store One', {
            'A1': ['Milk'],
          }),
          _storeWithItems('s2', 'Store Two', {
            'A1': ['Milk'],
            'B1': ['Bread'],
          }),
        ];
        await tester.pumpWidget(_wrap(plan, stores: stores));
        await tester.pumpAndSettle();

        await deferAndAdvance(tester);

        // Find the Checkbox for the carried-over 'Milk' item.
        // It appears inside the carried-over section above the regular stop.
        final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
        // The first checkbox belongs to the carried-over section ('Milk').
        final milkCheckbox = checkboxes.first;
        expect(milkCheckbox.onChanged, isNotNull);
      },
    );

    testWidgets(
      'carried-over item not stocked at next store has disabled checkbox',
      (tester) async {
        final plan = _twoStorePlan(
          store1Items: ['Milk'],
          store2Items: ['Bread'],
        );
        // Store Two does NOT stock Milk — carried-over 'Milk' should be locked.
        final stores = [
          _storeWithItems('s1', 'Store One', {
            'A1': ['Milk'],
          }),
          _storeWithItems('s2', 'Store Two', {
            'B1': ['Bread'],
          }),
        ];
        await tester.pumpWidget(_wrap(plan, stores: stores));
        await tester.pumpAndSettle();

        await deferAndAdvance(tester);

        final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
        final milkCheckbox = checkboxes.first;
        expect(milkCheckbox.onChanged, isNull);
      },
    );

    testWidgets('unavailable carried-over item still shows schedule button', (
      tester,
    ) async {
      final plan = _twoStorePlan(store1Items: ['Milk'], store2Items: ['Bread']);
      final stores = [
        _storeWithItems('s1', 'Store One', {
          'A1': ['Milk'],
        }),
        _storeWithItems('s2', 'Store Two', {
          'B1': ['Bread'],
        }),
      ];
      await tester.pumpWidget(_wrap(plan, stores: stores));
      await tester.pumpAndSettle();

      await deferAndAdvance(tester);

      // Both carried-over 'Milk' (unavailable) and regular 'Bread' show schedule.
      expect(find.byIcon(Icons.schedule), findsNWidgets(2));
    });
  });

  // ── Checkbox toggles ──────────────────────────────────────────────────────

  group('NavigationScreen – checkbox interactions', () {
    testWidgets('tapping checkbox marks item checked', (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(checkboxes.first);
      expect(checkbox.value, isTrue);
    });

    testWidgets('tapping checked checkbox unchecks it', (tester) async {
      // Use two items so the screen doesn't immediately go to _DoneView.
      await tester.pumpWidget(
        _wrap(
          _singleStorePlan(['Milk', 'Bread']),
          listItems: [
            ShoppingItem(name: 'Milk', checked: true),
            ShoppingItem(name: 'Bread'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // The first checkbox should be for 'Milk' (already checked = true).
      final checkboxes = find.byType(Checkbox);
      final milkCheckbox = tester.widget<Checkbox>(checkboxes.first);
      expect(milkCheckbox.value, isTrue);

      // Tap it to uncheck.
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      final afterToggle = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(afterToggle.value, isFalse);
    });

    testWidgets('checking all items triggers done view', (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });

  // ── Cancel tour popup ─────────────────────────────────────────────────────

  group('NavigationScreen – cancel tour', () {
    testWidgets('popup menu shows cancel-tour option', (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Cancel tour'), findsOneWidget);
    });

    testWidgets('selecting cancel tour pops the screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => ProviderScope(
                      overrides: [
                        navViewModeProvider.overrideWith(
                          () => _FakeNavViewModeNotifier(),
                        ),
                        shoppingListsProvider.overrideWith(
                          () =>
                              _FakeListsNotifier([ShoppingItem(name: 'Milk')]),
                        ),
                        supermarketsProvider.overrideWith(
                          () => _FakeStoresNotifier(),
                        ),
                      ],
                      child: NavigationScreen(
                        plan: _singleStorePlan(['Milk']),
                        listId: _listId,
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel tour'));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });
  });

  // ── Unmatched items ───────────────────────────────────────────────────────

  group('NavigationScreen – unmatched items', () {
    NavigationPlan planWithUnmatched() => NavigationPlan(
      storePlans: [
        StorePlan(
          storeId: 's1',
          storeName: 'TestMart',
          stops: [
            NavigationStop(cell: 'A1', items: ['Milk']),
          ],
          unmatched: [],
        ),
      ],
      globalUnmatched: ['Cheese', 'Butter'],
    );

    testWidgets('list view shows unmatched section', (tester) async {
      await tester.pumpWidget(_wrap(planWithUnmatched()));
      await tester.pumpAndSettle();

      // Switch to list view to see unmatched section.
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      expect(find.textContaining('Not found'), findsWidgets);
    });

    testWidgets('done view with unmatched shows warning section', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(planWithUnmatched()));
      await tester.pumpAndSettle();

      // Check the only matched item to reach done view.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Done view should appear.
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      // Unmatched section in done view (orange warning).
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('finish button appears in done view at last store', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('Finish'), findsOneWidget);
    });
  });

  // ── German locale ─────────────────────────────────────────────────────────

  group('NavigationScreen – German locale', () {
    testWidgets('renders in German without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navViewModeProvider.overrideWith(() => _FakeNavViewModeNotifier()),
            shoppingListsProvider.overrideWith(
              () => _FakeListsNotifier([ShoppingItem(name: 'Milch')]),
            ),
            supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NavigationScreen(
              plan: _singleStorePlan(['Milch']),
              listId: _listId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Navigation'), findsOneWidget);
    });
  });

  // ── View mode toggle ──────────────────────────────────────────────────────

  group('NavigationScreen – view mode', () {
    testWidgets('tapping view toggle switches to list view', (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();

      // Initial mode is grid — icon shows Icons.list to switch to list view.
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // After switching, icon shows Icons.grid_view to switch back.
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });

    testWidgets('items are still visible in list view', (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('starts in list view when preferred mode is list', (
      tester,
    ) async {
      // Override the provider to prefer list view.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navViewModeProvider.overrideWith(
              () => _FakeNavViewModeListNotifier(),
            ),
            shoppingListsProvider.overrideWith(
              () => _FakeListsNotifier([
                ShoppingItem(name: 'Milk'),
                ShoppingItem(name: 'Bread'),
              ]),
            ),
            supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NavigationScreen(
              plan: _singleStorePlan(['Milk', 'Bread']),
              listId: _listId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In list view, the toggle icon is Icons.grid_view (to switch to grid).
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      // Items are visible.
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
    });
  });

  // ── Empty store plan (all unmatched) ─────────────────────────────────────

  group('NavigationScreen – empty store plan', () {
    NavigationPlan _emptyStorePlan() => NavigationPlan(
      storePlans: [],
      globalUnmatched: ['Cheese', 'Butter'],
    );

    testWidgets('shows unmatched items when no store plans', (tester) async {
      await tester.pumpWidget(_wrap(_emptyStorePlan()));
      await tester.pumpAndSettle();
      // Shows the navigation title (app bar).
      expect(find.text('Navigation'), findsOneWidget);
      // Unmatched items are shown.
      expect(find.text('• Cheese'), findsOneWidget);
      expect(find.text('• Butter'), findsOneWidget);
    });

    testWidgets('assign-to-shop button appears for unmatched items', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_emptyStorePlan()));
      await tester.pumpAndSettle();
      // Both unmatched items should have an assign-to-shop button.
      expect(find.textContaining('Assign to shop'), findsWidgets);
    });

    testWidgets('tapping assign-to-shop opens shop picker dialog', (
      tester,
    ) async {
      final stores = [
        _storeWithItems('s1', 'BestMart', {'A1': ['Cheese']}),
      ];
      await tester.pumpWidget(_wrap(_emptyStorePlan(), stores: stores));
      await tester.pumpAndSettle();

      // Tap the first Assign to shop button.
      await tester.tap(find.textContaining('Assign to shop').first);
      await tester.pumpAndSettle();

      // The dialog shows "BestMart" as a choice.
      expect(find.text('BestMart'), findsOneWidget);
      // Dismiss.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });
  });

  // ── Multi-store tab navigation ────────────────────────────────────────────

  group('NavigationScreen – multi-store tab navigation', () {
    testWidgets('store tabs appear at top for two-store plan in grid view', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _twoStorePlan(store1Items: ['Milk'], store2Items: ['Bread']),
        ),
      );
      await tester.pumpAndSettle();

      // In grid mode with 2 stores, ChoiceChips for each store appear.
      expect(find.text('Store One'), findsWidgets);
      expect(find.text('Store Two'), findsWidgets);
    });

    testWidgets('tapping second store tab shows store two items', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _twoStorePlan(store1Items: ['Milk'], store2Items: ['Bread']),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Store Two chip.
      await tester.tap(find.text('Store Two').last);
      await tester.pumpAndSettle();

      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('progress bar is visible', (tester) async {
      await tester.pumpWidget(_wrap(_singleStorePlan(['Milk', 'Bread'])));
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  // ── List view with multiple stores ────────────────────────────────────────

  group('NavigationScreen – list view multi-store', () {
    testWidgets('list view shows all stores as sub-sections', (tester) async {
      await tester.pumpWidget(
        _wrap(_twoStorePlan(store1Items: ['Milk'], store2Items: ['Bread'])),
      );
      await tester.pumpAndSettle();

      // Switch to list view.
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Both store names shown as headers.
      expect(find.text('Store One'), findsWidgets);
      expect(find.text('Store Two'), findsWidgets);
      // Both items shown.
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('list view shows unmatched section when items unmatched', (
      tester,
    ) async {
      final plan = NavigationPlan(
        storePlans: [
          StorePlan(
            storeId: 's1',
            storeName: 'TestMart',
            stops: [NavigationStop(cell: 'A1', items: ['Milk'])],
            unmatched: ['Cheese'],
          ),
        ],
        globalUnmatched: [],
      );
      await tester.pumpWidget(_wrap(plan));
      await tester.pumpAndSettle();

      // Switch to list view.
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      expect(find.textContaining('Not found'), findsWidgets);
      expect(find.text('Cheese'), findsOneWidget);
    });
  });

  // ── Finish tour ────────────────────────────────────────────────────────────

  group('NavigationScreen – finish tour', () {
    testWidgets('tapping Finish from done view pops the screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => ProviderScope(
                      overrides: [
                        navViewModeProvider.overrideWith(
                          () => _FakeNavViewModeNotifier(),
                        ),
                        shoppingListsProvider.overrideWith(
                          () =>
                              _FakeListsNotifier([ShoppingItem(name: 'Milk')]),
                        ),
                        supermarketsProvider.overrideWith(
                          () => _FakeStoresNotifier(),
                        ),
                      ],
                      child: NavigationScreen(
                        plan: _singleStorePlan(['Milk']),
                        listId: _listId,
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Check the only item to reach done view.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Tap Finish.
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      // After finishing, back at the original page.
      expect(find.text('Open'), findsOneWidget);
    });
  });

  // ── Next shop advance from done view ────────────────────────────────────────

  group('NavigationScreen – done view next-shop advance', () {
    testWidgets('Next shop button advances to store two', (tester) async {
      final plan = _twoStorePlan(
        store1Items: ['Milk'],
        store2Items: ['Bread'],
      );
      await tester.pumpWidget(_wrap(plan));
      await tester.pumpAndSettle();

      // Check the Milk item to reach done view at store one.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Tap "Next shop".
      await tester.tap(find.text('Next shop'));
      await tester.pumpAndSettle();

      // Now at store two: Bread is shown.
      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('done view shows "Next shop" button at non-last store', (
      tester,
    ) async {
      final plan = _twoStorePlan(
        store1Items: ['Milk'],
        store2Items: ['Bread'],
      );
      await tester.pumpWidget(_wrap(plan));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('Next shop'), findsOneWidget);
      expect(find.text('Finish'), findsNothing);
    });
  });
}
