import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_colors.dart';
import 'splash_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.isFirstSetup});

  final bool isFirstSetup;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    if (_pinController.text.length < 4) {
      setState(() => _error = s.t('setPin'));
      return;
    }
    if (_pinController.text != _confirmController.text) {
      setState(() => _error = s.t('pinMismatch'));
      return;
    }

    await appState.lock.setPin(_pinController.text);

    if (widget.isFirstSetup) {
      final biometricAvailable = await appState.lock.biometricAvailable;
      if (biometricAvailable && mounted) {
        final enable = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(s.t('enableBiometric')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('no'))),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.t('yes'))),
            ],
          ),
        );
        if (enable == true) {
          await appState.lock.setBiometricEnabled(true);
        }
      }
      if (mounted) await _showPrivacyWarning();
    }

    if (!mounted) return;
    appState.lock.markActive();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PostUnlockGate()),
    );
  }

  Future<void> _showPrivacyWarning() async {
    final s = context.read<AppState>().strings;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(s.t('privacyWarningTitle')),
        content: Text(s.t('privacyWarningBody')),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('understood')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('setPin'))),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: colors.accentBrass),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: s.t('enterPin')),
            ),
            TextField(
              controller: _confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: s.t('confirmPin')),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _submit, child: Text(s.t('save'))),
            ),
          ],
        ),
      ),
    );
  }
}
