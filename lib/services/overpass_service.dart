import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
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
  OsmShopCategory(
    osmKey: 'shop',
    osmValue: 'supermarket',
    labelKey: 'catSupermarket',
  ),
  OsmShopCategory(
    osmKey: 'shop',
    osmValue: 'convenience',
    labelKey: 'catConvenience',
  ),
  OsmShopCategory(
    osmKey: 'shop',
    osmValue: 'electronics',
    labelKey: 'catElectronics',
  ),
  OsmShopCategory(
    osmKey: 'shop',
    osmValue: 'computer',
    labelKey: 'catComputer',
  ),
  OsmShopCategory(
    osmKey: 'shop',
    osmValue: 'doityourself',
    labelKey: 'catDoItYourself',
  ),
  OsmShopCategory(
    osmKey: 'shop',
    osmValue: 'hardware',
    labelKey: 'catHardware',
  ),
  OsmShopCategory(osmKey: 'shop', osmValue: 'bakery', labelKey: 'catBakery'),
  OsmShopCategory(osmKey: 'shop', osmValue: 'butcher', labelKey: 'catButcher'),
  OsmShopCategory(
    osmKey: 'amenity',
    osmValue: 'pharmacy',
    labelKey: 'catPharmacy',
  ),
  OsmShopCategory(osmKey: 'shop', osmValue: 'clothes', labelKey: 'catClothes'),
  OsmShopCategory(
    osmKey: 'shop',
    osmValue: 'department_store',
    labelKey: 'catDepartmentStore',
  ),
  OsmShopCategory(
    osmKey: 'shop',
    osmValue: 'furniture',
    labelKey: 'catFurniture',
  ),
  OsmShopCategory(osmKey: 'shop', osmValue: 'books', labelKey: 'catBooks'),
  OsmShopCategory(osmKey: 'shop', osmValue: 'sports', labelKey: 'catSports'),
  OsmShopCategory(
    osmKey: 'shop',
    osmValue: 'garden_centre',
    labelKey: 'catGardenCentre',
  ),
  OsmShopCategory(osmKey: 'shop', osmValue: 'pet', labelKey: 'catPet'),
  OsmShopCategory(osmKey: 'shop', osmValue: 'florist', labelKey: 'catFlorist'),
  OsmShopCategory(osmKey: 'shop', osmValue: 'shoes', labelKey: 'catShoes'),
];

/// Resolves a category's [labelKey] to a localised display string.
String osmCategoryLabel(AppLocalizations l, String labelKey) {
  switch (labelKey) {
    case 'catSupermarket':
      return l.catSupermarket;
    case 'catConvenience':
      return l.catConvenience;
    case 'catElectronics':
      return l.catElectronics;
    case 'catComputer':
      return l.catComputer;
    case 'catDoItYourself':
      return l.catDoItYourself;
    case 'catHardware':
      return l.catHardware;
    case 'catBakery':
      return l.catBakery;
    case 'catButcher':
      return l.catButcher;
    case 'catPharmacy':
      return l.catPharmacy;
    case 'catClothes':
      return l.catClothes;
    case 'catDepartmentStore':
      return l.catDepartmentStore;
    case 'catFurniture':
      return l.catFurniture;
    case 'catBooks':
      return l.catBooks;
    case 'catSports':
      return l.catSports;
    case 'catGardenCentre':
      return l.catGardenCentre;
    case 'catPet':
      return l.catPet;
    case 'catFlorist':
      return l.catFlorist;
    case 'catShoes':
      return l.catShoes;
    default:
      return labelKey;
  }
}

class OsmShop {
  final int osmId;
  final String name;
  final double lat;
  final double lng;
  final String? address; // constructed from addr:* tags
  final String? brand;

  /// The OSM category value that matched this shop (e.g. "supermarket", "bakery").
  final String? osmCategory;

  const OsmShop({
    required this.osmId,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.brand,
    this.osmCategory,
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

/// Thrown when an Overpass API request fails for a known reason.
///
/// [shortLabel] is a compact human-readable description suitable for display
/// in the UI (e.g. "429 – rate limited", "timeout").
///
/// [retryable] is true when the error is transient (e.g. server timeout,
/// bad gateway) and the caller may benefit from retrying. The service already
/// retries automatically; this flag is exposed so the UI can decide whether to
/// offer a manual retry as well.
///
/// [retryAfterSeconds] is an optional hint from the server (via
/// `Retry-After`) about how long to wait before retrying.
class OverpassException implements Exception {
  final String shortLabel;
  final String message;
  final bool retryable;
  final int? retryAfterSeconds;

  const OverpassException(
    this.shortLabel,
    this.message, {
    this.retryable = false,
    this.retryAfterSeconds,
  });

  @override
  String toString() => 'OverpassException($shortLabel): $message';
}

class OverpassService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Maximum number of total attempts (1 initial + retries).
  static const _kMaxAttempts = 3;

  /// Delays in seconds between consecutive attempts.
  static const _kRetryDelays = [1, 2];

  /// Returns shops of [category] within [radiusMeters] of [lat]/[lng].
  ///
  /// Transient errors (502, 503, 504, client timeout) are retried
  /// automatically up to [_kMaxAttempts] times before re-throwing.
  static Future<List<OsmShop>> searchNearby(
    double lat,
    double lng,
    int radiusMeters, {
    Set<OsmShopCategory> categories = const <OsmShopCategory>{},
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
    try {
      for (int attempt = 0; attempt < _kMaxAttempts; attempt++) {
        try {
          return await _singleAttempt(
            lat,
            lng,
            radiusMeters,
            categories: categories,
            client: client,
          );
        } on OverpassException catch (e) {
          if (!e.retryable || attempt == _kMaxAttempts - 1) rethrow;
          final delaySecs = e.retryAfterSeconds ?? _kRetryDelays[attempt];
          debugPrint(
            'Overpass: ${e.shortLabel} — retrying in ${delaySecs}s '
            '(attempt ${attempt + 2}/$_kMaxAttempts)',
          );
          await Future.delayed(Duration(seconds: delaySecs));
        }
      }
    } finally {
      if (httpClient == null) client.close();
    }
    // Unreachable: the loop either returns or rethrows.
    throw StateError('unreachable');
  }

  static Future<List<OsmShop>> _singleAttempt(
    double lat,
    double lng,
    int radiusMeters, {
    required Set<OsmShopCategory> categories,
    required http.Client client,
  }) async {
    final cats = categories.isEmpty ? osmShopCategories : categories.toList();
    final clauses = cats
        .map(
          (c) =>
              '  nwr["${c.osmKey}"="${c.osmValue}"](around:$radiusMeters,$lat,$lng);',
        )
        .join('\n');
    final timeout = (cats.length * 8).clamp(15, 45);
    final query =
        '[out:json][timeout:$timeout];\n(\n$clauses\n);\nout center tags;\n';

    final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse(_endpoint),
            body: {'data': query},
            headers: {'User-Agent': 'Fairelescourses/1.0'},
          )
          .timeout(Duration(seconds: timeout + 10));
    } on TimeoutException {
      debugPrint(
        'Overpass: client-side timeout after ${timeout + 10} s '
        '(query timeout was $timeout s)',
      );
      throw const OverpassException(
        'timeout',
        'Client-side HTTP timeout',
        retryable: true,
      );
    } on SocketException catch (e) {
      debugPrint('Overpass: network error — $e');
      throw OverpassException('no network', e.toString());
    }

    if (response.statusCode != 200) {
      final snippet = response.body.substring(
        0,
        min(300, response.body.length),
      );
      final (label, reason, retryable) = switch (response.statusCode) {
        429 => ('429 – rate limited', 'rate-limited (429)', false),
        400 => ('400 – bad query', 'bad query (400)', false),
        504 => ('504 – server timeout', 'server-side timeout (504)', true),
        502 => ('502 – bad gateway', 'bad gateway (502)', true),
        503 => ('503 – service unavailable', 'service unavailable (503)', true),
        _ => (
          'HTTP ${response.statusCode}',
          'HTTP ${response.statusCode}',
          false,
        ),
      };
      debugPrint('Overpass: $reason — $snippet');
      throw OverpassException(
        label,
        '$reason\n$snippet',
        retryable: retryable,
        retryAfterSeconds: retryable ? _parseRetryAfter(response) : null,
      );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      final snippet = response.body.substring(
        0,
        min(300, response.body.length),
      );
      debugPrint('Overpass: malformed JSON — $e — body: $snippet');
      throw OverpassException('bad response', 'Malformed JSON: $e\n$snippet');
    }

    // Overpass sometimes returns HTTP 200 with a remark describing a runtime
    // error (e.g. query timeout, memory exceeded).
    final remark = json['remark'] as String?;
    if (remark != null) {
      debugPrint('Overpass: remark in 200 response — $remark');
    }
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
      shops.add(
        OsmShop(
          osmId: e['id'] as int,
          name: name,
          lat: elLat,
          lng: elLng,
          address: address,
          brand: tags['brand'] as String?,
          osmCategory: _matchedCategory(tags),
        ),
      );
    }
    return shops;
  }

  /// Parses the `Retry-After` response header (seconds form only), capped at
  /// 8 seconds so the app never hangs for long.
  static int? _parseRetryAfter(http.Response response) {
    final header = response.headers['retry-after'];
    if (header == null) return null;
    final secs = int.tryParse(header.trim());
    return secs?.clamp(0, 8);
  }

  static String? _matchedCategory(Map<String, dynamic> tags) {
    for (final c in osmShopCategories) {
      if (tags[c.osmKey] == c.osmValue) return c.osmValue;
    }
    return null;
  }

  static String? _buildAddress(Map<String, dynamic> tags) {
    final street = tags['addr:street'] as String?;
    final num = tags['addr:housenumber'] as String?;
    final city = tags['addr:city'] as String?;
    final postcode = tags['addr:postcode'] as String?;

    final streetPart = street != null && num != null ? '$street $num' : street;
    final cityPart = postcode != null && city != null
        ? '$postcode $city'
        : postcode ?? city;
    final parts = [?streetPart, ?cityPart];
    return parts.isEmpty ? null : parts.join(', ');
  }
}
