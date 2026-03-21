import 'package:hive/hive.dart';

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
    this.ownerUid,
  });

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

  /// Find which cell contains a given item tag (case-insensitive, partial match).
  String? findCell(String item) {
    final q = item.toLowerCase().trim();
    for (final entry in cells.entries) {
      for (final tag in entry.value) {
        if (tag.toLowerCase().contains(q) || q.contains(tag.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return null;
  }

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
      );

  Supermarket copyWith({
    String? name,
    List<String>? rows,
    List<String>? cols,
    String? entrance,
    String? exit,
    Map<String, List<String>>? cells,
    Object? address = _sentinel,
    Object? lat = _sentinel,
    Object? lng = _sentinel,
  }) =>
      Supermarket(
        id: id,
        name: name ?? this.name,
        rows: rows ?? this.rows,
        cols: cols ?? this.cols,
        entrance: entrance ?? this.entrance,
        exit: exit ?? this.exit,
        cells: cells ?? this.cells,
        address: address == _sentinel ? this.address : address as String?,
        lat: lat == _sentinel ? this.lat : lat as double?,
        lng: lng == _sentinel ? this.lng : lng as double?,
      );
}

const _sentinel = Object();
