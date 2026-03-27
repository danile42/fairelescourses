import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/osm_shops_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class _FakeStoresNotifier extends SupermarketNotifier {
  @override
  List<Supermarket> build() => [];
}

Widget _wrap() => ProviderScope(
      overrides: [
        supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OsmShopsScreen(lat: 48.1, lng: 11.5, radiusMeters: 2000),
      ),
    );

void main() {
  group('OsmShopsScreen', () {
    testWidgets('shows error state when network is unavailable', (tester) async {
      // TestWidgetsFlutterBinding intercepts all HTTP and returns 400,
      // so the Overpass call fails and the error UI should appear.
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows category filter chip', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // The category chip should be visible (shows "Supermarket" by default).
      expect(find.byType(InputChip), findsOneWidget);
    });

    testWidgets('shows refresh button in app bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
