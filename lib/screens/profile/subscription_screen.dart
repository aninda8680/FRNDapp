import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../services/payment_service.dart';
import '../../models/payment_models.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Razorpay _razorpay;
  bool _isLoading = true;
  String _selectedTierKey = 'gold'; // Default selection
  Map<String, PaymentTier> _tiers = {};
  SubscriptionStatus? _userStatus;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final fetchedTiers = await PaymentService.getTiers();
      SubscriptionStatus? status;
      try {
        status = await PaymentService.getSubscriptionStatus();
      } catch (_) {
        status = const SubscriptionStatus(
          tier: 'free',
          isPremium: false,
          autopayStatus: 'none',
          validityDaysRemaining: 0,
          likesLimit: 15,
          superlikesLimit: 3,
          profileBoost: 1,
        );
      }

      if (mounted) {
        setState(() {
          _tiers = fetchedTiers;
          _userStatus = status;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openCheckout(PaymentTier tier) {
    _processPayment(tier.tier);
  }

  Future<void> _processPayment(String tierKey) async {
    setState(() => _isLoading = true);

    try {
      // 1. App requests order creation from backend
      final order = await PaymentService.createSubscription(tierKey);

      // 2. Open official Razorpay Checkout UI
      final options = {
        'key': order.keyId,
        'amount': order.amount,
        'name': 'FRND Premium',
        'description': order.tierName,
        'subscription_id': order.subscriptionId,
        'currency': order.currency,
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#0A0A0A'}
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showFailureDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() => _isLoading = true);
      
      // Razorpay Flutter plugin stores the raw response map in `data`. For subscriptions,
      // it returns `razorpay_subscription_id` instead of `razorpay_order_id`.
      final String subId = response.data?['razorpay_subscription_id'] ?? response.orderId ?? '';
      
      // 3. Send signature and IDs to backend for verification
      final verifiedStatus = await PaymentService.verifySubscription(
        subscriptionId: subId,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog('🎉 Pass activated! (${verifiedStatus.validityDaysRemaining} days remaining)');
        _loadData(); // Refresh UI
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showFailureDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isLoading = false);
      _showFailureDialog('Payment failed or was cancelled. Please try again.');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isLoading = false);
      _showFailureDialog('External wallets not supported for Autopay.');
    }
  }

  Future<void> _handleCancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        actionsAlignment: MainAxisAlignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.textColor1, width: 2),
        ),
        title: Text(
          'CANCEL AUTOPAY?',
          style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to cancel recurring payments? Your benefits remain active until your current 28-day billing period ends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KEEP AUTOPAY', style: TextStyle(color: AppColors.textColor1)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textColor1,
              foregroundColor: AppColors.cream,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CANCEL AUTOPAY'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PaymentService.cancelSubscription();
        if (mounted) {
          _showSuccessDialog('Autopay cancelled. Pass benefits stay active until period expires.');
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          _showFailureDialog(e.toString());
        }
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        actionsAlignment: MainAxisAlignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.textColor1, width: 2.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.stars, color: AppColors.textColor1, size: 28),
            const SizedBox(width: 8),
            Text(
              'PASS UNLOCKED! ✦',
              style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          SketchyButton(
            text: 'START SWIPING',
            showSparkles: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        actionsAlignment: MainAxisAlignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.textColor1, width: 2.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.textColor1, size: 28),
            const SizedBox(width: 8),
            Text(
              'PAYMENT ERROR',
              style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          SketchyButton(
            text: 'RETRY PAYMENT',
            showSparkles: false,
            onPressed: () {
              Navigator.pop(context);
              final tier = _tiers[_selectedTierKey];
              if (tier != null) _openCheckout(tier);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTier = _tiers[_selectedTierKey] ??
        const PaymentTier(
          tier: 'gold',
          name: 'Gold Pass Autopay',
          priceINR: 49,
          pricePaise: 4900,
          validityDays: 28,
          likesLimit: 50,
          superlikesLimit: 12,
          profileBoost: 6,
          isAutopay: true,
        );

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textColor1),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PREMIUM PASSES ✦',
          style: GoogleFonts.spaceMono(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
            color: AppColors.textColor1,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.textColor1, height: 2),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColor1),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Active Status Header Card
                    _buildActiveStatusCard(),
                    const SizedBox(height: 24),

                    // Section Title
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '✦ SELECT YOUR PASS ✦',
                            style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.2,
                              color: AppColors.textColor1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tier Selector Cards (Silver vs Gold)
                    _buildTierSelectorRow(),
                    const SizedBox(height: 24),


                    // Feature Matrix Table
                    _buildComparisonMatrix(),
                    const SizedBox(height: 28),

                    // Action CTA Button
                    SketchyButton(
                      text: 'CLAIM ${selectedTier.tier.toUpperCase()} PASS — ₹${selectedTier.priceINR}',
                      onPressed: () => _openCheckout(selectedTier),
                    ),
                    const SizedBox(height: 12),

                    // Autopay Notice
                    Center(
                      child: Text(
                        'Razorpay Autopay renews every 28 days. Cancel anytime.',
                        style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.textColor1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActiveStatusCard() {
    final isPremium = _userStatus?.isPremium ?? false;
    final currentTierName = (_userStatus?.tier ?? 'free').toUpperCase();
    final remainingDays = _userStatus?.validityDaysRemaining ?? 0;
    final autopayStatus = _userStatus?.autopayStatus ?? 'none';

    return SketchyContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: isPremium ? AppColors.textColor1 : AppColors.cream,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isPremium ? Icons.workspace_premium : Icons.stars_outlined,
                    color: isPremium ? AppColors.cream : AppColors.textColor1,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STATUS: $currentTierName PASS',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isPremium ? AppColors.cream : AppColors.textColor1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPremium ? AppColors.cream : AppColors.textColor1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPremium ? 'ACTIVE ✦' : 'FREE TIER',
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: isPremium ? AppColors.textColor1 : AppColors.cream,
                  ),
                ),
              ),
            ],
          ),
          if (isPremium) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Validity: $remainingDays Days Remaining',
                  style: GoogleFonts.spaceMono(fontSize: 12, color: AppColors.cream),
                ),
                if (autopayStatus == 'active')
                  GestureDetector(
                    onTap: _handleCancelSubscription,
                    child: Text(
                      'CANCEL AUTOPAY',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: AppColors.cream,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTierSelectorRow() {
    final silver = _tiers['silver'] ??
        const PaymentTier(
          tier: 'silver',
          name: 'Silver Pass',
          priceINR: 39,
          pricePaise: 3900,
          validityDays: 28,
          likesLimit: 25,
          superlikesLimit: 6,
          profileBoost: 3,
          isAutopay: true,
        );

    final gold = _tiers['gold'] ??
        const PaymentTier(
          tier: 'gold',
          name: 'Gold Pass',
          priceINR: 49,
          pricePaise: 4900,
          validityDays: 28,
          likesLimit: 50,
          superlikesLimit: 12,
          profileBoost: 6,
          isAutopay: true,
        );

    return Row(
      children: [
        // Silver Pass Card
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTierKey = 'silver'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedTierKey == 'silver' ? AppColors.textColor1 : AppColors.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.textColor1, width: 2.5),
              ),
              child: Column(
                children: [
                  Text(
                    'SILVER PASS',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _selectedTierKey == 'silver' ? AppColors.cream : AppColors.textColor1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${silver.priceINR} / 28 Days',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _selectedTierKey == 'silver' ? AppColors.cream : AppColors.textColor1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '3x Profile Boost\n25 Likes / Day\n6 Superlikes / Day',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: _selectedTierKey == 'silver' ? AppColors.cream : AppColors.textColor1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Gold Pass Card
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTierKey = 'gold'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedTierKey == 'gold' ? AppColors.textColor1 : AppColors.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.textColor1, width: 2.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _selectedTierKey == 'gold' ? AppColors.cream : AppColors.textColor1,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'BEST VALUE ✦',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _selectedTierKey == 'gold' ? AppColors.textColor1 : AppColors.cream,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GOLD PASS',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _selectedTierKey == 'gold' ? AppColors.cream : AppColors.textColor1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${gold.priceINR} / 28 Days',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _selectedTierKey == 'gold' ? AppColors.cream : AppColors.textColor1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '6x Max Boost\n50 Likes / Day\n12 Superlikes / Day',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: _selectedTierKey == 'gold' ? AppColors.cream : AppColors.textColor1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildComparisonMatrix() {
    return SketchyContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TIER COMPARISON MATRIX',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.textColor1, height: 1),
          const SizedBox(height: 8),
          _buildMatrixRow('Feature', 'Free', 'Silver', 'Gold', isHeader: true),
          const Divider(color: AppColors.textColor1, height: 1),
          _buildMatrixRow('Likes / Day', '15', '25', '50'),
          _buildMatrixRow('Superlikes / Day', '3', '6', '12'),
          _buildMatrixRow('Feed Boost', '1x Standard', '3x Higher', '6x Maximum'),
          _buildMatrixRow('Autopay Price', '₹0', '₹39 / mo', '₹49 / mo'),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(String feature, String free, String silver, String gold, {bool isHeader = false}) {
    final style = GoogleFonts.spaceMono(
      fontSize: isHeader ? 11 : 10,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: AppColors.textColor1,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(feature, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(free, textAlign: TextAlign.center, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(silver, textAlign: TextAlign.center, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(gold, textAlign: TextAlign.center, style: style),
          ),
        ],
      ),
    );
  }
}
