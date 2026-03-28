import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';

import '../models/firebase_credentials.dart';
import '../providers/firebase_app_provider.dart';
import '../providers/home_location_provider.dart';
import '../providers/household_provider.dart';
import '../providers/local_only_provider.dart';
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

  // Firebase instance editing
  bool _editingFirebase = false;
  bool _pasteJsonMode = false;
  bool _applyingFirebase = false;
  final _projectIdCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _appIdCtrl = TextEditingController();
  final _senderIdCtrl = TextEditingController();
  final _bucketCtrl = TextEditingController();
  final _jsonCtrl = TextEditingController();

  @override
  void dispose() {
    _joinCtrl.dispose();
    _homeCtrl.dispose();
    _projectIdCtrl.dispose();
    _apiKeyCtrl.dispose();
    _appIdCtrl.dispose();
    _senderIdCtrl.dispose();
    _bucketCtrl.dispose();
    _jsonCtrl.dispose();
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

  void _startEditingFirebase() {
    final saved = loadSavedFirebaseCredentials();
    if (saved != null) {
      _projectIdCtrl.text = saved.projectId;
      _apiKeyCtrl.text = saved.apiKey;
      _appIdCtrl.text = saved.appId;
      _senderIdCtrl.text = saved.messagingSenderId;
      _bucketCtrl.text = saved.storageBucket;
    }
    setState(() {
      _editingFirebase = true;
      _pasteJsonMode = false;
    });
  }

  Future<void> _applyFirebaseCredentials() async {
    final l = AppLocalizations.of(context)!;

    FirebaseCredentials? creds;
    if (_pasteJsonMode) {
      creds = FirebaseCredentials.fromGoogleServicesJson(_jsonCtrl.text.trim());
      if (creds == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.firebaseInstanceJsonInvalid)));
        return;
      }
    } else {
      final projectId = _projectIdCtrl.text.trim();
      final apiKey = _apiKeyCtrl.text.trim();
      final appId = _appIdCtrl.text.trim();
      final senderId = _senderIdCtrl.text.trim();
      final bucket = _bucketCtrl.text.trim();
      if (projectId.isEmpty ||
          apiKey.isEmpty ||
          appId.isEmpty ||
          senderId.isEmpty ||
          bucket.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.firebaseInstanceFieldsRequired)));
        return;
      }
      creds = FirebaseCredentials(
        projectId: projectId,
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        storageBucket: bucket,
      );
    }

    setState(() => _applyingFirebase = true);
    try {
      await applyCustomFirebaseCredentials(
          creds, ref.read(firebaseAppProvider.notifier));
      if (!mounted) return;
      // Leave household — it belongs to the old instance
      ref.read(householdProvider.notifier).clear();
      setState(() => _editingFirebase = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.firebaseInstanceSaved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _applyingFirebase = false);
    }
  }

  Future<void> _resetFirebaseInstance() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.firebaseInstanceResetConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.yes)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await clearCustomFirebaseCredentials(ref.read(firebaseAppProvider.notifier));
    if (!mounted) return;
    ref.read(householdProvider.notifier).clear();
    setState(() => _editingFirebase = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.firebaseInstanceSaved)));
  }

  Future<void> _toggleLocalOnly(bool value) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(value ? l.localOnlyConfirmEnable : l.localOnlyConfirmDisable),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.yes)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(localOnlyProvider.notifier).set(value);
    if (value) ref.read(householdProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final localOnly = ref.watch(localOnlyProvider);
    final hid = ref.watch(householdProvider);
    final homeLoc = ref.watch(homeLocationProvider);
    final theme = Theme.of(context);
    final savedCreds = loadSavedFirebaseCredentials();

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
            // ── Local-only toggle ────────────────────────────────────────────
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.localOnlyMode,
                  style: theme.textTheme.titleMedium),
              subtitle: Text(l.localOnlyModeDesc),
              value: localOnly,
              onChanged: _toggleLocalOnly,
            ),
            if (localOnly) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(l.localOnlyWarning,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer)),
              ),
              const SizedBox(height: 8),
            ],
            if (!localOnly) ...[
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
            // ── Firebase instance ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(l.firebaseInstanceTitle,
                      style: theme.textTheme.titleMedium),
                ),
                if (!_editingFirebase)
                  TextButton(
                    onPressed: _startEditingFirebase,
                    child: Text(l.firebaseInstanceChange),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_editingFirebase) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  savedCreds != null
                      ? l.firebaseInstanceCustom(savedCreds.projectId)
                      : l.firebaseInstanceDefault,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ] else ...[
              // Toggle: fields vs paste JSON
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                            value: false,
                            label: Text(l.firebaseInstanceProjectId)),
                        ButtonSegment(
                            value: true,
                            label: Text(l.firebaseInstancePasteJson)),
                      ],
                      selected: {_pasteJsonMode},
                      onSelectionChanged: (v) =>
                          setState(() => _pasteJsonMode = v.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_pasteJsonMode) ...[
                TextField(
                  controller: _jsonCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'google-services.json',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ] else ...[
                _field(_projectIdCtrl, l.firebaseInstanceProjectId),
                _field(_apiKeyCtrl, l.firebaseInstanceApiKey),
                _field(_appIdCtrl, l.firebaseInstanceAppId),
                _field(_senderIdCtrl, l.firebaseInstanceSenderId),
                _field(_bucketCtrl, l.firebaseInstanceBucket),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyingFirebase ? null : _applyFirebaseCredentials,
                      child: _applyingFirebase
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.firebaseInstanceSave),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed:
                        _applyingFirebase ? null : () => setState(() => _editingFirebase = false),
                    child: Text(l.cancel),
                  ),
                ],
              ),
              if (savedCreds != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _applyingFirebase ? null : _resetFirebaseInstance,
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                  child: Text(l.firebaseInstanceReset),
                ),
              ],
            ],
            const SizedBox(height: 24),
            ], // end if (!localOnly)
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );
}
