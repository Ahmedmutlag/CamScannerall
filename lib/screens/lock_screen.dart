import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_colors.dart';
import 'splash_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final appState = context.read<AppState>();
    if (!appState.lock.biometricEnabled) return;
    final available = await appState.lock.biometricAvailable;
    if (!available || !mounted) return;
    final ok = await appState.lock.authenticateWithBiometrics(
      appState.strings.t('unlockWithBiometric'),
    );
    if (ok && mounted) _unlockSuccess();
  }

  void _unlockSuccess() {
    final appState = context.read<AppState>();
    appState.lock.markActive();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PostUnlockGate()),
    );
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    final appState = context.read<AppState>();
    final ok = await appState.lock.verifyPin(_pinController.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _unlockSuccess();
    } else {
      setState(() => _error = appState.strings.t('wrongPin'));
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final colors = AppColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 72, color: colors.accentBrass),
              const SizedBox(height: AppSpacing.md),
              Text(s.t('appName'), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: s.t('enterPin')),
                onSubmitted: (_) => _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _verify,
                  child: Text(s.t('ok')),
                ),
              ),
              if (appState.lock.biometricEnabled) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(s.t('unlockWithBiometric')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
