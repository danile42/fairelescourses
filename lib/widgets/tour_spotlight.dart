import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/tour_provider.dart';

/// Applied to the main FAB so the spotlight can locate it.
final tourFabKey = GlobalKey(debugLabel: 'tourFab');

/// Applied to the "New shop" mini button when the FAB is expanded.
final tourNewShopKey = GlobalKey(debugLabel: 'tourNewShop');

/// Applied to the "New list" mini button when the FAB is expanded.
final tourNewListKey = GlobalKey(debugLabel: 'tourNewList');

/// Applied to the play button of the first list card.
final tourPlayKey = GlobalKey(debugLabel: 'tourPlay');

/// Invisible widget that manages a full-screen spotlight overlay.
/// Drop it anywhere inside the widget tree of a screen that has an [Overlay]
/// ancestor (i.e. inside a [MaterialApp]).
class TourSpotlight extends ConsumerStatefulWidget {
  const TourSpotlight({super.key});

  @override
  ConsumerState<TourSpotlight> createState() => _TourSpotlightState();
}

class _TourSpotlightState extends ConsumerState<TourSpotlight> with RouteAware {
  OverlayEntry? _entry;
  Rect? _targetRect;
  int _step = -1;
  bool _routeIsCurrent = true;
  ProviderSubscription<int>? _stepSub;
  ProviderSubscription<bool>? _fabSub;

  GlobalKey get _targetKey {
    if (_step == 2) return tourPlayKey;
    final expanded = ref.read(tourFabExpandedProvider);
    if (expanded) return _step == 0 ? tourNewShopKey : tourNewListKey;
    return tourFabKey;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _step = ref.read(tourStepProvider);
      _stepSub = ref.listenManual(tourStepProvider, (_, next) {
        _step = next;
        if (next < 0) {
          _removeEntry();
        } else {
          _scheduleRead();
        }
      });
      _fabSub = ref.listenManual(tourFabExpandedProvider, (prev, next) {
        if (_step >= 0 && _step < 2) _scheduleRead();
      });
      if (_step >= 0) _scheduleRead();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) tourRouteObserver.subscribe(this, route);
  }

  /// A new screen was pushed on top — hide the overlay without losing state.
  @override
  void didPushNext() {
    _routeIsCurrent = false;
    _entry?.remove();
    _entry = null;
  }

  /// Returned to this screen — restore the overlay.
  @override
  void didPopNext() {
    _routeIsCurrent = true;
    if (_step >= 0) _scheduleRead();
  }

  @override
  void dispose() {
    tourRouteObserver.unsubscribe(this);
    _stepSub?.close();
    _fabSub?.close();
    _removeEntry();
    super.dispose();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
    _targetRect = null;
  }

  void _scheduleRead({int retries = 15}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        if (retries > 0) _scheduleRead(retries: retries - 1);
        return;
      }
      _targetRect = box.localToGlobal(Offset.zero) & box.size;
      if (!_routeIsCurrent) return;
      if (_entry == null) {
        _entry = OverlayEntry(builder: _buildOverlay);
        Overlay.of(context).insert(_entry!);
      } else {
        _entry!.markNeedsBuild();
      }
    });
  }

  Widget _buildOverlay(BuildContext overlayCtx) {
    final rect = _targetRect;
    if (rect == null || _step < 0) return const SizedBox.shrink();

    final l = AppLocalizations.of(overlayCtx)!;
    final theme = Theme.of(overlayCtx);
    final mq = MediaQuery.of(overlayCtx);
    final screen = mq.size;

    final spotRadius = math.max(rect.width, rect.height) / 2 + 20;
    final spotCenter = rect.center;

    final aboveY = spotCenter.dy - spotRadius - 12;
    final belowY = spotCenter.dy + spotRadius + 12;
    final showAbove = aboveY > 180;
    final calloutTop = showAbove ? aboveY - 150 : belowY;

    final title = switch (_step) {
      0 => l.tourStep1Title,
      1 => l.tourStep2Title,
      _ => l.tourStep3Title,
    };
    final body = switch (_step) {
      0 => l.tourStep1Body,
      1 => l.tourStep2Body,
      _ => l.tourStep3Body,
    };

    return Stack(
      children: [
        // Dark scrim with circular cutout — pointer events pass through.
        IgnorePointer(
          child: SizedBox.fromSize(
            size: screen,
            child: CustomPaint(
              painter: _SpotlightPainter(
                center: spotCenter,
                radius: spotRadius,
              ),
            ),
          ),
        ),
        // Callout card — fully interactive.
        Positioned(
          left: 16,
          right: 16,
          top: calloutTop.clamp(mq.padding.top + 8, screen.height - 200),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(3, (i) {
                        final active = i == _step;
                        final done = i < _step;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: active ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: done || active
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            ref.read(tourStepProvider.notifier).complete(),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: theme.colorScheme.outline,
                        ),
                        child: Text(
                          l.tourSkip,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final double radius;

  const _SpotlightPainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.center != center || old.radius != radius;
}
