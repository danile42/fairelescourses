import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

import '../providers/home_location_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/supermarket_provider.dart';
import '../providers/firestore_sync_provider.dart';
import '../providers/household_provider.dart';
import '../models/shopping_list.dart';
import 'list_editor_screen.dart';
import 'osm_shops_screen.dart';
import 'store_editor_screen.dart';
import 'navigation_screen.dart';
import 'sync_screen.dart';
import 'shop_search_screen.dart';
import '../services/navigation_planner.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lists = ref.watch(shoppingListsProvider);
    final stores = ref.watch(supermarketsProvider);
    final hid = ref.watch(householdProvider);
    ref.watch(firestoreSyncProvider); // activates real-time sync

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.appTitle),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l.searchShops,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopSearchScreen()),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.sync,
                color: hid != null ? Colors.white : Colors.white54,
              ),
              tooltip: l.syncTitle,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncScreen()),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: l.homeTitle),
              Tab(text: l.shops),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ListsTab(lists: lists),
            _StoresTab(stores: stores),
          ],
        ),
        floatingActionButton: _HomeFab(lists: lists),
      ),
    );
  }
}

class _HomeFab extends ConsumerStatefulWidget {
  final List<dynamic> lists;
  const _HomeFab({required this.lists});

  @override
  ConsumerState<_HomeFab> createState() => _HomeFabState();
}

class _HomeFabState extends ConsumerState<_HomeFab> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final homeLoc = ref.watch(homeLocationProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_expanded) ...[
          _MiniButton(
            label: l.findNearby,
            icon: Icons.location_searching,
            onTap: () {
              setState(() => _expanded = false);
              if (homeLoc == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.setLocationFirst)));
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OsmShopsScreen(
                    lat: homeLoc.lat,
                    lng: homeLoc.lng,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _MiniButton(
            label: l.newShop,
            icon: Icons.store,
            onTap: () {
              setState(() => _expanded = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreEditorScreen()));
            },
          ),
          const SizedBox(height: 8),
          _MiniButton(
            label: l.newList,
            icon: Icons.list_alt,
            onTap: () {
              setState(() => _expanded = false);
              final newList = ShoppingList(
                id: _uuid.v4(),
                name: '',
                preferredStoreIds: [],
                items: [],
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ListEditorScreen(list: newList, isNew: true)),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MiniButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(label),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}

class _ListsTab extends ConsumerWidget {
  final List<ShoppingList> lists;
  const _ListsTab({required this.lists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    if (lists.isEmpty) {
      return Center(child: Text(l.noLists, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: lists.length,
      itemBuilder: (context, i) {
        final list = lists[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: Text(list.name.isEmpty ? '—' : list.name),
            subtitle: Text('${list.checkedCount}/${list.items.length}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: l.generatePlan,
                  onPressed: () {
                    final stores = ref.read(supermarketsProvider);
                    final plan = NavigationPlanner.plan(list, stores);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NavigationScreen(plan: plan, listId: list.id),
                    ));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, list.id, list.name, l),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ListEditorScreen(list: list, isNew: false)),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id, String name, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteConfirm(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l.no)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l.yes)),
        ],
      ),
    );
    if (ok == true) ref.read(shoppingListsProvider.notifier).remove(id);
  }
}

class _StoresTab extends ConsumerWidget {
  final List<dynamic> stores;
  const _StoresTab({required this.stores});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    if (stores.isEmpty) {
      return Center(child: Text(l.noShops, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)));
    }
    final currentUid = ref.watch(currentUidProvider);
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: stores.length,
      itemBuilder: (context, i) {
        final store = stores[i];
        // ownerUid == null means local-only (no household) — always editable.
        final isOwned = store.ownerUid == null || store.ownerUid == currentUid;
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.store_outlined,
              color: isOwned ? null : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(store.name),
            subtitle: Text('${store.rows.length}×${store.cols.length}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOwned) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ref, store.id, store.name, l),
                  ),
                ],
              ],
            ),
            onTap: isOwned
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StoreEditorScreen(existing: store)),
                    )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id, String name, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteConfirm(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l.no)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l.yes)),
        ],
      ),
    );
    if (ok == true) ref.read(supermarketsProvider.notifier).remove(id);
  }
}

