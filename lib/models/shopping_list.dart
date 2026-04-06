import 'package:hive_ce/hive_ce.dart';

part 'shopping_list.g.dart';

@HiveType(typeId: 1)
class ShoppingItem {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool checked;

  /// Optional category used as a fallback when matching items to shop cells.
  /// e.g. "Dairy" lets the item match any cell tagged "Dairy".
  @HiveField(2)
  String? category;

  ShoppingItem({required this.name, this.checked = false, this.category});

  ShoppingItem copyWith({
    String? name,
    bool? checked,
    Object? category = _sentinel,
  }) => ShoppingItem(
    name: name ?? this.name,
    checked: checked ?? this.checked,
    category: identical(category, _sentinel)
        ? this.category
        : category as String?,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'checked': checked,
    if (category != null) 'category': category,
  };

  factory ShoppingItem.fromMap(Map<String, dynamic> m) => ShoppingItem(
    name: m['name'] as String,
    checked: (m['checked'] as bool?) ?? false,
    category: m['category'] as String?,
  );
}

const _sentinel = Object();

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
  }) => ShoppingList(
    id: id,
    name: name ?? this.name,
    preferredStoreIds: preferredStoreIds ?? this.preferredStoreIds,
    items: items ?? this.items,
  );
}
