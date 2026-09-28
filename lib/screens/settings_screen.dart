import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

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
