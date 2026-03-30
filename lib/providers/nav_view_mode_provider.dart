import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _navViewModeKey = 'navViewMode';

/// Stores the preferred navigation view mode.
/// `true` means the user prefers the list view; `false` means grid view.
final navViewModeProvider = NotifierProvider<NavViewModeNotifier, bool>(
  NavViewModeNotifier.new,
);

class NavViewModeNotifier extends Notifier<bool> {
  @override
  bool build() => Hive.box<String>('settings').get(_navViewModeKey) == 'list';

  Future<void> set(bool preferList) async {
    await Hive.box<String>(
      'settings',
    ).put(_navViewModeKey, preferList ? 'list' : 'grid');
    state = preferList;
  }
}
