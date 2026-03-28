import 'package:hive/hive.dart';

import 'shop_floor.dart';

part 'supermarket.g.dart';

@HiveType(typeId: 0)
class Supermarket extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> rows; // e.g. ["A","B","C"]

  @HiveField(3)
  List<String> cols; // e.g. ["1","2","3"]

  @HiveField(4)
  String entrance; // e.g. "A1"

  @HiveField(5)
  String exit; // e.g. "E5"

  /// cell id -> list of goods tags, e.g. {"A1": ["Bread","Bakery"]}
  @HiveField(6)
  Map<String, List<String>> cells;

  @HiveField(7)
  String? address;

  @HiveField(8)
  double? lat;

  @HiveField(9)
  double? lng;

  /// Firestore ID of the shop this was copied from, if any.
  @HiveField(10)
  String? parentId;

  /// Draft cell splits. Keys use the format "$cellId:$axis:$index" where
  /// axis is "row" (top/bottom halves → promotes to a new row) or
  /// "col" (left/right halves → promotes to a new column), and index is 0 or 1.
  /// Example: {"B2:col:0": ["Dairy"], "B2:col:1": ["Cheese"]}
  @HiveField(11)
  Map<String, List<String>> subcells;

  /// OSM shop category value (e.g. "supermarket", "bakery") set when the shop
  /// is created by importing from OpenStreetMap. Used for category filtering.
  @HiveField(12)
  String? osmCategory;

  /// Additional floors beyond the ground floor (index 0).
  /// Stored as raw List<Map> so Hive can persist it without a custom adapter.
  @HiveField(14)
  List<dynamic>? floorsRaw;

  /// Optional display name for the ground floor (e.g. "Erdgeschoss" or custom).
  /// Null means the UI falls back to the locale-default "Ground floor" label.
  @HiveField(15)
  String? groundFloorName;

  /// Firebase Auth UID of the creator. Not persisted to Hive — populated
  /// from Firestore metadata so the UI can gate edit/delete controls.
  String? ownerUid;

  Supermarket({
    required this.id,
    required this.name,
    required this.rows,
    required this.cols,
    required this.entrance,
    required this.exit,
    required this.cells,
    this.address,
    this.lat,
    this.lng,
    this.parentId,
    this.ownerUid,
    this.osmCategory,
    this.floorsRaw,
    this.groundFloorName,
    Map<String, List<String>>? subcells,
  }) : subcells = subcells ?? {};

  // ---------------------------------------------------------------------------
  // Grid helpers
  // ---------------------------------------------------------------------------

  /// All valid cell ids for this supermarket.
  List<String> get allCells =>
      [for (final r in rows) for (final c in cols) '$r$c'];

  /// Manhattan distance between two cell ids. Returns null if either is invalid.
  int? distance(String a, String b) {
    final posA = _cellPos(a);
    final posB = _cellPos(b);
    if (posA == null || posB == null) return null;
    return (posA.$1 - posB.$1).abs() + (posA.$2 - posB.$2).abs();
  }

  /// Returns (rowIndex, colIndex) for a cell id, or null if not found.
  (int, int)? _cellPos(String cellId) {
    for (var ri = 0; ri < rows.length; ri++) {
      for (var ci = 0; ci < cols.length; ci++) {
        if ('${rows[ri]}${cols[ci]}' == cellId) return (ri, ci);
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Multi-floor helpers
  // ---------------------------------------------------------------------------

  /// Deserialised additional floors (floor index 1, 2, …).
  List<ShopFloor> get additionalFloors {
    final raw = floorsRaw;
    if (raw == null || raw.isEmpty) return [];
    return raw.map((e) => ShopFloor.fromMap(e as Map)).toList();
  }

  set additionalFloors(List<ShopFloor> floors) {
    floorsRaw = floors.isEmpty ? null : floors.map((f) => f.toMap()).toList();
  }

  /// Returns the [ShopFloor] for [index] (0 = ground floor / main grid).
  ShopFloor floorAt(int index) {
    if (index == 0) {
      return ShopFloor(
        name: groundFloorName ?? '',
        rows: rows,
        cols: cols,
        entrance: entrance,
        exit: exit,
        cells: cells,
        subcells: subcells,
      );
    }
    return additionalFloors[index - 1];
  }

  /// All floors as [ShopFloor] views.
  List<ShopFloor> get allFloors => [floorAt(0), ...additionalFloors];

  // ---------------------------------------------------------------------------
  // Grid helpers
  // ---------------------------------------------------------------------------

  /// Find which cell contains a given item tag (case-insensitive, partial match).
  /// Searches the ground floor first, then additional floors.
  /// Returns a base cell id for routing (floor-agnostic).
  String? findCell(String item) {
    final found = findCellWithFloor(item);
    return found?.$2;
  }

  /// Find which floor and cell contains [item]. Returns null if not found.
  ///
  /// Uses a two-pass strategy so an exact match on any floor beats a broad
  /// partial match on the ground floor:
  ///   Pass 1 — exact (case-insensitive) match across all floors.
  ///   Pass 2 — partial match across all floors (ground floor first).
  (int floor, String cell)? findCellWithFloor(String item) {
    final q = item.toLowerCase().trim();
    final extra = additionalFloors;

    // ── Pass 1: exact match ───────────────────────────────────────────────
    for (final entry in cells.entries) {
      for (final tag in entry.value) {
        if (tag.toLowerCase() == q) return (0, entry.key);
      }
    }
    for (final entry in subcells.entries) {
      for (final tag in entry.value) {
        if (tag.toLowerCase() == q) return (0, entry.key.split(':').first);
      }
    }
    for (var fi = 0; fi < extra.length; fi++) {
      for (final entry in extra[fi].cells.entries) {
        for (final tag in entry.value) {
          if (tag.toLowerCase() == q) return (fi + 1, entry.key);
        }
      }
      for (final entry in extra[fi].subcells.entries) {
        for (final tag in entry.value) {
          if (tag.toLowerCase() == q) return (fi + 1, entry.key.split(':').first);
        }
      }
    }

    // ── Pass 2: partial match (ground floor first) ────────────────────────
    for (final entry in cells.entries) {
      for (final tag in entry.value) {
        final t = tag.toLowerCase();
        if (t.contains(q) || q.contains(t)) return (0, entry.key);
      }
    }
    for (final entry in subcells.entries) {
      for (final tag in entry.value) {
        final t = tag.toLowerCase();
        if (t.contains(q) || q.contains(t)) return (0, entry.key.split(':').first);
      }
    }
    for (var fi = 0; fi < extra.length; fi++) {
      final cell = extra[fi].findCell(item);
      if (cell != null) return (fi + 1, cell);
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Split helpers
  // ---------------------------------------------------------------------------

  /// Whether [cellId] has a draft split.
  bool isSplit(String cellId) =>
      subcells.keys.any((k) => k.startsWith('$cellId:'));

  /// Returns "row" or "col" for a split cell, or null if not split.
  String? splitAxis(String cellId) {
    final key =
        subcells.keys.where((k) => k.startsWith('$cellId:')).firstOrNull;
    if (key == null) return null;
    return key.split(':')[1];
  }

  /// Returns the two subcell keys for [cellId] sorted as [":0", ":1"].
  List<String> subcellKeysOf(String cellId) =>
      subcells.keys.where((k) => k.startsWith('$cellId:')).toList()..sort();

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'rows': rows,
        'cols': cols,
        'entrance': entrance,
        'exit': exit,
        'cells': cells.map((k, v) => MapEntry(k, List<String>.from(v))),
        if (address != null) 'address': address,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (parentId != null) 'parentId': parentId,
        if (subcells.isNotEmpty)
          'subcells':
              subcells.map((k, v) => MapEntry(k, List<String>.from(v))),
        if (osmCategory != null) 'osmCategory': osmCategory,
        if (floorsRaw != null && floorsRaw!.isNotEmpty)
          'floors': additionalFloors.map((f) => f.toMap()).toList(),
        if (groundFloorName != null) 'groundFloorName': groundFloorName,
      };

  factory Supermarket.fromMap(Map<String, dynamic> m) => Supermarket(
        id: m['id'] as String,
        name: m['name'] as String,
        rows: List<String>.from(m['rows'] as List),
        cols: List<String>.from(m['cols'] as List),
        entrance: m['entrance'] as String,
        exit: m['exit'] as String,
        cells: (m['cells'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        ),
        address: m['address'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        parentId: m['parentId'] as String?,
        subcells: m['subcells'] != null
            ? (m['subcells'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, List<String>.from(v as List)),
              )
            : null,
        osmCategory: m['osmCategory'] as String?,
        floorsRaw: m['floors'] != null ? (m['floors'] as List).toList() : null,
        groundFloorName: m['groundFloorName'] as String?,
      );

  Supermarket copyWith({
    String? name,
    List<String>? rows,
    List<String>? cols,
    String? entrance,
    String? exit,
    Map<String, List<String>>? cells,
    Map<String, List<String>>? subcells,
    Object? address = _sentinel,
    Object? lat = _sentinel,
    Object? lng = _sentinel,
    Object? parentId = _sentinel,
    Object? osmCategory = _sentinel,
    Object? floorsRaw = _sentinel,
    Object? groundFloorName = _sentinel,
  }) =>
      Supermarket(
        id: id,
        name: name ?? this.name,
        rows: rows ?? this.rows,
        cols: cols ?? this.cols,
        entrance: entrance ?? this.entrance,
        exit: exit ?? this.exit,
        cells: cells ?? this.cells,
        subcells: subcells ?? this.subcells,
        address: address == _sentinel ? this.address : address as String?,
        lat: lat == _sentinel ? this.lat : lat as double?,
        lng: lng == _sentinel ? this.lng : lng as double?,
        parentId: parentId == _sentinel ? this.parentId : parentId as String?,
        osmCategory: osmCategory == _sentinel ? this.osmCategory : osmCategory as String?,
        floorsRaw: floorsRaw == _sentinel ? this.floorsRaw : floorsRaw as List<dynamic>?,
        groundFloorName: groundFloorName == _sentinel ? this.groundFloorName : groundFloorName as String?,
      );
}

const _sentinel = Object();
