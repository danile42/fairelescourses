import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

import '../models/shopping_list.dart';
import '../models/supermarket.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/supermarket_provider.dart';
import '../services/text_parser.dart';
import '../services/share_service.dart';
import '../services/navigation_planner.dart';
import 'navigation_screen.dart';

enum _ExitAction { save, discard }

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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l.keepEditing)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, _ExitAction.discard), child: Text(l.discardChanges)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, _ExitAction.save), child: Text(l.save)),
        ],
      ),
    );
  }

  void _addItem(String name) {
    if (name.isEmpty) return;
    setState(() {
      _dirty = true;
      _items = [..._items, ShoppingItem(name: name)];
    });
  }

  void _removeItem(int index) {
    setState(() {
      _dirty = true;
      _items = [..._items]..removeAt(index);
    });
  }

  void _toggleItem(int index) {
    setState(() {
      _dirty = true;
      _items = [..._items];
      _items[index] = _items[index].copyWith(checked: !_items[index].checked);
    });
  }

  void _generatePlan(BuildContext context) {
    final stores = ref.read(supermarketsProvider);
    final list = widget.list.copyWith(
      items: _items,
      preferredStoreIds: _preferredStoreIds,
    );
    final plan = NavigationPlanner.plan(list, stores);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NavigationScreen(plan: plan, listId: widget.list.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stores = ref.watch(supermarketsProvider);
    final suggestions = stores
        .expand((s) => s.cells.values.expand((goods) => goods))
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return PopScope(
      canPop: !_dirty,
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
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final storeNames = _preferredStoreIds
                  .map((id) => stores.firstWhere((s) => s.id == id, orElse: () => stores.first).name)
                  .toList();
              shareText(TextParser.exportShoppingList(
                widget.list.copyWith(items: _items),
                storeNames: storeNames,
              ));
            },
          ),
          TextButton(
            onPressed: _save,
            child: Text(l.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: l.listName, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                if (stores.isNotEmpty)
                  _StoreSelector(
                    stores: stores,
                    selectedIds: _preferredStoreIds,
                    onChanged: (ids) => setState(() { _dirty = true; _preferredStoreIds = ids; }),
                    label: l.preferredShops,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _items.isEmpty
                ? Center(child: Text(l.noItemsInList, style: const TextStyle(color: Colors.grey)))
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
                      return ListTile(
                        key: ValueKey(i),
                        leading: Checkbox(
                          value: item.checked,
                          onChanged: (_) => _toggleItem(i),
                        ),
                        title: Text(
                          item.name,
                          style: item.checked
                              ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                              : null,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _removeItem(i),
                        ),
                      );
                    },
                  ),
          ),
          _AddItemBar(suggestions: suggestions, onAdd: _addItem, label: l.addItem, hint: l.itemHint),
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _generatePlan(context),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l.generatePlan),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _AddItemBar extends StatefulWidget {
  final List<String> suggestions;
  final void Function(String name) onAdd;
  final String label;
  final String hint;

  const _AddItemBar({
    required this.suggestions,
    required this.onAdd,
    required this.label,
    required this.hint,
  });

  @override
  State<_AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<_AddItemBar> {
  TextEditingController? _autoCtrl;

  void _submit(String value) {
    final name = value.trim();
    if (name.isEmpty) return;
    widget.onAdd(name);
    // Autocomplete fills the field with the selected text on selection,
    // so clear it on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _autoCtrl?.clear();
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
            _autoCtrl = ctrl;
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
