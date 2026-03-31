import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/firebase_credentials.dart';

const _customAppName = 'custom';
const _credsKey = 'firebase_custom_credentials';

class FirebaseAppNotifier extends Notifier<FirebaseApp> {
  @override
  FirebaseApp build() {
    // If a custom app was initialized in main(), use it.
    final creds = loadSavedFirebaseCredentials();
    if (creds != null) {
      try {
        return Firebase.app(_customAppName);
      } catch (_) {}
    }
    return Firebase.app();
  }

  void setApp(FirebaseApp app) => state = app;
}

/// The active Firebase app — default (built-in) or a user-supplied custom one.
final firebaseAppProvider = NotifierProvider<FirebaseAppNotifier, FirebaseApp>(
  FirebaseAppNotifier.new,
);

/// Call from main() after Hive is open and the default Firebase app is initialized.
/// Signs in anonymously on whichever app will be used for sync.
Future<void> initActiveFirebaseApp() async {
  final creds = loadSavedFirebaseCredentials();
  if (creds == null) {
    await FirebaseAuth.instance.signInAnonymously();
    return;
  }
  final app = await _initNamedApp(creds);
  await FirebaseAuth.instanceFor(app: app).signInAnonymously();
}

/// Persist new credentials and switch the active app.
Future<void> applyCustomFirebaseCredentials(
  FirebaseCredentials creds,
  FirebaseAppNotifier notifier,
) async {
  final box = Hive.box<String>('settings');
  await box.put(_credsKey, creds.toJson());
  final app = await _initNamedApp(creds);
  await FirebaseAuth.instanceFor(app: app).signInAnonymously();
  notifier.setApp(app);
}

/// Remove custom credentials and revert to the default app.
Future<void> clearCustomFirebaseCredentials(
  FirebaseAppNotifier notifier,
) async {
  final box = Hive.box<String>('settings');
  await box.delete(_credsKey);
  try {
    await Firebase.app(_customAppName).delete();
  } catch (_) {}
  notifier.setApp(Firebase.app());
}

/// Returns the saved custom credentials, or null if using the default instance.
FirebaseCredentials? loadSavedFirebaseCredentials() {
  final box = Hive.box<String>('settings');
  final saved = box.get(_credsKey);
  if (saved == null) return null;
  try {
    return FirebaseCredentials.fromJson(saved);
  } catch (_) {
    return null;
  }
}

Future<FirebaseApp> _initNamedApp(FirebaseCredentials creds) async {
  try {
    await Firebase.app(_customAppName).delete();
  } catch (_) {}
  return Firebase.initializeApp(
    name: _customAppName,
    options: FirebaseOptions(
      apiKey: creds.apiKey,
      appId: creds.appId,
      messagingSenderId: creds.messagingSenderId,
      projectId: creds.projectId,
      storageBucket: creds.storageBucket,
    ),
  );
}
