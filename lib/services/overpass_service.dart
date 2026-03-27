import 'dart:convert';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

class OsmShopCategory {
  final String osmKey;
  final String osmValue;
  final String labelKey; // l10n key

  const OsmShopCategory({
    required this.osmKey,
    required this.osmValue,
    required this.labelKey,
  });
}

const osmShopCategories = [
  OsmShopCategory(osmKey: 'shop',    osmValue: 'supermarket',      labelKey: 'catSupermarket'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'convenience',      labelKey: 'catConvenience'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'electronics',      labelKey: 'catElectronics'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'computer',         labelKey: 'catComputer'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'doityourself',     labelKey: 'catDoItYourself'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'hardware',         labelKey: 'catHardware'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'bakery',           labelKey: 'catBakery'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'butcher',          labelKey: 'catButcher'),
  OsmShopCategory(osmKey: 'amenity', osmValue: 'pharmacy',         labelKey: 'catPharmacy'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'clothes',          labelKey: 'catClothes'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'department_store', labelKey: 'catDepartmentStore'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'furniture',        labelKey: 'catFurniture'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'books',            labelKey: 'catBooks'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'sports',           labelKey: 'catSports'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'garden_centre',    labelKey: 'catGardenCentre'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'pet',              labelKey: 'catPet'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'florist',          labelKey: 'catFlorist'),
  OsmShopCategory(osmKey: 'shop',    osmValue: 'shoes',            labelKey: 'catShoes'),
];

/// Resolves a category's [labelKey] to a localised display string.
String osmCategoryLabel(AppLocalizations l, String labelKey) {
  switch (labelKey) {
    case 'catSupermarket':     return l.catSupermarket;
    case 'catConvenience':     return l.catConvenience;
    case 'catElectronics':     return l.catElectronics;
    case 'catComputer':        return l.catComputer;
    case 'catDoItYourself':    return l.catDoItYourself;
    case 'catHardware':        return l.catHardware;
    case 'catBakery':          return l.catBakery;
    case 'catButcher':         return l.catButcher;
    case 'catPharmacy':        return l.catPharmacy;
    case 'catClothes':         return l.catClothes;
    case 'catDepartmentStore': return l.catDepartmentStore;
    case 'catFurniture':       return l.catFurniture;
    case 'catBooks':           return l.catBooks;
    case 'catSports':          return l.catSports;
    case 'catGardenCentre':    return l.catGardenCentre;
    case 'catPet':             return l.catPet;
    case 'catFlorist':         return l.catFlorist;
    case 'catShoes':           return l.catShoes;
    default:                   return labelKey;
  }
}

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

/// Formats a radius in metres to a human-readable string (e.g. 500 m, 2 km).
String formatOsmRadius(int meters) {
  if (meters >= 1000) {
    final km = meters / 1000;
    return km == km.roundToDouble() ? '${km.toInt()} km' : '$km km';
  }
  return '$meters m';
}

class OverpassService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Returns shops of [category] within [radiusMeters] of [lat]/[lng].
  static Future<List<OsmShop>> searchNearby(
      double lat, double lng, int radiusMeters,
      {Set<OsmShopCategory> categories = const <OsmShopCategory>{},
      http.Client? httpClient}) async {
    final cats = categories.isEmpty ? osmShopCategories : categories.toList();
    final clauses = cats
        .map((c) => '  nwr["${c.osmKey}"="${c.osmValue}"](around:$radiusMeters,$lat,$lng);')
        .join('\n');
    final timeout = (cats.length * 8).clamp(15, 45);
    final query = '[out:json][timeout:$timeout];\n(\n$clauses\n);\nout center tags;\n';
    final client = httpClient ?? http.Client();
    final http.Response response;
    try {
      response = await client
          .post(Uri.parse(_endpoint),
              body: {'data': query},
              headers: {'User-Agent': 'Fairelescourses/1.0'})
          .timeout(Duration(seconds: timeout + 10));
    } finally {
      if (httpClient == null) client.close();
    }

    if (response.statusCode != 200) {
      throw Exception('Overpass HTTP ${response.statusCode}');
    }

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
