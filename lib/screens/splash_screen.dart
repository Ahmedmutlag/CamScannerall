import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/corner_fold_motif.dart';
import 'lock_screen.dart';
import 'pin_setup_screen.dart';
import 'root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final appState = context.read<AppState>();

    Widget next;
    if (!appState.lock.hasPin) {
      next = const PinSetupScreen(isFirstSetup: true);
    } else {
      next = const LockScreen();
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final colors = AppColors.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CornerFoldMotif(size: 84, color: colors.primaryInk),
            const SizedBox(height: AppSpacing.md),
            Text(
              appState.strings.t('appName'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown right after a successful unlock. The app is free with no
/// purchase/trial gate, so this always leads straight to the home screen —
/// kept as its own widget so lock_screen doesn't need to know what comes
/// after unlocking.
class PostUnlockGate extends StatelessWidget {
  const PostUnlockGate({super.key});

  @override
  Widget build(BuildContext context) => const RootShell();
}
