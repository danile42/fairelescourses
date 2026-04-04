import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/tour_provider.dart';

/// Drop this anywhere in the widget tree (alongside [TourSpotlight]).
/// It shows a confetti burst over the whole screen when the tour completes.
class CelebrationOverlay extends ConsumerStatefulWidget {
  const CelebrationOverlay({super.key});

  @override
  ConsumerState<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends ConsumerState<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  AnimationController? _controller;
  ProviderSubscription<int>? _sub;

  static const _duration = Duration(milliseconds: 3800);

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFFFF8F00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFE91E63),
    Color(0xFF00ACC1),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sub = ref.listenManual(tourStepProvider, (prev, next) {
        if (next == -1 && prev != null && prev >= 0) _startCelebration();
      });
    });
  }

  void _startCelebration() {
    _controller?.dispose();
    _controller = AnimationController(vsync: this, duration: _duration);

    final rng = math.Random();
    final particles = List.generate(72, (_) => _Particle.random(rng, _colors));

    _entry?.remove();
    _entry = OverlayEntry(
      builder: (ctx) =>
          _CelebrationWidget(animation: _controller!, particles: particles),
    );
    Overlay.of(context).insert(_entry!);

    _controller!.forward().whenComplete(() {
      _entry?.remove();
      _entry = null;
    });
  }

  @override
  void dispose() {
    _sub?.close();
    _controller?.dispose();
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Particle data ─────────────────────────────────────────────────────────────

class _Particle {
  final double x; // normalised start x (0..1)
  final double delay; // fraction before appearing (0..0.35)
  final double speed; // fall speed multiplier (0.6..1.5)
  final double drift; // total horizontal shift in px (-70..70)
  final double wobble; // sine-wave amplitude in px (0..18)
  final double wobbleFreq; // sine cycles during fall (1..3)
  final Color color;
  final double size; // half-size in px (3..7)
  final double rotation0; // initial angle
  final double rotations; // total rotations (-3..3)
  final bool isCircle;

  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.wobble,
    required this.wobbleFreq,
    required this.color,
    required this.size,
    required this.rotation0,
    required this.rotations,
    required this.isCircle,
  });

  factory _Particle.random(math.Random rng, List<Color> colors) => _Particle(
    x: rng.nextDouble(),
    delay: rng.nextDouble() * 0.35,
    speed: 0.6 + rng.nextDouble() * 0.9,
    drift: (rng.nextDouble() - 0.5) * 140,
    wobble: rng.nextDouble() * 18,
    wobbleFreq: 1 + rng.nextDouble() * 2,
    color: colors[rng.nextInt(colors.length)],
    size: 3 + rng.nextDouble() * 4,
    rotation0: rng.nextDouble() * math.pi * 2,
    rotations: (rng.nextDouble() - 0.5) * 6,
    isCircle: rng.nextBool(),
  );
}

// ── Overlay widget ────────────────────────────────────────────────────────────

class _CelebrationWidget extends StatelessWidget {
  final Animation<double> animation;
  final List<_Particle> particles;

  const _CelebrationWidget({required this.animation, required this.particles});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (ctx, _) {
          final t = animation.value;

          // Global fade-out over the last 18 % of the animation.
          final globalAlpha = t > 0.82 ? 1.0 - (t - 0.82) / 0.18 : 1.0;

          // Card: elastic scale-in (0→0.18), hold (0.18→0.68), fade-out (0.68→0.88).
          final cardProgress = t < 0.18
              ? t / 0.18
              : t > 0.68
              ? math.max(0.0, 1.0 - (t - 0.68) / 0.20)
              : 1.0;
          final cardScale = t < 0.18
              ? Curves.elasticOut.transform(t / 0.18)
              : 1.0;
          final cardAlpha = (cardProgress * globalAlpha).clamp(0.0, 1.0);

          return Stack(
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: _ConfettiPainter(
                    t: t,
                    particles: particles,
                    globalAlpha: globalAlpha,
                    screenSize: size,
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, -0.25),
                  child: Opacity(
                    opacity: cardAlpha,
                    child: Transform.scale(
                      scale: cardScale,
                      child: Material(
                        elevation: 10,
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 22,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l.celebrationTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l.celebrationBody,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<_Particle> particles;
  final double globalAlpha;
  final Size screenSize;

  const _ConfettiPainter({
    required this.t,
    required this.particles,
    required this.globalAlpha,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final w = size.width;
    final h = size.height + 80.0;

    for (final p in particles) {
      if (t < p.delay) continue;

      // Effective local progress for this particle (accounts for stagger & speed).
      final pt = math.min(1.0, (t - p.delay) / (1.0 - p.delay) * p.speed);

      final px =
          p.x * w +
          p.drift * pt +
          math.sin(pt * p.wobbleFreq * math.pi * 2) * p.wobble;
      final py = pt * h - 40.0;

      if (py < -p.size * 2 || py > size.height + p.size * 2) continue;

      final rotation = p.rotation0 + pt * p.rotations * math.pi * 2;

      paint.color = p.color.withAlpha(
        (globalAlpha * 255).round().clamp(0, 255),
      );

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotation);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 2,
            height: p.size * 1.2,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.t != t || old.globalAlpha != globalAlpha;
}
