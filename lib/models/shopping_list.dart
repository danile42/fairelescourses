import 'package:hive/hive.dart';

part 'shopping_list.g.dart';

@HiveType(typeId: 1)
class ShoppingItem {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool checked;

  ShoppingItem({required this.name, this.checked = false});

  ShoppingItem copyWith({String? name, bool? checked}) =>
      ShoppingItem(name: name ?? this.name, checked: checked ?? this.checked);

  Map<String, dynamic> toMap() => {'name': name, 'checked': checked};

  factory ShoppingItem.fromMap(Map<String, dynamic> m) =>
      ShoppingItem(name: m['name'] as String, checked: (m['checked'] as bool?) ?? false);
}

@HiveType(typeId: 2)
class ShoppingList extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> preferredStoreIds;

  @HiveField(3)
  List<ShoppingItem> items;

  ShoppingList({
    required this.id,
    required this.name,
    required this.preferredStoreIds,
    required this.items,
  });

  int get checkedCount => items.where((i) => i.checked).length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'preferredStoreIds': preferredStoreIds,
        'items': items.map((i) => i.toMap()).toList(),
      };

  factory ShoppingList.fromMap(Map<String, dynamic> m) => ShoppingList(
        id: m['id'] as String,
        name: m['name'] as String,
        preferredStoreIds: List<String>.from(m['preferredStoreIds'] as List? ?? []),
        items: (m['items'] as List? ?? [])
            .map((i) => ShoppingItem.fromMap(i as Map<String, dynamic>))
            .toList(),
      );

  ShoppingList copyWith({
    String? name,
    List<String>? preferredStoreIds,
    List<ShoppingItem>? items,
  }) =>
      ShoppingList(
        id: id,
        name: name ?? this.name,
        preferredStoreIds: preferredStoreIds ?? this.preferredStoreIds,
        items: items ?? this.items,
      );
}
