import 'package:flutter_test/flutter_test.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/models/shop_floor.dart';
import 'package:fairelescourses/services/navigation_planner.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

ShoppingList makeList(List<String> itemNames, {List<String> preferred = const []}) =>
    ShoppingList(
      id: 'list-1',
      name: 'Test',
      preferredStoreIds: preferred,
      items: itemNames.map((n) => ShoppingItem(name: n)).toList(),
    );

Supermarket makeStore({
  required String id,
  String name = 'Store',
  List<String> rows = const ['A', 'B', 'C'],
  List<String> cols = const ['1', '2', '3'],
  String entrance = 'A1',
  String exit = 'C3',
  Map<String, List<String>> cells = const {},
}) =>
    Supermarket(
      id: id,
      name: name,
      rows: rows,
      cols: cols,
      entrance: entrance,
      exit: exit,
      cells: Map.from(cells),
    );

void main() {
  group('NavigationPlanner.plan', () {
    test('empty stores puts all items in globalUnmatched', () {
      final plan = NavigationPlanner.plan(makeList(['Milk', 'Bread']), []);
      expect(plan.storePlans, isEmpty);
      expect(plan.globalUnmatched, containsAll(['Milk', 'Bread']));
    });

    test('empty list produces empty plan', () {
      final store = makeStore(id: 's1', cells: {'A1': ['Milk']});
      final plan = NavigationPlanner.plan(makeList([]), [store]);
      expect(plan.storePlans, isEmpty);
      expect(plan.globalUnmatched, isEmpty);
    });

    test('items not found in any store go to globalUnmatched', () {
      final store = makeStore(id: 's1', cells: {'A1': ['Bread']});
      final plan = NavigationPlanner.plan(makeList(['Milk', 'Bread']), [store]);
      expect(plan.globalUnmatched, contains('Milk'));
      expect(plan.globalUnmatched, isNot(contains('Bread')));
    });

    test('found item is assigned and produces a stop', () {
      final store = makeStore(id: 's1', cells: {'A1': ['Milk']});
      final plan = NavigationPlanner.plan(makeList(['Milk']), [store]);
      expect(plan.storePlans.length, 1);
      expect(plan.storePlans.first.stops.length, 1);
      expect(plan.storePlans.first.stops.first.cell, 'A1');
      expect(plan.storePlans.first.stops.first.items, ['Milk']);
    });

    test('multiple items in the same cell are grouped into one stop', () {
      final store = makeStore(id: 's1', cells: {
        'A1': ['Milk', 'Butter'],
      });
      final plan = NavigationPlanner.plan(makeList(['Milk', 'Butter']), [store]);
      expect(plan.storePlans.first.stops.length, 1);
      expect(plan.storePlans.first.stops.first.items,
          containsAll(['Milk', 'Butter']));
    });

    test('items in different cells each get their own stop', () {
      final store = makeStore(id: 's1', cells: {
        'A1': ['Milk'],
        'C3': ['Bread'],
      });
      final plan = NavigationPlanner.plan(makeList(['Milk', 'Bread']), [store]);
      expect(plan.storePlans.first.stops.length, 2);
    });

    test('route follows nearest-neighbour from entrance', () {
      // Grid: A1(entrance) A2 A3 / B1 B2 B3 / C1 C2 C3
      // A2: dist 1 from A1
      // A3: dist 2 from A1, dist 1 from A2
      // C3: dist 4 from A1, dist 2 from A3
      // Nearest-neighbour: A1 → A2(Eggs, d=1) → A3(Butter, d=1) → C3(Bread, d=2)
      // Bread must be the last stop.
      final store = makeStore(id: 's1', cells: {
        'A2': ['Eggs'],   // distance from A1 = 1
        'A3': ['Butter'], // distance from A1 = 2, from A2 = 1
        'C3': ['Bread'],  // distance from A1 = 4, from A3 = 2
      });
      final plan =
          NavigationPlanner.plan(makeList(['Eggs', 'Butter', 'Bread']), [store]);
      final stops = plan.storePlans.first.stops;
      // Bread is furthest along the nearest-neighbour path and must be last.
      final breadIdx = stops.indexWhere((s) => s.items.contains('Bread'));
      final eggsIdx = stops.indexWhere((s) => s.items.contains('Eggs'));
      final butterIdx = stops.indexWhere((s) => s.items.contains('Butter'));
      expect(breadIdx, greaterThan(eggsIdx));
      expect(breadIdx, greaterThan(butterIdx));
    });

    test('preferred store wins over non-preferred for same item', () {
      final preferred = makeStore(id: 'pref', cells: {'A1': ['Milk']});
      final other = makeStore(id: 'other', cells: {'B1': ['Milk']});
      final plan = NavigationPlanner.plan(
        makeList(['Milk'], preferred: ['pref']),
        [other, preferred], // other comes first in list but preferred is flagged
      );
      expect(plan.storePlans.length, 1);
      expect(plan.storePlans.first.storeId, 'pref');
    });

    test('item assigned to first matching store only', () {
      final s1 = makeStore(id: 's1', cells: {'A1': ['Milk']});
      final s2 = makeStore(id: 's2', cells: {'B1': ['Milk']});
      final plan = NavigationPlanner.plan(makeList(['Milk']), [s1, s2]);
      expect(plan.storePlans.length, 1);
      expect(plan.storePlans.first.storeId, 's1');
    });

    test('store with no matching items is excluded from storePlans', () {
      final s1 = makeStore(id: 's1', cells: {'A1': ['Milk']});
      final s2 = makeStore(id: 's2', cells: {'B1': ['Bread']});
      final plan = NavigationPlanner.plan(makeList(['Milk']), [s1, s2]);
      expect(plan.storePlans.length, 1);
      expect(plan.storePlans.first.storeId, 's1');
    });

    test('case-insensitive item matching', () {
      final store = makeStore(id: 's1', cells: {'A2': ['whole milk']});
      final plan = NavigationPlanner.plan(makeList(['Whole Milk']), [store]);
      expect(plan.storePlans.first.stops.first.cell, 'A2');
    });

    test('totalItems counts all items across stops', () {
      final store = makeStore(id: 's1', cells: {
        'A1': ['Milk', 'Butter'],
        'B2': ['Bread'],
      });
      final plan =
          NavigationPlanner.plan(makeList(['Milk', 'Butter', 'Bread']), [store]);
      expect(plan.storePlans.first.totalItems, 3);
    });

    // ── multi-floor routing ───────────────────────────────────────────────────

    test('items on different floors get correct floor field on their stop', () {
      final store = makeStore(id: 's1', cells: {'A1': ['Milk']});
      store.additionalFloors = [
        ShopFloor(
          name: '',
          rows: ['A', 'B'],
          cols: ['1', '2'],
          entrance: 'A1',
          exit: 'B2',
          cells: {'B2': ['Electronics']},
        ),
      ];
      final plan =
          NavigationPlanner.plan(makeList(['Milk', 'Electronics']), [store]);
      final stops = plan.storePlans.first.stops;
      final milkStop = stops.firstWhere((s) => s.items.contains('Milk'));
      final elecStop = stops.firstWhere((s) => s.items.contains('Electronics'));
      expect(milkStop.floor, 0);
      expect(elecStop.floor, 1);
    });

    test('floor 0 stops precede floor 1 stops', () {
      final store = makeStore(id: 's1', cells: {'C3': ['Bread']});
      store.additionalFloors = [
        ShopFloor(
          name: '',
          rows: ['A', 'B'],
          cols: ['1', '2'],
          entrance: 'A1',
          exit: 'B2',
          cells: {'A1': ['Cheese']},
        ),
      ];
      final plan =
          NavigationPlanner.plan(makeList(['Bread', 'Cheese']), [store]);
      final stops = plan.storePlans.first.stops;
      final breadIdx = stops.indexWhere((s) => s.items.contains('Bread'));
      final cheeseIdx = stops.indexWhere((s) => s.items.contains('Cheese'));
      expect(breadIdx, lessThan(cheeseIdx));
    });

    test('items on same upper floor are grouped into one stop', () {
      final store = makeStore(id: 's1');
      store.additionalFloors = [
        ShopFloor(
          name: '',
          rows: ['A', 'B'],
          cols: ['1', '2'],
          entrance: 'A1',
          exit: 'B2',
          cells: {
            'A2': ['Cheese', 'Butter'],
          },
        ),
      ];
      final plan =
          NavigationPlanner.plan(makeList(['Cheese', 'Butter']), [store]);
      final stops = plan.storePlans.first.stops;
      expect(stops.length, 1);
      expect(stops.first.floor, 1);
      expect(stops.first.items, containsAll(['Cheese', 'Butter']));
    });
  });
}
