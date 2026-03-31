import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

const _settingsBox = 'settings';
const _householdKey = 'householdId';

final householdProvider = NotifierProvider<HouseholdNotifier, String?>(
  HouseholdNotifier.new,
);

class HouseholdNotifier extends Notifier<String?> {
  @override
  String? build() => Hive.box<String>(_settingsBox).get(_householdKey);

  Box<String> get _box => Hive.box<String>(_settingsBox);

  Future<void> setId(String id) async {
    final normalized = id.trim().toUpperCase();
    await _box.put(_householdKey, normalized);
    state = normalized;
  }

  Future<void> clear() async {
    await _box.delete(_householdKey);
    state = null;
  }

  static String generateId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
