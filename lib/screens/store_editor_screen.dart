import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../models/shop_floor.dart';
import '../models/supermarket.dart';
import '../providers/supermarket_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../services/nominatim_service.dart';
import '../widgets/store_grid.dart';

enum _ExitAction { save, discard }

enum _TapMode { normal, setEntrance, setExit }

const _uuid = Uuid();
const _maxDim = 26;

List<String> _makeRows(int n) =>
    List.generate(n, (i) => String.fromCharCode(65 + i)); // A, B, C …

List<String> _makeCols(int n) =>
    List.generate(n, (i) => '${i + 1}'); // 1, 2, 3 …

typedef ShopPrefill = ({String name, String? address, double? lat, double? lng, String? osmCategory});

/// Holds the editable state for one floor in the store editor.
class _FloorEditData {
  String name; // user-visible label (empty = use l10n default)
  int rowCount;
  int colCount;
  String entrance;
  String exit;
  Map<String, List<String>> cells;
  Map<String, List<String>> subcells;

  _FloorEditData({
    this.name = '',
    required this.rowCount,
    required this.colCount,
    required this.entrance,
    required this.exit,
    Map<String, List<String>>? cells,
    Map<String, List<String>>? subcells,
  })  : cells = cells ?? {},
        subcells = subcells ?? {};
}

class StoreEditorScreen extends ConsumerStatefulWidget {
  final Supermarket? existing;

  /// Pre-fills name/address/coords for a new shop (e.g. from OSM).
  /// Ignored when [existing] is provided.
  final ShopPrefill? prefill;

  /// Items to show as pinned suggestions in the cell goods editor,
  /// regardless of what the user is currently typing.
  final List<String> focusItems;

  const StoreEditorScreen(
      {super.key, this.existing, this.prefill, this.focusItems = const []});

  @override
  ConsumerState<StoreEditorScreen> createState() => _StoreEditorScreenState();
}

class _StoreEditorScreenState extends ConsumerState<StoreEditorScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _entranceCtrl;
  late final TextEditingController _exitCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _floorNameCtrl;
  late List<_FloorEditData> _floorData;
  int _currentFloor = 0;
  bool _dirty = false;
  bool _geocoding = false;
  _TapMode _tapMode = _TapMode.normal;

  // Proxy getters/setters — all grid-editing methods work unchanged.
  int get _rowCount => _floorData[_currentFloor].rowCount;
  set _rowCount(int v) => _floorData[_currentFloor].rowCount = v;
  int get _colCount => _floorData[_currentFloor].colCount;
  set _colCount(int v) => _floorData[_currentFloor].colCount = v;
  Map<String, List<String>> get _cells => _floorData[_currentFloor].cells;
  set _cells(Map<String, List<String>> v) => _floorData[_currentFloor].cells = v;
  Map<String, List<String>> get _subcells => _floorData[_currentFloor].subcells;
  set _subcells(Map<String, List<String>> v) => _floorData[_currentFloor].subcells = v;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    final p = widget.prefill;

    // Build floor data from existing store or defaults.
    _floorData = [
      _FloorEditData(
        name: s?.groundFloorName ?? '',
        rowCount: s != null ? s.rows.length.clamp(1, _maxDim) : 5,
        colCount: s != null ? s.cols.length.clamp(1, _maxDim) : 5,
        entrance: s?.entrance ?? 'A1',
        exit: s?.exit ?? 'E5',
        cells: s != null
            ? Map<String, List<String>>.from(
                s.cells.map((k, v) => MapEntry(k, List<String>.from(v))))
            : {},
        subcells: s != null
            ? Map<String, List<String>>.from(
                s.subcells.map((k, v) => MapEntry(k, List<String>.from(v))))
            : {},
      ),
      if (s != null)
        ...s.additionalFloors.map((f) => _FloorEditData(
              name: f.name,
              rowCount: f.rows.length.clamp(1, _maxDim),
              colCount: f.cols.length.clamp(1, _maxDim),
              entrance: f.entrance,
              exit: f.exit,
              cells: Map<String, List<String>>.from(
                  f.cells.map((k, v) => MapEntry(k, List<String>.from(v)))),
              subcells: Map<String, List<String>>.from(
                  f.subcells.map((k, v) => MapEntry(k, List<String>.from(v)))),
            )),
    ];

    _nameCtrl    = TextEditingController(text: s?.name ?? p?.name ?? '');
    _entranceCtrl = TextEditingController(text: _floorData[0].entrance);
    _exitCtrl     = TextEditingController(text: _floorData[0].exit);
    _addressCtrl  = TextEditingController(text: s?.address ?? p?.address ?? '');
    _floorNameCtrl = TextEditingController(text: _floorData[0].name);

    _nameCtrl.addListener(() => setState(() => _dirty = true));
    _entranceCtrl.addListener(() => setState(() => _dirty = true));
    _exitCtrl.addListener(() => setState(() => _dirty = true));
    _addressCtrl.addListener(() => setState(() => _dirty = true));
    _floorNameCtrl.addListener(() {
      _floorData[_currentFloor].name = _floorNameCtrl.text;
      setState(() => _dirty = true);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _entranceCtrl.dispose();
    _exitCtrl.dispose();
    _addressCtrl.dispose();
    _floorNameCtrl.dispose();
    super.dispose();
  }

  List<String> get _rows => _makeRows(_rowCount);
  List<String> get _cols => _makeCols(_colCount);

  // ── Floor management ──────────────────────────────────────────────────────

  void _switchFloor(int newIndex) {
    // Persist current controller values before switching.
    _floorData[_currentFloor].entrance = _entranceCtrl.text.trim().toUpperCase();
    _floorData[_currentFloor].exit = _exitCtrl.text.trim().toUpperCase();
    setState(() {
      _currentFloor = newIndex;
      _entranceCtrl.text = _floorData[newIndex].entrance;
      _exitCtrl.text = _floorData[newIndex].exit;
      _floorNameCtrl.text = _floorData[newIndex].name;
      _tapMode = _TapMode.normal;
    });
  }

  void _addFloor() {
    _floorData[_currentFloor].entrance = _entranceCtrl.text.trim().toUpperCase();
    _floorData[_currentFloor].exit = _exitCtrl.text.trim().toUpperCase();
    final prev = _floorData[_currentFloor];
    final rows = prev.rowCount;
    final cols = prev.colCount;
    final newFloor = _FloorEditData(rowCount: rows, colCount: cols, entrance: 'A1', exit: 'A1');
    setState(() {
      _dirty = true;
      _floorData.add(newFloor);
      _currentFloor = _floorData.length - 1;
      _entranceCtrl.text = newFloor.entrance;
      _exitCtrl.text = newFloor.exit;
      _floorNameCtrl.text = '';
      _tapMode = _TapMode.normal;
    });
  }

  void _removeCurrentFloor() {
    if (_currentFloor == 0) return;
    final prevFloor = _currentFloor - 1;
    setState(() {
      _dirty = true;
      _floorData.removeAt(_currentFloor);
      _currentFloor = prevFloor;
      _entranceCtrl.text = _floorData[prevFloor].entrance;
      _exitCtrl.text = _floorData[prevFloor].exit;
      _floorNameCtrl.text = _floorData[prevFloor].name;
      _tapMode = _TapMode.normal;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────

  /// Remove cells that no longer exist and fix entrance/exit if out of range.
  void _pruneAfterResize() {
    final validCells = {
      for (final r in _rows)
        for (final c in _cols) '$r$c'
    };
    _cells.removeWhere((k, _) => !validCells.contains(k));
    _subcells
        .removeWhere((k, _) => !validCells.contains(k.split(':').first));

    if (!validCells.contains(_entranceCtrl.text.toUpperCase())) {
      _entranceCtrl.text = '${_rows.first}${_cols.first}';
    }
    if (!validCells.contains(_exitCtrl.text.toUpperCase())) {
      _exitCtrl.text = '${_rows.last}${_cols.last}';
    }
  }

  void _changeRows(int delta) {
    final next = (_rowCount + delta).clamp(1, _maxDim);
    if (next == _rowCount) return;
    setState(() {
      _dirty = true;
      _rowCount = next;
      _pruneAfterResize();
    });
  }

  void _changeCols(int delta) {
    final next = (_colCount + delta).clamp(1, _maxDim);
    if (next == _colCount) return;
    setState(() {
      _dirty = true;
      _colCount = next;
      _pruneAfterResize();
    });
  }

  Future<void> _removeRowAt(int rowIndex) async {
    if (_rowCount <= 1) return;
    final l = AppLocalizations.of(context)!;
    final oldRows = _makeRows(_rowCount);
    final rowLabel = oldRows[rowIndex];
    final currentCols = _cols;

    final affectedItems = <String>[
      for (final col in currentCols)
        ...(_cells['$rowLabel$col'] ?? []),
      for (final col in currentCols)
        for (final key
            in _subcells.keys.where((k) => k.startsWith('$rowLabel$col:')))
          ...(_subcells[key] ?? []),
    ];

    if (affectedItems.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.deleteConfirm('${l.gridRows} $rowLabel')),
          content: Text(affectedItems.join(', ')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.delete)),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final newRows = _makeRows(_rowCount - 1);

    String remapRowInCell(String cellId) {
      if (cellId.isEmpty) return cellId;
      final row = cellId[0];
      final colPart = cellId.substring(1);
      final idx = oldRows.indexOf(row);
      if (idx < 0 || idx == rowIndex) return '${newRows.first}${currentCols.first}';
      if (idx > rowIndex) return '${newRows[idx - 1]}$colPart';
      return cellId;
    }

    setState(() {
      _dirty = true;
      for (final col in currentCols) {
        final cellId = '$rowLabel$col';
        _cells.remove(cellId);
        for (final key in _subcells.keys.where((k) => k.startsWith('$cellId:')).toList()) {
          _subcells.remove(key);
        }
      }
      for (var i = rowIndex + 1; i < oldRows.length; i++) {
        final oldRow = oldRows[i];
        final newRow = newRows[i - 1];
        for (final col in currentCols) {
          final oldId = '$oldRow$col';
          final newId = '$newRow$col';
          if (_cells.containsKey(oldId)) _cells[newId] = _cells.remove(oldId)!;
          for (final key in _subcells.keys.where((k) => k.startsWith('$oldId:')).toList()) {
            final suffix = key.substring(oldId.length);
            _subcells['$newId$suffix'] = _subcells.remove(key)!;
          }
        }
      }
      _entranceCtrl.text = remapRowInCell(_entranceCtrl.text);
      _exitCtrl.text = remapRowInCell(_exitCtrl.text);
      _rowCount--;
    });
  }

  Future<void> _removeColAt(int colIndex) async {
    if (_colCount <= 1) return;
    final l = AppLocalizations.of(context)!;
    final oldCols = _makeCols(_colCount);
    final colLabel = oldCols[colIndex];
    final currentRows = _rows;

    final affectedItems = <String>[
      for (final row in currentRows)
        ...(_cells['$row$colLabel'] ?? []),
      for (final row in currentRows)
        for (final key
            in _subcells.keys.where((k) => k.startsWith('$row$colLabel:')))
          ...(_subcells[key] ?? []),
    ];

    if (affectedItems.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.deleteConfirm('${l.gridCols} $colLabel')),
          content: Text(affectedItems.join(', ')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.delete)),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final newCols = _makeCols(_colCount - 1);

    String remapColInCell(String cellId) {
      if (cellId.isEmpty) return cellId;
      final row = cellId[0];
      final col = cellId.substring(1);
      final idx = oldCols.indexOf(col);
      if (idx < 0 || idx == colIndex) return '${currentRows.first}${newCols.first}';
      if (idx > colIndex) return '$row${newCols[idx - 1]}';
      return cellId;
    }

    setState(() {
      _dirty = true;
      for (final row in currentRows) {
        final cellId = '$row$colLabel';
        _cells.remove(cellId);
        for (final key in _subcells.keys.where((k) => k.startsWith('$cellId:')).toList()) {
          _subcells.remove(key);
        }
      }
      for (var i = colIndex + 1; i < oldCols.length; i++) {
        final oldCol = oldCols[i];
        final newCol = newCols[i - 1];
        for (final row in currentRows) {
          final oldId = '$row$oldCol';
          final newId = '$row$newCol';
          if (_cells.containsKey(oldId)) _cells[newId] = _cells.remove(oldId)!;
          for (final key in _subcells.keys.where((k) => k.startsWith('$oldId:')).toList()) {
            final suffix = key.substring(oldId.length);
            _subcells['$newId$suffix'] = _subcells.remove(key)!;
          }
        }
      }
      _entranceCtrl.text = remapColInCell(_entranceCtrl.text);
      _exitCtrl.text = remapColInCell(_exitCtrl.text);
      _colCount--;
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.shopName)));
      return;
    }

    // Persist current controller values into floor data before saving.
    _floorData[_currentFloor].entrance = _entranceCtrl.text.trim().toUpperCase();
    _floorData[_currentFloor].exit = _exitCtrl.text.trim().toUpperCase();

    double? lat = widget.existing?.lat ?? widget.prefill?.lat;
    double? lng = widget.existing?.lng ?? widget.prefill?.lng;
    final addressText = _addressCtrl.text.trim();

    final prefillAddress = widget.prefill?.address;
    final alreadyGeocoded = lat != null && lng != null &&
        (addressText == widget.existing?.address || addressText == prefillAddress);
    if (addressText.isNotEmpty && !alreadyGeocoded) {
      setState(() => _geocoding = true);
      final coords = await NominatimService.geocode(addressText);
      if (!mounted) return;
      setState(() => _geocoding = false);
      if (coords != null) {
        lat = coords.lat;
        lng = coords.lng;
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.geocodeFailed)));
      }
    } else if (addressText.isEmpty) {
      lat = null;
      lng = null;
    }

    final floor0 = _floorData[0];
    final store = Supermarket(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameCtrl.text.trim(),
      rows: _makeRows(floor0.rowCount),
      cols: _makeCols(floor0.colCount),
      entrance: floor0.entrance,
      exit: floor0.exit,
      cells: floor0.cells,
      subcells: floor0.subcells,
      address: addressText.isEmpty ? null : addressText,
      lat: lat,
      lng: lng,
      osmCategory: widget.existing?.osmCategory ?? widget.prefill?.osmCategory,
      groundFloorName: floor0.name.isEmpty ? null : floor0.name,
    );
    if (_floorData.length > 1) {
      store.additionalFloors = _floorData.sublist(1).map((f) => ShopFloor(
            name: f.name,
            rows: _makeRows(f.rowCount),
            cols: _makeCols(f.colCount),
            entrance: f.entrance,
            exit: f.exit,
            cells: f.cells,
            subcells: f.subcells,
          )).toList();
    }
    final notifier = ref.read(supermarketsProvider.notifier);
    if (widget.existing != null) {
      notifier.update(store);
    } else {
      notifier.add(store);
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

  /// Returns the initial text for a cell goods dialog: existing goods with
  /// any focusItems appended (unless already present).
  String _cellInitialText(List<String> existing) {
    if (widget.focusItems.isEmpty) return existing.join(', ');
    final existingLower = existing.map((e) => e.toLowerCase()).toSet();
    final toAdd = widget.focusItems
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !existingLower.contains(s.toLowerCase()))
        .toList();
    return [...existing, ...toAdd].join(', ');
  }

  List<String> _allListItemNames() {
    final focus = widget.focusItems.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    final lists = ref.read(shoppingListsProvider);
    final rest = lists
        .expand((list) => list.items)
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty && !focus.contains(name))
        .toSet()
        .toList()
      ..sort();
    return [...focus, ...rest];
  }

  Future<String?> _showGoodsEditDialog({
    required String title,
    required String initialText,
    required List<String> suggestions,
  }) {
    final l = AppLocalizations.of(context)!;
    final pinned = widget.focusItems
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final ctrl = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final text = ctrl.text;
          final lastComma = text.lastIndexOf(',');
          final partial =
              (lastComma >= 0 ? text.substring(lastComma + 1) : text).trim();
          final entered = text
              .split(',')
              .map((e) => e.trim().toLowerCase())
              .toSet();
          // Show pinned suggestions when there is no partial word being
          // typed: either the field is empty/ends with ", ", or the text
          // after the last comma is itself already a completed item.
          final showPinned =
              partial.isEmpty || entered.contains(partial.toLowerCase());
          final filtered = showPinned
              ? pinned
                  .where((s) => !entered.contains(s.toLowerCase()))
                  .take(8)
                  .toList()
              : suggestions
                  .where((s) =>
                      s.toLowerCase().contains(partial.toLowerCase()) &&
                      !entered.contains(s.toLowerCase()))
                  .take(8)
                  .toList();

          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(hintText: l.cellGoods),
                  autofocus: true,
                  maxLines: 3,
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (filtered.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: filtered
                        .map((s) => ActionChip(
                              label: Text(s),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                final lc = ctrl.text.lastIndexOf(',');
                                final prefix = lc >= 0
                                    ? '${ctrl.text.substring(0, lc + 1)} '
                                    : '';
                                final newText = '$prefix$s, ';
                                ctrl.value = TextEditingValue(
                                  text: newText,
                                  selection: TextSelection.collapsed(
                                      offset: newText.length),
                                );
                                setDialogState(() {});
                              },
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l.cancel)),
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, ctrl.text),
                  child: Text(l.ok)),
            ],
          );
        },
      ),
    );
  }

  void _onCellTap(String cellId) {
    if (_tapMode == _TapMode.setEntrance) {
      setState(() {
        _entranceCtrl.text = cellId;
        _dirty = true;
        _tapMode = _TapMode.normal;
      });
      return;
    }
    if (_tapMode == _TapMode.setExit) {
      setState(() {
        _exitCtrl.text = cellId;
        _dirty = true;
        _tapMode = _TapMode.normal;
      });
      return;
    }
    _editCell(cellId);
  }

  void _editCell(String cellId) async {
    final l = AppLocalizations.of(context)!;
    final result = await _showGoodsEditDialog(
      title: l.editCell(cellId),
      initialText: _cellInitialText(_cells[cellId] ?? []),
      suggestions: _allListItemNames(),
    );
    if (result != null && mounted) {
      setState(() {
        _dirty = true;
        final goods = result.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (goods.isEmpty) {
          _cells.remove(cellId);
        } else {
          _cells[cellId] = goods;
        }
      });
    }
  }

  void _editSubcell(String subcellKey) async {
    final l = AppLocalizations.of(context)!;
    final parts = subcellKey.split(':');
    final cellId = parts[0];
    final axis = parts[1];
    final isFirst = parts[2] == '0';
    final halfLabel = axis == 'col'
        ? (isFirst ? l.splitLeft : l.splitRight)
        : (isFirst ? l.splitTop : l.splitBottom);
    final result = await _showGoodsEditDialog(
      title: '${l.editCell(cellId)} – $halfLabel',
      initialText: _cellInitialText(_subcells[subcellKey] ?? []),
      suggestions: _allListItemNames(),
    );
    if (result != null && mounted) {
      setState(() {
        _dirty = true;
        final goods = result.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (goods.isEmpty) {
          _subcells.remove(subcellKey);
        } else {
          _subcells[subcellKey] = goods;
        }
      });
    }
  }

  /// Opens the split dialog for [cellId]: choose axis, then distribute items.
  void _startSplit(String cellId) async {
    final l = AppLocalizations.of(context)!;
    // If already split, do nothing — long-press handles options instead.
    if (_subcells.keys.any((k) => k.startsWith('$cellId:'))) return;

    final currentItems = List<String>.from(_cells[cellId] ?? []);

    // Step 1: Choose axis.
    final axis = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _AxisDialog(l: l),
    );
    if (axis == null || !mounted) return;

    // Step 2: Assign items to halves (skip if no items).
    if (currentItems.isEmpty) {
      setState(() {
        _dirty = true;
        _subcells['$cellId:$axis:0'] = [];
        _subcells['$cellId:$axis:1'] = [];
        _cells.remove(cellId);
      });
      return;
    }

    final assignments = await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) =>
          _ItemAssignDialog(l: l, items: currentItems, axis: axis),
    );
    if (assignments == null || !mounted) return;

    final half0 = currentItems
        .where((item) => (assignments[item] ?? 0) == 0)
        .toList();
    final half1 = currentItems
        .where((item) => (assignments[item] ?? 0) == 1)
        .toList();

    setState(() {
      _dirty = true;
      _subcells['$cellId:$axis:0'] = half0;
      _subcells['$cellId:$axis:1'] = half1;
      _cells.remove(cellId);
    });
  }

  /// Shows promote / revert options for a split cell.
  void _splitCellOptions(String cellId) async {
    final l = AppLocalizations.of(context)!;
    final axisKey =
        _subcells.keys.firstWhere((k) => k.startsWith('$cellId:'));
    final axis = axisKey.split(':')[1];
    final items0 = List<String>.from(_subcells['$cellId:$axis:0'] ?? []);
    final items1 = List<String>.from(_subcells['$cellId:$axis:1'] ?? []);
    final action = await showDialog<_SplitAction>(
      context: context,
      builder: (dialogContext) => _SplitOptionsDialog(
        l: l,
        cellId: cellId,
        axis: axis,
        items0: items0,
        items1: items1,
      ),
    );
    if (action == null || !mounted) return;
    if (action == _SplitAction.promote) {
      _promoteSplit(cellId);
    } else {
      _revertSplit(cellId);
    }
  }

  /// Commits the draft split: inserts a real row or column, migrates items.
  void _promoteSplit(String cellId) {
    final axisKey =
        _subcells.keys.firstWhere((k) => k.startsWith('$cellId:'));
    final axis = axisKey.split(':')[1];
    final key0 = '$cellId:$axis:0';
    final key1 = '$cellId:$axis:1';
    final items0 = List<String>.from(_subcells[key0] ?? []);
    final items1 = List<String>.from(_subcells[key1] ?? []);

    final rows = _rows;
    final cols = _cols;

    // Determine which row and col this cell belongs to.
    late final String cellRow;
    late final String cellCol;
    for (final r in rows) {
      if (cellId.startsWith(r) && cellId.length > r.length) {
        final maybeCol = cellId.substring(r.length);
        if (cols.contains(maybeCol)) {
          cellRow = r;
          cellCol = maybeCol;
          break;
        }
      }
    }

    setState(() {
      _dirty = true;
      _subcells.remove(key0);
      _subcells.remove(key1);

      if (axis == 'col') {
        final colIdx = cols.indexOf(cellCol);
        _colCount += 1;
        final newCols = _makeCols(_colCount);

        _cells = _remapKeys(_cells, rows, cols, newCols, colIdx, isCol: true);
        _subcells =
            _remapSubcellKeys(_subcells, rows, cols, newCols, colIdx, isCol: true);

        final newColLabel = newCols[colIdx + 1];
        if (items0.isNotEmpty) _cells[cellId] = items0;
        if (items1.isNotEmpty) _cells['$cellRow$newColLabel'] = items1;
        _fixEntranceExit(cols, newCols, colIdx, isCol: true);
      } else {
        final rowIdx = rows.indexOf(cellRow);
        _rowCount += 1;
        final newRows = _makeRows(_rowCount);

        _cells = _remapKeys(_cells, rows, cols, newRows, rowIdx, isCol: false);
        _subcells =
            _remapSubcellKeys(_subcells, rows, cols, newRows, rowIdx, isCol: false);

        final newRowLabel = newRows[rowIdx + 1];
        if (items0.isNotEmpty) _cells[cellId] = items0;
        if (items1.isNotEmpty) _cells['$newRowLabel$cellCol'] = items1;
        _fixEntranceExit(rows, newRows, rowIdx, isCol: false);
      }
    });
  }

  /// Remaps cell keys after inserting a row or column.
  /// [insertedAfterIdx] is the index in [oldLabels] after which the new label is inserted.
  Map<String, List<String>> _remapKeys(
    Map<String, List<String>> map,
    List<String> rows,
    List<String> cols,
    List<String> newLabels,
    int insertedAfterIdx, {
    required bool isCol,
  }) {
    final result = <String, List<String>>{};
    for (final entry in map.entries) {
      final cellRow = rows.firstWhere(
        (r) => entry.key.startsWith(r) &&
            cols.contains(entry.key.substring(r.length)),
        orElse: () => '',
      );
      if (cellRow.isEmpty) continue;
      final cellCol = entry.key.substring(cellRow.length);
      final idx = isCol ? cols.indexOf(cellCol) : rows.indexOf(cellRow);
      if (idx > insertedAfterIdx) {
        final newKey = isCol
            ? '$cellRow${newLabels[idx + 1]}'
            : '${newLabels[idx + 1]}$cellCol';
        result[newKey] = entry.value;
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Remaps subcell keys after inserting a row or column.
  Map<String, List<String>> _remapSubcellKeys(
    Map<String, List<String>> map,
    List<String> rows,
    List<String> cols,
    List<String> newLabels,
    int insertedAfterIdx, {
    required bool isCol,
  }) {
    final result = <String, List<String>>{};
    for (final entry in map.entries) {
      final subParts = entry.key.split(':');
      final base = subParts[0];
      final cellRow = rows.firstWhere(
        (r) =>
            base.startsWith(r) && cols.contains(base.substring(r.length)),
        orElse: () => '',
      );
      if (cellRow.isEmpty) continue;
      final cellCol = base.substring(cellRow.length);
      final idx = isCol ? cols.indexOf(cellCol) : rows.indexOf(cellRow);
      if (idx > insertedAfterIdx) {
        final newBase = isCol
            ? '$cellRow${newLabels[idx + 1]}'
            : '${newLabels[idx + 1]}$cellCol';
        result['$newBase:${subParts[1]}:${subParts[2]}'] = entry.value;
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Adjusts entrance/exit cell IDs after a row or column insertion.
  void _fixEntranceExit(
    List<String> oldLabels,
    List<String> newLabels,
    int insertedAfterIdx, {
    required bool isCol,
  }) {
    void fix(TextEditingController ctrl) {
      final val = ctrl.text.trim().toUpperCase();
      for (var i = insertedAfterIdx + 1; i < oldLabels.length; i++) {
        final old = oldLabels[i];
        if (isCol && val.endsWith(old)) {
          ctrl.text = '${val.substring(0, val.length - old.length)}${newLabels[i + 1]}';
          return;
        } else if (!isCol && val.startsWith(old)) {
          ctrl.text = '${newLabels[i + 1]}${val.substring(old.length)}';
          return;
        }
      }
    }

    fix(_entranceCtrl);
    fix(_exitCtrl);
  }

  /// Reverts a draft split: merges both halves back into the main cell.
  void _revertSplit(String cellId) {
    final keys = _subcells.keys
        .where((k) => k.startsWith('$cellId:'))
        .toList();
    final allItems = <String>[
      for (final key in keys) ...?_subcells[key],
    ];
    setState(() {
      _dirty = true;
      for (final key in keys) {
        _subcells.remove(key);
      }
      if (allItems.isNotEmpty) {
        _cells[cellId] = allItems;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = _rows;
    final cols = _cols;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final action = await _confirmUnsaved();
        if (!mounted) return;
        if (action == _ExitAction.save) {
          await _save();
        } else if (action == _ExitAction.discard) {
          navigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? l.newShop : l.editShop),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_geocoding)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: () => _save(),
              child: Text(l.save, style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l.shopName, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(labelText: l.shopAddress, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            // ── Floor tabs ─────────────────────────────────────────────────
            _FloorTabBar(
              floorData: _floorData,
              currentFloor: _currentFloor,
              onSwitch: _switchFloor,
              onAdd: _addFloor,
              onRemove: _currentFloor > 0 ? _removeCurrentFloor : null,
              floorLabel: (n) {
                final name = _floorData[n].name;
                if (name.isNotEmpty) return name;
                return n == 0 ? l.groundFloor : l.floorIndex(n);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _floorNameCtrl,
              decoration: InputDecoration(
                labelText: l.floorName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _EntranceExitCard(
                    icon: Icons.login,
                    label: l.setEntrance,
                    cellId: _entranceCtrl.text.trim().toUpperCase(),
                    color: Colors.green,
                    active: _tapMode == _TapMode.setEntrance,
                    onTap: () => setState(() => _tapMode =
                        _tapMode == _TapMode.setEntrance
                            ? _TapMode.normal
                            : _TapMode.setEntrance),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _EntranceExitCard(
                    icon: Icons.logout,
                    label: l.setExit,
                    cellId: _exitCtrl.text.trim().toUpperCase(),
                    color: Colors.red,
                    active: _tapMode == _TapMode.setExit,
                    onTap: () => setState(() => _tapMode =
                        _tapMode == _TapMode.setExit
                            ? _TapMode.normal
                            : _TapMode.setExit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_tapMode != _TapMode.normal)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _tapMode == _TapMode.setEntrance
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_outlined,
                        size: 16,
                        color: _tapMode == _TapMode.setEntrance
                            ? Colors.green.shade700
                            : Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      _tapMode == _TapMode.setEntrance
                          ? l.setEntrance
                          : l.setExit,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _tapMode == _TapMode.setEntrance
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '↓',
                      style: TextStyle(
                        color: _tapMode == _TapMode.setEntrance
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            StoreGrid(
              rows: rows,
              cols: cols,
              cells: _cells,
              subcells: _subcells,
              entrance: _entranceCtrl.text.trim().toUpperCase(),
              exit: _exitCtrl.text.trim().toUpperCase(),
              onCellTap: _onCellTap,
              onCellDoubleTap:
                  _tapMode == _TapMode.normal ? _startSplit : null,
              onSubcellTap:
                  _tapMode == _TapMode.normal ? _editSubcell : null,
              onSplitCellLongPress: _splitCellOptions,
              onAddRow: _rowCount < _maxDim ? () => _changeRows(1) : null,
              onAddCol: _colCount < _maxDim ? () => _changeCols(1) : null,
              onRowLongPress: _removeRowAt,
              onColLongPress: _removeColAt,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

enum _SplitAction { promote, revert }

// ---------------------------------------------------------------------------
// Axis picker dialog
// ---------------------------------------------------------------------------

class _AxisDialog extends StatelessWidget {
  final AppLocalizations l;
  const _AxisDialog({required this.l});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l.splitAxisLabel),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AxisCard(
            label: l.splitAxisCol,
            sublabel: '${l.splitLeft} / ${l.splitRight}',
            visual: const _SplitVisual(axis: 'col'),
            onTap: () => Navigator.pop(context, 'col'),
          ),
          _AxisCard(
            label: l.splitAxisRow,
            sublabel: '${l.splitTop} / ${l.splitBottom}',
            visual: const _SplitVisual(axis: 'row'),
            onTap: () => Navigator.pop(context, 'row'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
      ],
    );
  }
}

class _AxisCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final Widget visual;
  final VoidCallback onTap;

  const _AxisCard({
    required this.label,
    required this.sublabel,
    required this.visual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(sublabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

/// Small diagram showing a cell split by [axis] ("col" = vertical divider,
/// "row" = horizontal divider). Half 0 is in the primary container colour,
/// half 1 in the secondary container colour.
class _SplitVisual extends StatelessWidget {
  final String axis;
  const _SplitVisual({required this.axis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c0 = theme.colorScheme.primaryContainer;
    final c1 = theme.colorScheme.secondaryContainer;
    final divider = theme.colorScheme.outline;

    Widget half(Color color, {BorderRadius? radius}) => Expanded(
          child: Container(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        );

    const r = Radius.circular(4);
    final body = axis == 'col'
        ? Row(children: [
            half(c0, radius: const BorderRadius.horizontal(left: r)),
            Container(width: 1.5, color: divider),
            half(c1, radius: const BorderRadius.horizontal(right: r)),
          ])
        : Column(children: [
            half(c0, radius: const BorderRadius.vertical(top: r)),
            Container(height: 1.5, color: divider),
            half(c1, radius: const BorderRadius.vertical(bottom: r)),
          ]);

    return SizedBox(
      width: 72,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: body,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item assignment dialog
// ---------------------------------------------------------------------------

class _ItemAssignDialog extends StatefulWidget {
  final AppLocalizations l;
  final List<String> items;
  final String axis; // "col" or "row"
  const _ItemAssignDialog(
      {required this.l, required this.items, required this.axis});

  @override
  State<_ItemAssignDialog> createState() => _ItemAssignDialogState();
}

class _ItemAssignDialogState extends State<_ItemAssignDialog> {
  late final Map<String, int> _assignments;

  @override
  void initState() {
    super.initState();
    _assignments = {for (final item in widget.items) item: 0};
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final theme = Theme.of(context);
    final isCol = widget.axis == 'col';
    final label0 = isCol ? l.splitLeft : l.splitTop;
    final label1 = isCol ? l.splitRight : l.splitBottom;
    final color0 = theme.colorScheme.primaryContainer;
    final color1 = theme.colorScheme.secondaryContainer;

    final items0 = widget.items.where((i) => _assignments[i] == 0).toList();
    final items1 = widget.items.where((i) => _assignments[i] == 1).toList();

    Widget panelContent(
        String label, Color color, List<String> panelItems, int half) {
      final moveIcon = isCol
          ? (half == 0 ? Icons.arrow_forward : Icons.arrow_back)
          : (half == 0 ? Icons.arrow_downward : Icons.arrow_upward);
      return Container(
        constraints: const BoxConstraints(minHeight: 64),
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (panelItems.isEmpty)
              Text('—',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline))
            else
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: panelItems
                    .map((item) => ActionChip(
                          label: Text(item),
                          labelStyle: theme.textTheme.bodySmall,
                          avatar: Icon(moveIcon, size: 12),
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              setState(() => _assignments[item] = 1 - half),
                        ))
                    .toList(),
              ),
          ],
        ),
      );
    }

    final Widget panels = isCol
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: panelContent(label0, color0, items0, 0)),
                const SizedBox(width: 8),
                Expanded(child: panelContent(label1, color1, items1, 1)),
              ],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              panelContent(label0, color0, items0, 0),
              const SizedBox(height: 8),
              panelContent(label1, color1, items1, 1),
            ],
          );

    return AlertDialog(
      content: panels,
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(
            onPressed: () => Navigator.pop(context, _assignments),
            child: Text(l.ok)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Split options dialog (long-press on a split cell)
// ---------------------------------------------------------------------------

class _SplitOptionsDialog extends StatelessWidget {
  final AppLocalizations l;
  final String cellId;
  final String axis; // "col" or "row"
  final List<String> items0;
  final List<String> items1;

  const _SplitOptionsDialog({
    required this.l,
    required this.cellId,
    required this.axis,
    required this.items0,
    required this.items1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCol = axis == 'col';
    final label0 = isCol ? l.splitLeft : l.splitTop;
    final label1 = isCol ? l.splitRight : l.splitBottom;
    final c0 = theme.colorScheme.primaryContainer;
    final c1 = theme.colorScheme.secondaryContainer;

    return AlertDialog(
      title: Text(cellId),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Current split state preview ──────────────────────────────
          _SplitPreview(
            axis: axis,
            label0: label0,
            label1: label1,
            items0: items0,
            items1: items1,
            color0: c0,
            color1: c1,
          ),
          const SizedBox(height: 20),
          // ── Action cards ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SplitActionCard(
                  icon: Icons.call_split,
                  label: l.promoteSplit,
                  description: l.promoteSplitDesc,
                  color: theme.colorScheme.primaryContainer,
                  onTap: () =>
                      Navigator.pop(context, _SplitAction.promote),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SplitActionCard(
                  icon: Icons.call_merge,
                  label: l.revertSplit,
                  description: l.revertSplitDesc,
                  color: theme.colorScheme.errorContainer,
                  onTap: () =>
                      Navigator.pop(context, _SplitAction.revert),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel)),
      ],
    );
  }
}

/// Shows the current draft split state: two labelled halves with their items.
class _SplitPreview extends StatelessWidget {
  final String axis;
  final String label0;
  final String label1;
  final List<String> items0;
  final List<String> items1;
  final Color color0;
  final Color color1;

  const _SplitPreview({
    required this.axis,
    required this.label0,
    required this.label1,
    required this.items0,
    required this.items1,
    required this.color0,
    required this.color1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.colorScheme.outline;

    Widget half(String label, List<String> items, Color color,
        {BorderRadius? radius}) {
      return Container(
        decoration: BoxDecoration(color: color, borderRadius: radius),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            if (items.isEmpty)
              Text('—',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline))
            else
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: items
                    .map((item) => Text(item,
                        style: theme.textTheme.bodySmall))
                    .toList(),
              ),
          ],
        ),
      );
    }

    const r = Radius.circular(8);
    if (axis == 'col') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: half(label0, items0, color0,
                  radius: const BorderRadius.horizontal(left: r))),
              Container(width: 1.5, color: divider),
              Expanded(child: half(label1, items1, color1,
                  radius: const BorderRadius.horizontal(right: r))),
            ],
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            half(label0, items0, color0,
                radius: const BorderRadius.vertical(top: r)),
            Container(height: 1.5, color: divider),
            half(label1, items1, color1,
                radius: const BorderRadius.vertical(bottom: r)),
          ],
        ),
      );
    }
  }
}

/// Tappable action card used in the split options dialog.
class _SplitActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _SplitActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.onSurface),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(description,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dimension counter widget
// ---------------------------------------------------------------------------

class _DimensionCounter extends StatelessWidget {
  final String label;
  final int value;
  final String suffix;
  final int max;
  final void Function(int delta) onChanged;

  const _DimensionCounter({
    required this.label,
    required this.value,
    required this.suffix,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > 1 ? () => onChanged(-1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(suffix,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max ? () => onChanged(1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floor tab bar
// ---------------------------------------------------------------------------

class _FloorTabBar extends StatelessWidget {
  final List<_FloorEditData> floorData;
  final int currentFloor;
  final void Function(int) onSwitch;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final String Function(int) floorLabel;

  const _FloorTabBar({
    required this.floorData,
    required this.currentFloor,
    required this.onSwitch,
    required this.onAdd,
    this.onRemove,
    required this.floorLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < floorData.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(floorLabel(i)),
                      selected: currentFloor == i,
                      onSelected: (_) => onSwitch(i),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (onRemove != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Remove floor',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            color: theme.colorScheme.error,
          ),
        IconButton(
          icon: const Icon(Icons.add, size: 20),
          tooltip: 'Add floor',
          visualDensity: VisualDensity.compact,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _EntranceExitCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String cellId;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _EntranceExitCard({
    required this.icon,
    required this.label,
    required this.cellId,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? color : theme.colorScheme.outlineVariant,
            width: active ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: active ? color.withAlpha(25) : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: active ? color : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: active ? color : null)),
                  Text(cellId,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: active
                              ? color
                              : theme.colorScheme.onSurface)),
                ],
              ),
            ),
            if (active)
              Icon(Icons.touch_app_outlined, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
