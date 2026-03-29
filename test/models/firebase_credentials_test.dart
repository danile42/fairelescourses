import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:fairelescourses/models/firebase_credentials.dart';

void main() {
  const creds = FirebaseCredentials(
    projectId: 'my-project',
    apiKey: 'AIzaXXX',
    appId: '1:123:android:abc',
    messagingSenderId: '123456',
    storageBucket: 'my-project.appspot.com',
  );

  group('FirebaseCredentials toJson / fromJson', () {
    test('round-trips through JSON', () {
      final json = creds.toJson();
      final decoded = FirebaseCredentials.fromJson(json);
      expect(decoded.projectId, creds.projectId);
      expect(decoded.apiKey, creds.apiKey);
      expect(decoded.appId, creds.appId);
      expect(decoded.messagingSenderId, creds.messagingSenderId);
      expect(decoded.storageBucket, creds.storageBucket);
    });

    test('toJson produces valid JSON object', () {
      final map = jsonDecode(creds.toJson()) as Map<String, dynamic>;
      expect(map['projectId'], 'my-project');
      expect(map['apiKey'], 'AIzaXXX');
      expect(map['appId'], '1:123:android:abc');
      expect(map['messagingSenderId'], '123456');
      expect(map['storageBucket'], 'my-project.appspot.com');
    });
  });

  group('FirebaseCredentials.fromGoogleServicesJson', () {
    String makeGsJson({
      String projectId = 'gs-project',
      String projectNumber = '999',
      String storageBucket = 'gs-project.appspot.com',
      String appId = '1:999:android:fff',
      String apiKey = 'AIzaGS',
    }) => jsonEncode({
      'project_info': {
        'project_id': projectId,
        'project_number': projectNumber,
        'storage_bucket': storageBucket,
      },
      'client': [
        {
          'client_info': {'mobilesdk_app_id': appId},
          'api_key': [
            {'current_key': apiKey},
          ],
        },
      ],
    });

    test('parses a valid google-services.json', () {
      final result = FirebaseCredentials.fromGoogleServicesJson(makeGsJson());
      expect(result, isNotNull);
      expect(result!.projectId, 'gs-project');
      expect(result.messagingSenderId, '999');
      expect(result.storageBucket, 'gs-project.appspot.com');
      expect(result.appId, '1:999:android:fff');
      expect(result.apiKey, 'AIzaGS');
    });

    test('returns null for empty string', () {
      expect(FirebaseCredentials.fromGoogleServicesJson(''), isNull);
    });

    test('returns null for invalid JSON', () {
      expect(FirebaseCredentials.fromGoogleServicesJson('not json'), isNull);
    });

    test('returns null for JSON missing required keys', () {
      expect(
        FirebaseCredentials.fromGoogleServicesJson(jsonEncode({'foo': 'bar'})),
        isNull,
      );
    });
  });
}
