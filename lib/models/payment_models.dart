class PaymentTier {
  final String tier;
  final String name;
  final int priceINR;
  final int pricePaise;
  final int validityDays;
  final int likesLimit;
  final int superlikesLimit;
  final int profileBoost;
  final bool isAutopay;

  const PaymentTier({
    required this.tier,
    required this.name,
    required this.priceINR,
    required this.pricePaise,
    required this.validityDays,
    required this.likesLimit,
    required this.superlikesLimit,
    required this.profileBoost,
    required this.isAutopay,
  });

  factory PaymentTier.fromJson(Map<String, dynamic> json) {
    return PaymentTier(
      tier: json['tier'] ?? 'free',
      name: json['name'] ?? 'Free Tier',
      priceINR: (json['priceINR'] ?? 0) as int,
      pricePaise: (json['pricePaise'] ?? 0) as int,
      validityDays: (json['validityDays'] ?? 30) as int,
      likesLimit: (json['likesLimit'] ?? 15) as int,
      superlikesLimit: (json['superlikesLimit'] ?? 3) as int,
      profileBoost: (json['profileBoost'] ?? 1) as int,
      isAutopay: json['isAutopay'] ?? false,
    );
  }
}

class SubscriptionOrder {
  final String subscriptionId;
  final String planId;
  final int amount;
  final int amountINR;
  final String currency;
  final String keyId;
  final String tier;
  final String tierName;
  final int validityDays;
  final bool isAutopay;

  const SubscriptionOrder({
    required this.subscriptionId,
    required this.planId,
    required this.amount,
    required this.amountINR,
    required this.currency,
    required this.keyId,
    required this.tier,
    required this.tierName,
    required this.validityDays,
    required this.isAutopay,
  });

  factory SubscriptionOrder.fromJson(Map<String, dynamic> json) {
    return SubscriptionOrder(
      subscriptionId: json['subscriptionId'] ?? json['orderId'] ?? '',
      planId: json['planId'] ?? '',
      amount: (json['amount'] ?? 0) as int,
      amountINR: (json['amountINR'] ?? (json['amount'] != null ? json['amount'] ~/ 100 : 0)) as int,
      currency: json['currency'] ?? 'INR',
      keyId: json['keyId'] ?? '',
      tier: json['tier'] ?? 'silver',
      tierName: json['tierName'] ?? 'Silver Pass',
      validityDays: (json['validityDays'] ?? 30) as int,
      isAutopay: json['isAutopay'] ?? true,
    );
  }
}

class SubscriptionStatus {
  final String tier;
  final bool isPremium;
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
    return SubscriptionStatus(
      tier: json['tier'] ?? 'free',
      isPremium: json['isPremium'] ?? false,
      autopayStatus: json['autopayStatus'] ?? 'none',
      subscriptionExpiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
      validityDaysRemaining: (json['validityDaysRemaining'] ?? 0) as int,
      likesLimit: (limits['likesLimit'] ?? 15) as int,
      superlikesLimit: (limits['superlikesLimit'] ?? 3) as int,
      profileBoost: (limits['profileBoost'] ?? 1) as int,
    );
  }
}

enum PaymentResultStatus { success, failed, cancelled }

class PaymentResult {
  final PaymentResultStatus status;
  final String message;
  final String? subscriptionId;
  final String? paymentId;
  final String? signature;

  const PaymentResult({
    required this.status,
    required this.message,
    this.subscriptionId,
    this.paymentId,
    this.signature,
  });
}
