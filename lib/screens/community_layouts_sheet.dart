import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/community_layout.dart';
import '../providers/firestore_sync_provider.dart';

/// A modal bottom sheet that lists community-contributed cell-layout versions
/// for a shop identified by [osmId].
///
/// Returns the selected [CommunityLayout] via [Navigator.pop], or null if the
/// user dismisses without choosing one.
///
/// Callers are responsible for incrementing the import count and applying the
/// template to the editor after the sheet closes.
class CommunityLayoutsSheet extends ConsumerStatefulWidget {
  final int osmId;

  /// Called when the user taps the "Create" button in the empty state.
  /// The sheet pops itself before invoking this callback.
  final VoidCallback? onCreateTap;

  const CommunityLayoutsSheet({
    super.key,
    required this.osmId,
    this.onCreateTap,
  });

  @override
  ConsumerState<CommunityLayoutsSheet> createState() =>
      _CommunityLayoutsSheetState();
}

class _CommunityLayoutsSheetState extends ConsumerState<CommunityLayoutsSheet> {
  late Future<List<CommunityLayout>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = ref
          .read(firestoreServiceProvider)
          .listLayoutVersions(widget.osmId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // ── Handle + header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.communityLayoutsTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Body ───────────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<CommunityLayout>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.communityLayoutsError),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(l.communityLayoutsRetry),
                        ),
                      ],
                    ),
                  );
                }
                final layouts = snap.data!;
                if (layouts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.communityLayoutsEmpty,
                            textAlign: TextAlign.center,
                          ),
                          if (widget.onCreateTap != null) ...[
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onCreateTap!();
                              },
                              child: Text(l.createShop),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: layouts.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 4),
                  itemBuilder: (context, i) => _LayoutCard(layout: layouts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutCard extends StatelessWidget {
  final CommunityLayout layout;
  const _LayoutCard({required this.layout});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = layout.asTemplate;
    final floors = t.additionalFloors.length + 1;

    String age() {
      final pub = layout.publishedAt;
      if (pub == null) return '';
      final days = DateTime.now().difference(pub).inDays;
      return l.communityLayoutAge(days);
    }

    final subtitleParts = [
      l.communityLayoutGrid(t.rows.length, t.cols.length),
      if (floors > 1) l.nFloors(floors),
      if (layout.publishedAt != null) age(),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitleParts.join('  ·  '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.communityLayoutImports(layout.importCount),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, layout),
              child: Text(l.communityLayoutUse),
            ),
          ],
        ),
      ),
    );
  }
}
