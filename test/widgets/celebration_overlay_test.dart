import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:fairelescourses/providers/tour_provider.dart';
import 'package:fairelescourses/widgets/celebration_overlay.dart';

import '../helpers/hive_helper.dart';

Widget _wrap() => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: CelebrationOverlay()),
  ),
);

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

  group('CelebrationOverlay – initial state', () {
    testWidgets('renders as shrunk box when no celebration triggered', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // CelebrationOverlay builds as SizedBox.shrink()
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CelebrationOverlay – triggered', () {
    testWidgets('celebration shows confetti overlay after trigger', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Trigger the celebration via the provider.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CelebrationOverlay)),
      );
      container.read(celebrationTriggerProvider.notifier).trigger();

      // Advance past the post-frame callback.
      await tester.pump();
      await tester.pump();

      // Advance partway through the animation (card visible at ~18% of 3800ms).
      await tester.pump(const Duration(milliseconds: 400));

      // Celebration card is shown with the "You're all set!" message.
      expect(find.textContaining("You're all set!"), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Fast-forward past the 3.8 s animation to let it complete cleanly.
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('overlay entry is inserted into Overlay after trigger', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CelebrationOverlay)),
      );
      container.read(celebrationTriggerProvider.notifier).trigger();
      await tester.pump(); // post-frame callback
      await tester.pump(); // listenManual fires

      // Celebration entry is now in the overlay.
      expect(find.byType(IgnorePointer), findsWidgets);

      // Complete the animation.
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('CelebrationOverlay – German locale', () {
    testWidgets('shows German celebration text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: CelebrationOverlay()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CelebrationOverlay)),
      );
      container.read(celebrationTriggerProvider.notifier).trigger();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Alles bereit!'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 4));
    });
  });
}
