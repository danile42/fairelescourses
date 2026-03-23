import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

import '../models/supermarket.dart';
import '../providers/supermarket_provider.dart';
import '../services/overpass_service.dart';
import 'store_editor_screen.dart';

class OsmShopsScreen extends ConsumerStatefulWidget {
  final double lat;
  final double lng;
  final int radiusMeters;

  const OsmShopsScreen({
    super.key,
    required this.lat,
    required this.lng,
    this.radiusMeters = 1500,
  });

  @override
  ConsumerState<OsmShopsScreen> createState() => _OsmShopsScreenState();
}

class _OsmShopsScreenState extends ConsumerState<OsmShopsScreen> {
  List<OsmShop>? _shops;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _shops = null; _error = false; });
    try {
      final shops = await OverpassService.searchNearby(
          widget.lat, widget.lng, widget.radiusMeters);
      if (mounted) setState(() => _shops = shops);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  /// True if [osm] is already covered by an existing app shop
  /// (same name, case-insensitive, or within 200 m).
  bool _alreadyDefined(OsmShop osm, List<Supermarket> stores) {
    final nameLower = osm.name.toLowerCase();
    for (final s in stores) {
      if (s.name.toLowerCase() == nameLower) return true;
      if (s.lat != null && s.lng != null) {
        if (_haversine(osm.lat, osm.lng, s.lat!, s.lng!) < 0.2) return true;
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stores = ref.watch(supermarketsProvider);
    final theme = Theme.of(context);
    final radiusKm = (widget.radiusMeters / 1000.0).toStringAsFixed(1);

    Widget body;
    if (_shops == null && !_error) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l.osmSearching, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    } else if (_error) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(l.geocodeFailed, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: Text(l.ok)),
          ],
        ),
      );
    } else if (_shops!.isEmpty) {
      body = Center(
        child: Text(l.noOsmShopsFound, style: const TextStyle(color: Colors.grey)),
      );
    } else {
      body = ListView.builder(
        itemCount: _shops!.length,
        itemBuilder: (context, i) {
          final shop = _shops![i];
          final defined = _alreadyDefined(shop, stores);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.store_outlined),
              title: Text(shop.name),
              subtitle: Text([
                l.distanceKm(radiusKm),
                ?shop.address,
              ].nonNulls.join('  •  ')),
              trailing: defined
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
                              name: shop.name,
                              address: shop.address,
                              lat: shop.lat,
                              lng: shop.lng,
                            ),
                          ),
                        ),
                      ),
                      child: Text(l.createShop),
                    ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.osmShopsTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: body),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              l.osmAttribution,
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
