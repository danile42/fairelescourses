import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/shopping_list.dart';
import '../models/supermarket.dart';
import '../providers/household_provider.dart';
import '../providers/nav_session_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/supermarket_provider.dart';
import '../services/navigation_planner.dart';
import 'navigation_screen.dart';
import 'shop_search_screen.dart';
import 'store_editor_screen.dart';
import '../widgets/tour_hint_banner.dart';

enum _ExitAction { save, discard }

enum _ItemAction { rename, delete, move, assign }

class ListEditorScreen extends ConsumerStatefulWidget {
  final ShoppingList list;
  final bool isNew;

  const ListEditorScreen({super.key, required this.list, required this.isNew});

  @override
  ConsumerState<ListEditorScreen> createState() => _ListEditorScreenState();
}

class _ListEditorScreenState extends ConsumerState<ListEditorScreen> {
  late final TextEditingController _nameCtrl;
  late List<ShoppingItem> _items;
  late List<String> _preferredStoreIds;
  bool _dirty = false;
  bool _pendingItemText = false;
  final _barKey = GlobalKey<_AddItemBarState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.list.name);
    _items = List<ShoppingItem>.from(widget.list.items);
    _preferredStoreIds = List<String>.from(widget.list.preferredStoreIds);
    _nameCtrl.addListener(() => setState(() => _dirty = true));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    _barKey.currentState?.submitCurrent();
    final updated = widget.list.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim(),
      items: _items,
      preferredStoreIds: _preferredStoreIds,
    );
    final notifier = ref.read(shoppingListsProvider.notifier);
    if (widget.isNew) {
      notifier.add(updated);
    } else {
      notifier.update(updated);
    }
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<_ExitAction?> _confirmUnsaved() async {
    final l = AppLocalizations.of(context)!;
    return showDialog<_ExitAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l.unsavedChanges),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _ExitAction.discard),
            child: Text(l.discardChanges),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _ExitAction.save),
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  Box<String> get _categoryBox => Hive.box<String>('item_categories');

  String? _lookupCategory(String name) =>
      _categoryBox.get(name.toLowerCase().trim());

  void _saveCategory(String name, String? category) {
    final key = name.toLowerCase().trim();
    if (key.isEmpty) return;
    if (category != null && category.isNotEmpty) {
      _categoryBox.put(key, category);
    }
  }

  void _addItem(String name) {
    if (name.isEmpty) return;
    final category = _lookupCategory(name);
    final addedItem = ShoppingItem(name: name, category: category);
    setState(() {
      _dirty = true;
      _items = [..._items, addedItem];
    });
    _offerAssignIfUnmatched(addedItem);
  }

  bool _isItemAvailableInAnyStore(ShoppingItem item, List<Supermarket> stores) {
    return stores.any(
      (store) =>
          store.findCell(item.name, category: item.category?.trim()) != null,
    );
  }

  void _offerAssignIfUnmatched(ShoppingItem item) {
    if (!mounted) return;
    final stores = ref.read(supermarketsProvider);
    if (_isItemAvailableInAnyStore(item, stores)) return;
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${l.unmatched}: ${item.name}'),
          action: SnackBarAction(
            label: l.assignToShop,
            onPressed: () => unawaited(_showShopPicker(item.name)),
          ),
        ),
      );
  }

  Future<void> _showShopPicker(String item) async {
    final l = AppLocalizations.of(context)!;
    final shops = ref.read(supermarketsProvider);

    const searchSentinel = _SearchSentinel();
    final result = await showDialog<Object>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.whichShopForItem(item)),
        children: [
          ...shops.map(
            (shop) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, shop),
              child: Text(shop.name),
            ),
          ),
          if (shops.isNotEmpty) const Divider(height: 1),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, searchSentinel),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18),
                const SizedBox(width: 8),
                Text(l.searchShops),
              ],
            ),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;

    if (result is _SearchSentinel) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ShopSearchScreen(focusItem: item)),
      );
    } else if (result is Supermarket) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StoreEditorScreen(existing: result, focusItems: [item]),
        ),
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _dirty = true;
      _items = [..._items]..removeAt(index);
    });
  }

  Future<void> _moveItemToList(int index) async {
    final l = AppLocalizations.of(context)!;
    final allLists = ref.read(shoppingListsProvider);
    final targets = allLists.where((lst) => lst.id != widget.list.id).toList();
    if (targets.isEmpty) return;

    final target = await showDialog<ShoppingList>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.moveToList),
        children: targets
            .map(
              (lst) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, lst),
                child: Text(lst.name),
              ),
            )
            .toList(),
      ),
    );
    if (target == null || !mounted) return;

    final item = _items[index];
    setState(() {
      _dirty = true;
      _items = [..._items]..removeAt(index);
    });
    ref
        .read(shoppingListsProvider.notifier)
        .update(target.copyWith(items: [...target.items, item]));
  }

  Future<void> _editItem(int index, List<String> suggestions) async {
    final l = AppLocalizations.of(context)!;
    final item = _items[index];
    final ctrl = TextEditingController(text: item.name);
    String? pendingName = item.name;
    // Pre-fill category from memory if the item doesn't already have one.
    String? pendingCategory = item.category ?? _lookupCategory(item.name);
    // catCtrl is intentionally not disposed — see project gotcha on dialog controllers.
    final catCtrl = TextEditingController(text: pendingCategory ?? '');
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              initialValue: TextEditingValue(text: item.name),
              optionsBuilder: (tv) {
                if (tv.text.trim().isEmpty) return const [];
                final q = tv.text.toLowerCase();
                return suggestions
                    .where((s) => s.toLowerCase().contains(q))
                    .take(8);
              },
              onSelected: (value) {
                pendingName = value;
                final looked = _lookupCategory(value);
                Navigator.pop(dialogContext, (
                  value,
                  looked ?? pendingCategory,
                ));
              },
              fieldViewBuilder: (ctx, autoCtrl, focusNode, onFieldSubmitted) {
                ctrl.dispose(); // dispose our local ctrl; use the one Autocomplete creates
                return TextField(
                  controller: autoCtrl,
                  focusNode: focusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => pendingName = v,
                  onSubmitted: (_) => Navigator.pop(dialogContext, (
                    pendingName,
                    pendingCategory,
                  )),
                  textInputAction: TextInputAction.next,
                );
              },
              optionsViewBuilder: (ctx, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 280,
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: options
                          .map(
                            (o) => ListTile(
                              dense: true,
                              title: Text(o),
                              onTap: () => onSelected(o),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catCtrl,
              decoration: InputDecoration(
                labelText: l.itemCategory,
                hintText: l.itemCategoryHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  pendingCategory = v.trim().isEmpty ? null : v.trim(),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) =>
                  Navigator.pop(dialogContext, (pendingName, pendingCategory)),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, (pendingName, pendingCategory)),
            child: Text(AppLocalizations.of(dialogContext)!.save),
          ),
        ],
      ),
    );
    if (result == null) return;
    final (newName, newCategory) = result;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    _saveCategory(trimmed, newCategory);
    setState(() {
      _dirty = true;
      _items = [..._items];
      _items[index] = item.copyWith(
        name: trimmed,
        category: newCategory?.isEmpty ?? true ? null : newCategory,
      );
    });
  }

  static const _singleNavKey = 'singleNavActive';

  bool get _navModeSeen =>
      Hive.box<String>('settings').get('navModeSeen') == 'true';

  bool get _singleNavActive =>
      Hive.box<String>('settings').get(_singleNavKey) == 'true';

  void _startNav({required bool collaborative}) {
    final stores = ref.read(supermarketsProvider);
    final list = widget.list.copyWith(
      items: _items,
      preferredStoreIds: _preferredStoreIds,
    );
    final plan = NavigationPlanner.plan(list, stores);
    if (!collaborative) {
      Hive.box<String>('settings').put(_singleNavKey, 'true');
      setState(() {});
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          plan: plan,
          listId: widget.list.id,
          isCollaborative: collaborative,
          isHost: collaborative,
        ),
      ),
    ).then((_) {
      if (!collaborative && mounted) {
        Hive.box<String>('settings').delete(_singleNavKey);
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stores = ref.watch(supermarketsProvider);
    final suggestions =
        stores
            .expand((s) => s.cells.values.expand((goods) => goods))
            .map((g) => g.trim())
            .where((g) => g.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final existingNames = _items.map((i) => i.name.toLowerCase()).toSet();
    final addBarSuggestions = suggestions
        .where((s) => !existingNames.contains(s.toLowerCase()))
        .toList();

    return PopScope(
      canPop: !_dirty && !_pendingItemText,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final action = await _confirmUnsaved();
        if (!mounted) return;
        if (action == _ExitAction.save) {
          _save();
        } else if (action == _ExitAction.discard) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.listEditor),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _save,
              child: Text(l.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        bottomNavigationBar: TourHintBanner(
          visibleOnStep: 1,
          message: (l) => l.tourListEditorHint,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: l.listName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (stores.isNotEmpty)
                    _StoreSelector(
                      stores: stores,
                      selectedIds: _preferredStoreIds,
                      onChanged: (ids) => setState(() {
                        _dirty = true;
                        _preferredStoreIds = ids;
                      }),
                      label: l.preferredShops,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        l.noItemsInList,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _items.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          _dirty = true;
                          if (newIndex > oldIndex) newIndex--;
                          final item = _items.removeAt(oldIndex);
                          _items.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        final isAvailableInAnyStore =
                            _isItemAvailableInAnyStore(item, stores);
                        final otherLists = ref
                            .read(shoppingListsProvider)
                            .where((lst) => lst.id != widget.list.id)
                            .isNotEmpty;
                        return ListTile(
                          key: ValueKey(i),
                          leading: Checkbox(
                            value: item.checked,
                            onChanged: null,
                          ),
                          title: Text(
                            item.name,
                            style: item.checked
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          subtitle: item.category != null
                              ? Text(
                                  item.category!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
                          onTap: () => _editItem(i, suggestions),
                          trailing: PopupMenuButton<_ItemAction>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            padding: EdgeInsets.zero,
                            onSelected: (action) {
                              if (action == _ItemAction.rename) {
                                _editItem(i, suggestions);
                              } else if (action == _ItemAction.delete) {
                                _removeItem(i);
                              } else if (action == _ItemAction.move) {
                                _moveItemToList(i);
                              } else {
                                _showShopPicker(item.name);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: _ItemAction.rename,
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 16),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(ctx)!.rename),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: _ItemAction.delete,
                                child: Row(
                                  children: [
                                    const Icon(Icons.close, size: 16),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(ctx)!.delete),
                                  ],
                                ),
                              ),
                              if (otherLists)
                                PopupMenuItem(
                                  value: _ItemAction.move,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.drive_file_move_outline,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(ctx)!.moveToList,
                                      ),
                                    ],
                                  ),
                                ),
                              if (!isAvailableInAnyStore)
                                PopupMenuItem(
                                  value: _ItemAction.assign,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.store_outlined,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(ctx)!.assignToShop,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            _AddItemBar(
              key: _barKey,
              suggestions: addBarSuggestions,
              onAdd: _addItem,
              label: l.addItem,
              hint: l.itemHint,
              onPendingChanged: (hasPending) =>
                  setState(() => _pendingItemText = hasPending),
            ),
            if (_items.isNotEmpty)
              Builder(
                builder: (context) {
                  final hid = ref.watch(householdProvider);
                  final showTwo = hid != null && _navModeSeen;
                  final hasActiveCollab =
                      ref.watch(navSessionProvider).asData?.value != null;
                  final bottomInset = MediaQuery.of(context).padding.bottom;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
                    child: showTwo
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l.startShopping),
                              IconButton(
                                icon: const _NavIcon(Icons.person_outline),
                                tooltip: l.navModeSingle,
                                onPressed: hasActiveCollab
                                    ? null
                                    : () => _startNav(collaborative: false),
                              ),
                              IconButton(
                                icon: const _NavIcon(Icons.group_outlined),
                                tooltip: l.navModeCollaborative,
                                onPressed: hasActiveCollab || _singleNavActive
                                    ? null
                                    : () => _startNav(collaborative: true),
                              ),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: hasActiveCollab
                                  ? null
                                  : () => _startNav(collaborative: false),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(l.startNavigation),
                            ),
                          ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData base;
  const _NavIcon(this.base);

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        children: [
          Icon(base, size: 22, color: color),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow, size: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemBar extends StatefulWidget {
  final List<String> suggestions;
  final void Function(String name) onAdd;
  final String label;
  final String hint;
  final ValueChanged<bool>? onPendingChanged;

  const _AddItemBar({
    super.key,
    required this.suggestions,
    required this.onAdd,
    required this.label,
    required this.hint,
    this.onPendingChanged,
  });

  @override
  State<_AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<_AddItemBar> {
  TextEditingController? _autoCtrl;

  void submitCurrent() => _submit(_autoCtrl?.text ?? '');

  void _submit(String value) {
    final name = value.trim();
    if (name.isEmpty) return;
    widget.onAdd(name);
    // Autocomplete fills the field with the selected text on selection,
    // so clear it on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _autoCtrl?.clear();
        widget.onPendingChanged?.call(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Autocomplete<String>(
          optionsBuilder: (tv) {
            if (tv.text.trim().isEmpty) return const [];
            final q = tv.text.toLowerCase();
            return widget.suggestions
                .where((s) => s.toLowerCase().contains(q))
                .take(8);
          },
          onSelected: (value) => _submit(value),
          fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
            if (_autoCtrl != ctrl) {
              _autoCtrl = ctrl;
              ctrl.addListener(() {
                widget.onPendingChanged?.call(ctrl.text.trim().isNotEmpty);
              });
            }
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      labelText: widget.label,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (v) => _submit(v),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _submit(_autoCtrl?.text ?? ''),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StoreSelector extends StatelessWidget {
  final List<Supermarket> stores;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final String label;

  const _StoreSelector({
    required this.stores,
    required this.selectedIds,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: stores.map((s) {
            final selected = selectedIds.contains(s.id);
            return FilterChip(
              label: Text(s.name),
              selected: selected,
              onSelected: (val) {
                final ids = [...selectedIds];
                if (val) {
                  ids.add(s.id);
                } else {
                  ids.remove(s.id);
                }
                onChanged(ids);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SearchSentinel {
  const _SearchSentinel();
}
