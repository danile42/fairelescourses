import 'package:flutter_test/flutter_test.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/models/shop_floor.dart';

Supermarket makeStore({
  List<String> rows = const ['A', 'B', 'C'],
  List<String> cols = const ['1', '2', '3'],
  String entrance = 'A1',
  String exit = 'C3',
  Map<String, List<String>> cells = const {},
  Map<String, List<String>> subcells = const {},
}) =>
    Supermarket(
      id: 'store-1',
      name: 'Test Store',
      rows: rows,
      cols: cols,
      entrance: entrance,
      exit: exit,
      cells: Map.from(cells),
      subcells: Map.from(subcells),
    );

void main() {
  group('allCells', () {
    test('generates row × col cross product in order', () {
      final s = makeStore(rows: ['A', 'B'], cols: ['1', '2']);
      expect(s.allCells, ['A1', 'A2', 'B1', 'B2']);
    });

    test('single cell grid', () {
      final s = makeStore(rows: ['A'], cols: ['1']);
      expect(s.allCells, ['A1']);
    });
  });

  group('distance', () {
    test('same cell is 0', () {
      final s = makeStore();
      expect(s.distance('A1', 'A1'), 0);
    });

    test('adjacent column is 1', () {
      final s = makeStore();
      expect(s.distance('A1', 'A2'), 1);
    });

    test('adjacent row is 1', () {
      final s = makeStore();
      expect(s.distance('A1', 'B1'), 1);
    });

    test('diagonal is 2', () {
      final s = makeStore();
      expect(s.distance('A1', 'B2'), 2);
    });

    test('far corner is 4 on 3×3 grid', () {
      final s = makeStore();
      expect(s.distance('A1', 'C3'), 4);
    });

    test('invalid cell a returns null', () {
      final s = makeStore();
      expect(s.distance('Z9', 'A1'), isNull);
    });

    test('invalid cell b returns null', () {
      final s = makeStore();
      expect(s.distance('A1', 'Z9'), isNull);
    });

    test('both invalid returns null', () {
      final s = makeStore();
      expect(s.distance('X0', 'Y0'), isNull);
    });
  });

  group('findCell', () {
    test('exact match returns cell', () {
      final s = makeStore(cells: {
        'A1': ['Milk', 'Dairy'],
      });
      expect(s.findCell('Milk'), 'A1');
    });

    test('case-insensitive match', () {
      final s = makeStore(cells: {
        'B2': ['Bread'],
      });
      expect(s.findCell('bread'), 'B2');
      expect(s.findCell('BREAD'), 'B2');
    });

    test('partial match: query contains tag', () {
      final s = makeStore(cells: {
        'C3': ['Organic Milk'],
      });
      // tag.contains(query) path: "Organic Milk".contains("milk") → true (via toLowerCase)
      expect(s.findCell('organic milk'), 'C3');
    });

    test('partial match: tag contains query', () {
      final s = makeStore(cells: {
        'A2': ['Sparkling Water'],
      });
      expect(s.findCell('water'), 'A2');
    });

    test('not found returns null', () {
      final s = makeStore(cells: {'A1': ['Bread']});
      expect(s.findCell('Fish'), isNull);
    });

    test('empty cells returns null', () {
      final s = makeStore();
      expect(s.findCell('Anything'), isNull);
    });

    test('subcell lookup returns base cell id', () {
      final s = makeStore(subcells: {
        'B2:col:0': ['Cheese'],
        'B2:col:1': ['Butter'],
      });
      expect(s.findCell('Cheese'), 'B2');
      expect(s.findCell('Butter'), 'B2');
    });

    test('cell match takes priority over subcell', () {
      final s = makeStore(
        cells: {'A1': ['Milk']},
        subcells: {'B2:col:0': ['Milk']},
      );
      expect(s.findCell('Milk'), 'A1');
    });
  });

  group('split helpers', () {
    test('isSplit returns true when subcell key exists', () {
      final s = makeStore(subcells: {'B2:col:0': [], 'B2:col:1': []});
      expect(s.isSplit('B2'), isTrue);
      expect(s.isSplit('A1'), isFalse);
    });

    test('splitAxis returns col', () {
      final s = makeStore(subcells: {'B2:col:0': [], 'B2:col:1': []});
      expect(s.splitAxis('B2'), 'col');
    });

    test('splitAxis returns row', () {
      final s = makeStore(subcells: {'C1:row:0': [], 'C1:row:1': []});
      expect(s.splitAxis('C1'), 'row');
    });

    test('splitAxis returns null for unsplit cell', () {
      final s = makeStore();
      expect(s.splitAxis('A1'), isNull);
    });

    test('subcellKeysOf returns sorted keys', () {
      final s = makeStore(subcells: {'B2:col:1': [], 'B2:col:0': []});
      expect(s.subcellKeysOf('B2'), ['B2:col:0', 'B2:col:1']);
    });
  });

  group('serialization', () {
    test('toMap / fromMap roundtrip', () {
      final s = makeStore(
        cells: {'A1': ['Bread', 'Bakery']},
        subcells: {'B2:col:0': ['Cheese']},
      );
      final restored = Supermarket.fromMap(s.toMap());
      expect(restored.id, s.id);
      expect(restored.rows, s.rows);
      expect(restored.cols, s.cols);
      expect(restored.entrance, s.entrance);
      expect(restored.exit, s.exit);
      expect(restored.cells['A1'], ['Bread', 'Bakery']);
      expect(restored.subcells['B2:col:0'], ['Cheese']);
    });

    test('fromMap tolerates missing subcells', () {
      final map = {
        'id': 'x',
        'name': 'X',
        'rows': ['A'],
        'cols': ['1'],
        'entrance': 'A1',
        'exit': 'A1',
        'cells': <String, dynamic>{},
      };
      final s = Supermarket.fromMap(map);
      expect(s.subcells, isEmpty);
    });

    test('optional fields survive null roundtrip', () {
      final s = makeStore();
      expect(s.address, isNull);
      expect(s.lat, isNull);
      expect(s.lng, isNull);
      expect(s.parentId, isNull);
      final restored = Supermarket.fromMap(s.toMap());
      expect(restored.address, isNull);
      expect(restored.lat, isNull);
    });

    test('optional fields survive non-null roundtrip', () {
      final s = Supermarket(
        id: 'x', name: 'X',
        rows: ['A'], cols: ['1'],
        entrance: 'A1', exit: 'A1',
        cells: {}, address: '123 Main St',
        lat: 48.1, lng: 11.5, parentId: 'pid',
      );
      final restored = Supermarket.fromMap(s.toMap());
      expect(restored.address, '123 Main St');
      expect(restored.lat, 48.1);
      expect(restored.lng, 11.5);
      expect(restored.parentId, 'pid');
    });
  });

  group('multi-floor', () {
    ShopFloor _floor1({Map<String, List<String>>? cells}) => ShopFloor(
          name: 'Upper',
          rows: ['A', 'B'],
          cols: ['1', '2'],
          entrance: 'A1',
          exit: 'B2',
          cells: cells ?? {},
        );

    test('single-floor store has no additionalFloors', () {
      final s = makeStore();
      expect(s.additionalFloors, isEmpty);
      expect(s.allFloors.length, 1);
    });

    test('floorAt(0) returns ground floor data', () {
      final s = makeStore(
        rows: ['A', 'B'],
        cols: ['1', '2'],
        entrance: 'A1',
        exit: 'B2',
        cells: {'A1': ['Milk']},
      );
      final f = s.floorAt(0);
      expect(f.rows, ['A', 'B']);
      expect(f.entrance, 'A1');
      expect(f.cells['A1'], ['Milk']);
    });

    test('additionalFloors setter and getter roundtrip', () {
      final s = makeStore();
      s.additionalFloors = [_floor1()];
      expect(s.additionalFloors.length, 1);
      expect(s.additionalFloors.first.name, 'Upper');
      expect(s.allFloors.length, 2);
    });

    test('floorAt(1) returns first additional floor', () {
      final s = makeStore();
      s.additionalFloors = [_floor1(cells: {'B1': ['Books']})];
      final f = s.floorAt(1);
      expect(f.name, 'Upper');
      expect(f.cells['B1'], ['Books']);
    });

    test('findCellWithFloor returns (0, cell) for ground-floor item', () {
      final s = makeStore(cells: {'A1': ['Milk']});
      expect(s.findCellWithFloor('Milk'), (0, 'A1'));
    });

    test('findCellWithFloor returns (1, cell) for upper-floor item', () {
      final s = makeStore();
      s.additionalFloors = [_floor1(cells: {'B2': ['Cheese']})];
      expect(s.findCellWithFloor('Cheese'), (1, 'B2'));
    });

    test('exact match on floor 1 wins over partial match on floor 0', () {
      // "Brot" is on floor 0; "Brotaufstrich" is on floor 1.
      // Query "Brotaufstrich" should match floor 1 exactly,
      // not floor 0 via the partial-match ("Brot" contained in query).
      final s = makeStore(cells: {'A1': ['Brot']});
      s.additionalFloors = [_floor1(cells: {'A2': ['Brotaufstrich']})];
      final result = s.findCellWithFloor('Brotaufstrich');
      expect(result?.$1, 1);
      expect(result?.$2, 'A2');
    });

    test('findCellWithFloor returns null when item not on any floor', () {
      final s = makeStore(cells: {'A1': ['Milk']});
      s.additionalFloors = [_floor1(cells: {'B2': ['Cheese']})];
      expect(s.findCellWithFloor('Fish'), isNull);
    });

    test('toMap / fromMap roundtrip preserves additional floors', () {
      final s = makeStore(cells: {'A1': ['Milk']});
      s.additionalFloors = [_floor1(cells: {'B2': ['Electronics']})];
      final restored = Supermarket.fromMap(s.toMap());
      expect(restored.additionalFloors.length, 1);
      expect(restored.additionalFloors.first.name, 'Upper');
      expect(restored.additionalFloors.first.cells['B2'], ['Electronics']);
    });

    test('fromMap with no floors produces empty additionalFloors', () {
      final s = makeStore();
      final restored = Supermarket.fromMap(s.toMap());
      expect(restored.additionalFloors, isEmpty);
    });
  });
}
