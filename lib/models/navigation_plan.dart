class NavigationStop {
  final String cell;
  final List<String> items;

  /// 0 = ground floor, 1+ = additional floors.
  final int floor;

  const NavigationStop({
    required this.cell,
    required this.items,
    this.floor = 0,
  });
}

class StorePlan {
  final String storeId;
  final String storeName;
  final List<NavigationStop> stops;
  final List<String> unmatched;

  const StorePlan({
    required this.storeId,
    required this.storeName,
    required this.stops,
    required this.unmatched,
  });

  int get totalItems => stops.fold(0, (s, stop) => s + stop.items.length);
}

class NavigationPlan {
  final List<StorePlan> storePlans;
  final List<String> globalUnmatched;

  const NavigationPlan({
    required this.storePlans,
    required this.globalUnmatched,
  });
}
