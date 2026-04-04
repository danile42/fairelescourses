import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

const tourIntroKey = 'introSeen';

/// Passed to [MaterialApp.navigatorObservers] so [TourSpotlight] can
/// hide/show itself when other screens are pushed on top of HomeScreen.
final tourRouteObserver = RouteObserver<ModalRoute<void>>();

/// Current interactive tour step.
/// -1 = inactive (tour completed or skipped).
///  0 = step 1: create a store.
///  1 = step 2: create a shopping list.
///  2 = step 3: start navigation.
final tourStepProvider = NotifierProvider<TourStepNotifier, int>(
  TourStepNotifier.new,
);

/// Incremented each time the celebration should fire.
/// [CelebrationOverlay] watches for changes and starts the animation.
final celebrationTriggerProvider = NotifierProvider<_CelebrationTrigger, int>(
  _CelebrationTrigger.new,
);

class _CelebrationTrigger extends Notifier<int> {
  @override
  int build() => 0;
  void trigger() => state++;
}

/// Tracks whether the FAB is currently expanded (showing its mini buttons).
/// Updated by _HomeFabState so the spotlight can follow the expanded buttons.
final tourFabExpandedProvider = NotifierProvider<TourFabExpandedNotifier, bool>(
  TourFabExpandedNotifier.new,
);

class TourFabExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

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
