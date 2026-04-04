import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/shop_search_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';
// ShopSearchResult is used indirectly through FirestoreService mock

import '../helpers/hive_helper.dart';

// ── mocks / fakes ─────────────────────────────────────────────────────────────

class MockFirestoreService extends Mock implements FirestoreService {}

class _FakeStoresNotifier extends SupermarketNotifier {
  _FakeStoresNotifier([this._stores = const []]);
  final List<Supermarket> _stores;

  @override
  List<Supermarket> build() => _stores;

  @override
  Future<void> add(Supermarket s, {bool syncToFirestore = true}) async =>
      state = [...state, s];
}

// ── helpers ───────────────────────────────────────────────────────────────────

Supermarket _shop({String id = 's1', String name = 'Rewe'}) => Supermarket(
  id: id,
  name: name,
  rows: const ['A'],
  cols: const ['1'],
  entrance: 'A1',
  exit: 'A1',
  cells: const {},
);

MockFirestoreService _mockSvc() {
  final svc = MockFirestoreService();
  when(() => svc.searchByName(any())).thenAnswer((_) async => []);
  when(() => svc.searchByItem(any())).thenAnswer((_) async => []);
  when(
    () => svc.searchNearby(any(), any(), any()),
  ).thenAnswer((_) async => []);
  when(() => svc.upsertShop(any(), any())).thenAnswer((_) async {});
  return svc;
}

Widget _wrap({
  List<Supermarket> stores = const [],
  MockFirestoreService? mockService,
  String? focusItem,
  Locale locale = const Locale('en'),
}) {
  final svc = mockService ?? _mockSvc();
  return ProviderScope(
    overrides: [
      firestoreServiceProvider.overrideWithValue(svc),
      firestoreSyncProvider.overrideWith((ref) {}),
      supermarketsProvider.overrideWith(() => _FakeStoresNotifier(stores)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ShopSearchScreen(focusItem: focusItem),
    ),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    registerFallbackValue(
      Supermarket(
        id: '',
        name: '',
        rows: [],
        cols: [],
        entrance: '',
        exit: '',
        cells: {},
      ),
    );
    hiveDir = await setUpHive();
  });
  tearDownAll(() async {
    await tearDownHive(hiveDir);
  });
  setUp(() async {
    await clearHive();
  });

  group('ShopSearchScreen – basic render', () {
    testWidgets('shows AppBar with search title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Search shops'), findsOneWidget);
    });

    testWidgets('shows segmented button with three modes', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('By name'), findsOneWidget);
      expect(find.text('By item'), findsOneWidget);
      expect(find.text('By location'), findsOneWidget);
    });

    testWidgets('initial state shows minimum-characters hint', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Type at least 2 characters to search.'), findsOneWidget);
    });

    testWidgets('search field is present with correct hint', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a shop name…'), findsOneWidget);
    });
  });

  group('ShopSearchScreen – tab switching', () {
    testWidgets('switching to By item changes hint text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();

      expect(find.text('Type an item name…'), findsOneWidget);
    });

    testWidgets('switching to By location shows location hint', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('By location'));
      await tester.pumpAndSettle();

      // No home location set → "no location set" message
      expect(find.text('No home location set. Go to Sync to set one.'),
          findsOneWidget);
    });

    testWidgets('switching back to By name restores hint', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('By name'));
      await tester.pumpAndSettle();

      expect(find.text('Type a shop name…'), findsOneWidget);
    });
  });

  group('ShopSearchScreen – By name search', () {
    testWidgets('typing 2+ chars and waiting triggers search', (tester) async {
      final svc = _mockSvc();
      await tester.pumpWidget(_wrap(mockService: svc));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 're');
      // Wait for debounce (400 ms) and async response.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      verify(() => svc.searchByName('re')).called(1);
    });

    testWidgets('search with no results shows no-shops message', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 're');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('No shops found.'), findsOneWidget);
    });

    testWidgets('search returns results and shows shop name', (tester) async {
      final svc = _mockSvc();
      when(
        () => svc.searchByName('rewe'),
      ).thenAnswer((_) async => [_shop(name: 'Rewe Berlin')]);

      await tester.pumpWidget(_wrap(mockService: svc));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'rewe');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Rewe Berlin'), findsOneWidget);
    });

    testWidgets('result already in local stores shows "In your list" chip', (
      tester,
    ) async {
      final localShop = _shop(id: 's1', name: 'Rewe');
      final svc = _mockSvc();
      when(
        () => svc.searchByName('rewe'),
      ).thenAnswer((_) async => [localShop]);

      await tester.pumpWidget(
        _wrap(stores: [localShop], mockService: svc),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'rewe');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('In your list'), findsOneWidget);
    });
  });

  group('ShopSearchScreen – By item search', () {
    testWidgets('switching to By item and searching calls searchByItem', (
      tester,
    ) async {
      final svc = _mockSvc();
      await tester.pumpWidget(_wrap(mockService: svc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      verify(() => svc.searchByItem('milk')).called(1);
    });
  });

  group('ShopSearchScreen – By location', () {
    testWidgets(
      'By location without home shows no-location-set message',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        await tester.tap(find.text('By location'));
        await tester.pumpAndSettle();

        expect(
          find.text('No home location set. Go to Sync to set one.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('By location shows category filter chip', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('By location'));
      await tester.pumpAndSettle();

      // Category filter chip shows "Supermarket" label (default category).
      expect(find.text('Supermarket'), findsOneWidget);
    });
  });

  group('ShopSearchScreen – German locale', () {
    testWidgets('renders in German without error', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('de')));
      await tester.pumpAndSettle();

      // "Märkte suchen" is the German AppBar title.
      expect(find.text('Märkte suchen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('German By location tab switches correctly', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('de')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nach Ort'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ShopSearchScreen – persisted radius filter', () {
    setUp(() async {
      // Write to Hive outside testWidgets (real async) to avoid FakeAsync hang.
      await Hive.box<String>('settings').put('osmSearchRadius', '2000');
    });

    testWidgets('screen renders without error when radius is persisted', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Search shops'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ShopSearchScreen – persisted categories filter', () {
    setUp(() async {
      await Hive.box<String>('settings').put(
        'osmSearchCategories',
        'shop:supermarket',
      );
    });

    testWidgets('screen renders without error when categories are persisted', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Search shops'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ShopSearchScreen – By location text input', () {
    testWidgets('By location: typing clears results when text is short', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('By location'));
      await tester.pumpAndSettle();

      // Type less than 2 characters — should not crash.
      await tester.enterText(find.byType(TextField), 'B');
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('ShopSearchScreen – German category popup', () {
    testWidgets('opening category popup shows all category options in German', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(locale: const Locale('de')));
      await tester.pumpAndSettle();

      // Switch to By location tab.
      await tester.tap(find.text('Nach Ort'));
      await tester.pumpAndSettle();

      // Tap the category chip to open the popup menu.
      await tester.tap(find.text('Supermarkt'));
      await tester.pumpAndSettle();

      // Popup is open and shows category labels.
      expect(find.text('Kiosk / Laden'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Dismiss popup by tapping outside it.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
