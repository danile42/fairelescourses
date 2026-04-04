import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/tour_provider.dart';

/// A slim banner shown at the bottom of editor screens during the tour.
/// [visibleOnStep] is the step index during which this banner appears.
class TourHintBanner extends ConsumerWidget {
  final int visibleOnStep;
  final String Function(AppLocalizations) message;

  const TourHintBanner({
    super.key,
    required this.visibleOnStep,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(tourStepProvider);
    if (step != visibleOnStep) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        color: theme.colorScheme.primaryContainer,
        child: Row(
          children: [
            Icon(
              Icons.school_outlined,
              size: 18,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message(l),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(tourStepProvider.notifier).complete(),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
              child: Text(l.tourSkip, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
