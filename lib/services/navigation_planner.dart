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

  /// Build an ordered list of stops for the given items in [store],
  /// starting at entrance, ending at exit, using nearest-neighbor heuristic.
  static List<NavigationStop> _buildRoute(Supermarket store, List<String> items) {
    // Group items by cell.
    final Map<String, List<String>> cellItems = {};
    for (final item in items) {
      final cell = store.findCell(item);
      if (cell != null) {
        cellItems.putIfAbsent(cell, () => []).add(item);
      }
    }

    if (cellItems.isEmpty) return [];

    // Nearest-neighbor TSP from entrance → all cells → exit.
    final remaining = cellItems.keys.toList();
    final route = <String>[];
    String current = store.entrance;

    while (remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final da = store.distance(current, a) ?? 9999;
        final db = store.distance(current, b) ?? 9999;
        return da.compareTo(db);
      });
      current = remaining.removeAt(0);
      route.add(current);
    }

    return route.map((cell) => NavigationStop(cell: cell, items: cellItems[cell]!)).toList();
  }
}
