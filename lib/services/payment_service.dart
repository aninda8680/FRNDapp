import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_models.dart';
import 'auth_service.dart';

/// HTTP client for tier/status data from the backend.
///
/// Purchase initiation and verification is handled by [PlayBillingService].
/// This service is responsible for:
///   - Fetching available tier info (for UI display)
///   - Fetching the user's current subscription status
///   - Directing users to Google Play to manage/cancel subscriptions
class PaymentService {
  static const String _baseUrl = 'https://frnd-api-n3hv.onrender.com';

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    String? token = AuthService.token;
    if (token != null && token.isNotEmpty) {
      if (token.startsWith('token=')) token = token.substring(6);
      headers['Authorization'] = 'Bearer $token';
      headers['Cookie'] = 'token=$token';
    }
    return headers;
  }

  // ── Local hardcoded fallback defaults (used when API is unreachable) ────────
  // Values exactly match TIER_CONFIG on the backend.
  static const Map<String, PaymentTier> kDefaultTiers = {
    'free': PaymentTier(
      tier: 'free',
      name: 'Free Tier',
      priceINR: 0,
      validityDays: 28,
      likesLimit: 15,
      superlikesLimit: 3,
      profileBoost: 1,
    ),
    'silver': PaymentTier(
      tier: 'silver',
      name: 'Silver Pass',
      priceINR: 39,
      validityDays: 28,
      likesLimit: 25,
      superlikesLimit: 6,
      profileBoost: 3,
    ),
    'gold': PaymentTier(
      tier: 'gold',
      name: 'Gold Pass',
      priceINR: 49,
      validityDays: 28,
      likesLimit: 50,
      superlikesLimit: 12,
      profileBoost: 6,
    ),
  };

  /// Fetch available tier info from backend. Falls back to local defaults.
  static Future<Map<String, PaymentTier>> getTiers() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/payments/tiers'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tiersJson = data['tiers'] as Map<String, dynamic>? ?? {};
        final Map<String, PaymentTier> tiersMap = {};
        tiersJson.forEach((key, value) {
          tiersMap[key] = PaymentTier.fromJson(value as Map<String, dynamic>);
        });
        if (tiersMap.isNotEmpty) return tiersMap;
      }
    } catch (_) {
      // Fall through to local defaults
    }
    return kDefaultTiers;
  }

  /// Fetch the current user's subscription status from the backend.
  /// This is the authoritative source for tier, limits, and expiry.
  static Future<SubscriptionStatus> getSubscriptionStatus() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/payments/subscription-status'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return SubscriptionStatus.fromJson(jsonMap);
    } else {
      final errorJson = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(errorJson?['error'] ?? 'Failed to fetch subscription status');
    }
  }

  /// Returns the Google Play subscription management URI.
  /// Users cancel/manage their subscription here — not via an in-app button.
  static Uri getPlayManageSubscriptionsUri({String? productId, String? packageName}) {
    // Deep-link into the Google Play subscription management screen.
    final pkg = packageName ?? 'com.frnd.app';
    if (productId != null) {
      return Uri.parse(
          'https://play.google.com/store/account/subscriptions?sku=$productId&package=$pkg');
    }
    return Uri.parse('https://play.google.com/store/account/subscriptions');
  }
}
