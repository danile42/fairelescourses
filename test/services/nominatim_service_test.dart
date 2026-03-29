import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fairelescourses/services/nominatim_service.dart';

http.Client _client(Object body, {int status = 200}) =>
    MockClient((_) async => http.Response(jsonEncode(body), status));

void main() {
  group('NominatimService.geocode', () {
    test('returns lat/lng for valid response', () async {
      final client = _client([
        {'lat': '48.1374300', 'lon': '11.5754900', 'display_name': 'Munich'},
      ]);
      final result = await NominatimService.geocode(
        'Munich',
        httpClient: client,
      );
      expect(result, isNotNull);
      expect(result!.lat, closeTo(48.1374300, 1e-6));
      expect(result.lng, closeTo(11.5754900, 1e-6));
    });

    test('returns null for empty result list', () async {
      final client = _client(<dynamic>[]);
      final result = await NominatimService.geocode(
        'Nowhere',
        httpClient: client,
      );
      expect(result, isNull);
    });

    test('returns null on non-200 status', () async {
      final client = _client({'error': 'bad'}, status: 500);
      final result = await NominatimService.geocode(
        'Anywhere',
        httpClient: client,
      );
      expect(result, isNull);
    });

    test('returns null immediately for empty query', () async {
      // No HTTP client needed — the function returns early.
      final result = await NominatimService.geocode('');
      expect(result, isNull);
    });

    test('returns null immediately for whitespace-only query', () async {
      final result = await NominatimService.geocode('   ');
      expect(result, isNull);
    });

    test('returns null when lat is not a parseable number', () async {
      final client = _client([
        {'lat': 'invalid', 'lon': '11.5', 'display_name': 'X'},
      ]);
      final result = await NominatimService.geocode('X', httpClient: client);
      expect(result, isNull);
    });

    test('returns null when lon is missing', () async {
      final client = _client([
        {'lat': '48.1', 'display_name': 'X'},
      ]);
      final result = await NominatimService.geocode('X', httpClient: client);
      expect(result, isNull);
    });

    test('uses first result when multiple are returned', () async {
      final client = _client([
        {'lat': '10.0', 'lon': '20.0', 'display_name': 'First'},
        {'lat': '30.0', 'lon': '40.0', 'display_name': 'Second'},
      ]);
      final result = await NominatimService.geocode(
        'query',
        httpClient: client,
      );
      expect(result!.lat, closeTo(10.0, 1e-6));
    });
  });
}
