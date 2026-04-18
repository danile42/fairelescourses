import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/navigation_plan.dart';
import '../models/shopping_list.dart';
import '../models/supermarket.dart';
import '../providers/household_provider.dart';
import '../providers/nav_session_provider.dart';
import '../providers/nav_view_mode_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/supermarket_provider.dart';
import '../providers/firestore_sync_provider.dart';
import '../services/firestore_service.dart';
import '../services/navigation_planner.dart';
import '../widgets/mini_map.dart';
import 'list_editor_screen.dart';
import 'shop_search_screen.dart';
import 'store_editor_screen.dart';

const _uuid = Uuid();

enum _ViewMode { grid, list }

class NavigationScreen extends ConsumerStatefulWidget {
  final NavigationPlan plan;
  final String listId;
  final bool isCollaborative;
  final bool isHost;

  const NavigationScreen({
    super.key,
    required this.plan,
    required this.listId,
    this.isCollaborative = false,
    this.isHost = false,
  });

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen>
    with WidgetsBindingObserver {
  late NavigationPlan _plan;
  late Set<String> _knownItemNames;
  final Set<String> _newItems = {};
  late List<Set<String>> _checkedPerStore;
  final Set<String> _checkedUnmatched = {};
  int _storeIndex = 0;
  late _ViewMode _viewMode;
  late Set<String> _resolvedUnmatched;
  late Set<String> _navigatedUnmatched;

  // ── Collect-later state ──────────────────────────────────────────────────
  // Items the user deferred to the next store in the route.
  final Set<String> _deferNextShop = {};
  // Items the user wants saved to a new list at the end.
  final Set<String> _forNewList = {};
  // Items carried over from the previous store (populated when advancing).
  final List<String> _carriedOverItems = [];
  // Name of the store that sent the carried-over items (for section header).
  String? _carriedFromStoreName;
  // ────────────────────────────────────────────────────────────────────────

  // Cell of the most recently checked-off item — used for adjacent highlighting.
  String? _lastCheckedCell;
  int _lastCheckedFloor = 0;

  // Cached for use in dispose() — ref.read() is illegal after unmount.
  String? _cachedHid;
  FirestoreService? _cachedSvc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _plan = widget.plan;
    final preferList = ref.read(navViewModeProvider);
    _viewMode = preferList ? _ViewMode.list : _ViewMode.grid;
    _checkedPerStore = List.generate(_plan.storePlans.length, (_) => {});
    _resolvedUnmatched = {};
    _navigatedUnmatched = {};

    // Determine whether we are resuming a mid-tour session (nav state saved)
    // or starting a completely new tour.
    final isResumingTour =
        !widget.isCollaborative &&
        Hive.box<String>('settings').get(_navStateKey(widget.listId)) != null;

    // Always restore checked state from the shopping list so progress
    // survives app restarts in both single and collaborative mode.
    final list = ref
        .read(shoppingListsProvider)
        .where((l) => l.id == widget.listId)
        .firstOrNull;
    _knownItemNames = list != null
        ? list.items.map((i) => i.name.toLowerCase()).toSet()
        : _plan.storePlans
              .expand((sp) => sp.stops)
              .expand((s) => s.items)
              .map((i) => i.toLowerCase())
              .toSet();

    if (isResumingTour) {
      // Resuming after an app restart mid-tour: restore previous checked state.
      if (list != null) _syncCheckedFromList(list);
    } else {
      // New tour: reset all items to unchecked so the tour starts fresh.
      // _checkedPerStore is already all-empty; also persist to the list so
      // other devices (and the list view) see unchecked state immediately.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(shoppingListsProvider.notifier)
            .uncheckAll(widget.listId)
            .ignore();
      });
    }

    // Restore deferred/carry-over state if the app was killed mid-tour.
    // Checked progress is already restored from the shopping list above.
    if (!widget.isCollaborative) _restoreNavState();

    if (widget.isCollaborative) {
      // Cache values needed in dispose().
      if (widget.isHost) {
        _cachedHid = ref.read(householdProvider);
        _cachedSvc = ref.read(firestoreServiceProvider);

        // Host creates the session document.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cachedHid != null) {
            _cachedSvc!
                .upsertNavSession(_cachedHid!, widget.listId)
                .catchError(
                  (Object e) =>
                      debugPrint('Firestore upsertNavSession error: $e'),
                )
                .ignore();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save tour progress when the app is backgrounded or about to be killed.
    // On Android the OS sends paused → detached before killing the process,
    // so paused is the reliable checkpoint for crash recovery.
    if (!widget.isCollaborative &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached)) {
      _saveNavState();
    }
  }

  /// Derives per-store checked sets from the shopping list's checked items.
  void _syncCheckedFromList(ShoppingList list) {
    final checkedNames = list.items
        .where((i) => i.checked)
        .map((i) => i.name.toLowerCase())
        .toSet();
    for (int si = 0; si < _plan.storePlans.length; si++) {
      _checkedPerStore[si] = _plan.storePlans[si].stops
          .expand((s) => s.items)
          .where((item) => checkedNames.contains(item.toLowerCase()))
          .toSet();
    }
    final allUnmatchedNames = {
      ..._plan.globalUnmatched,
      ..._plan.storePlans.expand((sp) => sp.unmatched),
    };
    _checkedUnmatched
      ..clear()
      ..addAll(
        allUnmatchedNames.where(
          (item) => checkedNames.contains(item.toLowerCase()),
        ),
      );
  }

  // ── Nav-state persistence ─────────────────────────────────────────────────
  // Persists tour progress (store index, deferred sets, carry-overs) to the
  // Hive settings box so a crash mid-tour doesn't lose the user's place.
  // Checked items are already persisted via the shopping list.

  static String _navStateKey(String listId) => 'navState_$listId';

  void _saveNavState() {
    Hive.box<String>('settings').put(
      _navStateKey(widget.listId),
      jsonEncode({
        'storeIndex': _storeIndex,
        'deferNextShop': _deferNextShop.toList(),
        'forNewList': _forNewList.toList(),
        'carriedOverItems': _carriedOverItems,
        'carriedFromStoreName': _carriedFromStoreName,
      }),
    );
  }

  void _restoreNavState() {
    final raw = Hive.box<String>('settings').get(_navStateKey(widget.listId));
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final idx = (map['storeIndex'] as int?) ?? 0;
      if (idx > 0 && idx < _plan.storePlans.length) {
        _storeIndex = idx;
      }
      _deferNextShop.addAll(
        ((map['deferNextShop'] as List?)?.cast<String>()) ?? [],
      );
      _forNewList.addAll(((map['forNewList'] as List?)?.cast<String>()) ?? []);
      _carriedOverItems.addAll(
        ((map['carriedOverItems'] as List?)?.cast<String>()) ?? [],
      );
      _carriedFromStoreName = map['carriedFromStoreName'] as String?;
    } catch (e) {
      debugPrint('navState restore error: $e');
    }
  }

  void _clearNavState() {
    Hive.box<String>('settings').delete(_navStateKey(widget.listId));
  }

  // ─────────────────────────────────────────────────────────────────────────

  void _toggleUnmatched(String item) {
    setState(() {
      if (_checkedUnmatched.contains(item)) {
        _checkedUnmatched.remove(item);
      } else {
        _checkedUnmatched.add(item);
      }
    });
    ref
        .read(shoppingListsProvider.notifier)
        .toggleItemByName(widget.listId, item)
        .ignore();
  }

  StorePlan get _currentPlan => _plan.storePlans[_storeIndex];

  // ── Progress accounting (includes carried-over and deferred items) ───────

  int get _effectiveTotal => _currentPlan.totalItems + _carriedOverItems.length;

  int get _effectiveHandled {
    final checked = _checkedPerStore[_storeIndex];
    int count = 0;
    for (final stop in _currentPlan.stops) {
      for (final item in stop.items) {
        if (checked.contains(item) ||
            _deferNextShop.contains(item) ||
            _forNewList.contains(item)) {
          count++;
        }
      }
    }
    for (final item in _carriedOverItems) {
      if (checked.contains(item) ||
          _deferNextShop.contains(item) ||
          _forNewList.contains(item)) {
        count++;
      }
    }
    return count;
  }

  // ────────────────────────────────────────────────────────────────────────

  void _toggleItem(String item, {int? forStore}) {
    final si = forStore ?? _storeIndex;
    setState(() {
      final set = _checkedPerStore[si];
      if (set.contains(item)) {
        set.remove(item);
      } else {
        set.add(item);
        // Remember which cell this item was in so adjacent cells can be highlighted.
        for (final stop in _plan.storePlans[si].stops) {
          if (stop.items.contains(item)) {
            _lastCheckedCell = stop.cell;
            _lastCheckedFloor = stop.floor;
            break;
          }
        }
      }
    });
    // Persist checked state to the shopping list so progress survives restarts.
    ref
        .read(shoppingListsProvider.notifier)
        .toggleItemByName(widget.listId, item)
        .ignore();
  }

  bool _isChecked(String item, {int? forStore}) =>
      _checkedPerStore[forStore ?? _storeIndex].contains(item);

  bool _isDeferred(String item) =>
      _deferNextShop.contains(item) || _forNewList.contains(item);

  /// Shows a bottom sheet letting the user choose what to do with an item
  /// they cannot collect right now.
  Future<void> _showCollectLaterSheet(String item) async {
    final l = AppLocalizations.of(context)!;
    final storePlans = _plan.storePlans;
    final hasNextShop = _storeIndex < storePlans.length - 1;
    final nextShopName = hasNextShop
        ? storePlans[_storeIndex + 1].storeName
        : null;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                item,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l.collectLater,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const Divider(height: 1),
            if (hasNextShop)
              ListTile(
                leading: const Icon(Icons.skip_next, color: Colors.deepPurple),
                title: Text(l.deferToShop(nextShopName!)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _forNewList.remove(item);
                    _deferNextShop.add(item);
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.teal),
              title: Text(l.deferToNewList),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _deferNextShop.remove(item);
                  _forNewList.add(item);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l.cancel),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Advances to the next store, transferring deferred-to-next-shop items.
  void _advanceToNextShop() {
    setState(() {
      _carriedFromStoreName = _currentPlan.storeName;
      _carriedOverItems.addAll(_deferNextShop);
      _deferNextShop.clear();
      _storeIndex++;
    });
  }

  Future<void> _finishTour() async {
    _clearNavState();
    if (widget.isCollaborative) {
      ref
          .read(locallyDismissedNavSessionListIdProvider.notifier)
          .markFinished(widget.listId);
    }
    // Host deletes the collaborative session here (while still mounted,
    // so ref.read is legal). Doing it in dispose() would also fire on back.
    if (widget.isCollaborative && widget.isHost) {
      final hid = _cachedHid;
      if (hid != null) {
        try {
          await _cachedSvc?.deleteNavSession(hid);
        } catch (e) {
          debugPrint('Firestore deleteNavSession error: $e');
          if (mounted) {
            final l = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l.sessionEndFailed)));
          }
        }
      }
    }
    if (mounted) {
      Navigator.pop(context, true); // true = tour finished, not just paused
    }
  }

  /// Creates a new list from [items], then navigates to edit it.
  /// If [move] is true, the items are also removed from the source list.
  void _createListFromItems(Iterable<String> items, {required bool move}) {
    final newList = ShoppingList(
      id: _uuid.v4(),
      name: '',
      preferredStoreIds: [],
      items: items.map((n) => ShoppingItem(name: n)).toList(),
    );
    final notifier = ref.read(shoppingListsProvider.notifier);
    notifier.add(newList);
    if (move) {
      final source = ref
          .read(shoppingListsProvider)
          .where((l) => l.id == widget.listId)
          .firstOrNull;
      if (source != null) {
        final itemNames = items.toSet();
        notifier.update(
          source.copyWith(
            items: source.items
                .where((i) => !itemNames.contains(i.name))
                .toList(),
          ),
        );
      }
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ListEditorScreen(list: newList, isNew: false),
      ),
    );
  }

  Future<void> _navigateForResolved() async {
    final shops = ref.read(supermarketsProvider);
    final tempList = ShoppingList(
      id: _uuid.v4(),
      name: '',
      preferredStoreIds: [],
      items: _resolvedUnmatched.map((n) => ShoppingItem(name: n)).toList(),
    );
    final newPlan = NavigationPlanner.plan(tempList, shops);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(plan: newPlan, listId: tempList.id),
      ),
    );
    if (!mounted) return;

    final newNavigated = {..._navigatedUnmatched, ..._resolvedUnmatched};
    setState(() {
      _navigatedUnmatched = newNavigated;
      _resolvedUnmatched = {};
    });

    final allUnmatched = {
      ..._plan.globalUnmatched,
      ..._plan.storePlans.expand((s) => s.unmatched),
    };
    final allHandled = allUnmatched.every((i) => newNavigated.contains(i));
    final planDone =
        _plan.storePlans.isEmpty ||
        (_storeIndex >= _plan.storePlans.length - 1 &&
            _effectiveHandled >= _effectiveTotal);
    if (allHandled && planDone && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showShopPicker(String item) async {
    final l = AppLocalizations.of(context)!;
    final shops = ref.read(supermarketsProvider);

    // null = cancelled, _searchSentinel = open search, Supermarket = pick existing
    const searchSentinel = _SearchSentinel();
    final result = await showDialog<Object>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.whichShopForItem(item)),
        children: [
          ...shops.map(
            (s) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s),
              child: Text(s.name),
            ),
          ),
          const Divider(height: 1),
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
    if (!mounted) return;
    final allShopGoods = ref
        .read(supermarketsProvider)
        .expand(
          (s) => [
            ...s.cells.values.expand((v) => v),
            ...s.subcells.values.expand((v) => v),
          ],
        )
        .map((g) => g.toLowerCase())
        .toSet();
    final allUnmatched = {
      ..._plan.globalUnmatched,
      ..._plan.storePlans.expand((s) => s.unmatched),
    };
    setState(() {
      _resolvedUnmatched = allUnmatched
          .where(
            (u) =>
                allShopGoods.contains(u.toLowerCase()) &&
                !_navigatedUnmatched.contains(u),
          )
          .toSet();
    });
  }

  String? get _currentCell {
    for (final stop in _currentPlan.stops) {
      if (stop.items.any((i) => !_isChecked(i) && !_isDeferred(i))) {
        return stop.cell;
      }
    }
    return null;
  }

  /// Returns true when [cell] on [floor] is Manhattan-distance 1 from the
  /// cell of the last checked-off item.
  bool _isAdjacentCell(String cell, int floor) {
    final last = _lastCheckedCell;
    if (last == null || cell == last || floor != _lastCheckedFloor) {
      return false;
    }
    final stores = ref.read(supermarketsProvider);
    final store = stores.where((s) => s.id == _currentPlan.storeId).firstOrNull;
    return store?.floorAt(floor).isNeighbour(cell, last) ?? false;
  }

  int get _currentFloorIndex {
    for (final stop in _currentPlan.stops) {
      if (stop.items.any((i) => !_isChecked(i) && !_isDeferred(i))) {
        return stop.floor;
      }
    }
    return 0;
  }

  // ── Item row builders ────────────────────────────────────────────────────

  Widget _buildItemRow(
    String item, {
    bool available = true,
    int? forStore,
    bool highlighted = false,
  }) {
    final l = AppLocalizations.of(context)!;
    final isChecked = _isChecked(item, forStore: forStore);
    final isDeferredNext = _deferNextShop.contains(item);
    final isDeferredList = _forNewList.contains(item);
    final isDeferred = isDeferredNext || isDeferredList;
    final isUnavailable = !available && !isChecked && !isDeferred;

    final row = SizedBox(
      height: 36,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(
              value: isChecked,
              onChanged: (isDeferred || isUnavailable)
                  ? null
                  : (_) => _toggleItem(item, forStore: forStore),
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                decoration: (isChecked || isDeferred)
                    ? TextDecoration.lineThrough
                    : null,
                color: (isChecked || isDeferred || isUnavailable)
                    ? Colors.grey
                    : null,
              ),
            ),
          ),
          if (isDeferred) ...[
            Icon(
              isDeferredNext ? Icons.skip_next : Icons.playlist_add,
              size: 14,
              color: Colors.grey,
            ),
            SizedBox(
              width: 32,
              child: IconButton(
                icon: const Icon(Icons.undo, size: 14),
                visualDensity: VisualDensity.compact,
                tooltip: l.cancel,
                onPressed: () {
                  setState(() {
                    _deferNextShop.remove(item);
                    _forNewList.remove(item);
                  });
                },
              ),
            ),
          ] else if (!isChecked)
            SizedBox(
              width: 32,
              child: IconButton(
                icon: const Icon(Icons.schedule, size: 16),
                visualDensity: VisualDensity.compact,
                tooltip: l.collectLater,
                onPressed: () => _showCollectLaterSheet(item),
              ),
            ),
        ],
      ),
    );
    if (!highlighted) return row;
    return ColoredBox(
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.45),
      child: row,
    );
  }

  Widget _buildCarriedOverSection(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stores = ref.read(supermarketsProvider);
    final store = stores.where((s) => s.id == _currentPlan.storeId).firstOrNull;
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 2),
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  l.fromPreviousShop(_carriedFromStoreName ?? ''),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ..._carriedOverItems.map(
              (item) =>
                  _buildItemRow(item, available: store?.findCell(item) != null),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final plan = _plan;

    // Keep checked state in sync with the shared list, and detect new items.
    ref.listen<List<ShoppingList>>(shoppingListsProvider, (previous, lists) {
      if (!mounted) return;
      final list = lists.where((l) => l.id == widget.listId).firstOrNull;
      if (list == null) return;
      final added = list.items
          .where(
            (i) =>
                !i.checked && !_knownItemNames.contains(i.name.toLowerCase()),
          )
          .map((i) => i.name)
          .toSet();
      setState(() {
        if (added.isNotEmpty) _newItems.addAll(added);
        _syncCheckedFromList(list);
      });
    });

    if (_plan.storePlans.isEmpty) {
      final stillUnmatched = plan.globalUnmatched
          .where(
            (i) =>
                !_resolvedUnmatched.contains(i) &&
                !_navigatedUnmatched.contains(i),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: Text(l.navigationTitle),
          actions: [if (widget.isCollaborative) _CollaborativeBadge()],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_resolvedUnmatched.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.store_outlined,
                            color: Colors.blue.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.nowInShops,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._resolvedUnmatched.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            '• $item',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _navigateForResolved,
                        icon: const Icon(Icons.navigation, size: 16),
                        label: Text(l.generatePlan),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (stillUnmatched.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.search_off,
                            color: Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.unmatched,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...stillUnmatched.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _checkedUnmatched.contains(item),
                                onChanged: (_) => _toggleUnmatched(item),
                                visualDensity: VisualDensity.compact,
                              ),
                              Expanded(
                                child: Text(
                                  item,
                                  style: _checkedUnmatched.contains(item)
                                      ? const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                          fontSize: 13,
                                        )
                                      : const TextStyle(fontSize: 13),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showShopPicker(item),
                                icon: const Icon(
                                  Icons.store_outlined,
                                  size: 14,
                                ),
                                label: Text(
                                  l.assignToShop,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_resolvedUnmatched.isEmpty) ...[
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.unmatched,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: OutlinedButton.icon(
            onPressed: _finishTour,
            icon: const Icon(Icons.check),
            label: Text(l.finish),
          ),
        ),
      );
    }

    final storePlan = _currentPlan;
    final total = _effectiveTotal;
    final handled = _effectiveHandled;
    final allDone = total == 0 || handled >= total;
    final allTourItems = <String>{
      ...plan.globalUnmatched,
      ...plan.storePlans.expand((s) => s.unmatched),
      ..._carriedOverItems,
      ...plan.storePlans.expand((s) => s.stops).expand((stop) => stop.items),
    };
    final checkedTourItems = <String>{
      ..._checkedUnmatched,
      ..._checkedPerStore.expand((items) => items),
    };
    final allItemsCheckedOff =
        allTourItems.isNotEmpty &&
        allTourItems.every(checkedTourItems.contains);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navigationTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isCollaborative) _CollaborativeBadge(),
          IconButton(
            icon: Icon(
              _viewMode == _ViewMode.grid ? Icons.list : Icons.grid_view,
            ),
            tooltip: _viewMode == _ViewMode.grid ? l.viewList : l.viewGrid,
            onPressed: () => setState(
              () => _viewMode = _viewMode == _ViewMode.grid
                  ? _ViewMode.list
                  : _ViewMode.grid,
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: const Icon(Icons.cancel_outlined),
                  title: Text(l.cancelTour),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
            onSelected: (_) => _finishTour(),
          ),
        ],
        bottom: plan.storePlans.length > 1 && _viewMode == _ViewMode.grid
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
      body: Builder(
        builder: (context) {
          // In list view use overall totals across all stores.
          final listTotal = _viewMode == _ViewMode.list
              ? _plan.storePlans.fold(0, (s, sp) => s + sp.totalItems)
              : total;
          final listHandled = _viewMode == _ViewMode.list
              ? () {
                  int c = 0;
                  for (int si = 0; si < _plan.storePlans.length; si++) {
                    final checked = _checkedPerStore[si];
                    for (final stop in _plan.storePlans[si].stops) {
                      for (final item in stop.items) {
                        if (checked.contains(item) ||
                            _deferNextShop.contains(item) ||
                            _forNewList.contains(item)) {
                          c++;
                        }
                      }
                    }
                  }
                  return c;
                }()
              : handled;
          return Column(
            children: [
              LinearProgressIndicator(
                value: listTotal == 0 ? 1.0 : listHandled / listTotal,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
              ),
              if (_newItems.isNotEmpty)
                MaterialBanner(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  leading: const Icon(Icons.add_circle_outline),
                  content: Text(l.navListUpdated(_newItems.length)),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _newItems.clear()),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: _refreshPlan,
                      child: Text(l.navUpdateRoute),
                    ),
                  ],
                ),
              if (_viewMode == _ViewMode.grid)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        storePlan.storeName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(l.progress(handled, total)),
                    ],
                  ),
                ),
              if (_viewMode == _ViewMode.grid) ...[
                MiniMap(
                  storePlan: storePlan,
                  currentCell: _currentCell,
                  checkedItems: _checkedPerStore[_storeIndex],
                  currentFloor: _currentFloorIndex,
                  lastCheckedCell: _lastCheckedCell,
                  lastCheckedFloor: _lastCheckedFloor,
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: allDone
                    ? _DoneView(
                        plan: plan,
                        storeIndex: _storeIndex,
                        onNextShop: _advanceToNextShop,
                        onAssignToShop: _showShopPicker,
                        resolvedUnmatched: _resolvedUnmatched,
                        navigatedUnmatched: _navigatedUnmatched,
                        onNavigateResolved: _navigateForResolved,
                        onFinish: _finishTour,
                        deferNextShop: _deferNextShop,
                        forNewList: _forNewList,
                        carriedOverItems: _carriedOverItems,
                        checkedAtCurrentStore: _checkedPerStore[_storeIndex],
                        onCreateList: (items, move) =>
                            _createListFromItems(items, move: move),
                        checkedUnmatched: _checkedUnmatched,
                        onToggleUnmatched: _toggleUnmatched,
                        showAllItemsCollected: allItemsCheckedOff,
                      )
                    : _viewMode == _ViewMode.grid
                    ? _buildGridView(storePlan)
                    : _buildListView(),
              ),
            ],
          ); // Column
        },
      ), // Builder
    );
  }

  Widget _buildGridView(StorePlan storePlan) {
    final List<Object> items = [];
    int? lastFloor;
    for (final stop in storePlan.stops) {
      if (lastFloor == null || stop.floor != lastFloor) {
        if (stop.floor > 0) items.add(_FloorHeader(stop.floor));
        lastFloor = stop.floor;
      }
      items.add(stop);
    }
    return ListView.builder(
      itemCount: items.length + (_carriedOverItems.isNotEmpty ? 1 : 0),
      itemBuilder: (context, i) {
        if (_carriedOverItems.isNotEmpty) {
          if (i == 0) return _buildCarriedOverSection(context);
          i -= 1;
        }
        final entry = items[i];
        if (entry is _FloorHeader) return _buildFloorHeader(entry.floor);
        final stop = entry as NavigationStop;
        final allStopDone = stop.items.every(
          (item) => _isChecked(item) || _isDeferred(item),
        );
        final isCurrent =
            _lastCheckedCell == null &&
            stop.cell == _currentCell &&
            stop.floor == _currentFloorIndex;
        final isAdjacent =
            !isCurrent &&
            !allStopDone &&
            _isAdjacentCell(stop.cell, stop.floor);
        return AnimatedOpacity(
          opacity: allStopDone ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: isCurrent
                ? Theme.of(context).colorScheme.primaryContainer
                : isAdjacent
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: stop.items.map(_buildItemRow).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _refreshPlan() {
    final list = ref
        .read(shoppingListsProvider)
        .where((l) => l.id == widget.listId)
        .firstOrNull;
    if (list == null) return;
    final shops = ref.read(supermarketsProvider);
    final newPlan = NavigationPlanner.plan(list, shops);
    setState(() {
      _plan = newPlan;
      _knownItemNames = list.items.map((i) => i.name.toLowerCase()).toSet();
      // Resize _checkedPerStore to match the new plan length.
      while (_checkedPerStore.length < newPlan.storePlans.length) {
        _checkedPerStore.add({});
      }
      if (_checkedPerStore.length > newPlan.storePlans.length) {
        _checkedPerStore = _checkedPerStore.sublist(
          0,
          newPlan.storePlans.length,
        );
      }
      if (_storeIndex >= newPlan.storePlans.length &&
          newPlan.storePlans.isNotEmpty) {
        _storeIndex = newPlan.storePlans.length - 1;
      }
      _newItems.clear();
      _syncCheckedFromList(list);
    });
  }

  Widget _buildListView() {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final plans = _plan.storePlans;

    // Collect all unmatched items (store-specific + global), deduplicated.
    final allUnmatched = <String>{
      ..._plan.globalUnmatched,
      ...plans.expand((sp) => sp.unmatched),
    }.toList();

    return ListView(
      children: [
        if (_carriedOverItems.isNotEmpty) _buildCarriedOverSection(context),
        for (var si = 0; si < plans.length; si++) ...[
          // ── Shop sub-header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            child: Row(
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  plans[si].storeName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // ── Items in navigation order ────────────────────────────────────
          for (final stop in plans[si].stops)
            for (final item in stop.items)
              _buildItemRow(
                item,
                forStore: si,
                highlighted: _isAdjacentCell(stop.cell, stop.floor),
              ),
        ],
        // ── Unmatched items ──────────────────────────────────────────────
        if (allUnmatched.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            child: Row(
              children: [
                const Icon(Icons.search_off, color: Colors.grey, size: 15),
                const SizedBox(width: 6),
                Text(
                  l.unmatched,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...allUnmatched.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  Checkbox(
                    value: _checkedUnmatched.contains(item),
                    onChanged: (_) => _toggleUnmatched(item),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: _checkedUnmatched.contains(item)
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 13,
                            )
                          : const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showShopPicker(item),
                    icon: const Icon(Icons.store_outlined, size: 14),
                    label: Text(
                      l.assignToShop,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFloorHeader(int floor) {
    final l = AppLocalizations.of(context)!;
    final stores = ref.read(supermarketsProvider);
    final storePlan = _currentPlan;
    final store = stores.where((s) => s.id == storePlan.storeId).firstOrNull;
    final fname = store?.floorAt(floor).name ?? '';
    final label = fname.isNotEmpty ? fname : l.floorIndex(floor);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stairs, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _FloorHeader {
  final int floor;
  const _FloorHeader(this.floor);
}

class _CollaborativeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        avatar: const Icon(Icons.group, size: 14),
        label: Text(
          l.navCollaborativeLabel,
          style: const TextStyle(fontSize: 11),
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _StoreTabs extends StatelessWidget {
  final List<StorePlan> plans;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _StoreTabs({
    required this.plans,
    required this.currentIndex,
    required this.onTap,
  });

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
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(100),
              labelStyle: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
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
  final Future<void> Function(String item) onAssignToShop;
  final Set<String> resolvedUnmatched;
  final Set<String> navigatedUnmatched;
  final Future<void> Function() onNavigateResolved;
  final VoidCallback onFinish;
  // Collect-later state passed from parent:
  final Set<String> deferNextShop;
  final Set<String> forNewList;
  final List<String> carriedOverItems;
  final Set<String> checkedAtCurrentStore;
  // Copy/move unmatched items to a new list.
  final void Function(Iterable<String> items, bool move) onCreateList;
  final Set<String> checkedUnmatched;
  final void Function(String item) onToggleUnmatched;
  final bool showAllItemsCollected;

  const _DoneView({
    required this.plan,
    required this.storeIndex,
    required this.onNextShop,
    required this.onAssignToShop,
    required this.resolvedUnmatched,
    required this.navigatedUnmatched,
    required this.onNavigateResolved,
    required this.onFinish,
    required this.deferNextShop,
    required this.forNewList,
    required this.carriedOverItems,
    required this.checkedAtCurrentStore,
    required this.onCreateList,
    required this.checkedUnmatched,
    required this.onToggleUnmatched,
    required this.showAllItemsCollected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final isLastShop = storeIndex >= plan.storePlans.length - 1;
    final stillUnmatched =
        {...plan.globalUnmatched, ...plan.storePlans.expand((s) => s.unmatched)}
            .where(
              (i) =>
                  !resolvedUnmatched.contains(i) &&
                  !navigatedUnmatched.contains(i),
            )
            .toList();
    final hasExtra = resolvedUnmatched.isNotEmpty || stillUnmatched.isNotEmpty;

    // Items to save to a new list at the end of the tour.
    // At last shop: everything the user chose to defer, plus unchecked carried-over items.
    // At intermediate shops: only the forNewList set (they accumulate quietly until the end).
    final finalDeferredItems = isLastShop
        ? <String>{
            ...deferNextShop, // couldn't defer to a next shop (last store)
            ...forNewList,
            ...carriedOverItems.where(
              (i) => !checkedAtCurrentStore.contains(i),
            ),
          }.toList()
        : <String>[];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: (hasExtra || finalDeferredItems.isNotEmpty) && isLastShop
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(height: 12),
              if (showAllItemsCollected)
                Text(
                  l.allItemsChecked,
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        (hasExtra || finalDeferredItems.isNotEmpty) &&
                            isLastShop
                        ? Colors.orange.shade800
                        : null,
                  ),
                ),
              if (!isLastShop) ...[
                // ── Intermediate store done ──────────────────────────────
                const SizedBox(height: 16),
                ElevatedButton(onPressed: onNextShop, child: Text(l.nextShop)),
                // Show items that will be carried to the next store.
                if (deferNextShop.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _deferredInfoBox(
                    color: Colors.deepPurple.shade50,
                    iconColor: Colors.deepPurple,
                    icon: Icons.skip_next,
                    label: l.deferredToNextShop,
                    items: deferNextShop.toList(),
                  ),
                ],
              ] else ...[
                // ── Last store done ──────────────────────────────────────
                if (resolvedUnmatched.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.store_outlined,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.nowInShops,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...resolvedUnmatched.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              '• $item',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: onNavigateResolved,
                              icon: const Icon(Icons.navigation, size: 16),
                              label: Text(l.generatePlan),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  onCreateList(resolvedUnmatched, false),
                              icon: const Icon(Icons.copy_outlined, size: 16),
                              label: Text(l.copyToNewList),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  onCreateList(resolvedUnmatched, true),
                              icon: const Icon(
                                Icons.drive_file_move_outline,
                                size: 16,
                              ),
                              label: Text(l.moveToNewList),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (stillUnmatched.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_outlined,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.unmatched,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...stillUnmatched.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: checkedUnmatched.contains(item),
                                  onChanged: (_) => onToggleUnmatched(item),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: checkedUnmatched.contains(item)
                                        ? const TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey,
                                            fontSize: 13,
                                          )
                                        : const TextStyle(fontSize: 13),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => onAssignToShop(item),
                                  icon: const Icon(
                                    Icons.store_outlined,
                                    size: 14,
                                  ),
                                  label: Text(
                                    l.assignToShop,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  onCreateList(stillUnmatched, false),
                              icon: const Icon(Icons.copy_outlined, size: 16),
                              label: Text(l.copyToNewList),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  onCreateList(stillUnmatched, true),
                              icon: const Icon(
                                Icons.drive_file_move_outline,
                                size: 16,
                              ),
                              label: Text(l.moveToNewList),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                // ── Deferred / collect-later section ────────────────────
                if (finalDeferredItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.playlist_add,
                              color: Colors.deepPurple.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.deferToNewList,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...finalDeferredItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              '• $item',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            final newList = ShoppingList(
                              id: _uuid.v4(),
                              name: '',
                              preferredStoreIds: [],
                              items: finalDeferredItems
                                  .map((n) => ShoppingItem(name: n))
                                  .toList(),
                            );
                            ref
                                .read(shoppingListsProvider.notifier)
                                .add(newList);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ListEditorScreen(
                                  list: newList,
                                  isNew: false,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_alt, size: 16),
                          label: Text(l.newList),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onFinish,
                  icon: const Icon(Icons.check),
                  label: Text(l.finish),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _deferredInfoBox({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String label,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text('• $item', style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSentinel {
  const _SearchSentinel();
}
