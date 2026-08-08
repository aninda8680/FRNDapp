import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../services/payment_service.dart';
import '../../services/play_billing_service.dart';
import '../../models/payment_models.dart';
import '../../utils/responsive_utils.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String _selectedTierKey = 'gold';

  /// Active subscription status (from backend, authoritative).
  SubscriptionStatus? _userStatus;

  /// Product details loaded from Play Console.
  Map<String, PaymentTier> _tiers = PaymentService.kDefaultTiers;

  // Tracks the currently active product ID (for proration on upgrade/downgrade).
  String? _activeProductId;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen to purchase results and update UI accordingly.
    PlayBillingService.instance.onPurchaseResult.listen(_handlePurchaseResult);
  }

  Future<void> _loadData() async {
    // Load Play Console products (for prices).
    await PlayBillingService.instance.loadProducts();

    // Load tier info + user status from backend.
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
          if (fetchedTiers.isNotEmpty) _tiers = fetchedTiers;
          _userStatus = status;
          // Map active tier to Play product ID.
          if (status != null && status.tier == 'silver') {
            _activeProductId = kSilverPassId;
          } else if (status != null && status.tier == 'gold') {
            _activeProductId = kGoldPassId;
          }
        });
      }
    } catch (_) {
      // Keep defaults silently.
    }
  }

  void _handlePurchaseResult(PlayPurchaseResult result) {
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result.status) {
      case PlayPurchaseStatus.success:
        _showSuccessDialog(result.message);
        _loadData(); // Refresh status from backend.

      case PlayPurchaseStatus.pending:
        _showInfoDialog(
          '⏳ Purchase Pending',
          result.message,
        );

      case PlayPurchaseStatus.cancelled:
        // Silent — user dismissed the sheet. No dialog needed.
        break;

      case PlayPurchaseStatus.failed:
        _showFailureDialog(result.message);

      case PlayPurchaseStatus.unavailable:
        _showFailureDialog(result.message);
    }
  }

  Future<void> _startPurchase(String productId) async {
    setState(() => _isLoading = true);

    // If the user already has an active subscription, initiate a proration
    // replacement (upgrade/downgrade) rather than a separate new purchase.
    final String? oldProductId =
        (_activeProductId != null && _activeProductId != productId)
            ? _activeProductId
            : null;

    await PlayBillingService.instance.purchaseTier(
      productId: productId,
      currentProductId: oldProductId,
    );
    // Result arrives async via onPurchaseResult → _handlePurchaseResult.
  }

  Future<void> _openManageSubscriptions() async {
    final uri = PaymentService.getPlayManageSubscriptionsUri(
      productId: _activeProductId,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Play. Please manage your subscription there.'),
        ),
      );
    }
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

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
              'PURCHASE ERROR',
              style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          SketchyButton(
            text: 'CLOSE',
            showSparkles: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        actionsAlignment: MainAxisAlignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.textColor1, width: 2.5),
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Text(message),
        actions: [
          SketchyButton(
            text: 'OK',
            showSparkles: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedTier = _tiers[_selectedTierKey] ?? _tiers['gold']!;
    final playProducts = PlayBillingService.instance.products;

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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Status Header Card
                  _buildActiveStatusCard(),
                  SizedBox(height: context.responsiveHeight(24)),

                  // Section Title
                  Center(
                    child: Text(
                      '✦ SELECT YOUR PASS ✦',
                      style: GoogleFonts.spaceMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                        color: AppColors.textColor1,
                      ),
                    ),
                  ),
                  SizedBox(height: context.responsiveHeight(20)),

                  // Tier Selector Cards (Silver vs Gold)
                  _buildTierSelectorRow(playProducts),
                  SizedBox(height: context.responsiveHeight(24)),

                  // Feature Comparison Matrix
                  _buildComparisonMatrix(),
                  SizedBox(height: context.responsiveHeight(28)),

                  // CTA — subscribe via Google Play
                  SketchyButton(
                    text: 'SUBSCRIBE VIA GOOGLE PLAY ✦',
                    onPressed: _isLoading
                        ? () {}
                        : () => _startPurchase(
                              _selectedTierKey == 'silver'
                                  ? kSilverPassId
                                  : kGoldPassId,
                            ),
                  ),
                  SizedBox(height: context.responsiveHeight(12)),

                  // Billing notice
                  Center(
                    child: Text(
                      'Billed via Google Play. Renews every 28 days.\nCancel anytime from Google Play.',
                      style: GoogleFonts.spaceMono(
                          fontSize: 10, color: AppColors.textColor1),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: context.responsiveHeight(8)),

                  // Play Billing badge
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.security, size: 14, color: AppColors.textColor1),
                        const SizedBox(width: 6),
                        Text(
                          'Secured by Google Play Billing',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10, color: AppColors.textColor1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.textColor1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStatusCard() {
    final isPremium = _userStatus?.isPremium ?? false;
    final currentTierName = (_userStatus?.tier ?? 'free').toUpperCase();
    final remainingDays = _userStatus?.validityDaysRemaining ?? 0;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            SizedBox(height: context.responsiveHeight(12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Validity: $remainingDays Days Remaining',
                  style: GoogleFonts.spaceMono(
                      fontSize: 12, color: AppColors.cream),
                ),
                // Cancellation is now handled via Google Play.
                GestureDetector(
                  onTap: _openManageSubscriptions,
                  child: Text(
                    'MANAGE IN PLAY',
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

  Widget _buildTierSelectorRow(Map<String, ProductDetails> playProducts) {
    final silver = _tiers['silver'] ?? _tiers['gold']!;
    final gold = _tiers['gold'] ?? silver;

    // Use Play Console price string if available (authoritative), else fallback.
    final silverPrice = playProducts[kSilverPassId]?.price ?? '₹${silver.priceINR}';
    final goldPrice = playProducts[kGoldPassId]?.price ?? '₹${gold.priceINR}';

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
                color: _selectedTierKey == 'silver'
                    ? AppColors.textColor1
                    : AppColors.cream,
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
                      color: _selectedTierKey == 'silver'
                          ? AppColors.cream
                          : AppColors.textColor1,
                    ),
                  ),
                  SizedBox(height: context.responsiveHeight(6)),
                  Text(
                    '$silverPrice / 28 Days',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _selectedTierKey == 'silver'
                          ? AppColors.cream
                          : AppColors.textColor1,
                    ),
                  ),
                  SizedBox(height: context.responsiveHeight(8)),
                  Text(
                    '3x Profile Boost\n25 Likes / Day\n6 Superlikes / Day',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: _selectedTierKey == 'silver'
                          ? AppColors.cream
                          : AppColors.textColor1,
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
                color: _selectedTierKey == 'gold'
                    ? AppColors.textColor1
                    : AppColors.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.textColor1, width: 2.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _selectedTierKey == 'gold'
                          ? AppColors.cream
                          : AppColors.textColor1,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'BEST VALUE ✦',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _selectedTierKey == 'gold'
                            ? AppColors.textColor1
                            : AppColors.cream,
                      ),
                    ),
                  ),
                  SizedBox(height: context.responsiveHeight(4)),
                  Text(
                    'GOLD PASS',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _selectedTierKey == 'gold'
                          ? AppColors.cream
                          : AppColors.textColor1,
                    ),
                  ),
                  SizedBox(height: context.responsiveHeight(4)),
                  Text(
                    '$goldPrice / 28 Days',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _selectedTierKey == 'gold'
                          ? AppColors.cream
                          : AppColors.textColor1,
                    ),
                  ),
                  SizedBox(height: context.responsiveHeight(8)),
                  Text(
                    '6x Max Boost\n50 Likes / Day\n12 Superlikes / Day',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: _selectedTierKey == 'gold'
                          ? AppColors.cream
                          : AppColors.textColor1,
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
          SizedBox(height: context.responsiveHeight(12)),
          const Divider(color: AppColors.textColor1, height: 1),
          SizedBox(height: context.responsiveHeight(8)),
          _buildMatrixRow('Feature', 'Free', 'Silver', 'Gold', isHeader: true),
          const Divider(color: AppColors.textColor1, height: 1),
          _buildMatrixRow('Likes / Day', '15', '25', '50'),
          _buildMatrixRow('Superlikes / Day', '3', '6', '12'),
          _buildMatrixRow('Feed Boost', '1x Standard', '3x Higher', '6x Maximum'),
          _buildMatrixRow('Price', '₹0', '₹39 / mo', '₹49 / mo'),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(
    String feature,
    String free,
    String silver,
    String gold, {
    bool isHeader = false,
  }) {
    final style = GoogleFonts.spaceMono(
      fontSize: isHeader ? 11 : 10,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: AppColors.textColor1,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(feature, style: style)),
          Expanded(
              flex: 2,
              child: Text(free, textAlign: TextAlign.center, style: style)),
          Expanded(
              flex: 2,
              child: Text(silver, textAlign: TextAlign.center, style: style)),
          Expanded(
              flex: 2,
              child: Text(gold, textAlign: TextAlign.center, style: style)),
        ],
      ),
    );
  }
}
