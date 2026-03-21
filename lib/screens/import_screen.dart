import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

import '../models/shopping_list.dart';
import '../services/text_parser.dart';
import '../providers/supermarket_provider.dart';
import '../providers/shopping_list_provider.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final TextEditingController _ctrl = TextEditingController();
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final l = AppLocalizations.of(context)!;
    final result = TextParser.parse(_ctrl.text);
    if (!result.hasContent) {
      setState(() { _error = l.importError; _success = false; });
      return;
    }

    // Import shops
    for (final s in result.supermarkets) {
      ref.read(supermarketsProvider.notifier).add(s);
    }

    // Import lists — ask for each whether to create new or append
    for (final list in result.shoppingLists) {
      final allStores = ref.read(supermarketsProvider);
      final resolvedIds = list.preferredStoreIds.map((name) {
        try {
          return allStores.firstWhere((s) => s.name.toLowerCase() == name.toLowerCase()).id;
        } catch (_) { return null; }
      }).whereType<String>().toList();
      final resolved = list.copyWith(preferredStoreIds: resolvedIds);

      final existingLists = ref.read(shoppingListsProvider);
      if (existingLists.isNotEmpty && mounted) {
        final choice = await _askAppendOrNew(resolved, existingLists, l);
        if (!mounted) return;
        if (choice == null) continue; // cancelled
        if (choice == _ImportChoice.asNew) {
          ref.read(shoppingListsProvider.notifier).add(resolved);
        } else if (choice is _AppendChoice) {
          final target = choice.target;
          final merged = target.copyWith(items: [...target.items, ...resolved.items]);
          ref.read(shoppingListsProvider.notifier).update(merged);
        }
      } else {
        ref.read(shoppingListsProvider.notifier).add(resolved);
      }
    }

    setState(() { _error = null; _success = true; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.pop(context);
  }

  Future<dynamic> _askAppendOrNew(
    ShoppingList incoming,
    List<ShoppingList> existing,
    AppLocalizations l,
  ) {
    return showDialog<dynamic>(
      context: context,
      builder: (dialogContext) {
        ShoppingList? selected;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(incoming.name.isNotEmpty ? incoming.name : l.newList),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appendToExisting, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<ShoppingList>(
                  isExpanded: true,
                  hint: Text(l.selectList),
                  value: selected,
                  items: existing.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name.isNotEmpty ? e.name : '—'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selected = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, _ImportChoice.asNew),
                child: Text(l.importAsNew),
              ),
              ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () => Navigator.pop(dialogContext, _AppendChoice(selected!)),
                child: Text(l.appendToExisting),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.importTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: l.importHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_success)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l.importSuccess, style: const TextStyle(color: Colors.green)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.file_download_outlined),
                label: Text(l.importAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ImportChoice { asNew }

class _AppendChoice {
  final ShoppingList target;
  const _AppendChoice(this.target);
}
