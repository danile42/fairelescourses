/// A single floor's grid data within a multi-floor shop.
/// Mirrors the grid fields of [Supermarket] (rows, cols, entrance, exit,
/// cells, subcells) so the planner can treat each floor independently.
class ShopFloor {
  /// User-visible label (e.g. "Basement"). Empty = use l10n default.
  String name;
  List<String> rows;
  List<String> cols;
  String entrance;
  String exit;
  Map<String, List<String>> cells;
  Map<String, List<String>> subcells;

  ShopFloor({
    required this.name,
    required this.rows,
    required this.cols,
    required this.entrance,
    required this.exit,
    Map<String, List<String>>? cells,
    Map<String, List<String>>? subcells,
  }) : cells = cells ?? {},
       subcells = subcells ?? {};

  // ── Grid helpers (same logic as Supermarket) ──────────────────────────────

  List<String> get allCells => [
    for (final r in rows)
      for (final c in cols) '$r$c',
  ];

  int? distance(String a, String b) {
    final posA = _cellPos(a);
    final posB = _cellPos(b);
    if (posA == null || posB == null) return null;
    return (posA.$1 - posB.$1).abs() + (posA.$2 - posB.$2).abs();
  }

  /// Returns true when [a] and [b] are within the same 3×3 square —
  /// i.e. Chebyshev distance == 1 (includes diagonals).
  bool isNeighbour(String a, String b) {
    final posA = _cellPos(a);
    final posB = _cellPos(b);
    if (posA == null || posB == null) return false;
    final dr = (posA.$1 - posB.$1).abs();
    final dc = (posA.$2 - posB.$2).abs();
    return dr <= 1 && dc <= 1 && (dr + dc) > 0;
  }

  (int, int)? _cellPos(String cellId) {
    for (var ri = 0; ri < rows.length; ri++) {
      for (var ci = 0; ci < cols.length; ci++) {
        if ('${rows[ri]}${cols[ci]}' == cellId) return (ri, ci);
      }
    }
    return null;
  }

  /// Find which cell contains [item] using the same 3-pass strategy as
  /// [Supermarket.findCellWithFloor]: exact → all-words → substring.
  String? findCell(String item) {
    final q = item.toLowerCase().trim();

    // Pass 1: exact match
    for (final entry in cells.entries) {
      for (final tag in entry.value) {
        if (tag.toLowerCase() == q) return entry.key;
      }
    }
    for (final entry in subcells.entries) {
      for (final tag in entry.value) {
        if (tag.toLowerCase() == q) return entry.key.split(':').first;
      }
    }

    // Pass 2: all-words match
    final words = q.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length > 1) {
      for (final entry in cells.entries) {
        for (final tag in entry.value) {
          final t = tag.toLowerCase();
          if (words.every((w) => t.contains(w))) return entry.key;
        }
      }
      for (final entry in subcells.entries) {
        for (final tag in entry.value) {
          final t = tag.toLowerCase();
          if (words.every((w) => t.contains(w))) {
            return entry.key.split(':').first;
          }
        }
      }
    }

    // Pass 3: substring match
    for (final entry in cells.entries) {
      for (final tag in entry.value) {
        final t = tag.toLowerCase();
        if (t.contains(q) || q.contains(t)) return entry.key;
      }
    }
    for (final entry in subcells.entries) {
      for (final tag in entry.value) {
        final t = tag.toLowerCase();
        if (t.contains(q) || q.contains(t)) return entry.key.split(':').first;
      }
    }

    return null;
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'name': name,
    'rows': rows,
    'cols': cols,
    'entrance': entrance,
    'exit': exit,
    'cells': cells.map((k, v) => MapEntry(k, List<String>.from(v))),
    if (subcells.isNotEmpty)
      'subcells': subcells.map((k, v) => MapEntry(k, List<String>.from(v))),
  };

  factory ShopFloor.fromMap(Map m) => ShopFloor(
    name: (m['name'] as String?) ?? '',
    rows: List<String>.from(m['rows'] as List),
    cols: List<String>.from(m['cols'] as List),
    entrance: m['entrance'] as String,
    exit: m['exit'] as String,
    cells: (m['cells'] as Map).map(
      (k, v) => MapEntry(k as String, List<String>.from(v as List)),
    ),
    subcells: m['subcells'] != null
        ? (m['subcells'] as Map).map(
            (k, v) => MapEntry(k as String, List<String>.from(v as List)),
          )
        : null,
  );
}
