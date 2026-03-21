import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/supermarket.dart';
import '../models/shopping_list.dart';

class ShopSearchResult {
  final Supermarket shop;
  final double? distanceKm;
  const ShopSearchResult({required this.shop, this.distanceKm});
}

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Crypto helpers ─────────────────────────────────────────────────────────

  /// SHA-256(householdId) hex string — used as a queryable field and as the
  /// Firestore document path for lists, so the plain household ID never appears.
  static String _pathId(String hid) =>
      sha256.convert(utf8.encode(hid)).toString();

  static enc.Key _key(String hid) =>
      enc.Key(Uint8List.fromList(sha256.convert(utf8.encode(hid)).bytes));

  static String _encrypt(String hid, Map<String, dynamic> data) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key(hid), mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(jsonEncode(data), iv: iv);
    final combined = Uint8List(16 + encrypted.bytes.length)
      ..setRange(0, 16, iv.bytes)
      ..setRange(16, 16 + encrypted.bytes.length, encrypted.bytes);
    return base64Encode(combined);
  }

  static Map<String, dynamic> _decrypt(String hid, String blob) {
    final combined = base64Decode(blob);
    final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final cipher = enc.Encrypted(Uint8List.fromList(combined.sublist(16)));
    final encrypter = enc.Encrypter(enc.AES(_key(hid), mode: enc.AESMode.cbc));
    return jsonDecode(encrypter.decrypt(cipher, iv: iv)) as Map<String, dynamic>;
  }

  // ── Shops (top-level collection, unencrypted, multi-user) ─────────────────
  //
  // Each document stores the full shop definition plus:
  //   ownerUid      — Firebase Auth UID of the creator (enforced by security rules)
  //   householdHash — SHA-256(householdId), used to filter household members' shops

  static CollectionReference<Map<String, dynamic>> get _shopsCol =>
      _db.collection('shops');

  static Future<void> upsertShop(String hid, Supermarket s) {
    final data = s.toMap()
      ..['ownerUid'] = FirebaseAuth.instance.currentUser!.uid
      ..['householdHash'] = _pathId(hid)
      ..['nameLower'] = s.name.toLowerCase()
      ..['goodsList'] = _goodsList(s);
    if (s.lat == null) data.remove('lat');
    if (s.lng == null) data.remove('lng');
    if (s.address == null) data.remove('address');
    return _shopsCol.doc(s.id).set(data);
  }

  /// Flat deduplicated list of all goods in a shop, lowercased.
  static List<String> _goodsList(Supermarket s) => s.cells.values
      .expand((goods) => goods)
      .map((g) => g.toLowerCase().trim())
      .where((g) => g.isNotEmpty)
      .toSet()
      .toList();

  /// Prefix-search across all users' shop definitions by name.
  static Future<List<Supermarket>> searchByName(String query) async {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    final snap = await _shopsCol
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(30)
        .get();
    return snap.docs.map((d) => _shopFromDoc(d)).toList();
  }

  /// Find all shops that contain a given item (exact lowercase match in goodsList).
  static Future<List<Supermarket>> searchByItem(String item) async {
    if (item.isEmpty) return [];
    final snap = await _shopsCol
        .where('goodsList', arrayContains: item.toLowerCase().trim())
        .limit(30)
        .get();
    return snap.docs.map((d) => _shopFromDoc(d)).toList();
  }

  /// Find shops within [radiusKm] of [lat]/[lng], sorted by distance.
  static Future<List<ShopSearchResult>> searchNearby(
      double lat, double lng, double radiusKm) async {
    // Bounding box: 1° latitude ≈ 111 km
    final latDelta = radiusKm / 111.0;
    final snap = await _shopsCol
        .where('lat', isGreaterThanOrEqualTo: lat - latDelta)
        .where('lat', isLessThanOrEqualTo: lat + latDelta)
        .limit(200)
        .get();
    final results = <ShopSearchResult>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final sLat = (data['lat'] as num?)?.toDouble();
      final sLng = (data['lng'] as num?)?.toDouble();
      if (sLat == null || sLng == null) continue;
      final dist = _haversine(lat, lng, sLat, sLng);
      if (dist <= radiusKm) {
        results.add(ShopSearchResult(shop: _shopFromDoc(doc), distanceKm: dist));
      }
    }
    results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return results;
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  static Supermarket _shopFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final shop = Supermarket.fromMap(d.data());
    shop.ownerUid = d.data()['ownerUid'] as String?;
    return shop;
  }

  static Future<void> deleteShop(String hid, String id) =>
      _shopsCol.doc(id).delete();

  /// Streams all shops that belong to this household (any member's definitions).
  static Stream<List<Supermarket>> shopsStream(String hid) =>
      _shopsCol
          .where('householdHash', isEqualTo: _pathId(hid))
          .snapshots()
          .map((snap) {
            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            return snap.docs.map((d) {
              final data = d.data();
              final shop = Supermarket.fromMap(data);
              shop.ownerUid = data['ownerUid'] as String?;
              // Backfill search fields on first encounter if missing (owned shops only)
              if (shop.ownerUid == currentUid &&
                  (data['nameLower'] == null || data['goodsList'] == null)) {
                _shopsCol.doc(d.id).update({
                  'nameLower': shop.name.toLowerCase(),
                  'goodsList': _goodsList(shop),
                }).ignore();
              }
              return shop;
            }).toList();
          });

  // ── Lists (under hashed household path, encrypted) ────────────────────────

  static CollectionReference<Map<String, dynamic>> _lists(String hid) =>
      _db.collection('h').doc(_pathId(hid)).collection('l');

  static Future<void> upsertList(String hid, ShoppingList l) =>
      _lists(hid).doc(l.id).set({'d': _encrypt(hid, l.toMap())});

  static Future<void> deleteList(String hid, String id) =>
      _lists(hid).doc(id).delete();

  static Stream<List<ShoppingList>> listsStream(String hid) =>
      _lists(hid).snapshots().map((snap) => snap.docs
          .map((d) => ShoppingList.fromMap(_decrypt(hid, d.data()['d'] as String)))
          .toList());
}
