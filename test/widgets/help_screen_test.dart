import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/screens/help_screen.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

Widget _app(Widget screen, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: screen,
);

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, (call) async {
          if (call.method == 'launch' || call.method == 'launchUrl') {
            return true;
          }
          if (call.method == 'canLaunch' || call.method == 'canLaunchUrl') {
            return true;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, null);
  });

  group('HelpScreen', () {
    testWidgets('renders in English without error', (tester) async {
      await tester.pumpWidget(_app(const HelpScreen()));
      await tester.pumpAndSettle();
      expect(find.text('How Fairelescourses works'), findsOneWidget);
      // Single scrollable screen — shows all sections and a Get started button.
      expect(find.text('Shops'), findsWidgets);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('renders in German without error', (tester) async {
      await tester.pumpWidget(
        _app(const HelpScreen(), locale: const Locale('de')),
      );
      await tester.pumpAndSettle();
      expect(find.text('So funktioniert Fairelescourses'), findsOneWidget);
      // German close button.
      expect(find.text("Los geht's"), findsOneWidget);
    });

    testWidgets('Get started button pops the screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(
                  ctx,
                ).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Single-screen — scroll to the Get started button and tap it.
      await tester.ensureVisible(find.text('Get started'));
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('GitHub link button can be tapped without exception', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const HelpScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Learn more on GitHub'));
      await tester.tap(find.text('Learn more on GitHub'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ShopEditorHelpScreen', () {
    testWidgets('renders all sections in English', (tester) async {
      await tester.pumpWidget(_app(const ShopEditorHelpScreen()));
      await tester.pumpAndSettle();
      expect(find.text('How the shop editor works'), findsOneWidget);
      expect(find.text('The grid'), findsOneWidget);
      expect(find.text('Assigning goods'), findsOneWidget);
      expect(find.text('Entrance & exit'), findsOneWidget);
      expect(find.text('Multiple floors'), findsOneWidget);
      expect(find.text('Splitting cells'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('renders in German without error', (tester) async {
      await tester.pumpWidget(
        _app(const ShopEditorHelpScreen(), locale: const Locale('de')),
      );
      await tester.pumpAndSettle();
      expect(find.text('So funktioniert der Markt-Editor'), findsOneWidget);
      expect(find.text('Verstanden'), findsOneWidget);
    });

    testWidgets('grid body mentions coarse grid and splits', (tester) async {
      await tester.pumpWidget(_app(const ShopEditorHelpScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('coarse grid'), findsOneWidget);
    });

    testWidgets('Got it button dismisses the screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => const ShopEditorHelpScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Got it'));
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('FirebaseHelpScreen', () {
    testWidgets('renders all steps in English', (tester) async {
      await tester.pumpWidget(_app(const FirebaseHelpScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Custom Firebase setup'), findsOneWidget);
      expect(find.text('1. Create a Firebase project'), findsOneWidget);
      expect(find.text('2. Enable Firestore'), findsOneWidget);
      expect(find.text('3. Enable Anonymous Auth'), findsOneWidget);
      expect(find.text('4. Security rules'), findsOneWidget);
      expect(find.text('5. Your credentials'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('renders in German without error', (tester) async {
      await tester.pumpWidget(
        _app(const FirebaseHelpScreen(), locale: const Locale('de')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Eigene Firebase-Einrichtung'), findsOneWidget);
      expect(find.text('Verstanden'), findsOneWidget);
    });
  });
}
