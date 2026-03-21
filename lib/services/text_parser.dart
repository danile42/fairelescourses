import '../models/supermarket.dart';
import '../models/shopping_list.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Result of parsing a pasted text block.
class ParseResult {
  final List<Supermarket> supermarkets;
  final List<ShoppingList> shoppingLists;
  final List<String> errors;

  const ParseResult({
    required this.supermarkets,
    required this.shoppingLists,
    required this.errors,
  });

  bool get hasContent => supermarkets.isNotEmpty || shoppingLists.isNotEmpty;
}

class TextParser {
  /// Parse a free-form text that may contain one or more SHOP or LIST blocks.
  static ParseResult parse(String text) {
    final supermarkets = <Supermarket>[];
    final lists = <ShoppingList>[];
    final errors = <String>[];

    final lines = text.split('\n').map((l) => l.trim()).toList();
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      if (line.toUpperCase().startsWith('SHOP:')) {
        final result = _parseSupermarket(lines, i);
        if (result.value != null) supermarkets.add(result.value!);
        if (result.error != null) errors.add(result.error!);
        i = result.nextLine;
      } else if (line.toUpperCase().startsWith('LIST:')) {
        final result = _parseList(lines, i);
        if (result.value != null) lists.add(result.value!);
        if (result.error != null) errors.add(result.error!);
        i = result.nextLine;
      } else {
        i++;
      }
    }

    return ParseResult(supermarkets: supermarkets, shoppingLists: lists, errors: errors);
  }

  static _ParsedBlock<Supermarket> _parseSupermarket(List<String> lines, int start) {
    try {
      final name = lines[start].substring('SHOP:'.length).trim();
      if (name.isEmpty) return _ParsedBlock(error: 'SHOP: name missing', nextLine: start + 1);

      List<String> rows = [];
      List<String> cols = [];
      String entrance = '';
      String exit = '';
      final cells = <String, List<String>>{};

      int i = start + 1;
      while (i < lines.length) {
        final line = lines[i];
        if (_isBlockStart(line)) break;
        if (line.isEmpty) { i++; continue; }

        final upper = line.toUpperCase();
        if (upper.startsWith('ROWS:')) {
          rows = line.substring('ROWS:'.length).trim().split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
        } else if (upper.startsWith('COLS:')) {
          cols = line.substring('COLS:'.length).trim().split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
        } else if (upper.startsWith('ENTRANCE:')) {
          entrance = line.substring('ENTRANCE:'.length).trim().toUpperCase();
        } else if (upper.startsWith('EXIT:')) {
          exit = line.substring('EXIT:'.length).trim().toUpperCase();
        } else if (line.contains(':')) {
          final colonIdx = line.indexOf(':');
          final cellId = line.substring(0, colonIdx).trim().toUpperCase();
          final goods = line
              .substring(colonIdx + 1)
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (goods.isNotEmpty) cells[cellId] = goods;
        }
        i++;
      }

      if (rows.isEmpty || cols.isEmpty) {
        return _ParsedBlock(error: 'Shop "$name": ROWS or COLS missing', nextLine: i);
      }
      if (entrance.isEmpty) entrance = '${rows.first}${cols.first}';
      if (exit.isEmpty) exit = '${rows.last}${cols.last}';

      return _ParsedBlock(
        value: Supermarket(
          id: _uuid.v4(),
          name: name,
          rows: rows,
          cols: cols,
          entrance: entrance,
          exit: exit,
          cells: cells,
        ),
        nextLine: i,
      );
    } catch (e) {
      return _ParsedBlock(error: 'Error parsing shop: $e', nextLine: start + 1);
    }
  }

  static _ParsedBlock<ShoppingList> _parseList(List<String> lines, int start) {
    try {
      final name = lines[start].substring('LIST:'.length).trim();
      if (name.isEmpty) return _ParsedBlock(error: 'LIST: name missing', nextLine: start + 1);

      List<String> storeNames = [];
      final items = <ShoppingItem>[];

      int i = start + 1;
      while (i < lines.length) {
        final line = lines[i];
        if (_isBlockStart(line)) break;
        if (line.isEmpty) { i++; continue; }

        final upper = line.toUpperCase();
        if (upper.startsWith('STORES:')) {
          storeNames = line
              .substring('STORES:'.length)
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } else {
          // strip leading "- " or "* "
          final itemName = line.replaceFirst(RegExp(r'^[-*]\s*'), '').trim();
          if (itemName.isNotEmpty) items.add(ShoppingItem(name: itemName));
        }
        i++;
      }

      return _ParsedBlock(
        value: ShoppingList(
          id: _uuid.v4(),
          name: name,
          preferredStoreIds: storeNames, // names; caller resolves to IDs
          items: items,
        ),
        nextLine: i,
      );
    } catch (e) {
      return _ParsedBlock(error: 'Error parsing list: $e', nextLine: start + 1);
    }
  }

  static bool _isBlockStart(String line) {
    final u = line.toUpperCase();
    return u.startsWith('SHOP:') || u.startsWith('LIST:');
  }

  // ── Export ──────────────────────────────────────────────────────────────────

  static String exportSupermarket(Supermarket s) {
    final buf = StringBuffer();
    buf.writeln('SHOP: ${s.name}');
    buf.writeln('ROWS: ${s.rows.join(' ')}');
    buf.writeln('COLS: ${s.cols.join(' ')}');
    buf.writeln('ENTRANCE: ${s.entrance}');
    buf.writeln('EXIT: ${s.exit}');
    buf.writeln();
    for (final cell in s.allCells) {
      final goods = s.cells[cell];
      if (goods != null && goods.isNotEmpty) {
        buf.writeln('$cell: ${goods.join(', ')}');
      }
    }
    return buf.toString().trimRight();
  }

  static String exportShoppingList(ShoppingList l, {List<String> storeNames = const []}) {
    final buf = StringBuffer();
    buf.writeln('LIST: ${l.name}');
    if (storeNames.isNotEmpty) buf.writeln('STORES: ${storeNames.join(', ')}');
    buf.writeln();
    for (final item in l.items) {
      buf.writeln('- ${item.name}');
    }
    return buf.toString().trimRight();
  }
}

class _ParsedBlock<T> {
  final T? value;
  final String? error;
  final int nextLine;
  const _ParsedBlock({this.value, this.error, required this.nextLine});
}
