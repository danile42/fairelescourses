import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../models/supermarket.dart';
import '../providers/supermarket_provider.dart';
import '../services/nominatim_service.dart';
import '../widgets/store_grid.dart';

enum _ExitAction { save, discard }

const _uuid = Uuid();
const _maxDim = 26;

List<String> _makeRows(int n) =>
    List.generate(n, (i) => String.fromCharCode(65 + i)); // A, B, C …

List<String> _makeCols(int n) =>
    List.generate(n, (i) => '${i + 1}'); // 1, 2, 3 …

typedef ShopPrefill = ({String name, String? address, double? lat, double? lng});

class StoreEditorScreen extends ConsumerStatefulWidget {
  final Supermarket? existing;

  /// Pre-fills name/address/coords for a new shop (e.g. from OSM).
  /// Ignored when [existing] is provided.
  final ShopPrefill? prefill;

  const StoreEditorScreen({super.key, this.existing, this.prefill});

  @override
  ConsumerState<StoreEditorScreen> createState() => _StoreEditorScreenState();
}

class _StoreEditorScreenState extends ConsumerState<StoreEditorScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _entranceCtrl;
  late final TextEditingController _exitCtrl;
  late final TextEditingController _addressCtrl;
  late int _rowCount;
  late int _colCount;
  late Map<String, List<String>> _cells;
  bool _dirty = false;
  bool _geocoding = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    final p = widget.prefill;
    _nameCtrl    = TextEditingController(text: s?.name ?? p?.name ?? '');
    _rowCount    = s != null ? s.rows.length.clamp(1, _maxDim) : 5;
    _colCount    = s != null ? s.cols.length.clamp(1, _maxDim) : 5;
    _entranceCtrl = TextEditingController(text: s?.entrance ?? 'A1');
    _exitCtrl     = TextEditingController(text: s?.exit ?? 'E5');
    _addressCtrl  = TextEditingController(text: s?.address ?? p?.address ?? '');
    _cells = s != null
        ? Map<String, List<String>>.from(
            s.cells.map((k, v) => MapEntry(k, List<String>.from(v))))
        : {};
    _nameCtrl.addListener(() => setState(() => _dirty = true));
    _entranceCtrl.addListener(() => setState(() => _dirty = true));
    _exitCtrl.addListener(() => setState(() => _dirty = true));
    _addressCtrl.addListener(() => setState(() => _dirty = true));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _entranceCtrl.dispose();
    _exitCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  List<String> get _rows => _makeRows(_rowCount);
  List<String> get _cols => _makeCols(_colCount);

  /// Remove cells that no longer exist and fix entrance/exit if out of range.
  void _pruneAfterResize() {
    final validCells = {
      for (final r in _rows)
        for (final c in _cols) '$r$c'
    };
    _cells.removeWhere((k, _) => !validCells.contains(k));

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

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.shopName)));
      return;
    }

    double? lat = widget.existing?.lat ?? widget.prefill?.lat;
    double? lng = widget.existing?.lng ?? widget.prefill?.lng;
    final addressText = _addressCtrl.text.trim();

    // Geocode if address changed or is new (skip if coords already come from prefill)
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
        // Save without coordinates but continue
      }
    } else if (addressText.isEmpty) {
      lat = null;
      lng = null;
    }

    final store = Supermarket(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameCtrl.text.trim(),
      rows: _rows,
      cols: _cols,
      entrance: _entranceCtrl.text.trim().toUpperCase(),
      exit: _exitCtrl.text.trim().toUpperCase(),
      cells: _cells,
      address: addressText.isEmpty ? null : addressText,
      lat: lat,
      lng: lng,
    );
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

  void _editCell(String cellId) async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: (_cells[cellId] ?? []).join(', '));
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.editCell(cellId)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: l.cellGoods),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, ctrl.text), child: Text(l.ok)),
        ],
      ),
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
            Row(
              children: [
                Expanded(
                  child: _DimensionCounter(
                    label: l.gridRows,
                    value: _rowCount,
                    suffix: '(${rows.first}–${rows.last})',
                    max: _maxDim,
                    onChanged: _changeRows,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DimensionCounter(
                    label: l.gridCols,
                    value: _colCount,
                    suffix: '(1–$_colCount)',
                    max: _maxDim,
                    onChanged: _changeCols,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _entranceCtrl,
                    decoration: InputDecoration(labelText: l.entrance, border: const OutlineInputBorder()),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _exitCtrl,
                    decoration: InputDecoration(labelText: l.exit, border: const OutlineInputBorder()),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StoreGrid(
              rows: rows,
              cols: cols,
              cells: _cells,
              entrance: _entranceCtrl.text.trim().toUpperCase(),
              exit: _exitCtrl.text.trim().toUpperCase(),
              onCellTap: _editCell,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

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
