// THIS FILE IS A PLACEHOLDER.
// Replace it by running: flutterfire configure
// See setup instructions below.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('No Firebase options for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwipHghjjx5jfru6nf6PAMf255YpAwCw0',
    appId: '1:1089873679581:android:9f9becc58003bbdd133734',
    messagingSenderId: '1089873679581',
    projectId: 'fairelescourses-app',
    storageBucket: 'fairelescourses-app.firebasestorage.app',
  );

  // TODO: Replace with values from your google-services.json after running `flutterfire configure`
}
