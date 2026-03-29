import 'dart:convert';

class FirebaseCredentials {
  final String projectId;
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String storageBucket;

  const FirebaseCredentials({
    required this.projectId,
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.storageBucket,
  });

  String toJson() => jsonEncode({
    'projectId': projectId,
    'apiKey': apiKey,
    'appId': appId,
    'messagingSenderId': messagingSenderId,
    'storageBucket': storageBucket,
  });

  factory FirebaseCredentials.fromJson(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return FirebaseCredentials(
      projectId: m['projectId'] as String,
      apiKey: m['apiKey'] as String,
      appId: m['appId'] as String,
      messagingSenderId: m['messagingSenderId'] as String,
      storageBucket: m['storageBucket'] as String,
    );
  }

  /// Parse credentials from the contents of a google-services.json file.
  static FirebaseCredentials? fromGoogleServicesJson(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final info = m['project_info'] as Map<String, dynamic>;
      final client = (m['client'] as List).first as Map<String, dynamic>;
      final clientInfo = client['client_info'] as Map<String, dynamic>;
      final apiKey =
          ((client['api_key'] as List).first
                  as Map<String, dynamic>)['current_key']
              as String;
      return FirebaseCredentials(
        projectId: info['project_id'] as String,
        apiKey: apiKey,
        appId: clientInfo['mobilesdk_app_id'] as String,
        messagingSenderId: info['project_number'] as String,
        storageBucket: info['storage_bucket'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
