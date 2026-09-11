import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'database_service.dart';

/// Wraps Google Play Billing (via `in_app_purchase`) for a single
/// non-consumable "lifetime unlock" product. This is the only network
/// dependency in the whole app, and it talks to the Play Store directly —
/// never to a developer-owned server.
class PurchaseService {
  PurchaseService(this._db);

  final DatabaseService _db;

  static const String lifetimeProductId = 'camscannerall_lifetime_unlock';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? product;
  bool storeAvailable = false;

  final _stateController = StreamController<PurchaseServiceState>.broadcast();
  Stream<PurchaseServiceState> get stateStream => _stateController.stream;

  Future<void> init() async {
    storeAvailable = await _iap.isAvailable();
    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {});

    if (storeAvailable) {
      final response = await _iap.queryProductDetails({lifetimeProductId});
      if (response.productDetails.isNotEmpty) {
        product = response.productDetails.first;
      }
    }
  }

  Future<void> buy() async {
    if (product == null) {
      _stateController.add(PurchaseServiceState.error);
      return;
    }
    final param = PurchaseParam(productDetails: product!);
    _stateController.add(PurchaseServiceState.pending);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    _stateController.add(PurchaseServiceState.pending);
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != lifetimeProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _stateController.add(PurchaseServiceState.pending);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final settings = _db.settings;
          settings.isPurchased = true;
          await _db.saveSettings(settings);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _stateController.add(PurchaseServiceState.success);
          break;
        case PurchaseStatus.error:
          _stateController.add(PurchaseServiceState.error);
          break;
        case PurchaseStatus.canceled:
          _stateController.add(PurchaseServiceState.canceled);
          break;
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}

enum PurchaseServiceState { pending, success, error, canceled }
