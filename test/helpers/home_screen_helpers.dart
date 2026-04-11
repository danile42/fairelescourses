import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/nav_session.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/connectivity_provider.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/local_only_provider.dart';
import 'package:fairelescourses/providers/nav_session_provider.dart';
import 'package:fairelescourses/providers/nav_view_mode_provider.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/home_screen.dart';
import 'package:fairelescourses/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// ── mocks ────────────────────────────────────────────────────────────────────

class MockFirestoreService extends Mock implements FirestoreService {}

class NullHouseholdNotifier extends HouseholdNotifier {
  @override
  String? build() => null;
}

class FakeListsNotifier extends ShoppingListNotifier {
  FakeListsNotifier(this._lists);
  final List<ShoppingList> _lists;

  @override
  List<ShoppingList> build() => _lists;

  @override
  Future<void> remove(String id) async {
    state = [
      for (final e in state)
        if (e.id != id) e,
    ];
  }

  @override
  Future<void> copy(String listId) async {}
}

class FakeStoresNotifier extends SupermarketNotifier {
  @override
  List<Supermarket> build() => [];
}

class FakeStoresNotifierWith extends SupermarketNotifier {
  FakeStoresNotifierWith(this._stores);
  final List<Supermarket> _stores;

  @override
  List<Supermarket> build() => _stores;

  @override
  Future<void> remove(String id) async {
    state = [
      for (final s in state)
        if (s.id != id) s,
    ];
  }
}

class FakeNavViewModeNotifier extends NavViewModeNotifier {
  @override
  bool build() => false; // no Hive access
}

class FakeLocalOnlyNotifier extends LocalOnlyNotifier {
  @override
  bool build() => false; // no Hive access
}

class FakeDismissedNavSessionNotifier
    extends LocallyDismissedNavSessionNotifier {
  FakeDismissedNavSessionNotifier(this._listId);

  final String? _listId;

  @override
  String? build() => _listId;
}

// ── helpers ──────────────────────────────────────────────────────────────────

ShoppingList makeList(String id, String name) => ShoppingList(
  id: id,
  name: name,
  preferredStoreIds: [],
  items: [ShoppingItem(name: 'Milk')],
);

Widget wrapHomeScreen({
  required List<ShoppingList> lists,
  NavSession? session,
  List<Supermarket>? stores,
  String? dismissedSessionListId,
}) {
  final mockSvc = MockFirestoreService();
  when(() => mockSvc.deleteNavSession(any())).thenAnswer((_) async {});
  when(() => mockSvc.upsertList(any(), any())).thenAnswer((_) async {});
  when(() => mockSvc.deleteList(any(), any())).thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      householdProvider.overrideWith(() => NullHouseholdNotifier()),
      shoppingListsProvider.overrideWith(() => FakeListsNotifier(lists)),
      if (stores != null)
        supermarketsProvider.overrideWith(() => FakeStoresNotifierWith(stores))
      else
        supermarketsProvider.overrideWith(() => FakeStoresNotifier()),
      navSessionProvider.overrideWith((ref) => Stream.value(session)),
      locallyDismissedNavSessionListIdProvider.overrideWith(
        () => FakeDismissedNavSessionNotifier(dismissedSessionListId),
      ),
      navViewModeProvider.overrideWith(() => FakeNavViewModeNotifier()),
      localOnlyProvider.overrideWith(() => FakeLocalOnlyNotifier()),
      firestoreSyncProvider.overrideWith((ref) {}),
      currentUidProvider.overrideWith((ref) => null),
      firestoreServiceProvider.overrideWithValue(mockSvc),
      // connectivity_plus has no platform implementation in tests
      isOfflineProvider.overrideWith((ref) => Stream.value(false)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    ),
  );
}
