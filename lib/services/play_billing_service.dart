import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Product IDs — must exactly match Play Console product IDs.
const String kSilverPassId = 'frnd_silver_pass';
const String kGoldPassId = 'frnd_gold_pass';
const Set<String> kProductIds = {kSilverPassId, kGoldPassId};

/// Result of a Play Billing purchase attempt.
enum PlayPurchaseStatus {
  /// Purchase completed and server-verified successfully.
  success,

  /// User dismissed the purchase sheet (not an error).
  cancelled,

  /// Purchase pending (e.g. parental approval). UI should inform user.
  pending,

  /// Purchase or server verification failed.
  failed,

  /// Play Billing not available on this device (e.g. non-Android).
  unavailable,
}

class PlayPurchaseResult {
  final PlayPurchaseStatus status;
  final String message;
  final String? tier; // 'silver' | 'gold'

  const PlayPurchaseResult({
    required this.status,
    required this.message,
    this.tier,
  });
}

/// Singleton service managing the entire Google Play Billing lifecycle.
///
/// Lifecycle:
///   1. Call [init] once in main() before runApp().
///   2. Call [loadProducts] when the Subscription screen opens.
///   3. Call [purchaseTier] when user taps Subscribe.
///   4. Listen to [onPurchaseResult] to drive UI state changes.
///   5. Call [dispose] when the app is closing (not typically needed but available).
class PlayBillingService {
  PlayBillingService._();
  static final PlayBillingService instance = PlayBillingService._();

  static const String _baseUrl = 'https://frnd-api-n3hv.onrender.com';

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Loaded product details from Play Console.
  Map<String, ProductDetails> _products = {};
  bool _isAvailable = false;
  bool _isInitialized = false;

  // Callback sink: subscription_screen listens to this to update UI.
  final StreamController<PlayPurchaseResult> _resultController =
      StreamController<PlayPurchaseResult>.broadcast();

  /// Stream that emits purchase results. Subscribe in the UI layer.
  Stream<PlayPurchaseResult> get onPurchaseResult => _resultController.stream;

  // Tracks the most recently active Play purchase by product ID.
  // Used to supply oldPurchaseDetails for the proration upgrade/downgrade flow.
  final Map<String, GooglePlayPurchaseDetails> _activePurchases = {};

  bool get isAvailable => _isAvailable;
  Map<String, ProductDetails> get products => _products;

  /// Initialise Play Billing and start listening to the purchase stream.
  /// Must be called once before runApp().
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('[PlayBilling] Store not available on this device.');
      return;
    }

    // Listen to purchase updates for the lifetime of the app.
    _purchaseSubscription =
        _iap.purchaseStream.listen(_handlePurchaseUpdate, onError: (Object e) {
      debugPrint('[PlayBilling] Purchase stream error: $e');
    });

    // Restore any previously-purchased subscriptions on startup.
    await _iap.restorePurchases();

    debugPrint('[PlayBilling] Initialized.');
  }

  /// Query Play Console for product details. Call when the Subscription screen mounts.
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(kProductIds);

    if (response.error != null) {
      debugPrint('[PlayBilling] queryProductDetails error: ${response.error}');
    }

    _products = {
      for (final p in response.productDetails) p.id: p,
    };

    debugPrint('[PlayBilling] Loaded products: ${_products.keys}');
  }

  /// Initiate a purchase for a tier.
  ///
  /// [productId]    — `frnd_silver_pass` or `frnd_gold_pass`
  /// [currentProductId] — set when user already has an active subscription
  ///                      (triggers proration upgrade/downgrade flow via Play Billing).
  Future<void> purchaseTier({
    required String productId,
    String? currentProductId,
  }) async {
    if (!_isAvailable) {
      _resultController.add(const PlayPurchaseResult(
        status: PlayPurchaseStatus.unavailable,
        message: 'Google Play is not available on this device.',
      ));
      return;
    }

    final ProductDetails? product = _products[productId];
    if (product == null) {
      _resultController.add(const PlayPurchaseResult(
        status: PlayPurchaseStatus.failed,
        message: 'Subscription product not found. Please try again.',
      ));
      return;
    }

    late final PurchaseParam purchaseParam;

    // Build proration replacement param if upgrading/downgrading.
    if (currentProductId != null &&
        defaultTargetPlatform == TargetPlatform.android) {
      final GooglePlayPurchaseDetails? oldPurchase =
          _activePurchases[currentProductId];
      if (oldPurchase != null) {
        purchaseParam = GooglePlayPurchaseParam(
          productDetails: product,
          applicationUserName: AuthService.userId,
          changeSubscriptionParam: ChangeSubscriptionParam(
            oldPurchaseDetails: oldPurchase,
            replacementMode: ReplacementMode.withTimeProration,
          ),
        );
      } else {
        // No active purchase found for old product — do a fresh purchase.
        purchaseParam = GooglePlayPurchaseParam(
          productDetails: product,
          applicationUserName: AuthService.userId,
        );
      }
    } else {
      purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: AuthService.userId,
      );
    }

    // Subscriptions always use buyNonConsumable flow via in_app_purchase.
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    // Result arrives via _handlePurchaseUpdate stream — UI waits on onPurchaseResult.
  }

  /// Attempt to restore existing subscriptions (e.g. after reinstall or sign-in on new device).
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  /// Handles all incoming purchase state changes from the Play Billing stream.
  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      debugPrint(
          '[PlayBilling] Purchase update: ${purchase.productID} → ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _resultController.add(PlayPurchaseResult(
            status: PlayPurchaseStatus.pending,
            message:
                'Purchase pending approval. You\'ll be notified when it completes.',
            tier: _tierFromProductId(purchase.productID),
          ));

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Cache the active Google Play purchase for potential future proration use.
          if (defaultTargetPlatform == TargetPlatform.android &&
              purchase is GooglePlayPurchaseDetails) {
            _activePurchases[purchase.productID] = purchase;
          }
          // Must complete the purchase (acknowledge) via our backend.
          await _verifyAndAcknowledge(purchase);

        case PurchaseStatus.error:
          // IAPError.code == BillingResponse.userCanceled (1) → treat as cancelled.
          final bool isCancelled = purchase.error?.code == 'userCanceled' ||
              purchase.error?.details?.toString().contains('userCanceled') == true;
          if (isCancelled) {
            _resultController.add(const PlayPurchaseResult(
              status: PlayPurchaseStatus.cancelled,
              message: 'Purchase cancelled.',
            ));
          } else {
            _resultController.add(PlayPurchaseResult(
              status: PlayPurchaseStatus.failed,
              message: purchase.error?.message ?? 'Purchase failed. Please try again.',
            ));
          }
          // Complete the purchase so it doesn't get stuck.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

        case PurchaseStatus.canceled:
          _resultController.add(const PlayPurchaseResult(
            status: PlayPurchaseStatus.cancelled,
            message: 'Purchase cancelled.',
          ));
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
      }
    }
  }

  /// Send the purchase token to our backend for server-side verification
  /// against the Play Developer API. The backend also acknowledges the purchase.
  Future<void> _verifyAndAcknowledge(PurchaseDetails purchase) async {
    try {
      final headers = _buildHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/payments/play/verify'),
            headers: headers,
            body: json.encode({
              'purchaseToken': purchase.verificationData.serverVerificationData,
              'productId': purchase.productID,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        // Backend verified and acknowledged — complete the purchase client-side.
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tier = data['tier'] as String? ?? _tierFromProductId(purchase.productID);
        _resultController.add(PlayPurchaseResult(
          status: PlayPurchaseStatus.success,
          message: '🎉 ${tier == 'gold' ? 'Gold' : 'Silver'} Pass activated!',
          tier: tier,
        ));
      } else {
        final errorJson = json.decode(response.body) as Map<String, dynamic>?;
        _resultController.add(PlayPurchaseResult(
          status: PlayPurchaseStatus.failed,
          message: errorJson?['error'] as String? ??
              'Server verification failed (${response.statusCode}). Contact support.',
        ));
        // Do NOT complete the purchase — leave it pending so the user can retry.
      }
    } catch (e) {
      debugPrint('[PlayBilling] Verification error: $e');
      _resultController.add(PlayPurchaseResult(
        status: PlayPurchaseStatus.failed,
        message: 'Network error during verification. Please try again.',
      ));
    }
  }

  String? _tierFromProductId(String productId) {
    if (productId == kSilverPassId) return 'silver';
    if (productId == kGoldPassId) return 'gold';
    return null;
  }

  Map<String, String> _buildHeaders() {
    final headers = {'Content-Type': 'application/json'};
    String? token = AuthService.token;
    if (token != null && token.isNotEmpty) {
      if (token.startsWith('token=')) token = token.substring(6);
      headers['Authorization'] = 'Bearer $token';
      headers['Cookie'] = 'token=$token';
    }
    return headers;
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _resultController.close();
  }
}
