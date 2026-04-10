import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/providers/home_location_provider.dart';
import 'package:fairelescourses/screens/shop_search_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';
import 'helpers/hive_helper.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class _FakeStoresNotifier extends SupermarketNotifier {
  _FakeStoresNotifier([this._stores = const []]);
  final List<Supermarket> _stores;
  @override
  List<Supermarket> build() => _stores;
}

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

  testWidgets(
    'Searching around home location with no results shows no retry button',
    (tester) async {
      final mockSvc = MockFirestoreService();
      when(
        () => mockSvc.searchNearby(any(), any(), any()),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreServiceProvider.overrideWithValue(mockSvc),
            firestoreSyncProvider.overrideWith((ref) {}),
            supermarketsProvider.overrideWith(() => _FakeStoresNotifier([])),
            homeLocationProvider.overrideWith(() => HomeLocationNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ShopSearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Set home location
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ShopSearchScreen)),
      );
      await container
          .read(homeLocationProvider.notifier)
          .set('Home', 52.52, 13.405);
      await tester.pumpAndSettle();

      // Tap "Near me" chip to trigger search if it's not already triggered
      // Actually, when home location becomes non-null, if _nearMe is true, it might trigger.
      // In ShopSearchScreen:
      // final homeLoc = ref.watch(homeLocationProvider);
      // useEffect style logic might be missing for auto-trigger when provider changes?

      // Let's find the "Near me" chip and tap it.
      final nearMeChip = find.text('Near me');
      if (nearMeChip.evaluate().isNotEmpty) {
        await tester.tap(nearMeChip);
        await tester.pumpAndSettle();
      }

      // Verify no results message or retry button is NOT found (the bug)
      // Based on the issue description, we expect NO results and NO retry button.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Retry'), findsNothing);

      // Check if any results are shown
      expect(find.byType(Card), findsNothing);
    },
  );
}
