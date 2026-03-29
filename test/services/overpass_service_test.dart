import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fairelescourses/services/overpass_service.dart';

http.Client _client(Map<String, dynamic> body, {int status = 200}) =>
    MockClient((_) async => http.Response(jsonEncode(body), status));

Map<String, dynamic> _overpassResponse(List<Map<String, dynamic>> elements) => {
  'version': 0.6,
  'elements': elements,
};

Map<String, dynamic> _node(
  int id,
  double lat,
  double lon,
  Map<String, dynamic> tags,
) => {'type': 'node', 'id': id, 'lat': lat, 'lon': lon, 'tags': tags};

Map<String, dynamic> _way(
  int id,
  double lat,
  double lon,
  Map<String, dynamic> tags,
) => {
  'type': 'way',
  'id': id,
  'center': {'lat': lat, 'lon': lon},
  'tags': tags,
};

void main() {
  group('OverpassService.searchNearby', () {
    test('parses node with lat/lon', () async {
      final client = _client(
        _overpassResponse([
          _node(1, 48.1, 11.5, {'name': 'Test Market', 'shop': 'supermarket'}),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.length, 1);
      expect(results.first.osmId, 1);
      expect(results.first.name, 'Test Market');
      expect(results.first.lat, 48.1);
      expect(results.first.lng, 11.5);
    });

    test('parses way using center coordinates', () async {
      final client = _client(
        _overpassResponse([
          _way(99, 48.2, 11.6, {'name': 'Big Store', 'shop': 'supermarket'}),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.first.lat, 48.2);
      expect(results.first.lng, 11.6);
    });

    test('falls back to brand when name tag absent', () async {
      final client = _client(
        _overpassResponse([
          _node(2, 48.1, 11.5, {'brand': 'BrandCo', 'shop': 'supermarket'}),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.first.name, 'BrandCo');
      expect(results.first.brand, 'BrandCo');
    });

    test('filters out elements with no name and no brand', () async {
      final client = _client(
        _overpassResponse([
          _node(3, 48.1, 11.5, {'shop': 'supermarket'}),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results, isEmpty);
    });

    test('builds address from addr tags', () async {
      final client = _client(
        _overpassResponse([
          _node(4, 48.1, 11.5, {
            'name': 'Shop',
            'addr:street': 'Main St',
            'addr:housenumber': '10',
            'addr:postcode': '80333',
            'addr:city': 'Munich',
          }),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.first.address, 'Main St 10, 80333 Munich');
    });

    test('address with street only (no house number)', () async {
      final client = _client(
        _overpassResponse([
          _node(5, 48.1, 11.5, {
            'name': 'Shop',
            'addr:street': 'Oak Ave',
            'addr:city': 'Berlin',
          }),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.first.address, 'Oak Ave, Berlin');
    });

    test('address null when no addr tags', () async {
      final client = _client(
        _overpassResponse([
          _node(6, 48.1, 11.5, {'name': 'Shop'}),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.first.address, isNull);
    });

    test('empty elements list returns empty', () async {
      final client = _client(_overpassResponse([]));
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results, isEmpty);
    });

    test('HTTP error throws exception', () async {
      final client = _client({}, status: 429);
      expect(
        () =>
            OverpassService.searchNearby(48.0, 11.0, 2000, httpClient: client),
        throwsException,
      );
    });

    test('multiple elements parsed correctly', () async {
      final client = _client(
        _overpassResponse([
          _node(1, 48.1, 11.5, {'name': 'Alpha'}),
          _node(2, 48.2, 11.6, {'name': 'Beta'}),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.length, 2);
      expect(results.map((r) => r.name), containsAll(['Alpha', 'Beta']));
    });

    test('way without center coordinates is skipped', () async {
      final client = _client(
        _overpassResponse([
          {
            'type': 'way',
            'id': 10,
            'tags': {'name': 'Incomplete'},
          },
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results, isEmpty);
    });
  });

  group('formatOsmRadius', () {
    test('500 → "500 m"', () => expect(formatOsmRadius(500), '500 m'));
    test('1000 → "1 km"', () => expect(formatOsmRadius(1000), '1 km'));
    test('2000 → "2 km"', () => expect(formatOsmRadius(2000), '2 km'));
    test('5000 → "5 km"', () => expect(formatOsmRadius(5000), '5 km'));
    test('1500 → "1.5 km"', () => expect(formatOsmRadius(1500), '1.5 km'));
    test('999 → "999 m"', () => expect(formatOsmRadius(999), '999 m'));
  });

  group('osmCategoryLabel', () {
    // Just spot-check a few — the switch is exhaustive in the source.
    test('catSupermarket matches list entry', () {
      final cat = osmShopCategories.firstWhere(
        (c) => c.labelKey == 'catSupermarket',
      );
      expect(cat.osmKey, 'shop');
      expect(cat.osmValue, 'supermarket');
    });

    test('catPharmacy uses amenity key', () {
      final cat = osmShopCategories.firstWhere(
        (c) => c.labelKey == 'catPharmacy',
      );
      expect(cat.osmKey, 'amenity');
      expect(cat.osmValue, 'pharmacy');
    });

    test('all 18 categories have unique osmValue', () {
      final values = osmShopCategories.map((c) => c.osmValue).toSet();
      expect(values.length, osmShopCategories.length);
    });
  });
}
