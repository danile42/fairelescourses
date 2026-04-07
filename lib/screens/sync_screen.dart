import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairelescourses/l10n/app_localizations.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/firebase_credentials.dart';
import '../models/supermarket.dart';
import '../models/shopping_list.dart';
import '../providers/firebase_app_provider.dart';
import '../providers/home_location_provider.dart';
import '../providers/household_provider.dart';
import '../providers/local_only_provider.dart';
import '../providers/nav_view_mode_provider.dart';
import '../providers/seed_color_provider.dart';
import '../providers/supermarket_provider.dart';
import '../providers/shopping_list_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/nominatim_service.dart';
import 'help_screen.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _joinCtrl = TextEditingController();
  final _homeCtrl = TextEditingController();
  bool _joining = false;
  String? _joiningStep;
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

  bool get _firebaseFieldsComplete =>
      _projectIdCtrl.text.trim().isNotEmpty &&
      _apiKeyCtrl.text.trim().isNotEmpty &&
      _appIdCtrl.text.trim().isNotEmpty &&
      _senderIdCtrl.text.trim().isNotEmpty &&
      _bucketCtrl.text.trim().isNotEmpty;

  void _onFirebaseFieldChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    for (final ctrl in [
      _projectIdCtrl,
      _apiKeyCtrl,
      _appIdCtrl,
      _senderIdCtrl,
      _bucketCtrl,
    ]) {
      ctrl.addListener(_onFirebaseFieldChanged);
    }
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.geocodeFailed)));
      return;
    }
    await ref
        .read(homeLocationProvider.notifier)
        .set(query, coords.lat, coords.lng);
    if (!mounted) return;
    _homeCtrl.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.homeLocationSaved)));
  }

  Future<void> _clearHomeLocation() async {
    final l = AppLocalizations.of(context)!;
    await ref.read(homeLocationProvider.notifier).clear();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.homeLocationCleared)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.joinHouseholdInvalid)));
      return;
    }
    await _setHousehold(code);
    _joinCtrl.clear();
  }

  Future<void> _setHousehold(String id) async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _joining = true;
      _joiningStep = l.joiningStepJoining;
    });
    try {
      // 1. Set the household ID first so it's "active".
      await ref.read(householdProvider.notifier).setId(id);

      // 2. Upload local data. If this fails, the user is already in the household
      // but their local data hasn't been merged yet.
      if (mounted) setState(() => _joiningStep = l.joiningStepUploadingShops);
      await ref.read(supermarketsProvider.notifier).uploadAll(id);

      if (mounted) setState(() => _joiningStep = l.joiningStepUploadingLists);
      await ref.read(shoppingListsProvider.notifier).uploadAll(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error joining: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _joining = false;
          _joiningStep = null;
        });
      }
    }
  }

  Future<void> _leave() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.leaveHouseholdConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.yes),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(householdProvider.notifier).clear();
  }

  void _copy(String id) {
    final l = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.copiedToClipboard)));
  }

  Future<void> _startEditingFirebase() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 32),
        content: Text(l.firebaseAdvancedWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.firebaseAdvancedContinue),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.firebaseInstanceJsonInvalid)));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.firebaseInstanceFieldsRequired)),
        );
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
        creds,
        ref.read(firebaseAppProvider.notifier),
      );
      if (!mounted) return;
      // Leave household — it belongs to the old instance
      ref.read(householdProvider.notifier).clear();
      setState(() => _editingFirebase = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.firebaseInstanceSaved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.yes),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await clearCustomFirebaseCredentials(
      ref.read(firebaseAppProvider.notifier),
    );
    if (!mounted) return;
    ref.read(householdProvider.notifier).clear();
    setState(() => _editingFirebase = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.firebaseInstanceSaved)));
  }

  Future<void> _resetLocalData() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 32),
        content: Text(l.resetLocalDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l.yes),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await Hive.box<Supermarket>('supermarkets').clear();
    await Hive.box<ShoppingList>('shopping_lists').clear();
    await Hive.box<String>('settings').clear();
    ref.invalidate(supermarketsProvider);
    ref.invalidate(shoppingListsProvider);
    ref.invalidate(householdProvider);
    ref.invalidate(homeLocationProvider);
    ref.invalidate(localOnlyProvider);
    ref.invalidate(navViewModeProvider);
    ref.invalidate(seedColorProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.resetLocalDataDone)));
  }

  Future<void> _toggleLocalOnly(bool value) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: value ? null : const Text('Disable local-only mode'),
        content: Text(
          value ? l.localOnlyConfirmEnable : l.localOnlyConfirmDisable,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.yes),
          ),
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
    final preferListView = ref.watch(navViewModeProvider);
    final hid = ref.watch(householdProvider);
    final homeLoc = ref.watch(homeLocationProvider);
    final theme = Theme.of(context);
    final savedCreds = loadSavedFirebaseCredentials();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.configTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Home location ───────────────────────────────────────────────
            Text(l.homeLocation, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (homeLoc != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        homeLoc.address,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearHomeLocation,
                      child: Text(
                        l.delete,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
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
                    onSubmitted: (_) =>
                        _settingHome ? null : _setHomeLocation(),
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
            // ── Default navigation view ───────────────────────────────────────
            Text(l.navViewModeTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l.navViewModeDesc, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l.navViewModeGrid),
                  icon: const Icon(Icons.grid_view),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l.navViewModeList),
                  icon: const Icon(Icons.list),
                ),
              ],
              selected: {preferListView},
              onSelectionChanged: (v) =>
                  ref.read(navViewModeProvider.notifier).set(v.first),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
            // ── Menu color ───────────────────────────────────────────────────
            Text(l.menuColorTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _ColorPicker(
              current: ref.watch(seedColorProvider),
              onSelected: (c) => ref.read(seedColorProvider.notifier).set(c),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
            // ── Reset local data ─────────────────────────────────────────────
            Text(l.resetLocalDataTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l.resetLocalDataTitle),
              onPressed: _resetLocalData,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
            // ── Local-only toggle ────────────────────────────────────────────
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.localOnlyMode, style: theme.textTheme.titleMedium),
              subtitle: Text(l.localOnlyModeDesc),
              value: localOnly,
              onChanged: _toggleLocalOnly,
            ),
            if (localOnly) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l.localOnlyWarning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (!localOnly) ...[
              if (hid != null) ...[
                Text(l.yourHouseholdId, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        onPressed: () =>
                            SharePlus.instance.share(ShareParams(text: hid)),
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
                if (_joining && _joiningStep != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _joiningStep!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(),
              ),
              // ── Firebase instance ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.firebaseInstanceTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, size: 20),
                    tooltip: l.firebaseHelpTitle,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FirebaseHelpScreen(),
                      ),
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                            label: Text(l.firebaseInstanceProjectId),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(l.firebaseInstancePasteJson),
                          ),
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
                        onPressed:
                            _applyingFirebase ||
                                (!_pasteJsonMode && !_firebaseFieldsComplete)
                            ? null
                            : _applyFirebaseCredentials,
                        child: _applyingFirebase
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l.firebaseInstanceSave),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _applyingFirebase
                          ? null
                          : () => setState(() => _editingFirebase = false),
                      child: Text(l.cancel),
                    ),
                  ],
                ),
                if (savedCreds != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _applyingFirebase
                        ? null
                        : _resetFirebaseInstance,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
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
        labelText: '$label *',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}

// ── Preset color swatches ────────────────────────────────────────────────────

const _kPresetColors = [
  Color(0xFF2E7D32), // green (default)
  Color(0xFF1565C0), // blue
  Color(0xFF6A1B9A), // purple
  Color(0xFFAD1457), // pink
  Color(0xFFC62828), // red
  Color(0xFFE65100), // orange
  Color(0xFF00695C), // teal
  Color(0xFF37474F), // blue-grey
];

class _ColorPicker extends StatelessWidget {
  final Color current;
  final ValueChanged<Color> onSelected;

  const _ColorPicker({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _kPresetColors.map((color) {
        final selected = current.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () => onSelected(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
