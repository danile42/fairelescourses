import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../models/navigation_plan.dart';
import '../models/shopping_list.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/mini_map.dart';
import 'list_editor_screen.dart';

const _uuid = Uuid();

class NavigationScreen extends StatefulWidget {
  final NavigationPlan plan;
  final String listId;

  const NavigationScreen({super.key, required this.plan, required this.listId});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late List<Set<String>> _checkedPerStore; // checked item names per store plan
  int _storeIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkedPerStore = List.generate(widget.plan.storePlans.length, (_) => {});
  }

  StorePlan get _currentPlan => widget.plan.storePlans[_storeIndex];

  int get _checkedCount => _checkedPerStore[_storeIndex].length;
  int get _totalCount => _currentPlan.totalItems;

  void _toggleItem(String item) {
    setState(() {
      final set = _checkedPerStore[_storeIndex];
      if (set.contains(item)) {
        set.remove(item);
      } else {
        set.add(item);
      }
    });
  }

  bool _isChecked(String item) => _checkedPerStore[_storeIndex].contains(item);

  String? get _currentCell {
    for (final stop in _currentPlan.stops) {
      if (stop.items.any((i) => !_isChecked(i))) return stop.cell;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final plan = widget.plan;

    if (plan.storePlans.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l.navigationTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(l.unmatched, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              ...plan.globalUnmatched.map((i) => Text('• $i')),
            ],
          ),
        ),
      );
    }

    final storePlan = _currentPlan;
    final allDone = _checkedCount >= _totalCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navigationTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: plan.storePlans.length > 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _StoreTabs(
                  plans: plan.storePlans,
                  currentIndex: _storeIndex,
                  onTap: (i) => setState(() => _storeIndex = i),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _totalCount == 0 ? 1.0 : _checkedCount / _totalCount,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.store_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(storePlan.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(l.progress(_checkedCount, _totalCount)),
              ],
            ),
          ),
          // Mini map
          MiniMap(
            storePlan: storePlan,
            currentCell: _currentCell,
            checkedItems: _checkedPerStore[_storeIndex],
          ),
          const Divider(height: 1),
          // Stop list
          Expanded(
            child: allDone
                ? _DoneView(
                    plan: plan,
                    storeIndex: _storeIndex,
                    onNextShop: () => setState(() => _storeIndex++),
                  )
                : ListView.builder(
                    itemCount: storePlan.stops.length,
                    itemBuilder: (context, i) {
                      final stop = storePlan.stops[i];
                      final allStopDone = stop.items.every(_isChecked);
                      final isCurrent = stop.cell == _currentCell;
                      return AnimatedOpacity(
                        opacity: allStopDone ? 0.4 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          color: isCurrent ? Theme.of(context).colorScheme.primaryContainer : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6, right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(stop.cell,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: stop.items.map((item) => SizedBox(
                                      height: 32,
                                      child: CheckboxListTile(
                                        dense: true,
                                        visualDensity: VisualDensity.compact,
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        value: _isChecked(item),
                                        title: Text(item,
                                          style: TextStyle(
                                            fontSize: 13,
                                            decoration: _isChecked(item) ? TextDecoration.lineThrough : null,
                                            color: _isChecked(item) ? Colors.grey : null,
                                          ),
                                        ),
                                        onChanged: (_) => _toggleItem(item),
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StoreTabs extends StatelessWidget {
  final List<StorePlan> plans;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _StoreTabs({required this.plans, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: List.generate(plans.length, (i) {
          final selected = i == currentIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(plans[i].storeName),
              selected: selected,
              onSelected: (_) => onTap(i),
              selectedColor: Colors.white,
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(100),
              labelStyle: TextStyle(color: selected ? Theme.of(context).colorScheme.primary : Colors.white),
            ),
          );
        }),
      ),
    );
  }
}

class _DoneView extends ConsumerWidget {
  final NavigationPlan plan;
  final int storeIndex;
  final VoidCallback onNextShop;

  const _DoneView({required this.plan, required this.storeIndex, required this.onNextShop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final isLastShop = storeIndex >= plan.storePlans.length - 1;
    final unmatched = {
      ...plan.globalUnmatched,
      ...plan.storePlans.expand((s) => s.unmatched),
    }.toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            Text(l.allItemsChecked, style: const TextStyle(fontSize: 18)),
            if (!isLastShop) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onNextShop,
                child: Text(l.nextShop),
              ),
            ] else ...[
              if (unmatched.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${l.unmatched}: ${unmatched.join(', ')}',
                          style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: Text(l.finish),
                  ),
                  if (unmatched.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        final newList = ShoppingList(
                          id: _uuid.v4(),
                          name: '',
                          preferredStoreIds: [],
                          items: unmatched.map((n) => ShoppingItem(name: n)).toList(),
                        );
                        ref.read(shoppingListsProvider.notifier).add(newList);
                        Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => ListEditorScreen(list: newList, isNew: false)));
                      },
                      icon: const Icon(Icons.list_alt),
                      label: Text(l.newList),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

