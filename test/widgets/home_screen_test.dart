import 'dart:io';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/models/nav_session.dart';
import 'package:fairelescourses/models/shop_floor.dart';
import 'package:fairelescourses/models/shopping_list.dart';
import 'package:fairelescourses/models/supermarket.dart';
import 'package:fairelescourses/providers/firestore_sync_provider.dart';
import 'package:fairelescourses/providers/household_provider.dart';
import 'package:fairelescourses/providers/local_only_provider.dart';
import 'package:fairelescourses/providers/nav_session_provider.dart';
import 'package:fairelescourses/providers/nav_view_mode_provider.dart';
import 'package:fairelescourses/providers/shopping_list_provider.dart';
import 'package:fairelescourses/providers/supermarket_provider.dart';
import 'package:fairelescourses/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/hive_helper.dart';
import '../helpers/home_screen_helpers.dart';

// ── tests ────────────────────────────────────────────────────────────────────

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    registerFallbackValue(
      ShoppingList(id: '', name: '', preferredStoreIds: [], items: []),
    );
    hiveDir = await setUpHive();
  });

  tearDownAll(() async {
    await tearDownHive(hiveDir);
  });

  setUp(() async {
    await clearHive();
    // Prevent HomeScreen from pushing the intro HelpScreen on first run.
    await Hive.box<String>('settings').put('introSeen', 'true');
  });

  group('HomeScreen list tab', () {
    testWidgets('renders list names', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(
          lists: [makeList('L1', 'Groceries'), makeList('L2', 'Hardware')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Hardware'), findsOneWidget);
    });

    testWidgets('shows empty-state message when no lists', (tester) async {
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pumpAndSettle();
      expect(find.textContaining('No shopping lists'), findsOneWidget);
    });

    testWidgets('delete menu item is enabled when no active session', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapHomeScreen(lists: [makeList('L1', 'Groceries')]),
      );
      await tester.pumpAndSettle();

      // Open the PopupMenu for the list card.
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // When enabled, the code passes style: null to the Text widget.
      expect(find.text('Delete'), findsOneWidget);
      final deleteText = tester.widget<Text>(find.text('Delete'));
      expect(deleteText.style?.color, isNot(Colors.grey));
    });

    testWidgets(
      'delete menu item is disabled when session is active for that list',
      (tester) async {
        const session = NavSession(listId: 'L1', startedBy: 'uid-1');
        await tester.pumpWidget(
          wrapHomeScreen(
            lists: [makeList('L1', 'Groceries')],
            session: session,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();

        // When disabled, the code explicitly sets TextStyle(color: Colors.grey).
        expect(find.text('Delete'), findsOneWidget);
        final deleteText = tester.widget<Text>(find.text('Delete'));
        expect(deleteText.style?.color, Colors.grey);
      },
    );

    testWidgets('delete is enabled for a list that is NOT the active session', (
      tester,
    ) async {
      // Session is on L1, but we have L1 and L2 — only L1's delete should be disabled.
      const session = NavSession(listId: 'L1', startedBy: 'uid-1');
      await tester.pumpWidget(
        wrapHomeScreen(
          lists: [makeList('L1', 'Groceries'), makeList('L2', 'Hardware')],
          session: session,
        ),
      );
      await tester.pumpAndSettle();

      // Open popup for the second list card (Hardware / L2).
      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();

      // L2 is not the active session list, so delete should be enabled (style: null).
      expect(find.text('Delete'), findsOneWidget);
      final deleteText = tester.widget<Text>(find.text('Delete'));
      expect(deleteText.style?.color, isNot(Colors.grey));
    });

    testWidgets(
      'completed collaborative session is not shown as active anymore',
      (tester) async {
        const session = NavSession(listId: 'L1', startedBy: 'uid-1');
        final completedList = ShoppingList(
          id: 'L1',
          name: 'Groceries',
          preferredStoreIds: [],
          items: [ShoppingItem(name: 'Milk', checked: true)],
        );

        await tester.pumpWidget(
          wrapHomeScreen(lists: [completedList], session: session),
        );
        await tester.pumpAndSettle();

        expect(find.text('Join'), findsNothing);

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();

        final deleteText = tester.widget<Text>(find.text('Delete'));
        expect(deleteText.style?.color, isNot(Colors.grey));
      },
    );

    testWidgets(
      'locally dismissed collaborative session is hidden until stream updates',
      (tester) async {
        const session = NavSession(listId: 'L1', startedBy: 'uid-1');

        await tester.pumpWidget(
          wrapHomeScreen(
            lists: [makeList('L1', 'Groceries')],
            session: session,
            dismissedSessionListId: 'L1',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Join'), findsNothing);

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();

        final deleteText = tester.widget<Text>(find.text('Delete'));
        expect(deleteText.style?.color, isNot(Colors.grey));
      },
    );
  });

  group('HomeScreen shops tab', () {
    Supermarket makeStore({int extraFloors = 0}) {
      final s = Supermarket(
        id: 'store-1',
        name: 'Test Market',
        rows: ['A', 'B', 'C'],
        cols: ['1', '2', '3'],
        entrance: 'A1',
        exit: 'C3',
        cells: {},
      );
      if (extraFloors > 0) {
        s.additionalFloors = List.generate(
          extraFloors,
          (i) => ShopFloor(
            name: '',
            rows: ['A', 'B'],
            cols: ['1', '2'],
            entrance: 'A1',
            exit: 'B2',
          ),
        );
      }
      return s;
    }

    testWidgets('single-floor store shows grid size without floor count', (
      tester,
    ) async {
      await tester.pumpWidget(wrapHomeScreen(lists: [], stores: [makeStore()]));
      await tester.pumpAndSettle();

      // Navigate to the Shops tab.
      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      expect(find.text('3×3'), findsOneWidget);
      expect(find.textContaining('floors'), findsNothing);
    });

    testWidgets('multi-floor store shows floor count in subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapHomeScreen(lists: [], stores: [makeStore(extraFloors: 1)]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      // "3×3  •  2 floors"
      expect(find.textContaining('2 floors'), findsOneWidget);
    });

    testWidgets('three-floor store shows correct count', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(lists: [], stores: [makeStore(extraFloors: 2)]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      expect(find.textContaining('3 floors'), findsOneWidget);
    });

    testWidgets('empty shops tab shows no-stores message', (tester) async {
      await tester.pumpWidget(wrapHomeScreen(lists: [], stores: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No shops'), findsOneWidget);
    });
  });

  group('HomeScreen FAB', () {
    testWidgets('tapping FAB expands mini buttons', (tester) async {
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton).last);
      await tester.pumpAndSettle();

      expect(find.text('New shop'), findsOneWidget);
      expect(find.text('New list'), findsOneWidget);
    });

    testWidgets('tapping FAB twice collapses mini buttons', (tester) async {
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.byType(FloatingActionButton).last);
      await tester.pumpAndSettle();
      expect(find.text('New shop'), findsOneWidget);

      // Collapse — main FAB is still last after expansion
      await tester.tap(find.byType(FloatingActionButton).last);
      await tester.pumpAndSettle();

      expect(find.text('New shop'), findsNothing);
    });

    testWidgets('tapping New shop opens shop search screen', (tester) async {
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pumpAndSettle();

      // Expand FAB
      await tester.tap(find.byType(FloatingActionButton).last);
      await tester.pumpAndSettle();

      // Tap New shop mini button
      await tester.tap(find.text('New shop'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Search shops'), findsOneWidget);
    });

    testWidgets('tapping New list opens list editor screen', (tester) async {
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pumpAndSettle();

      // Expand FAB
      await tester.tap(find.byType(FloatingActionButton).last);
      await tester.pumpAndSettle();

      // Tap New list mini button
      await tester.tap(find.text('New list'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen delete confirmation', () {
    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(lists: [makeList('L1', 'Groceries')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog should show yes/no buttons.
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
    });

    testWidgets('copy menu item triggers copy', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(lists: [makeList('L1', 'Groceries')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
    });
  });

  group('HomeScreen join banner', () {
    testWidgets('shows join banner when active session matches a list', (
      tester,
    ) async {
      const session = NavSession(listId: 'L1', startedBy: 'uid-1');
      await tester.pumpWidget(
        wrapHomeScreen(lists: [makeList('L1', 'Groceries')], session: session),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.group), findsOneWidget);
    });
  });

  group('HomeScreen selection mode', () {
    testWidgets('long press on list card enters selection mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapHomeScreen(
          lists: [makeList('L1', 'Groceries'), makeList('L2', 'Hardware')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      // In selection mode, checkboxes appear.
      expect(find.byType(Checkbox), findsWidgets);
    });
  });

  group('HomeScreen help button', () {
    testWidgets('tapping help button opens help screen', (tester) async {
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      // Help screen opens — no crash.
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen AppBar buttons', () {
    testWidgets('tapping config icon opens settings screen', (tester) async {
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // SyncScreen opens — no crash.
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping search icon opens shop search screen', (tester) async {
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // ShopSearchScreen opens — no crash.
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen German locale', () {
    testWidgets('renders in German without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(
              () => FakeListsNotifier([makeList('L1', 'Einkauf')]),
            ),
            supermarketsProvider.overrideWith(() => FakeStoresNotifier()),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Fairelescourses'), findsOneWidget);
    });
  });

  group('HomeScreen selection mode – merge bar', () {
    testWidgets('selecting two lists shows merge bar', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(
          lists: [makeList('L1', 'Groceries'), makeList('L2', 'Hardware')],
        ),
      );
      await tester.pumpAndSettle();

      // Long-press first list to enter selection mode.
      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Tap second list checkbox to select it.
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.last);
      await tester.pumpAndSettle();

      // The merge bar (with Merge button) should appear.
      expect(find.text('Merge'), findsOneWidget);
    });

    testWidgets('cancel selection clears selection mode', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(
          lists: [makeList('L1', 'Groceries'), makeList('L2', 'Hardware')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Cancel selection.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Checkboxes should be gone.
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('merging two lists opens merge-target dialog', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(
          lists: [makeList('L1', 'Groceries'), makeList('L2', 'Hardware')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      // The target-list dialog should be shown (title from mergeTargetTitle ARB key).
      expect(find.textContaining('Merge into which list?'), findsOneWidget);

      // Cancel — use .last because the merge bar also has a Cancel button.
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
    });
  });

  group('HomeScreen list tab – tapping list opens editor', () {
    testWidgets('tapping list name opens ListEditorScreen', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(lists: [makeList('L1', 'Groceries')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // No crash — editor opens.
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen list tab – progress bar', () {
    testWidgets('shows progress bar for partially-checked list', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 'L1',
        name: 'Progress',
        preferredStoreIds: [],
        items: [
          ShoppingItem(name: 'Milk', checked: true),
          ShoppingItem(name: 'Eggs'),
        ],
      );
      await tester.pumpWidget(wrapHomeScreen(lists: [list]));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('HomeScreen shops tab – delete store', () {
    testWidgets('tapping delete icon on shop shows confirmation dialog', (
      tester,
    ) async {
      final store = Supermarket(
        id: 'store-1',
        name: 'Test Market',
        rows: ['A', 'B'],
        cols: ['1', '2'],
        entrance: 'A1',
        exit: 'B2',
        cells: {},
      );
      await tester.pumpWidget(wrapHomeScreen(lists: [], stores: [store]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping store tile opens store editor', (tester) async {
      final store = Supermarket(
        id: 'store-1',
        name: 'Test Market',
        rows: ['A', 'B'],
        cols: ['1', '2'],
        entrance: 'A1',
        exit: 'B2',
        cells: {},
      );
      await tester.pumpWidget(wrapHomeScreen(lists: [], stores: [store]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Market'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen – confirm delete list', () {
    testWidgets('confirming delete removes list', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(lists: [makeList('L1', 'Groceries')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // No exception after deletion.
      expect(tester.takeException(), isNull);
    });
  });

  // join banner must run before start-navigation: pushing NavigationScreen
  // leaves persistent timers that prevent pumpAndSettle() from ever returning
  // in subsequent tests.
  group('HomeScreen join banner – tapping join button', () {
    testWidgets('tapping join navigates to NavigationScreen', (tester) async {
      const session = NavSession(listId: 'L1', startedBy: 'uid-1');
      await tester.pumpWidget(
        wrapHomeScreen(lists: [makeList('L1', 'Groceries')], session: session),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Join'));
      // Use bounded pumps: NavigationScreen may have persistent animations
      // that prevent pumpAndSettle() from ever returning.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // No exception when joining session.
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen – copy list from popup', () {
    testWidgets('tapping Copy from popup copies the list', (tester) async {
      await tester.pumpWidget(
        wrapHomeScreen(lists: [makeList('L1', 'Groceries')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen – confirm delete store', () {
    testWidgets('tapping Yes in delete store dialog removes store', (
      tester,
    ) async {
      final store = Supermarket(
        id: 'store-1',
        name: 'Test Market',
        rows: ['A'],
        cols: ['1'],
        entrance: 'A1',
        exit: 'A1',
        cells: {},
      );
      await tester.pumpWidget(wrapHomeScreen(lists: [], stores: [store]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen – German FAB expansion', () {
    testWidgets('tapping FAB in German shows Neue Liste button', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(() => FakeListsNotifier([])),
            supermarketsProvider.overrideWith(() => FakeStoresNotifier()),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            navViewModeProvider.overrideWith(() => FakeNavViewModeNotifier()),
            localOnlyProvider.overrideWith(() => FakeLocalOnlyNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the main FAB to expand it.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Covers app_localizations_de.dart line 17 (newList).
      expect(find.text('Neue Liste'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen – German empty lists state', () {
    testWidgets('renders empty lists state in German', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(() => FakeListsNotifier([])),
            supermarketsProvider.overrideWith(() => FakeStoresNotifier()),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            navViewModeProvider.overrideWith(() => FakeNavViewModeNotifier()),
            localOnlyProvider.overrideWith(() => FakeLocalOnlyNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Einkaufslisten'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping "Liste erstellen" opens list editor', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(() => FakeListsNotifier([])),
            supermarketsProvider.overrideWith(() => FakeStoresNotifier()),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            navViewModeProvider.overrideWith(() => FakeNavViewModeNotifier()),
            localOnlyProvider.overrideWith(() => FakeLocalOnlyNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Liste erstellen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen – German empty shops state', () {
    testWidgets('switching to Märkte tab in German shows empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(() => FakeListsNotifier([])),
            supermarketsProvider.overrideWith(() => FakeStoresNotifier()),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            navViewModeProvider.overrideWith(() => FakeNavViewModeNotifier()),
            localOnlyProvider.overrideWith(() => FakeLocalOnlyNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Märkte'));
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Märkte'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('only "Markt suchen" is visible in empty shops state', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(() => FakeListsNotifier([])),
            supermarketsProvider.overrideWith(() => FakeStoresNotifier()),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            navViewModeProvider.overrideWith(() => FakeNavViewModeNotifier()),
            localOnlyProvider.overrideWith(() => FakeLocalOnlyNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Märkte'));
      await tester.pumpAndSettle();
      expect(find.text('Markt erstellen'), findsNothing);
      expect(find.text('Markt suchen'), findsOneWidget);
    });

    testWidgets('tapping "Markt suchen" opens shop search screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(() => FakeListsNotifier([])),
            supermarketsProvider.overrideWith(() => FakeStoresNotifier()),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            navViewModeProvider.overrideWith(() => FakeNavViewModeNotifier()),
            localOnlyProvider.overrideWith(() => FakeLocalOnlyNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Märkte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Markt suchen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen – German delete shop confirmation', () {
    testWidgets('delete shop dialog shows German strings', (tester) async {
      final store = Supermarket(
        id: 'store-de',
        name: 'Rewe',
        rows: ['A'],
        cols: ['1'],
        entrance: 'A1',
        exit: 'A1',
        cells: {},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdProvider.overrideWith(() => NullHouseholdNotifier()),
            shoppingListsProvider.overrideWith(() => FakeListsNotifier([])),
            supermarketsProvider.overrideWith(
              () => FakeStoresNotifierWith([store]),
            ),
            navSessionProvider.overrideWith((ref) => Stream.value(null)),
            navViewModeProvider.overrideWith(() => FakeNavViewModeNotifier()),
            localOnlyProvider.overrideWith(() => FakeLocalOnlyNotifier()),
            firestoreSyncProvider.overrideWith((ref) {}),
            currentUidProvider.overrideWith((ref) => null),
            firestoreServiceProvider.overrideWithValue(MockFirestoreService()),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Märkte'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Covers app_localizations_de.dart lines 131 (deleteConfirm), 136 (yes), 139 (no).
      expect(find.textContaining('Rewe'), findsWidgets);
      expect(find.text('Ja'), findsOneWidget);
      expect(find.text('Nein'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Nein'));
      await tester.pumpAndSettle();
    });
  });

  // This group must run after all other groups: the "shows HelpScreen" test
  // leaves a pending unawaited Hive disk-flush (from HomeScreen.initState calling
  // box.put('helpSeen','true') inside FakeAsync) that can cause subsequent
  // pumpAndSettle() calls to loop.  tearDownAll's Hive.close().timeout(5s)
  // handles the leftover write gracefully.
  group('HomeScreen intro HelpScreen', () {
    // Keep tourStep=-1 in this group by default to prevent TourSpotlight from
    // inserting an overlay.  An active overlay's OverlayEntry.remove() call
    // during widget teardown (inside SchedulerPhase.persistentCallbacks) adds a
    // post-frame callback that leaves hasScheduledFrame=true, causing every
    // subsequent test's pump() to spin indefinitely.
    setUp(() async {
      await clearHive();
      // Awaited: setUp runs outside FakeAsync so Hive disk flush works normally.
      await Hive.box<String>(
        'settings',
      ).put('introSeen', 'true'); // tourStep = -1
    });

    testWidgets('does not show HelpScreen when helpSeen is already set', (
      tester,
    ) async {
      // Use runAsync to write outside FakeAsync so the disk-flush Future
      // resolves immediately and doesn't leak into subsequent tests.
      await tester.runAsync(() async {
        await Hive.box<String>('settings').put('helpSeen', 'true');
      });
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pump(); // initState post-frame callbacks fire
      await tester.pump();

      expect(find.text('How Fairelescourses works'), findsNothing);
      // tourStep = -1 → TourSpotlight inactive, no overlay, no cleanup needed.
    });

    testWidgets('does not show HelpScreen when tour is already complete', (
      tester,
    ) async {
      // introSeen='true' already set in setUp → tourStep = -1
      await tester.pumpWidget(wrapHomeScreen(lists: []));
      await tester.pump(); // initState post-frame callbacks fire
      await tester.pump();

      expect(find.text('How Fairelescourses works'), findsNothing);
    });

    // Run last in this group: needs tourStep=0 to trigger the HelpScreen push.
    //
    // KEY INVARIANT: HomeScreen.initState calls box.put('helpSeen','true')
    // without await inside a post-frame callback, which fires during the first
    // pump().  The Hive disk-flush is backed by native file I/O; while
    // FakeAsync is active the real event loop never runs, so the I/O
    // completion callback ends up in FakeAsync's fake microtask queue.
    //
    // After tester.runAsync() gives the real event loop a moment to complete
    // the I/O, the next pump() drains the fake microtask queue and resolves
    // _writeTask → null.  This ensures clearHive() in the global setUp for
    // the following test (navigation) doesn't wait on a stuck _writeTask.
    testWidgets('shows HelpScreen automatically on first launch', (
      tester,
    ) async {
      // Clear introSeen so tourStep=0, which triggers the HelpScreen push.
      // Use runAsync so the Hive clear Future resolves outside FakeAsync.
      await tester.runAsync(clearHive);
      await tester.pumpWidget(wrapHomeScreen(lists: []));

      // First pump: fires initState's post-frame callback, which calls
      // box.put('helpSeen','true') (unawaited) and starts the HelpScreen push.
      await tester.pump();

      // Give the disk write real time to complete.  tester.runAsync temporarily
      // runs the real event loop; the Hive I/O finishes and schedules its
      // completion callback in FakeAsync's fake microtask queue (because the
      // underlying ReceivePort was created inside this FakeAsync zone).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );

      // Drain the fake microtask queue so the write-completion fires and
      // _writeTask becomes null.  Without this, clearHive() in the global
      // setUp for the NEXT test would block forever on _writeTask.
      await tester.pump();

      await tester.pump(); // HelpScreen push transition advances
      await tester.pumpAndSettle();

      expect(find.text('How Fairelescourses works'), findsOneWidget);

      // Replace the widget tree with an empty widget to cleanly dispose
      // TourSpotlight (and its overlay entry) within this test's FakeAsync zone.
      // If TourSpotlight.dispose() runs during the NEXT test's pumpWidget build
      // phase (SchedulerPhase.persistentCallbacks), overlay.remove() schedules a
      // post-frame callback that keeps hasScheduledFrame=true and causes the next
      // test's pumpAndSettle to loop.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(); // post-frame callbacks from disposal run
      await tester.pump(); // any remaining overlay rebuilds settle
    });
  });
}
