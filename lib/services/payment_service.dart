import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/payment_models.dart';
import 'auth_service.dart';

class PaymentService {
  static const String _baseUrl = 'https://frnd-api-n3hv.onrender.com';

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    String? token = AuthService.token;
    
    if (token != null && token.isNotEmpty) {
      // Extract just the JWT value, removing 'token=' prefix if it exists
      if (token.startsWith('token=')) {
        token = token.substring(6);
      }
      headers['Authorization'] = 'Bearer $token';
      headers['Cookie'] = 'token=$token';
    }
    return headers;
  }

  /// 1. Fetch available payment tiers & pricing from backend
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

        return tiersMap;
      }
    } catch (_) {
      // Fallback local defaults if network unavailable
    }

    return {
      'free': const PaymentTier(
        tier: 'free',
        name: 'Free Tier',
        priceINR: 0,
        pricePaise: 0,
        validityDays: 30,
        likesLimit: 15,
        superlikesLimit: 3,
        profileBoost: 1,
        isAutopay: false,
      ),
      'silver': const PaymentTier(
        tier: 'silver',
        name: 'Silver Pass Autopay',
        priceINR: 39,
        pricePaise: 3900,
        validityDays: 30,
        likesLimit: 25,
        superlikesLimit: 6,
        profileBoost: 3,
        isAutopay: true,
      ),
      'gold': const PaymentTier(
        tier: 'gold',
        name: 'Gold Pass Autopay',
        priceINR: 49,
        pricePaise: 4900,
        validityDays: 30,
        likesLimit: 50,
        superlikesLimit: 12,
        profileBoost: 6,
        isAutopay: true,
      ),
    };
  }

  /// 2. Initiate Order / Subscription creation with backend
  /// Client sends ONLY tier ID. Price is resolved server-side!
  static Future<SubscriptionOrder> createSubscription(
    String tier, {
    String? idempotencyKey,
  }) async {
    final headers = _headers;
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/payments/create-subscription'),
          headers: headers,
          body: json.encode({'tier': tier, 'idempotencyKey': idempotencyKey}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return SubscriptionOrder.fromJson(jsonMap);
    } else {
      final errorJson = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(
        errorJson?['error'] ?? 'Failed to initialize payment order (${response.statusCode})',
      );
    }
  }

  /// 3. Verify Payment Signature with backend before marking transaction successful
  static Future<SubscriptionStatus> verifySubscription({
    required String subscriptionId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/payments/verify-subscription'),
          headers: _headers,
          body: json.encode({
            'razorpay_subscription_id': subscriptionId,
            'razorpay_payment_id': paymentId,
            'razorpay_signature': signature,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return SubscriptionStatus.fromJson(jsonMap);
    } else {
      final errorJson = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(
        errorJson?['error'] ?? 'Server-side payment verification failed (${response.statusCode})',
      );
    }
  }

  /// 4. Fetch current user subscription status from backend
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

  /// 5. Cancel recurring subscription
  static Future<SubscriptionStatus> cancelSubscription() async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/payments/cancel-subscription'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return SubscriptionStatus.fromJson(jsonMap);
    } else {
      final errorJson = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(errorJson?['error'] ?? 'Failed to cancel subscription');
    }
  }
}
