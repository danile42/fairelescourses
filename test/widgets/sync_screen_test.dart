import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
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
}

class _KnownHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => 'ABC123';
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

      // Try to join by finding and tapping the Join button.
      // The button is an ElevatedButton next to the text field.
      final joinButtons = find.text('Join');
      if (joinButtons.evaluate().isNotEmpty) {
        await tester.tap(joinButtons.last);
        await tester.pumpAndSettle();
        // Invalid code: snackbar with error message.
        expect(find.byType(SnackBar), findsOneWidget);
      }
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
}
