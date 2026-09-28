import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/backup_service.dart';
import '../theme/app_colors.dart';

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
    try {
      final bytes = await appState.backup.createBackup(password);
      await appState.backup.markBackupDone();
      if (!mounted) return;
      await appState.share.shareBytes(bytes, 'backup_${DateTime.now().millisecondsSinceEpoch}.dsbackup');
      if (!mounted) return;
      final colors = AppColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: colors.accentBrass,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(s.t('backupCreated'), style: const TextStyle(color: Colors.white))),
          ],
        ),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('backupCreateError'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final appState = context.read<AppState>();
    final s = appState.strings;

    final file = await FilePicker.pickFile();
    if (file == null || file.path == null) return;
    final path = file.path!;

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
    try {
      final bytes = await File(path).readAsBytes();
      final resultStatus = await appState.backup.restoreBackup(bytes, password);
      if (!mounted) return;
      final message = resultStatus == BackupRestoreResult.success ? s.t('restoreSuccess') : s.t('wrongPassword');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('wrongPassword'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseAutoBackupFolder() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final path = await FilePicker.getDirectoryPath();
    if (path == null || !mounted) return;

    // Confirm the folder is actually writable before saving it — on some
    // Android versions a picked directory outside the app's own storage
    // can silently reject writes; surfacing that now beats a mysterious
    // failure during a background auto-backup run 60 days later.
    try {
      final probe = File('$path/.camscanner_write_test');
      await probe.writeAsBytes(const [0]);
      await probe.delete();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('autoBackupWriteError'))));
      return;
    }

    await appState.backup.setAutoBackupFolder(path);
    if (mounted) setState(() {});
  }

  Future<void> _cleanUpFiles() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('cleanUpFilesTitle')),
        content: Text(s.t('cleanUpFilesBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.t('ok'))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final removed = await appState.cleanUpOrphanedFiles();
      if (!mounted) return;
      final message = removed == 0 ? s.t('noFilesToClean') : '$removed ${s.t('filesRemoved')}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('operationFailedGeneric'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                _sectionTitle(s.t('autoBackup')),
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(s.t('autoBackupFolder')),
                  subtitle: Text(settings.autoBackupFolderPath ?? s.t('autoBackupNotSet')),
                  trailing: settings.autoBackupFolderPath == null
                      ? TextButton(onPressed: _chooseAutoBackupFolder, child: Text(s.t('chooseFolder')))
                      : IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: s.t('remove'),
                          onPressed: () async {
                            await appState.backup.setAutoBackupFolder(null);
                            setState(() {});
                          },
                        ),
                  onTap: settings.autoBackupFolderPath == null ? _chooseAutoBackupFolder : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  child: Text(
                    s.t('autoBackupExplain'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.of(context).textSecondary,
                        ),
                  ),
                ),
                const Divider(),
                _sectionTitle(s.t('storage')),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: Text(s.t('cleanUpFiles')),
                  onTap: _cleanUpFiles,
                ),
                const Divider(),
                _sectionTitle(s.t('viewMode')),
                RadioGroup<String>(
                  groupValue: settings.viewMode,
                  onChanged: (v) => appState.setViewMode(v!),
                  child: Column(
                    children: [
                      RadioListTile<String>(value: 'grid', title: Text(s.t('grid'))),
                      RadioListTile<String>(value: 'list', title: Text(s.t('list'))),
                    ],
                  ),
                ),
                const Divider(),
                _sectionTitle(s.t('language')),
                RadioGroup<String>(
                  groupValue: settings.languageCode,
                  onChanged: (v) => appState.setLanguage(v!),
                  child: Column(
                    children: [
                      RadioListTile<String>(value: 'ar', title: const Text('العربية')),
                      RadioListTile<String>(value: 'en', title: const Text('English')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) => Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs,
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
          ),
        ),
      );
}
