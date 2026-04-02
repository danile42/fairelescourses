import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/nav_session.dart';
import '../models/supermarket.dart';
import '../models/shopping_list.dart';

class ShopSearchResult {
  final Supermarket shop;
  final double? distanceKm;
  const ShopSearchResult({required this.shop, this.distanceKm});
}

class FirestoreService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirestoreService(FirebaseApp app)
    : _db = FirebaseFirestore.instanceFor(app: app),
      _auth = FirebaseAuth.instanceFor(app: app);

  String? get currentUid => _auth.currentUser?.uid;

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
    return jsonDecode(encrypter.decrypt(cipher, iv: iv))
        as Map<String, dynamic>;
  }

  // ── Shops (top-level collection, unencrypted, multi-user) ─────────────────

  CollectionReference<Map<String, dynamic>> get _shopsCol =>
      _db.collection('shops');

  CollectionReference<Map<String, dynamic>> get _publicShopsCol =>
      _db.collection('public_shops');

  Future<void> upsertShop(String hid, Supermarket s) {
    final data = s.toMap()
      ..['ownerUid'] = _auth.currentUser!.uid
      ..['householdHash'] = _pathId(hid)
      ..['nameLower'] = s.name.toLowerCase()
      ..['goodsList'] = _goodsList(s);
    if (s.lat == null) data.remove('lat');
    if (s.lng == null) data.remove('lng');
    if (s.address == null) data.remove('address');
    return _shopsCol.doc(s.id).set(data);
  }

  /// Writes the cell layout of an OSM-imported shop to the public collection
  /// so other users importing the same OSM node see it pre-populated.
  Future<void> upsertPublicCells(Supermarket s) {
    if (s.osmId == null) return Future.value();
    return _publicShopsCol.doc('${s.osmId}').set({
      'osmId': s.osmId,
      'rows': s.rows,
      'cols': s.cols,
      'entrance': s.entrance,
      'exit': s.exit,
      'cells': s.cells,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: false));
  }

  /// Fetches the publicly shared cell layout for an OSM shop, or null if none.
  Future<Supermarket?> fetchPublicShop(int osmId) async {
    final doc = await _publicShopsCol.doc('$osmId').get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    return Supermarket(
      id: 'osm_$osmId',
      name: '',
      rows: List<String>.from(d['rows'] as List),
      cols: List<String>.from(d['cols'] as List),
      entrance: d['entrance'] as String,
      exit: d['exit'] as String,
      cells: (d['cells'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      ),
      osmId: osmId,
    );
  }

  static List<String> _goodsList(Supermarket s) => s.cells.values
      .expand((goods) => goods)
      .map((g) => g.toLowerCase().trim())
      .where((g) => g.isNotEmpty)
      .toSet()
      .toList();

  Future<List<Supermarket>> searchByName(String query) async {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    final snap = await _shopsCol
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(30)
        .get();
    return snap.docs.map(_shopFromDoc).toList();
  }

  Future<List<Supermarket>> searchByItem(String item) async {
    if (item.isEmpty) return [];
    final snap = await _shopsCol
        .where('goodsList', arrayContains: item.toLowerCase().trim())
        .limit(30)
        .get();
    return snap.docs.map(_shopFromDoc).toList();
  }

  Future<List<ShopSearchResult>> searchNearby(
    double lat,
    double lng,
    double radiusKm,
  ) async {
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
        results.add(
          ShopSearchResult(shop: _shopFromDoc(doc), distanceKm: dist),
        );
      }
    }
    results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return results;
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  static Supermarket _shopFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final shop = Supermarket.fromMap(d.data());
    shop.ownerUid = d.data()['ownerUid'] as String?;
    return shop;
  }

  Future<void> deleteShop(String hid, String id) => _shopsCol.doc(id).delete();

  Stream<List<Supermarket>> shopsStream(String hid) => _shopsCol
      .where('householdHash', isEqualTo: _pathId(hid))
      .snapshots()
      .map((snap) {
        final uid = _auth.currentUser?.uid;
        return snap.docs.map((d) {
          final data = d.data();
          final shop = Supermarket.fromMap(data);
          shop.ownerUid = data['ownerUid'] as String?;
          if (shop.ownerUid == uid &&
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

  CollectionReference<Map<String, dynamic>> _lists(String hid) =>
      _db.collection('h').doc(_pathId(hid)).collection('l');

  Future<void> upsertList(String hid, ShoppingList l) =>
      _lists(hid).doc(l.id).set({'d': _encrypt(hid, l.toMap())});

  Future<void> deleteList(String hid, String id) =>
      _lists(hid).doc(id).delete();

  // ── Collaborative navigation session ─────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _navDoc(String hid) =>
      _db.collection('h').doc(_pathId(hid)).collection('nav').doc('current');

  Future<void> upsertNavSession(String hid, String listId) => _navDoc(hid).set({
    'listId': listId,
    'startedBy': _auth.currentUser!.uid,
    'startedAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteNavSession(String hid) => _navDoc(hid).delete();

  Stream<NavSession?> navSessionStream(String hid) =>
      _navDoc(hid).snapshots().map((snap) {
        if (!snap.exists || snap.data() == null) return null;
        final data = snap.data()!;
        return NavSession(
          listId: data['listId'] as String,
          startedBy: data['startedBy'] as String,
        );
      });

  Stream<List<ShoppingList>> listsStream(String hid) =>
      _lists(hid).snapshots().map(
        (snap) => snap.docs
            .map(
              (d) =>
                  ShoppingList.fromMap(_decrypt(hid, d.data()['d'] as String)),
            )
            .toList(),
      );
}
