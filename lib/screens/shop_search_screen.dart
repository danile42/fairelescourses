import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../models/supermarket.dart';
import '../providers/home_location_provider.dart';
import '../providers/supermarket_provider.dart';
import '../services/firestore_service.dart';
import '../services/nominatim_service.dart';

const _uuid = Uuid();

enum _SearchMode { byName, byItem, byLocation }

class ShopSearchScreen extends ConsumerStatefulWidget {
  const ShopSearchScreen({super.key});

  @override
  ConsumerState<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends ConsumerState<ShopSearchScreen> {
  TextEditingController? _autoCtrl;
  List<ShopSearchResult> _results = [];
  bool _loading = false;
  bool _searched = false;
  bool _geocoding = false;
  _SearchMode _mode = _SearchMode.byName;
  bool _nearMe = true;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (_mode == _SearchMode.byLocation) {
      // Location search is triggered on submit only
      if (q.trim().length < 2) {
        setState(() { _results = []; _searched = false; });
      }
      return;
    }
    if (q.trim().length < 2) {
      setState(() { _results = []; _searched = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      List<ShopSearchResult> results;
      if (_mode == _SearchMode.byLocation) {
        final home = ref.read(homeLocationProvider);
        double? lat, lng;
        if (_nearMe && home != null) {
          lat = home.lat;
          lng = home.lng;
        } else {
          setState(() => _geocoding = true);
          final coords = await NominatimService.geocode(q);
          if (!mounted) return;
          setState(() => _geocoding = false);
          if (coords == null) {
            setState(() { _loading = false; _searched = true; _results = []; });
            final l = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.geocodeFailed)));
            return;
          }
          lat = coords.lat;
          lng = coords.lng;
        }
        results = await FirestoreService.searchNearby(lat, lng, 25.0);
      } else {
        final shops = _mode == _SearchMode.byItem
            ? await FirestoreService.searchByItem(q)
            : await FirestoreService.searchByName(q);
        results = shops.map((s) => ShopSearchResult(shop: s)).toList();
      }
      if (mounted) {
        setState(() { _results = results; _loading = false; _searched = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _searched = true; });
    }
  }

  void _switchMode(_SearchMode mode) {
    _autoCtrl?.clear();
    setState(() {
      _mode = mode;
      _results = [];
      _searched = false;
    });
    // Auto-search when switching to "By location" with Near Me enabled
    if (mode == _SearchMode.byLocation) {
      final home = ref.read(homeLocationProvider);
      if (_nearMe && home != null) {
        _search('');
      }
    }
  }

  Future<void> _import(BuildContext context, Supermarket source) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final copy = Supermarket(
      id: _uuid.v4(),
      name: source.name,
      rows: List<String>.from(source.rows),
      cols: List<String>.from(source.cols),
      entrance: source.entrance,
      exit: source.exit,
      cells: Map<String, List<String>>.from(
        source.cells.map((k, v) => MapEntry(k, List<String>.from(v))),
      ),
      address: source.address,
      lat: source.lat,
      lng: source.lng,
    );
    await ref.read(supermarketsProvider.notifier).add(copy);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l.shopImported)));
    setState(() {}); // refresh "known" badges
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stores = ref.watch(supermarketsProvider);
    final homeLoc = ref.watch(homeLocationProvider);
    final knownNames = stores.map((s) => s.name.toLowerCase()).toSet();
    final itemSuggestions = stores
        .expand((s) => s.cells.values.expand((goods) => goods))
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.searchShops),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SegmentedButton<_SearchMode>(
              segments: [
                ButtonSegment(
                    value: _SearchMode.byName,
                    label: Text(l.searchByName),
                    icon: const Icon(Icons.store_outlined)),
                ButtonSegment(
                    value: _SearchMode.byItem,
                    label: Text(l.searchByItem),
                    icon: const Icon(Icons.shopping_basket_outlined)),
                ButtonSegment(
                    value: _SearchMode.byLocation,
                    label: Text(l.searchByLocation),
                    icon: const Icon(Icons.location_on_outlined)),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => _switchMode(v.first),
            ),
          ),
          if (_mode == _SearchMode.byLocation && homeLoc != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                children: [
                  FilterChip(
                    avatar: const Icon(Icons.near_me, size: 16),
                    label: Text(l.nearMe),
                    selected: _nearMe,
                    onSelected: (val) {
                      setState(() {
                        _nearMe = val;
                        _results = [];
                        _searched = false;
                      });
                      if (val) {
                        _autoCtrl?.clear();
                        _search('');
                      }
                    },
                  ),
                ],
              ),
            ),
          if (!(_mode == _SearchMode.byLocation && _nearMe && homeLoc != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Autocomplete<String>(
                optionsBuilder: (tv) {
                  if (_mode != _SearchMode.byItem || tv.text.trim().isEmpty) {
                    return const [];
                  }
                  final q = tv.text.toLowerCase();
                  return itemSuggestions
                      .where((s) => s.toLowerCase().contains(q))
                      .take(8);
                },
                onSelected: (value) {
                  _debounce?.cancel();
                  _search(value);
                },
                fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
                  _autoCtrl = ctrl;
                  return TextField(
                    controller: ctrl,
                    focusNode: focusNode,
                    autofocus: _mode != _SearchMode.byLocation,
                    decoration: InputDecoration(
                      hintText: _mode == _SearchMode.byItem
                          ? l.searchItemHint
                          : _mode == _SearchMode.byLocation
                              ? l.locationSearchHint
                              : l.searchShopsHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: (_loading || _geocoding)
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (q) {
                      _debounce?.cancel();
                      if (_mode == _SearchMode.byLocation) {
                        if (q.trim().length >= 2) _search(q.trim());
                      } else {
                        if (q.trim().length >= 2) _search(q.trim());
                      }
                    },
                  );
                },
              ),
            ),
          Expanded(child: _buildResults(context, l, knownNames, theme)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, AppLocalizations l,
      Set<String> knownNames, ThemeData theme) {
    // "Near me" with no location set
    if (_mode == _SearchMode.byLocation) {
      final homeLoc = ref.read(homeLocationProvider);
      if (_nearMe && homeLoc == null && !_searched) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l.noLocationSet,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ),
        );
      }
    }

    if (!_searched) {
      if (_mode == _SearchMode.byLocation && _nearMe) {
        return const SizedBox.shrink();
      }
      return Center(
        child: Text(l.searchShopsMinChars,
            style: const TextStyle(color: Colors.grey)),
      );
    }
    if (_loading && _results.isEmpty) return const SizedBox.shrink();
    if (_results.isEmpty) {
      return Center(
          child: Text(l.noShopsFound,
              style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final result = _results[i];
        final shop = result.shop;
        final known = knownNames.contains(shop.name.toLowerCase());
        final distText = result.distanceKm != null
            ? l.distanceKm(result.distanceKm!.toStringAsFixed(1))
            : null;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.store_outlined),
            title: Text(shop.name),
            subtitle: Text([
              '${shop.rows.length}×${shop.cols.length}  •  ${shop.cells.length} cells',
              ?distText,
              ?shop.address,
            ].nonNulls.join('  •  ')),
            trailing: known
                ? Chip(
                    label: Text(l.shopAlreadyKnown,
                        style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontSize: 12)),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    padding: EdgeInsets.zero,
                  )
                : FilledButton(
                    onPressed: () => _import(context, shop),
                    child: Text(l.importShop),
                  ),
          ),
        );
      },
    );
  }
}
