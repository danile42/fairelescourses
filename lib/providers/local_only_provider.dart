import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _localOnlyKey = 'localOnly';

final localOnlyProvider =
    NotifierProvider<LocalOnlyNotifier, bool>(LocalOnlyNotifier.new);

class LocalOnlyNotifier extends Notifier<bool> {
  @override
  bool build() =>
      Hive.box<String>('settings').get(_localOnlyKey) == 'true';

  Future<void> set(bool value) async {
    await Hive.box<String>('settings').put(_localOnlyKey, value ? 'true' : 'false');
    state = value;
  }
}
