import 'package:flutter/material.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int total) {
    if (_page < total - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final pages = [
      _TourPage(
        icon: Icons.store_outlined,
        title: l.helpShopsTitle,
        body: l.helpShopsBody,
        theme: theme,
      ),
      _TourPage(
        icon: Icons.shopping_cart_outlined,
        title: l.helpListsTitle,
        body: l.helpListsBody,
        theme: theme,
      ),
      _TourPage(
        icon: Icons.play_arrow_outlined,
        title: l.helpNavTitle,
        body: l.helpNavBody,
        theme: theme,
      ),
      _TourPage(
        icon: Icons.sync,
        title: l.helpSyncTitle,
        body: l.helpSyncBody,
        theme: theme,
        extra: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              l.helpDataTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
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
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.helpTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(pages.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: active
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    );
                  }),
                ),
                FilledButton(
                  onPressed: () => _next(pages.length),
                  child: Text(
                    _page < pages.length - 1 ? l.tourNext : l.helpClose,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TourPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final ThemeData theme;
  final Widget? extra;

  const _TourPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.theme,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (extra != null) extra!,
        ],
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
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shop editor help screen
// ─────────────────────────────────────────────────────────────────────────────

class ShopEditorHelpScreen extends StatelessWidget {
  const ShopEditorHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.shopEditorHelpTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              icon: Icons.grid_on_outlined,
              title: l.shopEditorHelpGridTitle,
              body: l.shopEditorHelpGridBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.label_outlined,
              title: l.shopEditorHelpGoodsTitle,
              body: l.shopEditorHelpGoodsBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.login,
              title: l.shopEditorHelpEntranceTitle,
              body: l.shopEditorHelpEntranceBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.layers_outlined,
              title: l.shopEditorHelpFloorsTitle,
              body: l.shopEditorHelpFloorsBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.call_split,
              title: l.shopEditorHelpSplitTitle,
              body: l.shopEditorHelpSplitBody,
              theme: theme,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.shopEditorHelpClose),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Firebase help screen
// ─────────────────────────────────────────────────────────────────────────────

class FirebaseHelpScreen extends StatelessWidget {
  const FirebaseHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.firebaseHelpTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              icon: Icons.add_circle_outline,
              title: l.firebaseHelpProjectTitle,
              body: l.firebaseHelpProjectBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.storage_outlined,
              title: l.firebaseHelpFirestoreTitle,
              body: l.firebaseHelpFirestoreBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.person_outlined,
              title: l.firebaseHelpAuthTitle,
              body: l.firebaseHelpAuthBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.shield_outlined,
              title: l.firebaseHelpRulesTitle,
              body: l.firebaseHelpRulesBody,
              theme: theme,
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.key_outlined,
              title: l.firebaseHelpCredsTitle,
              body: l.firebaseHelpCredsBody,
              theme: theme,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.firebaseHelpClose),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
