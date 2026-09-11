import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/backup_service.dart';
import 'paywall_screen.dart';
import 'pin_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<String?> _askPassword(String title) async {
    final controller = TextEditingController();
    final s = context.read<AppState>().strings;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(labelText: s.t('backupPasswordHint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(s.t('ok'))),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final password = await _askPassword(s.t('createBackup'));
    if (password == null || password.isEmpty) return;

    setState(() => _busy = true);
    final bytes = await appState.backup.createBackup(password);
    await appState.backup.markBackupDone();
    setState(() => _busy = false);

    if (!mounted) return;
    await appState.share.shareBytes(bytes, 'backup_${DateTime.now().millisecondsSinceEpoch}.dsbackup');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('backupCreated'))));
    setState(() {});
  }

  Future<void> _restoreBackup() async {
    final appState = context.read<AppState>();
    final s = appState.strings;

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;

    final password = await _askPassword(s.t('restoreBackup'));
    if (password == null || password.isEmpty || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('restoreBackup')),
        content: Text(s.t('privacyWarningBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.t('ok'))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final bytes = await File(path).readAsBytes();
    final resultStatus = await appState.backup.restoreBackup(bytes, password);
    setState(() => _busy = false);

    if (!mounted) return;
    final message = resultStatus == BackupRestoreResult.success ? s.t('restoreSuccess') : s.t('wrongPassword');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final settings = appState.settings;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings'))),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionTitle(s.t('security')),
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(s.t('changePin')),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PinSetupScreen(isFirstSetup: false)),
                  ),
                ),
                FutureBuilder<bool>(
                  future: appState.lock.biometricAvailable,
                  builder: (context, snap) {
                    if (snap.data != true) return const SizedBox.shrink();
                    return SwitchListTile(
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(s.t('enableBiometric')),
                      value: settings.biometricEnabled,
                      onChanged: (v) async {
                        await appState.lock.setBiometricEnabled(v);
                        setState(() {});
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(s.t('autoLockMinutes')),
                  trailing: DropdownButton<int>(
                    value: settings.autoLockMinutes,
                    items: const [1, 5, 15, 30, 60]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      await appState.lock.setAutoLockMinutes(v);
                      setState(() {});
                    },
                  ),
                ),
                const Divider(),
                _sectionTitle(s.t('backup')),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(s.t('createBackup')),
                  onTap: _createBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: Text(s.t('restoreBackup')),
                  onTap: _restoreBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(s.t('lastBackup')),
                  trailing: Text(
                    settings.lastBackupDate != null
                        ? DateFormat('yyyy-MM-dd').format(settings.lastBackupDate!)
                        : s.t('never'),
                  ),
                ),
                const Divider(),
                _sectionTitle(s.t('viewMode')),
                RadioListTile<String>(
                  value: 'grid',
                  groupValue: settings.viewMode,
                  title: Text(s.t('grid')),
                  onChanged: (v) => appState.setViewMode(v!),
                ),
                RadioListTile<String>(
                  value: 'list',
                  groupValue: settings.viewMode,
                  title: Text(s.t('list')),
                  onChanged: (v) => appState.setViewMode(v!),
                ),
                const Divider(),
                _sectionTitle(s.t('language')),
                RadioListTile<String>(
                  value: 'ar',
                  groupValue: settings.languageCode,
                  title: const Text('العربية'),
                  onChanged: (v) => appState.setLanguage(v!),
                ),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: settings.languageCode,
                  title: const Text('English'),
                  onChanged: (v) => appState.setLanguage(v!),
                ),
                const Divider(),
                _sectionTitle(s.t('purchaseStatus')),
                ListTile(
                  leading: Icon(settings.isPurchased ? Icons.verified_outlined : Icons.timer_outlined),
                  title: Text(settings.isPurchased ? s.t('purchased') : s.t('trialActive')),
                  subtitle: settings.isPurchased ? null : Text('${s.t('daysLeft')}: ${appState.trial.daysLeft}'),
                  trailing: settings.isPurchased
                      ? null
                      : TextButton(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
                          child: Text(s.t('buyNow')),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}
