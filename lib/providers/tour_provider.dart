import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

const tourIntroKey = 'introSeen';

/// Current interactive tour step.
/// -1 = inactive (tour completed or skipped).
///  0 = step 1: create a store.
///  1 = step 2: create a shopping list.
///  2 = step 3: start navigation.
final tourStepProvider = NotifierProvider<TourStepNotifier, int>(
  TourStepNotifier.new,
);

class TourStepNotifier extends Notifier<int> {
  @override
  int build() {
    final seen = Hive.box<String>('settings').get(tourIntroKey) == 'true';
    return seen ? -1 : 0;
  }

  void advance(int fromStep) {
    if (state == fromStep) state = fromStep + 1;
  }

  void complete() {
    Hive.box<String>('settings').put(tourIntroKey, 'true');
    state = -1;
  }
}
