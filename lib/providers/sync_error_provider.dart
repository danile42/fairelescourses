import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the most recent Firestore sync error message, or null when there is none.
/// Providers report errors here; the UI watches this and shows a snackbar.
final syncErrorProvider = NotifierProvider<SyncErrorNotifier, String?>(
  SyncErrorNotifier.new,
);

class SyncErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void report(String message) => state = message;
  void clear() => state = null;
}
