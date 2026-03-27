import 'package:flutter_test/flutter_test.dart';
import 'package:fairelescourses/models/shopping_list.dart';

void main() {
  // ── ShoppingItem ──────────────────────────────────────────────────────────

  group('ShoppingItem', () {
    test('default checked is false', () {
      final item = ShoppingItem(name: 'Milk');
      expect(item.checked, isFalse);
    });

    test('copyWith name', () {
      final item = ShoppingItem(name: 'Milk', checked: true);
      final copy = item.copyWith(name: 'Bread');
      expect(copy.name, 'Bread');
      expect(copy.checked, isTrue);
    });

    test('copyWith checked', () {
      final item = ShoppingItem(name: 'Milk');
      final copy = item.copyWith(checked: true);
      expect(copy.name, 'Milk');
      expect(copy.checked, isTrue);
    });

    test('toMap / fromMap roundtrip', () {
      final item = ShoppingItem(name: 'Eggs', checked: true);
      final map = item.toMap();
      final restored = ShoppingItem.fromMap(map);
      expect(restored.name, item.name);
      expect(restored.checked, item.checked);
    });

    test('fromMap defaults checked to false when missing', () {
      final item = ShoppingItem.fromMap({'name': 'Butter'});
      expect(item.checked, isFalse);
    });
  });

  // ── ShoppingList ──────────────────────────────────────────────────────────

  group('ShoppingList', () {
    ShoppingList makeList({List<ShoppingItem>? items}) => ShoppingList(
          id: 'list-1',
          name: 'Weekly',
          preferredStoreIds: ['s1'],
          items: items ??
              [
                ShoppingItem(name: 'Milk'),
                ShoppingItem(name: 'Bread', checked: true),
                ShoppingItem(name: 'Eggs', checked: true),
              ],
        );

    test('checkedCount counts only checked items', () {
      expect(makeList().checkedCount, 2);
    });

    test('checkedCount is 0 for empty list', () {
      expect(makeList(items: []).checkedCount, 0);
    });

    test('checkedCount is 0 when none checked', () {
      final list = makeList(
          items: [ShoppingItem(name: 'A'), ShoppingItem(name: 'B')]);
      expect(list.checkedCount, 0);
    });

    test('copyWith preserves id', () {
      final list = makeList();
      final copy = list.copyWith(name: 'Renamed');
      expect(copy.id, list.id);
      expect(copy.name, 'Renamed');
    });

    test('copyWith items replaces list', () {
      final list = makeList();
      final copy = list.copyWith(items: [ShoppingItem(name: 'X')]);
      expect(copy.items.length, 1);
      expect(copy.items.first.name, 'X');
    });

    test('toMap / fromMap roundtrip', () {
      final list = makeList();
      final map = list.toMap();
      final restored = ShoppingList.fromMap(map);
      expect(restored.id, list.id);
      expect(restored.name, list.name);
      expect(restored.preferredStoreIds, list.preferredStoreIds);
      expect(restored.items.length, list.items.length);
      expect(restored.items[1].checked, isTrue);
    });

    test('fromMap tolerates missing preferredStoreIds', () {
      final map = {
        'id': 'x',
        'name': 'Test',
        'items': <dynamic>[],
      };
      final list = ShoppingList.fromMap(map);
      expect(list.preferredStoreIds, isEmpty);
    });

    test('fromMap tolerates missing items', () {
      final map = {
        'id': 'x',
        'name': 'Test',
        'preferredStoreIds': <dynamic>[],
      };
      final list = ShoppingList.fromMap(map);
      expect(list.items, isEmpty);
    });
  });
}
