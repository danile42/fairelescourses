import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

const _seedColorKey = 'seedColor';
const defaultSeedColor = Color(0xFF2E7D32);

final seedColorProvider = NotifierProvider<SeedColorNotifier, Color>(
  SeedColorNotifier.new,
);

class SeedColorNotifier extends Notifier<Color> {
  @override
  Color build() {
    final hex = Hive.box<String>('settings').get(_seedColorKey);
    if (hex == null) return defaultSeedColor;
    return Color(int.parse(hex));
  }

  Future<void> set(Color color) async {
    await Hive.box<String>('settings').put(_seedColorKey, '${color.value}');
    state = color;
  }

  Future<void> reset() async {
    await Hive.box<String>('settings').delete(_seedColorKey);
    state = defaultSeedColor;
  }
}
