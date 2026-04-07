import 'package:cloud_firestore/cloud_firestore.dart';

import 'supermarket.dart';

/// A single community-contributed cell-layout version for an OSM shop.
///
/// Documents live at `public_shops/{osmId}/versions/{versionId}`.
/// [importCount] is incremented atomically each time a user imports the layout;
/// the browse sheet sorts by this value so the most-used layout floats to the
/// top.
class CommunityLayout {
  final String versionId;
  final int osmId;
  final String publishedBy;
  final DateTime? publishedAt;
  final int importCount;
  final String shopName;
  final String? address;

  /// A [Supermarket] built from the layout fields, suitable for use as a
  /// [StoreEditorScreen.template] to pre-populate the grid.
  final Supermarket asTemplate;

  const CommunityLayout({
    required this.versionId,
    required this.osmId,
    required this.publishedBy,
    this.publishedAt,
    required this.importCount,
    required this.shopName,
    this.address,
    required this.asTemplate,
  });

  static CommunityLayout fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final ts = d['publishedAt'];
    final osmId = (d['osmId'] as num).toInt();
    return CommunityLayout(
      versionId: doc.id,
      osmId: osmId,
      publishedBy: d['publishedBy'] as String? ?? '',
      publishedAt: ts is Timestamp ? ts.toDate() : null,
      importCount: (d['importCount'] as num?)?.toInt() ?? 0,
      shopName: d['shopName'] as String? ?? '',
      address: d['address'] as String?,
      asTemplate: Supermarket(
        id: 'osm_$osmId',
        name: d['shopName'] as String? ?? '',
        rows: List<String>.from(d['rows'] as List),
        cols: List<String>.from(d['cols'] as List),
        entrance: d['entrance'] as String,
        exit: d['exit'] as String,
        cells: (d['cells'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        ),
        subcells: d['subcells'] != null
            ? (d['subcells'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, List<String>.from(v as List)),
              )
            : null,
        floorsRaw: d['floors'] != null ? (d['floors'] as List).toList() : null,
        osmId: osmId,
      ),
    );
  }
}
