import 'dart:convert';

import 'package:http/http.dart' as http;

class NominatimService {
  static const _base = 'https://nominatim.openstreetmap.org/search';

  /// Returns (lat, lng) for the given address query, or null if not found.
  static Future<({double lat, double lng})?> geocode(
    String query, {
    http.Client? httpClient,
  }) async {
    if (query.trim().isEmpty) return null;
    final uri = Uri.parse(_base).replace(
      queryParameters: {'q': query.trim(), 'format': 'json', 'limit': '1'},
    );
    final client = httpClient ?? http.Client();
    final http.Response response;
    try {
      response = await client
          .get(
            uri,
            headers: {
              'User-Agent': 'Fairelescourses/1.0 (shopping navigation app)',
              'Accept-Language': 'en,de;q=0.9',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } finally {
      if (httpClient == null) client.close();
    }
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) return null;
    final item = data.first as Map<String, dynamic>;
    final lat = double.tryParse(item['lat'] as String? ?? '');
    final lng = double.tryParse(item['lon'] as String? ?? '');
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }
}
