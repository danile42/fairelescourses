import 'package:flutter/material.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.helpTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              icon: Icons.store_outlined,
              title: l.helpShopsTitle,
              body: l.helpShopsBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.shopping_cart_outlined,
              title: l.helpListsTitle,
              body: l.helpListsBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.navigation_outlined,
              title: l.helpNavTitle,
              body: l.helpNavBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.group_outlined,
              title: l.helpSyncTitle,
              body: l.helpSyncBody,
              theme: theme,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(l.helpDataTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _DataRow(
              icon: Icons.phone_android,
              text: l.helpDataLocal,
              color: theme.colorScheme.primary,
              theme: theme,
            ),
            const SizedBox(height: 8),
            _DataRow(
              icon: Icons.cloud_outlined,
              text: l.helpDataCloud,
              color: theme.colorScheme.tertiary,
              theme: theme,
            ),
            const SizedBox(height: 8),
            _DataRow(
              icon: Icons.lock_outlined,
              text: l.helpDataLocalOnly,
              color: theme.colorScheme.secondary,
              theme: theme,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.helpClose),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final ThemeData theme;

  const _Section({
    required this.icon,
    required this.title,
    required this.body,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: theme.colorScheme.onPrimaryContainer, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final ThemeData theme;

  const _DataRow({
    required this.icon,
    required this.text,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
