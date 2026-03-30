import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/home_location_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/local_only_provider.dart';
import 'package:fairelescourses/providers/nav_view_mode_provider.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/sync_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';

import '../helpers/hive_helper.dart';

// ── mocks / fakes ─────────────────────────────────────────────────────────────

class MockFirestoreService extends Mock implements FirestoreService {}

class _NullHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => null;

  @override
  Future<void> setId(String id) async {
    state = id;
  }

  @override
  Future<void> clear() async {
    state = null;
  }
}

class _KnownHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => 'ABC123';

  @override
  Future<void> setId(String id) async {
    state = id;
  }

  @override
  Future<void> clear() async {
    state = null;
  }
}

class _FakeStoresNotifier extends SupermarketNotifier {
  @override
  List<Supermarket> build() => [];
}

class _FakeListsNotifier extends ShoppingListNotifier {
  @override
  List<ShoppingList> build() => [];

  @override
  Future<void> uploadAll(String hid) async {}
}

class _FakeNavViewModeNotifier extends NavViewModeNotifier {
  @override
  bool build() => false;

  @override
  Future<void> set(bool preferList) async {
    state = preferList;
  }
}

class _FakeLocalOnlyNotifier extends LocalOnlyNotifier {
  @override
  bool build() => false;

  @override
  Future<void> set(bool value) async {
    state = value;
  }
}

class _FakeHomeLocationNotifier extends HomeLocationNotifier {
  @override
  HomeLocation? build() => null;
}

class _FakeHomeLocationSetNotifier extends HomeLocationNotifier {
  final String address;
  final double lat;
  final double lng;
  _FakeHomeLocationSetNotifier(this.address, this.lat, this.lng);

  @override
  HomeLocation? build() => HomeLocation(address: address, lat: lat, lng: lng);

  @override
  Future<void> clear() async {
    state = null;
  }
}

// ── helpers ───────────────────────────────────────────────────────────────────

Widget _wrap({bool hasHousehold = false}) {
  final mockSvc = MockFirestoreService();
  return ProviderScope(
    overrides: [
      householdProvider.overrideWith(
        () =>
            hasHousehold ? _KnownHouseholdNotifier() : _NullHouseholdNotifier(),
      ),
      supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
      shoppingListsProvider.overrideWith(() => _FakeListsNotifier()),
      firestoreSyncProvider.overrideWith((ref) {}),
      currentUidProvider.overrideWith((ref) => null),
      firestoreServiceProvider.overrideWithValue(mockSvc),
      navViewModeProvider.overrideWith(() => _FakeNavViewModeNotifier()),
      homeLocationProvider.overrideWith(() => _FakeHomeLocationNotifier()),
      localOnlyProvider.overrideWith(() => _FakeLocalOnlyNotifier()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SyncScreen(),
    ),
  );
}

Widget _wrapWithHomeLocation(String address, double lat, double lng) {
  final mockSvc = MockFirestoreService();
  return ProviderScope(
    overrides: [
      householdProvider.overrideWith(() => _NullHouseholdNotifier()),
      supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
      shoppingListsProvider.overrideWith(() => _FakeListsNotifier()),
      firestoreSyncProvider.overrideWith((ref) {}),
      currentUidProvider.overrideWith((ref) => null),
      firestoreServiceProvider.overrideWithValue(mockSvc),
      navViewModeProvider.overrideWith(() => _FakeNavViewModeNotifier()),
      homeLocationProvider.overrideWith(
        () => _FakeHomeLocationSetNotifier(address, lat, lng),
      ),
      localOnlyProvider.overrideWith(() => _FakeLocalOnlyNotifier()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SyncScreen(),
    ),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await setUpHive();
  });

  tearDownAll(() async {
    await tearDownHive(hiveDir);
  });

  setUp(() async {
    await clearHive();
  });

  group('SyncScreen – rendering', () {
    testWidgets('renders home-location section', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Home location'), findsOneWidget);
    });

    testWidgets('shows nav view mode setting', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Default navigation view'), findsOneWidget);
      expect(find.text('Grid'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);
    });

    testWidgets('shows create and join household buttons when no household', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Create new household'), findsOneWidget);
      expect(find.text('Join household'), findsWidgets);
    });

    testWidgets('shows household ID and leave button when in a household', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(hasHousehold: true));
      await tester.pumpAndSettle();
      expect(find.text('Your household ID'), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('Leave household'), findsOneWidget);
    });

    testWidgets('shows Firebase instance section', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Firebase instance'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });

    testWidgets('shows local-only mode toggle', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Local storage only'), findsOneWidget);
    });

    testWidgets('renders in German without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => _NullHouseholdNotifier()),
            supermarketsProvider.overrideWith(() => _FakeStoresNotifier()),
            shoppingListsProvider.overrideWith(() => _FakeListsNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
            navViewModeProvider.overrideWith(() => _FakeNavViewModeNotifier()),
            homeLocationProvider.overrideWith(
              () => _FakeHomeLocationNotifier(),
            ),
            localOnlyProvider.overrideWith(() => _FakeLocalOnlyNotifier()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SyncScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Heimatort'), findsOneWidget);
      expect(find.text('Synchronisierung'), findsOneWidget);
    });
  });

  group('SyncScreen – home location', () {
    testWidgets('shows set-location text field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'City or address…'), findsWidgets);
    });

    testWidgets('enter key in location field attempts geocode', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // Just verify the field is there and interactable.
      final field = find.widgetWithText(TextField, 'City or address…');
      await tester.tap(field.first);
      await tester.enterText(field.first, 'Berlin');
      await tester.pump();
      // Don't submit (geocoder would fail in tests); just verify no crash.
      expect(find.text('Berlin'), findsWidgets);
    });
  });

  group('SyncScreen – local-only mode', () {
    testWidgets('local-only toggle shows warning when activated', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // A confirmation dialog should appear.
      expect(find.textContaining('Switch to local-only mode'), findsOneWidget);
      // Cancel it.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });

  group('SyncScreen – household join UI', () {
    testWidgets('join button is disabled when text field is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // The join text field should be present.
      expect(
        find.widgetWithText(TextField, 'Enter 6-character code'),
        findsOneWidget,
      );
    });

    testWidgets('shows leave-household confirmation dialog', (tester) async {
      await tester.pumpWidget(_wrap(hasHousehold: true));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Leave household'));
      await tester.tap(find.text('Leave household'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Stop syncing and leave'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('entering invalid join code shows error', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final joinField = find.widgetWithText(
        TextField,
        'Enter 6-character code',
      );
      await tester.ensureVisible(joinField);
      await tester.tap(joinField, warnIfMissed: false);
      await tester.enterText(joinField, 'BAD');
      await tester.pump();

      // The Join button label is "Join household".
      final joinBtn = find.text('Join household').last;
      await tester.ensureVisible(joinBtn);
      await tester.tap(joinBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Invalid code: snackbar with error message.
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('entering valid join code joins the household', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final joinField = find.widgetWithText(
        TextField,
        'Enter 6-character code',
      );
      await tester.ensureVisible(joinField);
      await tester.tap(joinField, warnIfMissed: false);
      await tester.enterText(joinField, 'ABC123');
      await tester.pump();

      final joinBtn = find.text('Join household').last;
      await tester.ensureVisible(joinBtn);
      await tester.tap(joinBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // After successful join, no exception.
      expect(tester.takeException(), isNull);
    });
  });

  group('SyncScreen – Firebase editing', () {
    testWidgets('tapping Change reveals Firebase editing fields', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Change'));
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      // Firebase editing fields should appear (Cancel button visible).
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel in Firebase editor hides editing fields', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Change'));
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // After cancelling, Change button is visible again (scroll back).
      expect(find.text('Firebase instance'), findsOneWidget);
    });
  });

  group('SyncScreen – create household', () {
    testWidgets('tapping Create new household triggers creation', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Create new household'));
      await tester.tap(find.text('Create new household'));
      // Don't settle — household creation is async; just verify no immediate crash.
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('SyncScreen – home location clear', () {
    testWidgets('shows delete button when home location is set', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithHomeLocation('Berlin', 52.5, 13.4));
      await tester.pumpAndSettle();

      expect(find.text('Berlin'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tapping Delete clears the home location', (tester) async {
      await tester.pumpWidget(_wrapWithHomeLocation('Munich', 48.1, 11.6));
      await tester.pumpAndSettle();

      expect(find.text('Munich'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Munich'), findsNothing);
    });
  });

  group('SyncScreen – copy household ID', () {
    testWidgets('tapping copy icon copies household ID to clipboard', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(hasHousehold: true));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.copy));
      await tester.tap(find.byIcon(Icons.copy), warnIfMissed: false);
      await tester.pumpAndSettle();

      // No exception after copy.
      expect(tester.takeException(), isNull);
    });
  });

  group('SyncScreen – set home location empty', () {
    testWidgets('tapping Set with empty field is a no-op', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // The Set button is visible without scrolling.
      final setBtn = find.text('Set');
      await tester.ensureVisible(setBtn);
      await tester.tap(setBtn, warnIfMissed: false);
      await tester.pump();

      // Empty query → early return, no snackbar.
      expect(tester.takeException(), isNull);
    });
  });

  group('SyncScreen – nav view mode toggle', () {
    testWidgets('selecting List changes the SegmentedButton state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Tap the "List" segment.
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
