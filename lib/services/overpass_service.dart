import 'dart:convert';

import 'package:http/http.dart' as http;

class OsmShop {
  final int osmId;
  final String name;
  final double lat;
  final double lng;
  final String? address; // constructed from addr:* tags
  final String? brand;

  const OsmShop({
    required this.osmId,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.brand,
  });
}

class OverpassService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Returns supermarkets within [radiusMeters] of [lat]/[lng].
  static Future<List<OsmShop>> searchNearby(
      double lat, double lng, int radiusMeters) async {
    final query = '''
[out:json][timeout:10];
(
  node["shop"="supermarket"](around:$radiusMeters,$lat,$lng);
  way["shop"="supermarket"](around:$radiusMeters,$lat,$lng);
);
out center tags;
''';
    final response = await http.post(
      Uri.parse(_endpoint),
      body: {'data': query},
      headers: {'User-Agent': 'Fairelescourses/1.0'},
    ).timeout(const Duration(seconds: 14));

    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = json['elements'] as List<dynamic>;

    final shops = <OsmShop>[];
    for (final el in elements) {
      final e = el as Map<String, dynamic>;
      final tags = (e['tags'] as Map<String, dynamic>?) ?? {};
      final name = tags['name'] as String? ?? tags['brand'] as String?;
      if (name == null || name.isEmpty) continue;

      // Nodes have lat/lon directly; ways have a 'center' object.
      double? elLat, elLng;
      if (e['type'] == 'node') {
        elLat = (e['lat'] as num?)?.toDouble();
        elLng = (e['lon'] as num?)?.toDouble();
      } else {
        final center = e['center'] as Map<String, dynamic>?;
        elLat = (center?['lat'] as num?)?.toDouble();
        elLng = (center?['lon'] as num?)?.toDouble();
      }
      if (elLat == null || elLng == null) continue;

      final address = _buildAddress(tags);
      shops.add(OsmShop(
        osmId: e['id'] as int,
        name: name,
        lat: elLat,
        lng: elLng,
        address: address,
        brand: tags['brand'] as String?,
      ));
    }
    return shops;
  }

  static String? _buildAddress(Map<String, dynamic> tags) {
    final street = tags['addr:street'] as String?;
    final num = tags['addr:housenumber'] as String?;
    final city = tags['addr:city'] as String?;
    final postcode = tags['addr:postcode'] as String?;

    final streetPart = street != null && num != null
        ? '$street $num'
        : street;
    final cityPart = postcode != null && city != null
        ? '$postcode $city'
        : city;
    final parts = [?streetPart, ?cityPart];
    return parts.isEmpty ? null : parts.join(', ');
  }
}
