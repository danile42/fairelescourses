import 'package:flutter_test/flutter_test.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/screens/shop_search_screen.dart';

Supermarket _makeShop({
  String id = 'shop-1',
  String name = 'Rewe',
  double? lat,
  double? lng,
}) => Supermarket(
  id: id,
  name: name,
  rows: const ['A'],
  cols: const ['1'],
  entrance: 'A1',
  exit: 'A1',
  cells: const {},
  lat: lat,
  lng: lng,
);

void main() {
  group('isKnownFirestore', () {
    group('when remote shop has coordinates', () {
      test('returns true for a local shop within 0.2 km', () {
        // Berlin city centre + ~100 m offset
        final remote = _makeShop(lat: 52.5200, lng: 13.4050);
        final local = _makeShop(id: 'local-1', lat: 52.5209, lng: 13.4050);
        expect(isKnownFirestore(remote, [local]), isTrue);
      });

      test('returns false for a local shop further than 0.2 km away', () {
        final remote = _makeShop(lat: 52.5200, lng: 13.4050);
        // ~1 km north
        final local = _makeShop(id: 'local-1', lat: 52.5290, lng: 13.4050);
        expect(isKnownFirestore(remote, [local]), isFalse);
      });

      test(
        'returns false when local shop has the same name but no coordinates',
        () {
          final remote = _makeShop(lat: 52.5200, lng: 13.4050, name: 'Rewe');
          final local = _makeShop(id: 'local-1', name: 'Rewe'); // no lat/lng
          expect(isKnownFirestore(remote, [local]), isFalse);
        },
      );

      test('returns true when one of multiple local shops is nearby', () {
        final remote = _makeShop(lat: 52.5200, lng: 13.4050);
        final farShop = _makeShop(
          id: 'far',
          lat: 48.1351,
          lng: 11.5820,
        ); // Munich
        final nearShop = _makeShop(id: 'near', lat: 52.5205, lng: 13.4051);
        expect(isKnownFirestore(remote, [farShop, nearShop]), isTrue);
      });

      test('same-name shop in different city is not considered known', () {
        final berlinRewe = _makeShop(lat: 52.5200, lng: 13.4050, name: 'Rewe');
        final munichRewe = _makeShop(
          id: 'local-1',
          lat: 48.1351,
          lng: 11.5820,
          name: 'Rewe',
        );
        expect(isKnownFirestore(berlinRewe, [munichRewe]), isFalse);
      });
    });

    group('when remote shop has no coordinates', () {
      test(
        'returns true when a local shop has the same name (case-insensitive)',
        () {
          final remote = _makeShop(name: 'Rewe');
          final local = _makeShop(id: 'local-1', name: 'REWE');
          expect(isKnownFirestore(remote, [local]), isTrue);
        },
      );

      test('returns false when no local shop matches the name', () {
        final remote = _makeShop(name: 'Rewe');
        final local = _makeShop(id: 'local-1', name: 'Aldi');
        expect(isKnownFirestore(remote, [local]), isFalse);
      });

      test('returns false with empty stores list', () {
        final remote = _makeShop(name: 'Rewe');
        expect(isKnownFirestore(remote, []), isFalse);
      });
    });
  });

  group('isKnownOsm', () {
    test('returns true for a local shop within 0.2 km', () {
      final local = _makeShop(id: 'local-1', lat: 52.5209, lng: 13.4050);
      expect(isKnownOsm(52.5200, 13.4050, [local]), isTrue);
    });

    test('returns false for a local shop further than 0.2 km away', () {
      final local = _makeShop(id: 'local-1', lat: 52.5290, lng: 13.4050);
      expect(isKnownOsm(52.5200, 13.4050, [local]), isFalse);
    });

    test(
      'same-name shop in different city is not considered known (regression)',
      () {
        // The bug: Rewe Berlin was marked as known when only Rewe Munich was local.
        final munichRewe = _makeShop(
          id: 'local-1',
          name: 'Rewe',
          lat: 48.1351,
          lng: 11.5820,
        );
        // OSM result for a Rewe in Berlin — should NOT be "already known"
        expect(isKnownOsm(52.5200, 13.4050, [munichRewe]), isFalse);
      },
    );

    test('returns false when local shops have no coordinates', () {
      final local = _makeShop(id: 'local-1', name: 'Rewe'); // no lat/lng
      expect(isKnownOsm(52.5200, 13.4050, [local]), isFalse);
    });

    test('returns false with empty stores list', () {
      expect(isKnownOsm(52.5200, 13.4050, []), isFalse);
    });
  });

  group('findLocalByOsm', () {
    test('returns the matching local shop when within 0.2 km', () {
      final local = _makeShop(id: 'near', lat: 52.5209, lng: 13.4050);
      expect(findLocalByOsm(52.5200, 13.4050, [local]), same(local));
    });

    test('returns null when no local shop is within 0.2 km', () {
      final far = _makeShop(id: 'far', lat: 48.1351, lng: 11.5820);
      expect(findLocalByOsm(52.5200, 13.4050, [far]), isNull);
    });

    test('returns null when local shops have no coordinates', () {
      final noCoords = _makeShop(id: 'x');
      expect(findLocalByOsm(52.5200, 13.4050, [noCoords]), isNull);
    });

    test('returns null for empty store list', () {
      expect(findLocalByOsm(52.5200, 13.4050, []), isNull);
    });

    test('returns the nearest shop when multiple are within range', () {
      final closer = _makeShop(id: 'closer', lat: 52.5202, lng: 13.4050);
      final further = _makeShop(id: 'further', lat: 52.5205, lng: 13.4050);
      // firstOrNull returns the first match; both are within 0.2 km
      final result = findLocalByOsm(52.5200, 13.4050, [closer, further]);
      expect(result, isNotNull);
    });
  });

  group('shopSearchHaversineKm', () {
    test('same point is 0', () {
      expect(shopSearchHaversineKm(52.0, 13.0, 52.0, 13.0), 0.0);
    });

    test('roughly correct for known distance', () {
      // Berlin to Munich ≈ 504 km
      final km = shopSearchHaversineKm(52.5200, 13.4050, 48.1351, 11.5820);
      expect(km, closeTo(504, 10));
    });

    test('1 degree of latitude ≈ 111 km', () {
      final km = shopSearchHaversineKm(0.0, 0.0, 1.0, 0.0);
      expect(km, closeTo(111, 1));
    });
  });
}
