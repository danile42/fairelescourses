import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/nav_session.dart';
import '../models/shopping_list.dart';
import '../providers/firestore_sync_provider.dart';
import '../providers/household_provider.dart';
import '../providers/nav_session_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/supermarket_provider.dart';
import '../providers/sync_error_provider.dart';
import '../providers/tour_provider.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/tour_spotlight.dart';
import 'help_screen.dart';
import 'list_editor_screen.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = Hive.box<String>('settings');
      if (box.get(helpSeenKey) != 'true' && ref.read(tourStepProvider) >= 0) {
        box.put(helpSeenKey, 'true');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpScreen()),
        );
      }
    });
  }

  void _openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lists = ref.watch(shoppingListsProvider);
    final stores = ref.watch(supermarketsProvider);
    ref.watch(householdProvider);
    ref.watch(firestoreSyncProvider); // activates real-time sync

    final session = ref.watch(navSessionProvider);

    // Auto-advance tour steps based on app state.
    ref.listen(supermarketsProvider, (_, next) {
      if (next.isNotEmpty) ref.read(tourStepProvider.notifier).advance(0);
    });
    ref.listen(shoppingListsProvider, (_, next) {
      if (next.isNotEmpty) ref.read(tourStepProvider.notifier).advance(1);
    });

    // Show a snackbar when a background Firestore sync write fails.
    ref.listen(syncErrorProvider, (_, error) {
      if (error == null || !mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.syncError)));
      ref.read(syncErrorProvider.notifier).clear();
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/icon.png', height: 28, width: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Text(l.appTitle, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: l.helpTitle,
              onPressed: _openHelp,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l.searchShops,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopSearchScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              tooltip: l.configTitle,
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
            const TourSpotlight(),
            const CelebrationOverlay(),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_expanded) ...[
          _MiniButton(
            fabKey: tourNewShopKey,
            label: l.newShop,
            icon: Icons.store,
            onTap: () {
              setState(() => _expanded = false);
              ref.read(tourFabExpandedProvider.notifier).set(false);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopSearchScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _MiniButton(
            fabKey: tourNewListKey,
            label: l.newList,
            icon: Icons.list_alt,
            onTap: () {
              setState(() => _expanded = false);
              ref.read(tourFabExpandedProvider.notifier).set(false);
              final newList = ShoppingList(
                id: _uuid.v4(),
                name: '',
                preferredStoreIds: [],
                items: [],
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListEditorScreen(list: newList, isNew: true),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          key: tourFabKey,
          onPressed: () {
            final next = !_expanded;
            setState(() => _expanded = next);
            ref.read(tourFabExpandedProvider.notifier).set(next);
          },
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
  final Key? fabKey;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MiniButton({
    this.fabKey,
    required this.label,
    required this.icon,
    required this.onTap,
  });

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
          key: fabKey,
          heroTag: label,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? bodyWidget;
  final List<Widget> actions;

  const _EmptyState({
    required this.icon,
    required this.title,
    this.body = '',
    this.bodyWidget,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (bodyWidget != null)
              bodyWidget!
            else
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 28),
            ...actions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(width: double.infinity, child: a),
              ),
            ),
          ],
        ),
      ),
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
    final selected = widget.lists
        .where((l) => _selectedIds.contains(l.id))
        .toList();
    final targetId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.mergeTargetTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.mergeTargetSubtitle,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...selected.map(
              (list) => ListTile(
                title: Text(list.name.isEmpty ? '—' : list.name),
                subtitle: Text('${list.items.length} items'),
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.pop(ctx, list.id),
              ),
            ),
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

  bool get _navModeSeen =>
      Hive.box<String>('settings').get('navModeSeen') == 'true';

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
    final hasActiveCollabSession =
        ref.read(navSessionProvider).asData?.value != null;
    // Mark as seen so that after this the two buttons appear directly.
    Hive.box<String>('settings').put('navModeSeen', 'true');
    setState(() {});
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l.navModeTitle,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const _NavIcon(Icons.person_outline),
            title: Text(l.navModeSingle),
            subtitle: Text(l.navModeSingleDesc),
            enabled: !hasActiveCollabSession,
            onTap: hasActiveCollabSession
                ? null
                : () {
                    Navigator.pop(ctx);
                    _launchNavigation(list, collaborative: false);
                  },
          ),
          ListTile(
            leading: const _NavIcon(Icons.group_outlined),
            title: Text(l.navModeCollaborative),
            subtitle: Text(l.navModeCollaborativeDesc),
            enabled: !hasActiveCollabSession && !_singleNavActive,
            onTap: hasActiveCollabSession || _singleNavActive
                ? null
                : () {
                    Navigator.pop(ctx);
                    _launchNavigation(list, collaborative: true);
                  },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const _singleNavKey = 'singleNavActive';

  bool get _singleNavActive =>
      Hive.box<String>('settings').get(_singleNavKey) == 'true';

  void _launchNavigation(ShoppingList list, {required bool collaborative}) {
    final isTourFinalStep = ref.read(tourStepProvider) == 2;
    if (isTourFinalStep) {
      ref.read(tourStepProvider.notifier).complete();
    }
    final stores = ref.read(supermarketsProvider);
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
          listId: list.id,
          isCollaborative: collaborative,
          isHost: collaborative,
        ),
      ),
    ).then((result) {
      if (isTourFinalStep && result == true && mounted) {
        ref.read(celebrationTriggerProvider.notifier).trigger();
      }
      if (!collaborative && mounted) {
        Hive.box<String>('settings').delete(_singleNavKey);
        setState(() {});
      }
    });
  }

  Future<void> _confirmDelete(String id, String name) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.yes),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(shoppingListsProvider.notifier).remove(id);
      final session = ref.read(navSessionProvider).asData?.value;
      if (session != null && session.listId == id) {
        final hid = ref.read(householdProvider);
        if (hid != null) {
          ref
              .read(firestoreServiceProvider)
              .deleteNavSession(hid)
              .catchError(
                (Object e) =>
                    debugPrint('Firestore deleteNavSession error: $e'),
              )
              .ignore();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lists = widget.lists;
    final hid = ref.watch(householdProvider);
    final showTwoNavButtons = hid != null && _navModeSeen;
    final activeSession = ref.watch(navSessionProvider).asData?.value;
    final hasActiveCollabSession = activeSession != null;

    if (lists.isEmpty) {
      final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
      return _EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: l.emptyListsTitle,
        bodyWidget: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${l.emptyListsBodyBefore} ', style: bodyStyle),
            IconButton(
              icon: const _NavIcon(Icons.person_outline),
              tooltip: l.navModeSingle,
              onPressed: null,
            ),
            Text(' ${l.emptyListsBodyOr} ', style: bodyStyle),
            IconButton(
              icon: const _NavIcon(Icons.group_outlined),
              tooltip: l.navModeCollaborative,
              onPressed: null,
            ),
            Text(' ${l.emptyListsBodyAfter}', style: bodyStyle),
          ],
        ),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l.emptyListsCreate),
            onPressed: () {
              final newList = ShoppingList(
                id: _uuid.v4(),
                name: '',
                preferredStoreIds: [],
                items: [],
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListEditorScreen(list: newList, isNew: true),
                ),
              );
            },
          ),
        ],
      );
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
              final isSessionList = activeSession?.listId == list.id;
              final inProgress =
                  !_selecting &&
                  list.checkedCount > 0 &&
                  list.checkedCount < list.items.length;
              return Card(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: _selecting
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelect(list.id),
                            )
                          : const Icon(Icons.shopping_cart_outlined),
                      title: Text(list.name.isEmpty ? '—' : list.name),
                      subtitle: Text(
                        '${list.checkedCount}/${list.items.length}',
                      ),
                      trailing: _selecting
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showTwoNavButtons) ...[
                                  IconButton(
                                    icon: const _NavIcon(Icons.person_outline),
                                    tooltip: l.navModeSingle,
                                    onPressed: hasActiveCollabSession
                                        ? null
                                        : () => _launchNavigation(
                                            list,
                                            collaborative: false,
                                          ),
                                  ),
                                  IconButton(
                                    icon: const _NavIcon(Icons.group_outlined),
                                    tooltip: l.navModeCollaborative,
                                    onPressed:
                                        hasActiveCollabSession ||
                                            _singleNavActive
                                        ? null
                                        : () => _launchNavigation(
                                            list,
                                            collaborative: true,
                                          ),
                                  ),
                                ] else
                                  IconButton(
                                    key: i == 0 ? tourPlayKey : null,
                                    icon: const Icon(Icons.play_arrow),
                                    tooltip: l.generatePlan,
                                    onPressed: hasActiveCollabSession
                                        ? null
                                        : () => _startNavigation(list),
                                  ),
                                PopupMenuButton<String>(
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'copy',
                                      child: ListTile(
                                        leading: const Icon(Icons.content_copy),
                                        title: Text(l.copyList),
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      enabled: !isSessionList,
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.delete_outline,
                                          color: isSessionList
                                              ? Colors.grey
                                              : null,
                                        ),
                                        title: Text(
                                          l.delete,
                                          style: isSessionList
                                              ? const TextStyle(
                                                  color: Colors.grey,
                                                )
                                              : null,
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'copy') {
                                      ref
                                          .read(shoppingListsProvider.notifier)
                                          .copy(list.id)
                                          .ignore();
                                    } else if (value == 'delete') {
                                      _confirmDelete(list.id, list.name);
                                    }
                                  },
                                ),
                              ],
                            ),
                      onTap: _selecting
                          ? () => _toggleSelect(list.id)
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ListEditorScreen(list: list, isNew: false),
                              ),
                            ),
                      onLongPress: _selecting
                          ? null
                          : () => _toggleSelect(list.id),
                    ),
                    if (inProgress)
                      LinearProgressIndicator(
                        value: list.checkedCount / list.items.length,
                        minHeight: 3,
                      ),
                  ],
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
    final listName = list == null ? '?' : (list.name.isEmpty ? '—' : list.name);
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
                '$listName · ${l.navCollaborativeActive}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: list == null
                  ? null
                  : () {
                      final uid = ref.read(currentUidProvider);
                      final isHost = session.startedBy == uid;
                      final stores = ref.read(supermarketsProvider);
                      final plan = NavigationPlanner.plan(list, stores);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NavigationScreen(
                            plan: plan,
                            listId: list.id,
                            isCollaborative: true,
                            isHost: isHost,
                          ),
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
      return _EmptyState(
        icon: Icons.store_outlined,
        title: l.emptyShopsTitle,
        body: l.emptyShopsBody,
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l.emptyShopsCreate),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoreEditorScreen()),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(l.emptyShopsFind),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopSearchScreen()),
            ),
          ),
        ],
      );
    }
    final currentUid = ref.watch(currentUidProvider);
    final inHousehold = ref.watch(householdProvider) != null;
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: stores.length,
      itemBuilder: (context, i) {
        final store = stores[i];
        // All household shops are editable by any household member.
        // Without a household, only the creator may edit/delete.
        final canEdit =
            inHousehold ||
            store.ownerUid == null ||
            store.ownerUid == currentUid;
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.store_outlined,
              color: canEdit ? null : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(store.name),
            subtitle: Text(() {
              final grid = '${store.rows.length}×${store.cols.length}';
              final floorCount = 1 + store.additionalFloors.length as int;
              return floorCount > 1
                  ? '$grid  •  ${l.nFloors(floorCount)}'
                  : grid;
            }()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEdit) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _confirmDelete(context, ref, store.id, store.name, l),
                  ),
                ],
              ],
            ),
            onTap: canEdit
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreEditorScreen(existing: store),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
    AppLocalizations l,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.yes),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(supermarketsProvider.notifier).remove(id);
  }
}

/// Icon that overlays a small play triangle badge on a base icon,
/// used to distinguish single-person and collaborative navigation buttons.
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
