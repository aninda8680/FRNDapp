/// Describes a subscription tier's entitlements and pricing.
/// Used for display in the Subscription screen and local fallback defaults.
class PaymentTier {
  final String tier;
  final String name;
  final int priceINR;
  final int validityDays;
  final int likesLimit;
  final int superlikesLimit;
  final int profileBoost;

  const PaymentTier({
    required this.tier,
    required this.name,
    required this.priceINR,
    required this.validityDays,
    required this.likesLimit,
    required this.superlikesLimit,
    required this.profileBoost,
  });

  factory PaymentTier.fromJson(Map<String, dynamic> json) {
    return PaymentTier(
      tier: json['tier'] ?? 'free',
      name: json['name'] ?? 'Free Tier',
      priceINR: (json['priceINR'] ?? 0) as int,
      validityDays: (json['validityDays'] ?? 28) as int,
      likesLimit: (json['likesLimit'] ?? 15) as int,
      superlikesLimit: (json['superlikesLimit'] ?? 3) as int,
      profileBoost: (json['profileBoost'] ?? 1) as int,
    );
  }
}

/// Current subscription status fetched from the backend.
class SubscriptionStatus {
  final String tier;
  final bool isPremium;

  /// For Play Billing subscribers this is 'active' or 'none'.
  /// For grandfathered Razorpay subscribers it may be 'cancelled' or 'halted'.
  final String autopayStatus;
  final DateTime? subscriptionExpiresAt;
  final int validityDaysRemaining;
  final int likesLimit;
  final int superlikesLimit;
  final int profileBoost;

  const SubscriptionStatus({
    required this.tier,
    required this.isPremium,
    required this.autopayStatus,
    this.subscriptionExpiresAt,
    required this.validityDaysRemaining,
    required this.likesLimit,
    required this.superlikesLimit,
    required this.profileBoost,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final limits = json['limits'] as Map<String, dynamic>? ?? {};
    final expiresAtStr = json['subscriptionExpiresAt'] as String?;
    final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
    final int rawRemainingDays = (json['validityDaysRemaining'] ?? 0) as int;

    // Client-side expiration guard — server is authoritative.
    final bool isExpired =
        (expiresAt != null && DateTime.now().isAfter(expiresAt)) ||
            (json['tier'] != null &&
                json['tier'] != 'free' &&
                rawRemainingDays <= 0);

    final String effectiveTier = isExpired ? 'free' : (json['tier'] ?? 'free');
    final bool effectiveIsPremium = isExpired ? false : (json['isPremium'] ?? false);
    final int effectiveDays = isExpired ? 0 : rawRemainingDays;

    return SubscriptionStatus(
      tier: effectiveTier,
      isPremium: effectiveIsPremium,
      autopayStatus: isExpired ? 'none' : (json['autopayStatus'] ?? 'none'),
      subscriptionExpiresAt: expiresAt,
      validityDaysRemaining: effectiveDays > 0 ? effectiveDays : 0,
      likesLimit: isExpired ? 15 : ((limits['likesLimit'] ?? 15) as int),
      superlikesLimit: isExpired ? 3 : ((limits['superlikesLimit'] ?? 3) as int),
      profileBoost: isExpired ? 1 : ((limits['profileBoost'] ?? 1) as int),
    );
  }
}
