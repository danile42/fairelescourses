import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'hive_registrar.g.dart';

import 'models/supermarket.dart';
import 'models/shopping_list.dart';
import 'providers/firebase_app_provider.dart';
import 'providers/seed_color_provider.dart';
import 'providers/tour_provider.dart';
import 'screens/home_screen.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  Hive.registerAdapters();

  await Hive.openBox<Supermarket>('supermarkets');
  await Hive.openBox<ShoppingList>('shopping_lists');
  await Hive.openBox<String>('settings');
  await Hive.openBox<String>('item_categories');

  // Sign in anonymously on whichever Firebase app is configured
  // (initializes the custom named app if credentials are saved in Hive).
  // Skipped when local-only mode is active.
  final localOnly = Hive.box<String>('settings').get('localOnly') == 'true';
  if (!localOnly) {
    await initActiveFirebaseApp();
  } else {
    // Re-initialize default Firebase app for the session (it may have been deleted)
    // and sign in anonymously.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const ProviderScope(child: FairelesCourses()));
}

class FairelesCourses extends ConsumerWidget {
  const FairelesCourses({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedColor = ref.watch(seedColorProvider);
    return MaterialApp(
      title: 'Fairelescourses',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('de')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      ),
      navigatorObservers: [tourRouteObserver],
      home: const HomeScreen(),
    );
  }
}
