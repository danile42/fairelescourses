import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'models/supermarket.dart';
import 'models/shopping_list.dart';
import 'screens/home_screen.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.signInAnonymously();

  await Hive.initFlutter();
  Hive.registerAdapter(SupermarketAdapter());
  Hive.registerAdapter(ShoppingItemAdapter());
  Hive.registerAdapter(ShoppingListAdapter());

  await Hive.openBox<Supermarket>('supermarkets');
  await Hive.openBox<ShoppingList>('shopping_lists');
  await Hive.openBox<String>('settings');

  runApp(const ProviderScope(child: FairelesCourses()));
}

class FairelesCourses extends StatelessWidget {
  const FairelesCourses({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fairelescourses',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
