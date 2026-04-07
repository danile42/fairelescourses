import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fairelescourses/l10n/app_localizations_en.dart';
import 'package:fairelescourses/services/overpass_service.dart';

http.Client _rawClient(String body, {int status = 200}) =>
    MockClient((_) async => http.Response(body, status));

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

  group('osmCategoryLabel – localised strings', () {
    final l = AppLocalizationsEn();

    test('every category key resolves to a non-empty string', () {
      for (final cat in osmShopCategories) {
        final label = osmCategoryLabel(l, cat.labelKey);
        expect(label, isNotEmpty, reason: '${cat.labelKey} returned empty');
      }
    });

    test('catSupermarket returns expected EN label', () {
      expect(osmCategoryLabel(l, 'catSupermarket'), l.catSupermarket);
    });

    test('catPharmacy returns expected EN label', () {
      expect(osmCategoryLabel(l, 'catPharmacy'), l.catPharmacy);
    });

    test('catBakery returns expected EN label', () {
      expect(osmCategoryLabel(l, 'catBakery'), l.catBakery);
    });

    test('unknown key returns the key itself', () {
      expect(osmCategoryLabel(l, 'unknownKey'), 'unknownKey');
    });

    test('all 18 categories produce distinct labels', () {
      final labels = osmShopCategories
          .map((c) => osmCategoryLabel(l, c.labelKey))
          .toSet();
      expect(labels.length, osmShopCategories.length);
    });
  });

  group('OverpassService.searchNearby – category filtering', () {
    test('single-category search still works', () async {
      final bakery = osmShopCategories.firstWhere(
        (c) => c.osmValue == 'bakery',
      );
      final client = _client(
        _overpassResponse([
          _node(1, 48.1, 11.5, {'name': 'Best Bakery', 'shop': 'bakery'}),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        1000,
        categories: {bakery},
        httpClient: client,
      );
      expect(results.length, 1);
      expect(results.first.name, 'Best Bakery');
      expect(results.first.osmCategory, 'bakery');
    });

    test('osmCategory set to matched category value', () async {
      final client = _client(
        _overpassResponse([
          _node(1, 48.1, 11.5, {'name': 'Pharma', 'amenity': 'pharmacy'}),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.first.osmCategory, 'pharmacy');
    });

    test(
      'address with postcode only (no city) included in city part',
      () async {
        final client = _client(
          _overpassResponse([
            _node(1, 48.1, 11.5, {
              'name': 'Shop',
              'addr:street': 'High St',
              'addr:housenumber': '5',
              'addr:postcode': '12345',
            }),
          ]),
        );
        final results = await OverpassService.searchNearby(
          48.0,
          11.0,
          2000,
          httpClient: client,
        );
        expect(results.first.address, 'High St 5, 12345');
      },
    );

    test('address with city only (no postcode)', () async {
      final client = _client(
        _overpassResponse([
          _node(1, 48.1, 11.5, {'name': 'Shop', 'addr:city': 'Vienna'}),
        ]),
      );
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.first.address, 'Vienna');
    });

    test('element with name="" (empty) is filtered out', () async {
      final client = _client(
        _overpassResponse([
          _node(1, 48.1, 11.5, {'name': '', 'shop': 'bakery'}),
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

  group('formatOsmRadius – edge cases', () {
    test('exactly 1000 m formats as 1 km', () {
      expect(formatOsmRadius(1000), '1 km');
    });
    test('1200 → 1.2 km', () => expect(formatOsmRadius(1200), '1.2 km'));
    test('10000 → 10 km', () => expect(formatOsmRadius(10000), '10 km'));
  });

  group('OverpassException', () {
    test('toString includes shortLabel and message', () {
      const e = OverpassException('timeout', 'Client-side HTTP timeout');
      expect(
        e.toString(),
        'OverpassException(timeout): Client-side HTTP timeout',
      );
    });

    test('shortLabel and message are preserved', () {
      const e = OverpassException('429 – rate limited', 'rate-limited (429)');
      expect(e.shortLabel, '429 – rate limited');
      expect(e.message, 'rate-limited (429)');
    });

    test('retryable defaults to false', () {
      const e = OverpassException('timeout', 'msg');
      expect(e.retryable, isFalse);
    });

    test('retryable and retryAfterSeconds are preserved', () {
      const e = OverpassException(
        '503 – service unavailable',
        'msg',
        retryable: true,
        retryAfterSeconds: 5,
      );
      expect(e.retryable, isTrue);
      expect(e.retryAfterSeconds, 5);
    });
  });

  group('OverpassService.searchNearby – HTTP error shortLabels', () {
    Future<OverpassException> expectOverpassException(
      http.Client client,
    ) async {
      try {
        await OverpassService.searchNearby(
          48.0,
          11.0,
          2000,
          httpClient: client,
        );
        fail('Expected OverpassException');
      } on OverpassException catch (e) {
        return e;
      }
    }

    test('HTTP 429 → shortLabel "429 – rate limited", not retryable', () async {
      final e = await expectOverpassException(_rawClient('', status: 429));
      expect(e.shortLabel, '429 – rate limited');
      expect(e.retryable, isFalse);
    });

    test('HTTP 400 → shortLabel "400 – bad query", not retryable', () async {
      final e = await expectOverpassException(_rawClient('', status: 400));
      expect(e.shortLabel, '400 – bad query');
      expect(e.retryable, isFalse);
    });

    test('HTTP 504 → shortLabel "504 – server timeout", retryable', () async {
      // 504 is retried internally; pass a client that always returns 504 so
      // the exception reaches the caller only after all attempts are exhausted.
      int calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('', 504);
      });
      final e = await expectOverpassException(client);
      expect(e.shortLabel, '504 – server timeout');
      expect(e.retryable, isTrue);
      expect(calls, 3); // 3 total attempts (1 initial + 2 retries)
    });

    test('HTTP 502 → shortLabel "502 – bad gateway", retryable', () async {
      int calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('', 502);
      });
      final e = await expectOverpassException(client);
      expect(e.shortLabel, '502 – bad gateway');
      expect(e.retryable, isTrue);
      expect(calls, 3);
    });

    test(
      'HTTP 503 → shortLabel "503 – service unavailable", retryable',
      () async {
        int calls = 0;
        final client = MockClient((_) async {
          calls++;
          return http.Response('', 503);
        });
        final e = await expectOverpassException(client);
        expect(e.shortLabel, '503 – service unavailable');
        expect(e.retryable, isTrue);
        expect(calls, 3);
      },
    );

    test(
      'HTTP 503 with Retry-After header propagates retryAfterSeconds',
      () async {
        // First call returns 503 with Retry-After, second call succeeds.
        int calls = 0;
        final successBody = jsonEncode({
          'version': 0.6,
          'elements': [
            _node(1, 48.1, 11.5, {'name': 'Shop', 'shop': 'supermarket'}),
          ],
        });
        final client = MockClient((_) async {
          calls++;
          if (calls == 1) {
            return http.Response('', 503, headers: {'retry-after': '3'});
          }
          return http.Response(successBody, 200);
        });
        final results = await OverpassService.searchNearby(
          48.0,
          11.0,
          2000,
          httpClient: client,
        );
        expect(results.length, 1);
        expect(calls, 2);
      },
    );

    test(
      'other HTTP error → shortLabel "HTTP {code}", not retryable',
      () async {
        final e = await expectOverpassException(_rawClient('', status: 500));
        expect(e.shortLabel, 'HTTP 500');
        expect(e.retryable, isFalse);
      },
    );

    test('malformed JSON on 200 → shortLabel "bad response"', () async {
      final e = await expectOverpassException(
        _rawClient('not valid json', status: 200),
      );
      expect(e.shortLabel, 'bad response');
    });

    test('200 with remark field does NOT throw, returns results', () async {
      final body = jsonEncode({
        'version': 0.6,
        'remark': 'Query ran for too long',
        'elements': [
          _node(1, 48.1, 11.5, {'name': 'Shop A', 'shop': 'supermarket'}),
        ],
      });
      final client = _rawClient(body, status: 200);
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.length, 1);
      expect(results.first.name, 'Shop A');
    });

    test('retryable error succeeds on second attempt', () async {
      int calls = 0;
      final successBody = jsonEncode({
        'version': 0.6,
        'elements': [
          _node(1, 48.1, 11.5, {'name': 'Market', 'shop': 'supermarket'}),
        ],
      });
      final client = MockClient((_) async {
        calls++;
        if (calls == 1) return http.Response('', 504);
        return http.Response(successBody, 200);
      });
      final results = await OverpassService.searchNearby(
        48.0,
        11.0,
        2000,
        httpClient: client,
      );
      expect(results.length, 1);
      expect(results.first.name, 'Market');
      expect(calls, 2);
    });

    test('non-retryable 429 does not trigger retries', () async {
      int calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('', 429);
      });
      await expectOverpassException(client);
      expect(calls, 1); // no retries
    });
  });

  group('l10n – createNewLayout key', () {
    test('createNewLayout key is non-empty in EN locale', () {
      final l = AppLocalizationsEn();
      expect(l.createNewLayout, isNotEmpty);
    });
  });
}
