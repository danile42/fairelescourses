import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/home_location_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/shop_search_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';

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

class _FakeHomeLocationNotifier extends HomeLocationNotifier {
  _FakeHomeLocationNotifier(this._location);

  final HomeLocation? _location;

  @override
  HomeLocation? build() => _location;
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
  when(() => svc.searchByItem(any())).thenAnswer((_) async => []);
  when(() => svc.searchNearby(any(), any(), any())).thenAnswer((_) async => []);
  when(() => svc.upsertShop(any(), any())).thenAnswer((_) async {});
  return svc;
}

Widget _wrap({
  List<Supermarket> stores = const [],
  MockFirestoreService? mockService,
  String? focusItem,
  Locale locale = const Locale('en'),
  HomeLocation? homeLocation,
}) {
  final svc = mockService ?? _mockSvc();
  return ProviderScope(
    overrides: [
      firestoreServiceProvider.overrideWithValue(svc),
      firestoreSyncProvider.overrideWith((ref) {}),
      homeLocationProvider.overrideWith(
        () => _FakeHomeLocationNotifier(homeLocation),
      ),
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

    testWidgets('shows segmented button with two modes', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('By location'), findsOneWidget);
      expect(find.text('By item'), findsOneWidget);
      expect(find.text('By name'), findsNothing);
    });

    testWidgets('default mode is By location — shows no-location-set hint', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // No home location set → no-location-set message shown (no search field).
      expect(
        find.text('No home location set. Go to Sync to set one.'),
        findsOneWidget,
      );
    });

    testWidgets('shows localized press-search hint in English', (tester) async {
      await tester.pumpWidget(
        _wrap(
          homeLocation: const HomeLocation(
            address: 'Berlin',
            lat: 52.52,
            lng: 13.405,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Press'), findsOneWidget);
      expect(find.text('to search.'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('shows localized press-search hint in German', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('de'),
          homeLocation: const HomeLocation(
            address: 'Berlin',
            lat: 52.52,
            lng: 13.405,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tippe auf'), findsOneWidget);
      expect(find.text('zum Suchen.'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsWidgets);
    });
  });

  group('ShopSearchScreen – tab switching', () {
    testWidgets('switching to By item shows text field with item hint', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();

      expect(find.text('Type an item name…'), findsOneWidget);
    });

    testWidgets('switching back to By location shows no-location-set hint', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('By location'));
      await tester.pumpAndSettle();

      expect(
        find.text('No home location set. Go to Sync to set one.'),
        findsOneWidget,
      );
    });
  });

  group('ShopSearchScreen – By item search', () {
    testWidgets('typing in By item does not auto-search', (tester) async {
      final svc = _mockSvc();
      await tester.pumpWidget(_wrap(mockService: svc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();

      final itemField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Type an item name…',
      );
      await tester.enterText(itemField, 'milk');
      await tester.pumpAndSettle();

      verifyNever(() => svc.searchByItem(any()));
    });

    testWidgets('searching by item calls searchByItem', (tester) async {
      final svc = _mockSvc();
      await tester.pumpWidget(_wrap(mockService: svc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();

      final itemField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Type an item name…',
      );
      await tester.enterText(itemField, 'milk');
      await tester.pump();
      final button = tester.widget<IconButton>(
        find.byKey(const Key('shopSearchExecuteButton')),
      );
      expect(button.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('shopSearchExecuteButton')));
      await tester.pumpAndSettle();

      verify(() => svc.searchByItem('milk')).called(1);
    });

    testWidgets('By item no results shows advisory text, not Create shop', (
      tester,
    ) async {
      final svc = _mockSvc();
      await tester.pumpWidget(_wrap(mockService: svc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();

      final itemField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Type an item name…',
      );
      await tester.enterText(itemField, 'milk');
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('shopSearchExecuteButton')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('shopSearchExecuteButton')));
      await tester.pumpAndSettle();

      verify(() => svc.searchByItem('milk')).called(1);
      expect(find.text('New shop'), findsNothing);
    });

    testWidgets('By item result shows shop name', (tester) async {
      final svc = _mockSvc();
      when(
        () => svc.searchByItem('milk'),
      ).thenAnswer((_) async => [_shop(name: 'Rewe Berlin')]);

      await tester.pumpWidget(_wrap(mockService: svc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();

      final itemField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Type an item name…',
      );
      await tester.enterText(itemField, 'milk');
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('shopSearchExecuteButton')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('shopSearchExecuteButton')));
      await tester.pumpAndSettle();

      verify(() => svc.searchByItem('milk')).called(1);
      expect(find.text('Rewe Berlin'), findsOneWidget);
    });

    testWidgets('result already in local stores shows "In your list" chip', (
      tester,
    ) async {
      final localShop = _shop(id: 's1', name: 'Rewe');
      final svc = _mockSvc();
      when(() => svc.searchByItem('milk')).thenAnswer((_) async => [localShop]);

      await tester.pumpWidget(_wrap(stores: [localShop], mockService: svc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();

      final itemField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Type an item name…',
      );
      await tester.enterText(itemField, 'milk');
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('shopSearchExecuteButton')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('shopSearchExecuteButton')));
      await tester.pumpAndSettle();

      verify(() => svc.searchByItem('milk')).called(1);
      expect(find.text('In your list'), findsOneWidget);
    });
  });

  group('ShopSearchScreen – By location', () {
    testWidgets('location input field wires submit handler', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.onSubmitted, isNotNull);
    });

    testWidgets(
      'entered-location mode with home shows only one search button',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            homeLocation: const HomeLocation(
              address: 'Berlin',
              lat: 52.52,
              lng: 13.405,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FilterChip).first); // disable Near me
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('shopSearchExecuteButton')),
          findsOneWidget,
        );
      },
    );

    testWidgets('near-me interactions do not auto-search', (tester) async {
      final svc = _mockSvc();
      await tester.pumpWidget(
        _wrap(
          mockService: svc,
          homeLocation: const HomeLocation(
            address: 'Berlin',
            lat: 52.52,
            lng: 13.405,
          ),
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => svc.searchNearby(any(), any(), any()));

      await tester.tap(find.byType(FilterChip).first);
      await tester.pumpAndSettle();
      verifyNever(() => svc.searchNearby(any(), any(), any()));

      await tester.tap(find.byType(FilterChip).first);
      await tester.pumpAndSettle();
      verifyNever(() => svc.searchNearby(any(), any(), any()));
    });

    testWidgets('By location without home shows no-location-set message', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // By location is the default; just confirm message is shown.
      expect(
        find.text('No home location set. Go to Sync to set one.'),
        findsOneWidget,
      );
    });

    testWidgets('By location shows category filter chip', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Category filter chip shows "Supermarket" label (default category).
      expect(find.text('Supermarket'), findsOneWidget);
    });

    testWidgets('By location: typing clears results when text is short', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // No home location → "Near me" chip absent; text field is shown.
      // Enter less than 2 characters — should not crash.
      await tester.enterText(find.byType(TextField), 'B');
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('ShopSearchScreen – German locale', () {
    testWidgets('renders in German without error', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.text('Märkte suchen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('German By item tab switches correctly', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('de')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nach Artikel'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('opening category popup shows all category options in German', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(locale: const Locale('de')));
      await tester.pumpAndSettle();

      // By location is the default; tap the category chip.
      await tester.tap(find.text('Supermarkt'));
      await tester.pumpAndSettle();

      expect(find.text('Kiosk / Laden'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ShopSearchScreen – persisted radius filter', () {
    setUp(() async {
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
      await Hive.box<String>(
        'settings',
      ).put('osmSearchCategories', 'shop:supermarket');
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
}
