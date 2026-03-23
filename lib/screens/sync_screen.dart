import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

import '../providers/home_location_provider.dart';
import '../providers/household_provider.dart';
import '../providers/supermarket_provider.dart';
import '../providers/shopping_list_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/nominatim_service.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _joinCtrl = TextEditingController();
  final _homeCtrl = TextEditingController();
  bool _joining = false;
  bool _settingHome = false;

  @override
  void dispose() {
    _joinCtrl.dispose();
    _homeCtrl.dispose();
    super.dispose();
  }

  Future<void> _setHomeLocation() async {
    final l = AppLocalizations.of(context)!;
    final query = _homeCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _settingHome = true);
    final coords = await NominatimService.geocode(query);
    if (!mounted) return;
    setState(() => _settingHome = false);
    if (coords == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.geocodeFailed)));
      return;
    }
    await ref.read(homeLocationProvider.notifier).set(query, coords.lat, coords.lng);
    if (!mounted) return;
    _homeCtrl.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.homeLocationSaved)));
  }

  Future<void> _clearHomeLocation() async {
    final l = AppLocalizations.of(context)!;
    await ref.read(homeLocationProvider.notifier).clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.homeLocationCleared)));
  }

  Future<void> _create() async {
    final id = HouseholdNotifier.generateId();
    await _setHousehold(id);
  }

  Future<void> _join() async {
    final l = AppLocalizations.of(context)!;
    final code = _joinCtrl.text.trim().toUpperCase();
    final valid = RegExp(r'^[A-Z0-9]{6}$').hasMatch(code);
    if (!valid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.joinHouseholdInvalid)));
      return;
    }
    await _setHousehold(code);
    _joinCtrl.clear();
  }

  Future<void> _setHousehold(String id) async {
    setState(() => _joining = true);
    try {
      // Upload local data before subscribing so it doesn't get wiped by the snapshot
      await ref.read(supermarketsProvider.notifier).uploadAll(id);
      await ref.read(shoppingListsProvider.notifier).uploadAll(id);
      await ref.read(householdProvider.notifier).setId(id);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _leave() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.leaveHouseholdConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.yes)),
        ],
      ),
    );
    if (ok == true) ref.read(householdProvider.notifier).clear();
  }

  void _copy(String id) {
    final l = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.copiedToClipboard)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hid = ref.watch(householdProvider);
    final homeLoc = ref.watch(homeLocationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.syncTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hid != null) ...[
              Text(l.yourHouseholdId, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hid,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: l.copiedToClipboard,
                      onPressed: () => _copy(hid),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      tooltip: l.shareHouseholdId,
                      onPressed: () => Share.share(hid),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.link_off),
                label: Text(l.leaveHousehold),
                onPressed: _leave,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(),
              ),
              Text(l.joinHousehold,
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.add_home_outlined),
                label: Text(l.createHousehold),
                onPressed: _joining ? null : _create,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(),
              ),
              Text(l.joinHousehold, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
            ],
            TextField(
              controller: _joinCtrl,
              decoration: InputDecoration(
                hintText: l.joinHouseholdHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onSubmitted: (_) => _joining ? null : _join(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _joining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(l.joinHousehold),
                onPressed: _joining ? null : _join,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
            // ── Home location ───────────────────────────────────────────────
            Text(l.homeLocation, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (homeLoc != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(homeLoc.address,
                          style: theme.textTheme.bodyMedium),
                    ),
                    TextButton(
                      onPressed: _clearHomeLocation,
                      child: Text(l.delete,
                          style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _homeCtrl,
                    decoration: InputDecoration(
                      hintText: l.homeLocationHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _settingHome ? null : _setHomeLocation(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _settingHome ? null : _setHomeLocation,
                  child: _settingHome
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.setHomeLocation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
