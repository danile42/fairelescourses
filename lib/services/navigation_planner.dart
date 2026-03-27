import '../models/supermarket.dart';
import '../models/shopping_list.dart';
import '../models/navigation_plan.dart';

class NavigationPlanner {
  /// Build a full navigation plan for [list] across [stores].
  /// Preferred stores are tried first. Items not found anywhere go to globalUnmatched.
  static NavigationPlan plan(ShoppingList list, List<Supermarket> stores) {
    if (stores.isEmpty) {
      return NavigationPlan(
        storePlans: [],
        globalUnmatched: list.items.map((i) => i.name).toList(),
      );
    }

    // Determine store order: preferred first, then rest.
    final preferred = stores.where((s) => list.preferredStoreIds.contains(s.id)).toList();
    final others = stores.where((s) => !list.preferredStoreIds.contains(s.id)).toList();
    final orderedStores = [...preferred, ...others];

    // Assign each item to the first store that can match it.
    final Map<String, List<String>> storeItems = {for (final s in orderedStores) s.id: []};
    final globalUnmatched = <String>[];

    for (final item in list.items) {
      bool found = false;
      for (final store in orderedStores) {
        if (store.findCell(item.name) != null) {
          storeItems[store.id]!.add(item.name);
          found = true;
          break;
        }
      }
      if (!found) globalUnmatched.add(item.name);
    }

    final storePlans = <StorePlan>[];
    for (final store in orderedStores) {
      final items = storeItems[store.id]!;
      if (items.isEmpty) continue;
      final stops = _buildRoute(store, items);
      final unmatched = items.where((i) => store.findCell(i) == null).toList();
      storePlans.add(StorePlan(
        storeId: store.id,
        storeName: store.name,
        stops: stops,
        unmatched: unmatched,
      ));
    }

    return NavigationPlan(storePlans: storePlans, globalUnmatched: globalUnmatched);
  }

  /// Build an ordered list of stops for the given items in [store].
  /// Groups by floor, then runs nearest-neighbor routing within each floor.
  static List<NavigationStop> _buildRoute(Supermarket store, List<String> items) {
    // Group items by (floor, cell).
    final Map<(int, String), List<String>> floorCellItems = {};
    for (final item in items) {
      final found = store.findCellWithFloor(item);
      if (found != null) {
        floorCellItems.putIfAbsent(found, () => []).add(item);
      }
    }

    if (floorCellItems.isEmpty) return [];

    // Route floor by floor in ascending order.
    final floors = floorCellItems.keys.map((k) => k.$1).toSet().toList()..sort();
    final stops = <NavigationStop>[];

    for (final floorIdx in floors) {
      final floorObj = store.floorAt(floorIdx);
      final cellItems = {
        for (final e in floorCellItems.entries)
          if (e.key.$1 == floorIdx) e.key.$2: e.value,
      };

      final remaining = cellItems.keys.toList();
      String current = floorObj.entrance;

      while (remaining.isNotEmpty) {
        remaining.sort((a, b) {
          final da = floorObj.distance(current, a) ?? 9999;
          final db = floorObj.distance(current, b) ?? 9999;
          return da.compareTo(db);
        });
        current = remaining.removeAt(0);
        stops.add(NavigationStop(
          cell: current,
          items: cellItems[current]!,
          floor: floorIdx,
        ));
      }
    }

    return stops;
  }
}
