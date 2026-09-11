import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'home_screen.dart';
import 'lock_screen.dart';
import 'paywall_screen.dart';
import 'pin_setup_screen.dart';

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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.document_scanner_outlined, size: 84),
            const SizedBox(height: 16),
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

/// Decides, after a successful unlock, whether to show the home screen or
/// the paywall based on trial/purchase state.
class PostUnlockGate extends StatelessWidget {
  const PostUnlockGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.trial.isLocked) {
      return const PaywallScreen(canDismiss: false);
    }
    return const HomeScreen();
  }
}
