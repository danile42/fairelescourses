import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/tour_provider.dart';

const _steps = [
  (Icons.store_outlined, 'tourStep1Title', 'tourStep1Body'),
  (Icons.shopping_cart_outlined, 'tourStep2Title', 'tourStep2Body'),
  (Icons.play_arrow_outlined, 'tourStep3Title', 'tourStep3Body'),
];

class TourCard extends ConsumerWidget {
  const TourCard({super.key});

  String _title(AppLocalizations l, int step) => switch (step) {
    0 => l.tourStep1Title,
    1 => l.tourStep2Title,
    _ => l.tourStep3Title,
  };

  String _body(AppLocalizations l, int step) => switch (step) {
    0 => l.tourStep1Body,
    1 => l.tourStep2Body,
    _ => l.tourStep3Body,
  };

  IconData _icon(int step) => _steps[step.clamp(0, 2)].$1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(tourStepProvider);
    if (step < 0) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Step dots
                ...List.generate(_steps.length, (i) {
                  final active = i == step;
                  final done = i < step;
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
                  child: Text(l.tourSkip, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon(step),
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(l, step),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_body(l, step), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
