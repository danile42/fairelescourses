import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../models/community_layout.dart';
import '../models/supermarket.dart';
import '../providers/firestore_sync_provider.dart';
import '../providers/home_location_provider.dart';
import '../providers/supermarket_provider.dart';
import '../services/firestore_service.dart';
import '../services/nominatim_service.dart';
import '../services/overpass_service.dart';
import 'community_layouts_sheet.dart';
import 'store_editor_screen.dart';

enum _SearchMode { byLocation, byItem }

double shopSearchHaversineKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLng / 2) *
          sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// Returns true if [shop] is already represented in [stores].
/// When [shop] has coordinates, proximity (< 0.2 km) is used; otherwise
/// falls back to a case-insensitive name match.
bool isKnownFirestore(Supermarket shop, List<Supermarket> stores) {
  final lat = shop.lat;
  final lng = shop.lng;
  if (lat != null && lng != null) {
    return stores.any(
      (s) =>
          s.lat != null &&
          s.lng != null &&
          shopSearchHaversineKm(lat, lng, s.lat!, s.lng!) < 0.2,
    );
  }
  return stores.any((s) => s.name.toLowerCase() == shop.name.toLowerCase());
}

/// Returns true if an OSM shop result is already represented in [stores].
/// OSM shops always have coordinates, so only proximity (< 0.2 km) is used.
bool isKnownOsm(double osmLat, double osmLng, List<Supermarket> stores) =>
    findLocalByOsm(osmLat, osmLng, stores) != null;

/// Returns the local [Supermarket] that matches the given OSM coordinates,
/// or null if none is within 0.2 km.
Supermarket? findLocalByOsm(
  double osmLat,
  double osmLng,
  List<Supermarket> stores,
) => stores
    .where(
      (s) =>
          s.lat != null &&
          s.lng != null &&
          shopSearchHaversineKm(osmLat, osmLng, s.lat!, s.lng!) < 0.2,
    )
    .firstOrNull;

class ShopSearchScreen extends ConsumerStatefulWidget {
  /// When set, importing or creating a shop will open it immediately in the
  /// store editor with this item pre-focused, then return to the caller.
  final String? focusItem;

  const ShopSearchScreen({super.key, this.focusItem});

  @override
  ConsumerState<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

const _executeSearchButtonKey = Key('shopSearchExecuteButton');
const _retrySearchButtonKey = Key('shopSearchRetryButton');

class _ShopSearchScreenState extends ConsumerState<ShopSearchScreen> {
  TextEditingController? _autoCtrl;
  List<ShopSearchResult> _firestoreResults = [];
  List<OsmShop> _osmResults = [];
  bool _loading = false;
  bool _searched = false;
  bool _geocoding = false;
  bool _osmLoading = false;
  String? _networkError;
  String? _osmError;
  double? _lastLat;
  double? _lastLng;
  _SearchMode _mode = _SearchMode.byLocation;
  bool _nearMe = true;
  Set<OsmShopCategory> _selectedCategories = {osmShopCategories[0]};
  Set<String> _selectedBrands = {};
  String? _osmNameFilter;
  String _draftQuery = '';
  bool _showMap = false;
  int _osmRadiusMeters = 2000;
  Timer? _debounce;
  Timer? _retryTimer;
  int _retrySecondsLeft = 0;

  static const _kRadius = 'osmSearchRadius';
  static const _kCategories = 'osmSearchCategories';

  @override
  void initState() {
    super.initState();
    final box = Hive.box<String>('settings');
    final r = int.tryParse(box.get(_kRadius) ?? '');
    if (r != null) _osmRadiusMeters = r;
    final cats = box.get(_kCategories);
    if (cats != null && cats.isNotEmpty) {
      final loaded = cats
          .split(',')
          .map(
            (k) => osmShopCategories
                .where((c) => '${c.osmKey}:${c.osmValue}' == k)
                .firstOrNull,
          )
          .nonNulls
          .toSet();
      if (loaded.isNotEmpty) _selectedCategories = loaded;
    }
  }

  void _persistFilters() {
    final box = Hive.box<String>('settings');
    box.put(_kRadius, _osmRadiusMeters.toString());
    box.put(
      _kCategories,
      _selectedCategories.map((c) => '${c.osmKey}:${c.osmValue}').join(','),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _clearResults() {
    _firestoreResults = [];
    _osmResults = [];
    _searched = false;
    _networkError = null;
    _osmError = null;
    _osmLoading = false;
    _lastLat = null;
    _lastLng = null;
    _selectedBrands = {};
    _osmNameFilter = null;
    _showMap = false;
  }

  void _resetVisibleResults({bool preserveLastLocation = true}) {
    _retryTimer?.cancel();
    _firestoreResults = [];
    _osmResults = [];
    _loading = false;
    _searched = false;
    _geocoding = false;
    _osmLoading = false;
    _networkError = null;
    _osmError = null;
    _selectedBrands = {};
    _osmNameFilter = null;
    _showMap = false;
    _retrySecondsLeft = 0;
    if (!preserveLastLocation) {
      _lastLat = null;
      _lastLng = null;
    }
  }

  bool _canExecuteSearch(HomeLocation? homeLoc) {
    if (_mode == _SearchMode.byLocation && _nearMe && homeLoc != null) {
      return true;
    }
    return _draftQuery.length >= 2;
  }

  Future<void> _runSearchFromCurrentInput() async {
    _debounce?.cancel();
    final homeLoc = ref.read(homeLocationProvider);
    if (_mode == _SearchMode.byLocation && _nearMe && homeLoc != null) {
      _debounce = Timer(const Duration(milliseconds: 400), () => _search(''));
      return;
    }
    final query = _draftQuery;
    if (query.length < 2) {
      if (!mounted) return;
      setState(() => _resetVisibleResults());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  bool get _hasMapData {
    if (!_searched) return false;
    return _firestoreResults.any(
          (r) => r.shop.lat != null && r.shop.lng != null,
        ) ||
        _osmResults.isNotEmpty;
  }

  void _onChanged(String q) {
    if (!mounted) return;
    setState(() {
      _draftQuery = q.trim();
      _resetVisibleResults();
    });
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      if (_mode == _SearchMode.byLocation) {
        await _searchByLocation(q);
      } else {
        // byItem
        final svc = ref.read(firestoreServiceProvider);
        final shops = await svc.searchByItem(q);
        if (!mounted) return;
        // Also include locally-stored shops that contain the queried item.
        final remoteIds = shops.map((s) => s.id).toSet();
        final qLower = q.toLowerCase().trim();
        final localMatches = ref
            .read(supermarketsProvider)
            .where(
              (s) =>
                  !remoteIds.contains(s.id) &&
                  (s.cells.values.any(
                        (goods) =>
                            goods.any((g) => g.toLowerCase().trim() == qLower),
                      ) ||
                      s.subcells.values.any(
                        (goods) =>
                            goods.any((g) => g.toLowerCase().trim() == qLower),
                      )),
            )
            .map((s) => ShopSearchResult(shop: s))
            .toList();
        if (!mounted) return;
        setState(() {
          _firestoreResults = [
            ...localMatches,
            ...shops.map((s) => ShopSearchResult(shop: s)),
          ];
          _osmResults = [];
          _loading = false;
          _searched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _searched = true;
          _networkError = e.toString();
        });
      }
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
        setState(() {
          _loading = false;
          _searched = true;
        });
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.geocodeFailed)));
        return;
      }
      lat = coords.lat;
      lng = coords.lng;
    }

    _lastLat = lat;
    _lastLng = lng;

    setState(() => _osmLoading = true);

    List<ShopSearchResult> firestoreHits;
    try {
      firestoreHits = await ref
          .read(firestoreServiceProvider)
          .searchNearby(lat, lng, 25.0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searched = true;
        _networkError = e.toString();
        _osmLoading = false;
      });
      return;
    }

    if (!mounted) return;
    // OSM-linked shops are now auto-published to the community versions
    // subcollection on every save, so they surface via the community layouts
    // sheet when tapping an OSM card.  Only show non-OSM Firestore results as
    // standalone cards; let the OSM cards handle the rest.
    final nonOsmFirestoreHits = firestoreHits
        .where((r) => r.shop.osmId == null)
        .toList();
    setState(() {
      _firestoreResults = nonOsmFirestoreHits;
      _loading = false;
      _searched = true;
    });

    try {
      final osmHits = await OverpassService.searchNearby(
        lat,
        lng,
        _osmRadiusMeters,
        categories: _selectedCategories,
      );
      if (!mounted) return;
      final osmOnly = osmHits
          .where((osm) => !_coveredByFirestore(osm, nonOsmFirestoreHits))
          .toList();
      setState(() {
        _osmResults = osmOnly;
        _osmLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _osmLoading = false;
        _osmError = e is OverpassException ? e.shortLabel : 'error';
      });
      _startRetryCountdown();
    }
  }

  void _startRetryCountdown([int seconds = 5]) {
    _retryTimer?.cancel();
    setState(() => _retrySecondsLeft = seconds);
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _retrySecondsLeft--;
        if (_retrySecondsLeft <= 0) t.cancel();
      });
    });
  }

  Future<void> _retryOsm() async {
    final lat = _lastLat;
    final lng = _lastLng;
    if (lat == null || lng == null) return;
    _retryTimer?.cancel();
    setState(() {
      _retrySecondsLeft = 0;
      _osmError = null;
      _osmLoading = true;
    });
    try {
      final osmHits = await OverpassService.searchNearby(
        lat,
        lng,
        _osmRadiusMeters,
        categories: _selectedCategories,
      );
      if (!mounted) return;
      final osmOnly = osmHits
          .where((osm) => !_coveredByFirestore(osm, _firestoreResults))
          .toList();
      setState(() {
        _osmResults = osmOnly;
        _osmLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _osmLoading = false;
        _osmError = e is OverpassException ? e.shortLabel : 'error';
      });
      _startRetryCountdown();
    }
  }

  bool _coveredByFirestore(OsmShop osm, List<ShopSearchResult> hits) {
    final name = osm.name.toLowerCase();
    for (final r in hits) {
      if (r.shop.name.toLowerCase() == name) return true;
      final sLat = r.shop.lat;
      final sLng = r.shop.lng;
      if (sLat != null &&
          sLng != null &&
          _haversine(osm.lat, osm.lng, sLat, sLng) < 0.2) {
        return true;
      }
    }
    return false;
  }

  static double _haversine(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) => shopSearchHaversineKm(lat1, lng1, lat2, lng2);

  static String _extractBrand(String name, String? osmBrand) {
    if (osmBrand != null && osmBrand.isNotEmpty) return osmBrand;
    final first = name.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? name : first;
  }

  Set<String> get _availableBrands {
    final brands = <String>{};
    for (final r in _firestoreResults) {
      brands.add(_extractBrand(r.shop.name, null));
    }
    for (final osm in _osmResults) {
      brands.add(_extractBrand(osm.name, osm.brand));
    }
    return brands;
  }

  void _switchMode(_SearchMode mode) {
    _autoCtrl?.clear();
    setState(() {
      _mode = mode;
      _draftQuery = '';
      _clearResults();
    });
  }

  Future<void> _import(BuildContext context, Supermarket source) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final copy = Supermarket(
      id: source.id,
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
      osmId: source.osmId,
      osmCategory: source.osmCategory,
      osmCategories: source.osmCategories ?? source.categories,
    );
    // The shop already exists in Firestore (it came from a community search).
    // Writing it back would fail with PERMISSION_DENIED (the current user
    // doesn't own the remote document). Save locally only.
    await ref
        .read(supermarketsProvider.notifier)
        .add(copy, syncToFirestore: false);
    if (!mounted) return;
    if (widget.focusItem != null) {
      await nav.push(
        MaterialPageRoute(
          builder: (_) => StoreEditorScreen(
            existing: copy,
            focusItems: [widget.focusItem!],
          ),
        ),
      );
      if (mounted) nav.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l.shopImported)));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stores = ref.watch(supermarketsProvider);
    final homeLoc = ref.watch(homeLocationProvider);
    final itemSuggestions =
        stores
            .expand((s) => s.cells.values.expand((goods) => goods))
            .map((g) => g.trim())
            .where((g) => g.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final theme = Theme.of(context);

    // Apply brand filter (empty selection = show all).
    // Firestore results that are already in the local collection are kept
    // in the list — _buildFirestoreCard shows them with an "In your list"
    // chip instead of an Import button.
    final filteredFirestore = _selectedBrands.isEmpty
        ? _firestoreResults
        : _firestoreResults
              .where(
                (r) =>
                    _selectedBrands.contains(_extractBrand(r.shop.name, null)),
              )
              .toList();
    final filteredOsm = _osmResults.where((osm) {
      if (_osmNameFilter != null &&
          !osm.name.toLowerCase().contains(_osmNameFilter!)) {
        return false;
      }
      if (_selectedBrands.isNotEmpty &&
          !_selectedBrands.contains(_extractBrand(osm.name, osm.brand))) {
        return false;
      }
      return true;
    }).toList();

    final availableBrands = _availableBrands;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.searchShops),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_hasMapData)
            IconButton(
              icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
              tooltip: _showMap ? l.listView : l.mapView,
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SegmentedButton<_SearchMode>(
              segments: [
                ButtonSegment(
                  value: _SearchMode.byLocation,
                  label: Text(l.searchByLocation),
                  icon: const Icon(Icons.location_on_outlined),
                ),
                ButtonSegment(
                  value: _SearchMode.byItem,
                  label: Text(l.searchByItem),
                  icon: const Icon(Icons.shopping_basket_outlined),
                ),
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
                    avatar: const Icon(Icons.home, size: 16),
                    label: Text(l.nearMe),
                    selected: _nearMe,
                    onSelected: (val) {
                      setState(() {
                        _nearMe = val;
                        _resetVisibleResults();
                      });
                      if (val) {
                        _autoCtrl?.clear();
                        _draftQuery = '';
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildRadiusPicker(theme),
                  const Spacer(),
                  IconButton(
                    key: _executeSearchButtonKey,
                    icon: const Icon(Icons.search),
                    onPressed: _canExecuteSearch(homeLoc)
                        ? _runSearchFromCurrentInput
                        : null,
                  ),
                ],
              ),
            ),
          if (!(_mode == _SearchMode.byLocation && _nearMe && homeLoc != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (tv) {
                        if (_mode != _SearchMode.byItem ||
                            tv.text.trim().isEmpty) {
                          return const [];
                        }
                        final q = tv.text.toLowerCase();
                        return itemSuggestions
                            .where((s) => s.toLowerCase().contains(q))
                            .take(8);
                      },
                      onSelected: (_) => _onChanged(_autoCtrl?.text ?? ''),
                      fieldViewBuilder:
                          (context, ctrl, focusNode, onFieldSubmitted) {
                            _autoCtrl = ctrl;
                            return TextField(
                              controller: ctrl,
                              focusNode: focusNode,
                              autofocus: _mode != _SearchMode.byLocation,
                              decoration: InputDecoration(
                                hintText: _mode == _SearchMode.byItem
                                    ? l.searchItemHint
                                    : l.locationSearchHint,
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: (_loading || _geocoding)
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: _onChanged,
                              onSubmitted: (_) {
                                if (_mode == _SearchMode.byLocation) {
                                  _runSearchFromCurrentInput();
                                }
                              },
                              textInputAction: TextInputAction.done,
                            );
                          },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!(_mode == _SearchMode.byLocation && homeLoc != null))
                    IconButton(
                      key: _executeSearchButtonKey,
                      icon: const Icon(Icons.search),
                      onPressed: _canExecuteSearch(homeLoc)
                          ? _runSearchFromCurrentInput
                          : null,
                    ),
                ],
              ),
            ),
          if (_mode == _SearchMode.byLocation ||
              (_searched && availableBrands.length >= 2))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                children: [
                  if (_mode == _SearchMode.byLocation)
                    _buildCategoryFilter(l, theme),
                  if (_mode == _SearchMode.byLocation &&
                      _searched &&
                      availableBrands.length >= 2)
                    const SizedBox(width: 8),
                  if (_searched && availableBrands.length >= 2)
                    _buildBrandFilter(l, theme, availableBrands),
                ],
              ),
            ),
          if (_showMap && _hasMapData) ...[
            if (_osmError != null || _osmLoading) _buildOsmStatusRow(l, theme),
            Expanded(
              child: _buildMapView(
                context,
                l,
                stores,
                theme,
                filteredFirestore,
                filteredOsm,
              ),
            ),
          ] else
            Expanded(
              child: _buildResults(
                context,
                l,
                stores,
                theme,
                filteredFirestore,
                filteredOsm,
              ),
            ),
        ],
      ),
    );
  }

  // ── List view ────────────────────────────────────────────────────────────────

  Widget _buildResults(
    BuildContext context,
    AppLocalizations l,
    List<Supermarket> stores,
    ThemeData theme,
    List<ShopSearchResult> filteredFirestore,
    List<OsmShop> filteredOsm,
  ) {
    if (_mode == _SearchMode.byLocation) {
      final homeLoc = ref.read(homeLocationProvider);
      if (_nearMe && homeLoc == null && !_searched) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l.noLocationSet,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      }
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_networkError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                l.geocodeFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (!_searched) {
      // Show OSM status in location mode, otherwise show the same
      // "press search" hint in both search modes.
      if (_mode == _SearchMode.byLocation && _osmError != null) {
        return _buildOsmStatusRow(l, theme);
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.searchPromptBeforeIcon,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    l.searchPromptAfterIcon,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final hasFirestore = filteredFirestore.isNotEmpty;
    final hasOsm = filteredOsm.isNotEmpty;
    final showOsmSection = hasOsm || _osmLoading || _osmError != null;

    // If search completed but has no results and OSM had an error, show retry
    if (!hasFirestore && !hasOsm && _osmError != null) {
      return _buildOsmStatusRow(l, theme);
    }

    if (!hasFirestore && !showOsmSection) {
      if (_selectedBrands.isNotEmpty) {
        return Center(
          child: Text(
            l.noShopsMatchFilter,
            style: const TextStyle(color: Colors.grey),
          ),
        );
      }
      if (_mode == _SearchMode.byItem) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l.searchByItemNoResults,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.noShopsFound, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreEditorScreen(
                    focusItems: widget.focusItem != null
                        ? [widget.focusItem!]
                        : const [],
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.newShop),
            ),
          ],
        ),
      );
    }

    // Section layout: [firestore items] [osm divider?] [osm items] [attribution?]
    final firestoreCount = filteredFirestore.length;
    final osmDividerCount = hasFirestore && showOsmSection ? 1 : 0;
    final osmSectionStart = firestoreCount + osmDividerCount;
    final osmItemCount = _osmLoading || _osmError != null
        ? 1
        : filteredOsm.length;
    final totalItems = osmSectionStart + osmItemCount;

    return ListView.builder(
      itemCount: totalItems + (showOsmSection ? 1 : 0),
      itemBuilder: (context, i) {
        if (showOsmSection && i == totalItems) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              l.osmAttribution,
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Firestore cards
        if (i < firestoreCount) {
          return _buildFirestoreCard(
            context,
            l,
            filteredFirestore[i],
            stores,
            theme,
          );
        }

        // OSM section divider
        if (osmDividerCount > 0 && i == firestoreCount) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l.osmShopsTitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          );
        }

        if (_osmLoading || _osmError != null) {
          return _buildOsmStatusRow(l, theme);
        }

        final osmIndex = i - osmSectionStart;
        return _buildOsmCard(context, l, filteredOsm[osmIndex], stores, theme);
      },
    );
  }

  void _openInEditor(BuildContext ctx, Supermarket store) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => StoreEditorScreen(existing: store)),
    );
  }

  Supermarket? _findLocalByOsm(OsmShop osm, List<Supermarket> stores) =>
      findLocalByOsm(osm.lat, osm.lng, stores) ??
      stores.where((s) => s.osmId == osm.osmId).firstOrNull;

  Widget _buildFirestoreCard(
    BuildContext context,
    AppLocalizations l,
    ShopSearchResult result,
    List<Supermarket> stores,
    ThemeData theme,
  ) {
    final shop = result.shop;
    final localStore = stores.where((s) => s.id == shop.id).firstOrNull;
    final known = localStore != null;
    final distText = result.distanceKm != null
        ? l.distanceKm(result.distanceKm!.toStringAsFixed(1))
        : null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.store_outlined),
        title: Text(shop.name),
        subtitle: Text(
          [
            '${shop.rows.length}×${shop.cols.length}  •  ${shop.cells.length} cells',
            ?distText,
            ?shop.address,
          ].nonNulls.join('  •  '),
        ),
        onTap: known ? () => _openInEditor(context, localStore) : null,
        trailing: known
            ? Chip(
                label: Text(
                  l.shopAlreadyKnown,
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                ),
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

  Future<void> _createFromOsm(BuildContext ctx, OsmShop osm) async {
    final nav = Navigator.of(ctx);
    Supermarket? template;
    try {
      template = await ref
          .read(firestoreServiceProvider)
          .fetchPublicShop(osm.osmId);
    } catch (_) {
      // network error; proceed without template
    }
    if (!mounted) return;
    await nav.push(
      MaterialPageRoute(
        builder: (_) => StoreEditorScreen(
          prefill: (
            name: osm.name,
            address: osm.address,
            lat: osm.lat,
            lng: osm.lng,
            osmId: osm.osmId,
            osmCategory: osm.osmCategory,
            osmCategories: osm.osmCategory != null ? [osm.osmCategory!] : null,
          ),
          template: template,
          focusItems: widget.focusItem != null ? [widget.focusItem!] : const [],
        ),
      ),
    );
  }

  Future<void> _browseLayouts(BuildContext ctx, OsmShop osm) async {
    final nav = Navigator.of(ctx);
    bool wantCreate = false;
    final layout = await showModalBottomSheet<CommunityLayout>(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => CommunityLayoutsSheet(
        osmId: osm.osmId,
        onCreateTap: () => wantCreate = true,
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (wantCreate) {
      await _createFromOsm(ctx, osm);
      if (!mounted) return;
      if (widget.focusItem != null) nav.pop();
      return;
    }
    if (layout == null) return;
    ref
        .read(firestoreServiceProvider)
        .incrementImportCount(osm.osmId, layout.versionId)
        .ignore();
    await nav.push(
      MaterialPageRoute(
        builder: (_) => StoreEditorScreen(
          prefill: (
            name: osm.name,
            address: osm.address,
            lat: osm.lat,
            lng: osm.lng,
            osmId: osm.osmId,
            osmCategory: osm.osmCategory,
            osmCategories: osm.osmCategory != null ? [osm.osmCategory!] : null,
          ),
          template: layout.asTemplate,
          focusItems: widget.focusItem != null ? [widget.focusItem!] : const [],
        ),
      ),
    );
    if (!mounted) return;
    if (widget.focusItem != null) nav.pop();
  }

  Widget _buildOsmCard(
    BuildContext context,
    AppLocalizations l,
    OsmShop osm,
    List<Supermarket> stores,
    ThemeData theme,
  ) {
    final localStore = _findLocalByOsm(osm, stores);
    final alreadyLocal = localStore != null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.store_outlined, color: theme.colorScheme.secondary),
        title: Text(osm.name),
        subtitle: Text([?osm.address].nonNulls.join('  •  ')),
        onTap: alreadyLocal
            ? () => _openInEditor(context, localStore)
            : () => _browseLayouts(context, osm),
        trailing: alreadyLocal
            ? Chip(
                label: Text(
                  l.alreadyDefined,
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: theme.colorScheme.secondaryContainer,
                padding: EdgeInsets.zero,
              )
            : null,
      ),
    );
  }

  // ── Map view ─────────────────────────────────────────────────────────────────

  Widget _buildMapView(
    BuildContext context,
    AppLocalizations l,
    List<Supermarket> stores,
    ThemeData theme,
    List<ShopSearchResult> filteredFirestore,
    List<OsmShop> filteredOsm,
  ) {
    final markers = <Marker>[];

    for (final r in filteredFirestore) {
      final lat = r.shop.lat;
      final lng = r.shop.lng;
      if (lat == null || lng == null) continue;
      final localStore = stores.where((s) => s.id == r.shop.id).firstOrNull;
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => _showFirestoreSheet(context, l, r, localStore, theme),
            child: Icon(
              Icons.location_pin,
              size: 36,
              color: localStore != null
                  ? Colors.grey
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    for (final osm in filteredOsm) {
      final localStore = _findLocalByOsm(osm, stores);
      markers.add(
        Marker(
          point: LatLng(osm.lat, osm.lng),
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () =>
                _showOsmSheet(context, l, osm, localStore, stores, theme),
            child: Icon(
              Icons.location_pin,
              size: 36,
              color: localStore != null
                  ? Colors.grey
                  : theme.colorScheme.secondary,
            ),
          ),
        ),
      );
    }

    // Center on last searched location; fall back to centroid of markers
    final LatLng center;
    if (_lastLat != null && _lastLng != null) {
      center = LatLng(_lastLat!, _lastLng!);
    } else if (markers.isNotEmpty) {
      final avgLat =
          markers.map((m) => m.point.latitude).reduce((a, b) => a + b) /
          markers.length;
      final avgLng =
          markers.map((m) => m.point.longitude).reduce((a, b) => a + b) /
          markers.length;
      center = LatLng(avgLat, avgLng);
    } else {
      center = const LatLng(51.5, 10.0); // centre of Germany as fallback
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: _lastLat != null ? 12.0 : 10.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fairelescourses.fairelescourses',
        ),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  void _showFirestoreSheet(
    BuildContext pageContext,
    AppLocalizations l,
    ShopSearchResult result,
    Supermarket? localStore,
    ThemeData theme,
  ) {
    final shop = result.shop;
    final known = localStore != null;
    showModalBottomSheet(
      context: pageContext,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shop.name, style: theme.textTheme.titleLarge),
              if (shop.address != null) ...[
                const SizedBox(height: 4),
                Text(shop.address!, style: theme.textTheme.bodyMedium),
              ],
              if (result.distanceKm != null) ...[
                const SizedBox(height: 4),
                Text(
                  l.distanceKm(result.distanceKm!.toStringAsFixed(1)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: known
                    ? FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _openInEditor(pageContext, localStore);
                        },
                        child: Text(l.editShop),
                      )
                    : FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _import(pageContext, shop);
                        },
                        child: Text(l.importShop),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOsmSheet(
    BuildContext pageContext,
    AppLocalizations l,
    OsmShop osm,
    Supermarket? localStore,
    List<Supermarket> stores,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: pageContext,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(osm.name, style: theme.textTheme.titleLarge),
              if (osm.address != null) ...[
                const SizedBox(height: 4),
                Text(osm.address!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: localStore != null
                    ? FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _openInEditor(pageContext, localStore);
                        },
                        child: Text(l.editShop),
                      )
                    : FilledButton(
                        onPressed: () async {
                          final nav = Navigator.of(pageContext);
                          Navigator.pop(sheetCtx);
                          await _createFromOsm(pageContext, osm);
                          if (!mounted) return;
                          if (widget.focusItem != null) {
                            nav.pop();
                          }
                        },
                        child: Text(l.createShop),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category filter (byLocation mode) ────────────────────────────────────────

  Widget _buildCategoryFilter(AppLocalizations l, ThemeData theme) {
    final active = _selectedCategories.length > 1;
    return PopupMenuButton<OsmShopCategory>(
      tooltip: l.brandFilter,
      onSelected: (cat) {
        setState(() {
          if (_selectedCategories.contains(cat)) {
            if (_selectedCategories.length > 1) _selectedCategories.remove(cat);
          } else {
            _selectedCategories.add(cat);
          }
          _osmResults = [];
          _osmError = null;
        });
        _persistFilters();
      },
      itemBuilder: (ctx) => osmShopCategories
          .map(
            (cat) => CheckedPopupMenuItem<OsmShopCategory>(
              value: cat,
              checked: _selectedCategories.contains(cat),
              child: Text(osmCategoryLabel(l, cat.labelKey)),
            ),
          )
          .toList(),
      child: InputChip(
        avatar: Icon(
          Icons.category_outlined,
          size: 18,
          color: active
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(
          _selectedCategories.length == 1
              ? osmCategoryLabel(l, _selectedCategories.first.labelKey)
              : '${osmCategoryLabel(l, _selectedCategories.first.labelKey)} + ${_selectedCategories.length - 1}',
        ),
        selected: active,
        onDeleted: active
            ? () {
                setState(() {
                  _selectedCategories = {osmShopCategories[0]};
                  _osmResults = [];
                  _osmError = null;
                });
                _persistFilters();
              }
            : null,
        onPressed: null,
      ),
    );
  }

  // ── Radius picker ─────────────────────────────────────────────────────────────

  static const _radiusOptions = [500, 1000, 2000, 5000, 10000];

  Widget _buildRadiusPicker(ThemeData theme) {
    return PopupMenuButton<int>(
      onSelected: (r) {
        setState(() {
          _osmRadiusMeters = r;
          _osmResults = [];
          _osmError = null;
        });
        _persistFilters();
      },
      itemBuilder: (ctx) => _radiusOptions
          .map(
            (r) => CheckedPopupMenuItem<int>(
              value: r,
              checked: r == _osmRadiusMeters,
              child: Text(formatOsmRadius(r)),
            ),
          )
          .toList(),
      child: Chip(
        avatar: Icon(
          Icons.radio_button_checked,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(formatOsmRadius(_osmRadiusMeters)),
      ),
    );
  }

  // ── OSM status row (error or loading) ────────────────────────────────────────

  Widget _buildOsmStatusRow(AppLocalizations l, ThemeData theme) {
    if (_osmLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final cooling = _retrySecondsLeft > 0;
    final errorLabel = _osmError;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.osmLoadFailed,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          if (errorLabel != null)
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              color: Colors.grey,
              tooltip: errorLabel,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.osmLoadFailed),
                  content: Text(errorLabel),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.ok),
                    ),
                  ],
                ),
              ),
            ),
          TextButton.icon(
            key: _retrySearchButtonKey,
            onPressed: cooling ? null : _retryOsm,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(cooling ? '${l.retry} ($_retrySecondsLeft)' : l.retry),
          ),
        ],
      ),
    );
  }

  // ── Brand filter ─────────────────────────────────────────────────────────────

  Widget _buildBrandFilter(
    AppLocalizations l,
    ThemeData theme,
    Set<String> brands,
  ) {
    final sorted = brands.toList()..sort();
    final active = _selectedBrands.isNotEmpty;
    return PopupMenuButton<String>(
      tooltip: l.brandFilter,
      onSelected: (brand) {
        setState(() {
          if (_selectedBrands.contains(brand)) {
            _selectedBrands.remove(brand);
          } else {
            _selectedBrands.add(brand);
          }
        });
      },
      itemBuilder: (ctx) => sorted
          .map(
            (brand) => CheckedPopupMenuItem<String>(
              value: brand,
              checked: _selectedBrands.contains(brand),
              child: Text(brand),
            ),
          )
          .toList(),
      child: InputChip(
        avatar: Icon(
          Icons.storefront_outlined,
          size: 18,
          color: active
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(
          active
              ? _selectedBrands.length == 1
                    ? _selectedBrands.first
                    : '${_selectedBrands.first} + ${_selectedBrands.length - 1}'
              : l.brandFilter,
        ),
        selected: active,
        onDeleted: active ? () => setState(() => _selectedBrands = {}) : null,
        onPressed: null, // tap handled by PopupMenuButton
      ),
    );
  }
}
