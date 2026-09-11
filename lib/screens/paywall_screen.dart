import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/purchase_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.canDismiss = true});

  final bool canDismiss;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final product = appState.purchase.product;

    return PopScope(
      canPop: widget.canDismiss,
      child: Scaffold(
        appBar: widget.canDismiss ? AppBar(title: Text(s.t('buyNow'))) : null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium_outlined, size: 84),
                const SizedBox(height: 16),
                Text(
                  s.t('trialTitle'),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(s.t('trialBody'), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (product != null)
                  Text(
                    product.price,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _buy,
                    child: _busy
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s.t('buyNow')),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _restore,
                  child: Text(s.t('restorePurchases')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    final appState = context.read<AppState>();
    final sub = appState.purchase.stateStream.listen((state) {
      if (!mounted) return;
      if (state == PurchaseServiceState.success) {
        appState.refreshPurchaseState();
      }
      if (state == PurchaseServiceState.error || state == PurchaseServiceState.canceled) {
        setState(() => _busy = false);
      }
    });
    await appState.purchase.buy();
    await Future.delayed(const Duration(seconds: 2));
    sub.cancel();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final appState = context.read<AppState>();
    final sub = appState.purchase.stateStream.listen((state) {
      if (state == PurchaseServiceState.success) {
        appState.refreshPurchaseState();
      }
    });
    await appState.purchase.restore();
    await Future.delayed(const Duration(seconds: 2));
    sub.cancel();
    if (mounted) setState(() => _busy = false);
  }
}
