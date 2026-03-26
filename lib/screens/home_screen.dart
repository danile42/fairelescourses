import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

import '../models/nav_session.dart';
import '../models/shopping_list.dart';
import '../providers/firestore_sync_provider.dart';
import '../providers/home_location_provider.dart';
import '../providers/household_provider.dart';
import '../providers/nav_session_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/supermarket_provider.dart';
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

    final session = ref.watch(navSessionProvider);

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
        body: Column(
          children: [
            if (session.hasValue && session.value != null)
              _JoinBanner(session: session.value!, lists: lists),
            Expanded(
              child: TabBarView(
                children: [
                  _ListsTab(lists: lists),
                  _StoresTab(stores: stores),
                ],
              ),
            ),
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

class _ListsTab extends ConsumerStatefulWidget {
  final List<ShoppingList> lists;
  const _ListsTab({required this.lists});

  @override
  ConsumerState<_ListsTab> createState() => _ListsTabState();
}

class _ListsTabState extends ConsumerState<_ListsTab> {
  final Set<String> _selectedIds = {};

  bool get _selecting => _selectedIds.isNotEmpty;

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _cancelSelection() => setState(() => _selectedIds.clear());

  Future<void> _showMergeDialog() async {
    final l = AppLocalizations.of(context)!;
    final selected = widget.lists.where((l) => _selectedIds.contains(l.id)).toList();
    final targetId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.mergeTargetTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.mergeTargetSubtitle,
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 12),
            ...selected.map((list) => ListTile(
                  title: Text(list.name.isEmpty ? '—' : list.name),
                  subtitle: Text('${list.items.length} items'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.pop(ctx, list.id),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
    if (targetId == null || !mounted) return;
    await ref
        .read(shoppingListsProvider.notifier)
        .merge(_selectedIds.toList(), targetId);
    if (mounted) setState(() => _selectedIds.clear());
  }

  void _startNavigation(ShoppingList list) {
    final hid = ref.read(householdProvider);
    if (hid == null) {
      _launchNavigation(list, collaborative: false);
    } else {
      _showModePicker(list);
    }
  }

  void _showModePicker(ShoppingList list) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l.navModeTitle,
                style: Theme.of(ctx).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l.navModeSingle),
            subtitle: Text(l.navModeSingleDesc),
            onTap: () {
              Navigator.pop(ctx);
              _launchNavigation(list, collaborative: false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: Text(l.navModeCollaborative),
            subtitle: Text(l.navModeCollaborativeDesc),
            onTap: () {
              Navigator.pop(ctx);
              _launchNavigation(list, collaborative: true);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _launchNavigation(ShoppingList list, {required bool collaborative}) {
    final stores = ref.read(supermarketsProvider);
    final plan = NavigationPlanner.plan(list, stores);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          plan: plan,
          listId: list.id,
          isCollaborative: collaborative,
          isHost: collaborative,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final l = AppLocalizations.of(context)!;
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
    if (ok == true && mounted) ref.read(shoppingListsProvider.notifier).remove(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lists = widget.lists;

    if (lists.isEmpty) {
      return Center(
          child: Text(l.noLists,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: lists.length,
            itemBuilder: (context, i) {
              final list = lists[i];
              final isSelected = _selectedIds.contains(list.id);
              return Card(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: _selecting
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelect(list.id),
                        )
                      : const Icon(Icons.shopping_cart_outlined),
                  title: Text(list.name.isEmpty ? '—' : list.name),
                  subtitle: Text('${list.checkedCount}/${list.items.length}'),
                  trailing: _selecting
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              tooltip: l.generatePlan,
                              onPressed: () => _startNavigation(list),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _confirmDelete(list.id, list.name),
                            ),
                          ],
                        ),
                  onTap: _selecting
                      ? () => _toggleSelect(list.id)
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ListEditorScreen(list: list, isNew: false)),
                          ),
                  onLongPress: _selecting
                      ? null
                      : () => _toggleSelect(list.id),
                ),
              );
            },
          ),
        ),
        if (_selecting)
          _MergeBar(
            selectedCount: _selectedIds.length,
            onMerge: _selectedIds.length >= 2 ? _showMergeDialog : null,
            onCancel: _cancelSelection,
          ),
      ],
    );
  }
}

class _JoinBanner extends ConsumerWidget {
  final NavSession session;
  final List<ShoppingList> lists;
  const _JoinBanner({required this.session, required this.lists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final list = lists.where((e) => e.id == session.listId).firstOrNull;
    final listName =
        list == null ? '?' : (list.name.isEmpty ? '—' : list.name);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.group, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${l.navCollaborativeActive} · $listName',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: list == null
                  ? null
                  : () {
                      final stores = ref.read(supermarketsProvider);
                      final plan = NavigationPlanner.plan(list, stores);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NavigationScreen(
                            plan: plan,
                            listId: list.id,
                            isCollaborative: true,
                            isHost: false,
                          ),
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact),
              child: Text(l.navJoin),
            ),
          ],
        ),
      ),
    );
  }
}

class _MergeBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onMerge;
  final VoidCallback onCancel;

  const _MergeBar({
    required this.selectedCount,
    required this.onMerge,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              l.mergeListsSelected(selectedCount),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(onPressed: onCancel, child: Text(l.cancel)),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onMerge,
              icon: const Icon(Icons.merge, size: 18),
              label: Text(l.mergeLists),
            ),
          ],
        ),
      ),
    );
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

