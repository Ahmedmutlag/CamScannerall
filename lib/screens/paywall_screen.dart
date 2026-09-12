import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';

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
    final colors = AppColors.of(context);

    return PopScope(
      canPop: widget.canDismiss,
      child: Scaffold(
        appBar: widget.canDismiss ? AppBar(title: Text(s.t('buyNow'))) : null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium_outlined, size: 84, color: colors.primaryInk),
                const SizedBox(height: AppSpacing.md),
                Text(
                  s.t('trialTitle'),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.t('trialBody'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (product != null)
                  Text(
                    product.price,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.sm),
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
