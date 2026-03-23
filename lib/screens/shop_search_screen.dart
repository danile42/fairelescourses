import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
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
  _SearchMode _mode = _SearchMode.byName;
  bool _nearMe = true;
  Set<String> _selectedBrands = {};
  bool _showMap = false;
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
    _networkError = null;
    _osmError = null;
    _osmLoading = false;
    _lastLat = null;
    _lastLng = null;
    _selectedBrands = {};
    _showMap = false;
  }

  bool get _hasMapData {
    if (!_searched) return false;
    return _firestoreResults.any((r) => r.shop.lat != null && r.shop.lng != null) ||
        _osmResults.isNotEmpty;
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
        setState(() { _loading = false; _searched = true; });
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.geocodeFailed)));
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
      firestoreHits = await FirestoreService.searchNearby(lat, lng, 25.0);
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
    setState(() {
      _firestoreResults = firestoreHits;
      _loading = false;
      _searched = true;
    });

    try {
      final osmHits = await OverpassService.searchNearby(lat, lng, 2000);
      if (!mounted) return;
      final osmOnly = osmHits
          .where((osm) => !_coveredByFirestore(osm, firestoreHits))
          .toList();
      setState(() {
        _osmResults = osmOnly;
        _osmLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _osmLoading = false;
        _osmError = e.toString();
      });
    }
  }

  Future<void> _retryOsm() async {
    final lat = _lastLat;
    final lng = _lastLng;
    if (lat == null || lng == null) return;
    setState(() {
      _osmError = null;
      _osmLoading = true;
    });
    try {
      final osmHits = await OverpassService.searchNearby(lat, lng, 2000);
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
        _osmError = e.toString();
      });
    }
  }

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
      parentId: source.id,
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

    // Apply brand filter (empty selection = show all)
    final filteredFirestore = _selectedBrands.isEmpty
        ? _firestoreResults
        : _firestoreResults
            .where((r) => _selectedBrands.contains(_extractBrand(r.shop.name, null)))
            .toList();
    final filteredOsm = _selectedBrands.isEmpty
        ? _osmResults
        : _osmResults
            .where((osm) => _selectedBrands.contains(_extractBrand(osm.name, osm.brand)))
            .toList();

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
          if (_searched && availableBrands.length >= 2)
            _buildBrandFilter(l, theme, availableBrands),
          if (_showMap && _hasMapData)
            Expanded(
              child: _buildMapView(
                  context, l, knownNames, stores, theme, filteredFirestore, filteredOsm),
            )
          else
            Expanded(
              child: _buildResults(
                  context, l, knownNames, stores, theme, filteredFirestore, filteredOsm),
            ),
        ],
      ),
    );
  }

  // ── List view ────────────────────────────────────────────────────────────────

  Widget _buildResults(
      BuildContext context,
      AppLocalizations l,
      Set<String> knownNames,
      List<Supermarket> stores,
      ThemeData theme,
      List<ShopSearchResult> filteredFirestore,
      List<OsmShop> filteredOsm) {
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
              Text(l.geocodeFailed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (!_searched) {
      if (_mode == _SearchMode.byLocation && _nearMe) return const SizedBox.shrink();
      return Center(
        child: Text(l.searchShopsMinChars, style: const TextStyle(color: Colors.grey)),
      );
    }

    final hasFirestore = filteredFirestore.isNotEmpty;
    final hasOsm = filteredOsm.isNotEmpty;
    final showOsmSection = hasOsm || _osmLoading || _osmError != null;

    if (!hasFirestore && !showOsmSection) {
      return Center(
        child: Text(
          _selectedBrands.isNotEmpty ? l.noShopsMatchFilter : l.noShopsFound,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final firestoreCount = filteredFirestore.length;
    final showDivider = hasFirestore && showOsmSection;
    final osmCount = filteredOsm.length;
    final osmSectionStart = firestoreCount + (showDivider ? 1 : 0);
    final osmItemCount = _osmLoading || _osmError != null ? 1 : osmCount;
    final showAttribution = showOsmSection;
    final totalItems = osmSectionStart + osmItemCount;

    return ListView.builder(
      itemCount: totalItems + (showAttribution ? 1 : 0),
      itemBuilder: (context, i) {
        if (showAttribution && i == totalItems) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              l.osmAttribution,
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

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

        if (i < firestoreCount) {
          return _buildFirestoreCard(
              context, l, filteredFirestore[i], knownNames, theme);
        }

        if (_osmLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (_osmError != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.osmLoadFailed,
                      style: const TextStyle(color: Colors.grey)),
                ),
                TextButton.icon(
                  onPressed: _retryOsm,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l.retry),
                ),
              ],
            ),
          );
        }

        final osmIndex = i - osmSectionStart;
        return _buildOsmCard(
            context, l, filteredOsm[osmIndex], stores, knownNames, theme);
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

  // ── Map view ─────────────────────────────────────────────────────────────────

  Widget _buildMapView(
      BuildContext context,
      AppLocalizations l,
      Set<String> knownNames,
      List<Supermarket> stores,
      ThemeData theme,
      List<ShopSearchResult> filteredFirestore,
      List<OsmShop> filteredOsm) {
    final markers = <Marker>[];

    for (final r in filteredFirestore) {
      final lat = r.shop.lat;
      final lng = r.shop.lng;
      if (lat == null || lng == null) continue;
      final known = knownNames.contains(r.shop.name.toLowerCase());
      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _showFirestoreSheet(context, l, r, known, theme),
          child: Icon(
            Icons.location_pin,
            size: 36,
            color: known ? Colors.grey : theme.colorScheme.primary,
          ),
        ),
      ));
    }

    for (final osm in filteredOsm) {
      final alreadyLocal = knownNames.contains(osm.name.toLowerCase()) ||
          stores.any((s) =>
              s.lat != null &&
              s.lng != null &&
              _haversine(osm.lat, osm.lng, s.lat!, s.lng!) < 0.2);
      markers.add(Marker(
        point: LatLng(osm.lat, osm.lng),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _showOsmSheet(context, l, osm, alreadyLocal, stores, knownNames, theme),
          child: Icon(
            Icons.location_pin,
            size: 36,
            color: alreadyLocal ? Colors.grey : theme.colorScheme.secondary,
          ),
        ),
      ));
    }

    // Center on last searched location; fall back to centroid of markers
    final LatLng center;
    if (_lastLat != null && _lastLng != null) {
      center = LatLng(_lastLat!, _lastLng!);
    } else if (markers.isNotEmpty) {
      final avgLat = markers.map((m) => m.point.latitude).reduce((a, b) => a + b) / markers.length;
      final avgLng = markers.map((m) => m.point.longitude).reduce((a, b) => a + b) / markers.length;
      center = LatLng(avgLat, avgLng);
    } else {
      center = const LatLng(51.5, 10.0); // centre of Germany as fallback
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: _lastLat != null ? 12.0 : 10.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fairelescourses.fairelescourses',
        ),
        MarkerLayer(markers: markers),
        RichAttributionWidget(attributions: [
          TextSourceAttribution('OpenStreetMap contributors'),
        ]),
      ],
    );
  }

  void _showFirestoreSheet(BuildContext pageContext, AppLocalizations l,
      ShopSearchResult result, bool known, ThemeData theme) {
    final shop = result.shop;
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
                Text(l.distanceKm(result.distanceKm!.toStringAsFixed(1)),
                    style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: known
                    ? OutlinedButton(
                        onPressed: null,
                        child: Text(l.shopAlreadyKnown),
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
      bool alreadyLocal,
      List<Supermarket> stores,
      Set<String> knownNames,
      ThemeData theme) {
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
                child: alreadyLocal
                    ? OutlinedButton(
                        onPressed: null,
                        child: Text(l.alreadyDefined),
                      )
                    : FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          Navigator.push(
                            pageContext,
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
                          );
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

  // ── Brand filter ─────────────────────────────────────────────────────────────

  Widget _buildBrandFilter(AppLocalizations l, ThemeData theme, Set<String> brands) {
    final sorted = brands.toList()..sort();
    final active = _selectedBrands.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: PopupMenuButton<String>(
          tooltip: l.brandFilter,
          // Close only on explicit dismiss, not on item tap, by returning
          // a dummy future from onSelected and never popping.
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
              .map((brand) => CheckedPopupMenuItem<String>(
                    value: brand,
                    checked: _selectedBrands.contains(brand),
                    child: Text(brand),
                  ))
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
                  ? '${l.brandFilter}: ${_selectedBrands.join(', ')}'
                  : l.brandFilter,
            ),
            selected: active,
            onDeleted: active ? () => setState(() => _selectedBrands = {}) : null,
            onPressed: null, // tap handled by PopupMenuButton
          ),
        ),
      ),
    );
  }
}
