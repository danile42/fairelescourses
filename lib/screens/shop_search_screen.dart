import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../models/supermarket.dart';
import '../providers/home_location_provider.dart';
import '../providers/supermarket_provider.dart';
import '../services/firestore_service.dart';
import '../services/nominatim_service.dart';
import '../services/overpass_service.dart';
import 'store_editor_screen.dart';

const _uuid = Uuid();

enum _SearchMode { byName, byItem, byLocation }

class ShopSearchScreen extends ConsumerStatefulWidget {
  const ShopSearchScreen({super.key});

  @override
  ConsumerState<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends ConsumerState<ShopSearchScreen> {
  TextEditingController? _autoCtrl;
  // Firestore results (shops with full layout data)
  List<ShopSearchResult> _firestoreResults = [];
  // OSM-only results (shops not yet in Firestore, no layout data)
  List<OsmShop> _osmResults = [];
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

  void _clearResults() {
    _firestoreResults = [];
    _osmResults = [];
    _searched = false;
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (_mode == _SearchMode.byLocation) {
      if (q.trim().length < 2) setState(_clearResults);
      return;
    }
    if (q.trim().length < 2) {
      setState(_clearResults);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      if (_mode == _SearchMode.byLocation) {
        await _searchByLocation(q);
      } else {
        final shops = _mode == _SearchMode.byItem
            ? await FirestoreService.searchByItem(q)
            : await FirestoreService.searchByName(q);
        if (mounted) {
          setState(() {
            _firestoreResults = shops.map((s) => ShopSearchResult(shop: s)).toList();
            _osmResults = [];
            _loading = false;
            _searched = true;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _searched = true; });
    }
  }

  Future<void> _searchByLocation(String q) async {
    final home = ref.read(homeLocationProvider);
    double lat, lng;

    if (_nearMe && home != null) {
      lat = home.lat;
      lng = home.lng;
    } else {
      setState(() => _geocoding = true);
      final coords = await NominatimService.geocode(q);
      if (!mounted) return;
      setState(() => _geocoding = false);
      if (coords == null) {
        setState(() { _loading = false; _searched = true; });
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.geocodeFailed)));
        return;
      }
      lat = coords.lat;
      lng = coords.lng;
    }

    // Run Firestore (25 km) and Overpass (2 km) in parallel
    final futures = await Future.wait([
      FirestoreService.searchNearby(lat, lng, 25.0),
      OverpassService.searchNearby(lat, lng, 2000),
    ]);

    if (!mounted) return;
    final firestoreHits = futures[0] as List<ShopSearchResult>;
    final osmHits = futures[1] as List<OsmShop>;

    // Remove OSM shops already represented in Firestore results
    final osmOnly = osmHits.where((osm) => !_coveredByFirestore(osm, firestoreHits)).toList();

    setState(() {
      _firestoreResults = firestoreHits;
      _osmResults = osmOnly;
      _loading = false;
      _searched = true;
    });
  }

  /// True if an OSM shop already has a matching entry in the Firestore results
  /// (same name or within 200 m).
  bool _coveredByFirestore(OsmShop osm, List<ShopSearchResult> hits) {
    final name = osm.name.toLowerCase();
    for (final r in hits) {
      if (r.shop.name.toLowerCase() == name) return true;
      final sLat = r.shop.lat;
      final sLng = r.shop.lng;
      if (sLat != null && sLng != null && _haversine(osm.lat, osm.lng, sLat, sLng) < 0.2) {
        return true;
      }
    }
    return false;
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _switchMode(_SearchMode mode) {
    _autoCtrl?.clear();
    setState(() {
      _mode = mode;
      _clearResults();
    });
    if (mode == _SearchMode.byLocation) {
      final home = ref.read(homeLocationProvider);
      if (_nearMe && home != null) _search('');
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
    setState(() {});
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
                        _clearResults();
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
                      if (q.trim().length >= 2) _search(q.trim());
                    },
                  );
                },
              ),
            ),
          Expanded(child: _buildResults(context, l, knownNames, stores, theme)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, AppLocalizations l,
      Set<String> knownNames, List<Supermarket> stores, ThemeData theme) {
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
      if (_mode == _SearchMode.byLocation && _nearMe) return const SizedBox.shrink();
      return Center(
        child: Text(l.searchShopsMinChars, style: const TextStyle(color: Colors.grey)),
      );
    }
    if (_loading && _firestoreResults.isEmpty && _osmResults.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasFirestore = _firestoreResults.isNotEmpty;
    final hasOsm = _osmResults.isNotEmpty;

    if (!hasFirestore && !hasOsm) {
      return Center(
          child: Text(l.noShopsFound, style: const TextStyle(color: Colors.grey)));
    }

    // Build a flat list: Firestore results, then divider, then OSM results
    final firestoreCount = _firestoreResults.length;
    final osmCount = _osmResults.length;
    // Items: firestoreCount + (divider if both) + osmCount
    final showDivider = hasFirestore && hasOsm;
    final totalItems = firestoreCount + (showDivider ? 1 : 0) + osmCount;

    return ListView.builder(
      itemCount: totalItems + (hasOsm ? 1 : 0), // +1 for attribution footer
      itemBuilder: (context, i) {
        // Attribution footer at the very end
        if (i == totalItems) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              l.osmAttribution,
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Divider between sections
        if (showDivider && i == firestoreCount) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(l.osmShopsTitle,
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
              ),
              const Expanded(child: Divider()),
            ]),
          );
        }

        // Firestore result
        if (i < firestoreCount) {
          return _buildFirestoreCard(context, l, _firestoreResults[i], knownNames, theme);
        }

        // OSM result
        final osmIndex = i - firestoreCount - (showDivider ? 1 : 0);
        return _buildOsmCard(context, l, _osmResults[osmIndex], stores, knownNames, theme);
      },
    );
  }

  Widget _buildFirestoreCard(BuildContext context, AppLocalizations l,
      ShopSearchResult result, Set<String> knownNames, ThemeData theme) {
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
  }

  Widget _buildOsmCard(BuildContext context, AppLocalizations l, OsmShop osm,
      List<Supermarket> stores, Set<String> knownNames, ThemeData theme) {
    // Check if already in the user's local database
    final alreadyLocal = knownNames.contains(osm.name.toLowerCase()) ||
        stores.any((s) =>
            s.lat != null &&
            s.lng != null &&
            _haversine(osm.lat, osm.lng, s.lat!, s.lng!) < 0.2);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.store_outlined, color: theme.colorScheme.secondary),
        title: Text(osm.name),
        subtitle: Text([?osm.address].nonNulls.join('  •  ')),
        trailing: alreadyLocal
            ? Chip(
                label: Text(l.alreadyDefined,
                    style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 12)),
                backgroundColor: theme.colorScheme.secondaryContainer,
                padding: EdgeInsets.zero,
              )
            : FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreEditorScreen(
                      prefill: (
                        name: osm.name,
                        address: osm.address,
                        lat: osm.lat,
                        lng: osm.lng,
                      ),
                    ),
                  ),
                ),
                child: Text(l.createShop),
              ),
      ),
    );
  }
}
