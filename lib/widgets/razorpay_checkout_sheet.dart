import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/payment_models.dart';
import 'sketchy_button.dart';
import 'sketchy_container.dart';

enum PaymentMethodType { upi, card, netbanking }

class RazorpayCheckoutSheet extends StatefulWidget {
  final PaymentTier tier;
  final Function(PaymentMethodType method, String methodDetail) onPay;

  const RazorpayCheckoutSheet({
    super.key,
    required this.tier,
    required this.onPay,
  });

  static Future<void> show({
    required BuildContext context,
    required PaymentTier tier,
    required Function(PaymentMethodType method, String methodDetail) onPay,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RazorpayCheckoutSheet(
        tier: tier,
        onPay: onPay,
      ),
    );
  }

  @override
  State<RazorpayCheckoutSheet> createState() => _RazorpayCheckoutSheetState();
}

class _RazorpayCheckoutSheetState extends State<RazorpayCheckoutSheet> {
  PaymentMethodType _selectedMethod = PaymentMethodType.upi;
  final TextEditingController _detailController = TextEditingController(text: 'user@upi');

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.inkBlack, width: 3),
          left: BorderSide(color: AppColors.inkBlack, width: 3),
          right: BorderSide(color: AppColors.inkBlack, width: 3),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkBlack,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.inkBlack, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'RAZORPAY CHECKOUT',
                      style: GoogleFonts.spaceMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.1,
                        color: AppColors.inkBlack,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.inkBlack, width: 2),
                    ),
                    child: const Icon(Icons.close, size: 16, color: AppColors.inkBlack),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order Summary Card
            SketchyContainer(
              backgroundColor: AppColors.inkBlack,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.tier.name.toUpperCase(),
                        style: GoogleFonts.spaceMono(
                          color: AppColors.cream,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '₹${widget.tier.priceINR}.00',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Billing Cycle: 30 Days Autopay',
                        style: TextStyle(color: AppColors.cream, fontSize: 11),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'AUTOPAY',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select Payment Method Header
            Text(
              'SELECT PAYMENT METHOD',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.inkBlack,
              ),
            ),
            const SizedBox(height: 12),

            // Payment Options
            _buildMethodOption(
              type: PaymentMethodType.upi,
              title: 'UPI / Instant Autopay',
              subtitle: 'GPay, PhonePe, Paytm, BHIM UPI',
              icon: Icons.qr_code_scanner,
              hint: 'Enter VPA / UPI ID (e.g. user@upi)',
            ),
            const SizedBox(height: 10),
            _buildMethodOption(
              type: PaymentMethodType.card,
              title: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, RuPay Cards',
              icon: Icons.credit_card,
              hint: 'Enter Card Number',
            ),
            const SizedBox(height: 10),
            _buildMethodOption(
              type: PaymentMethodType.netbanking,
              title: 'Netbanking',
              subtitle: 'SBI, HDFC, ICICI, Axis Bank',
              icon: Icons.account_balance,
              hint: 'Select Bank Name',
            ),
            const SizedBox(height: 20),

            // Method Input Field
            Text(
              _getMethodLabel(),
              style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _detailController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: AppColors.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inkBlack, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inkBlack, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inkBlack, width: 2.5),
                ),
              ),
              style: GoogleFonts.spaceMono(fontSize: 13, color: AppColors.inkBlack),
            ),
            const SizedBox(height: 24),

            // Security Notice
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: AppColors.inkBlack),
                SizedBox(width: 6),
                Text(
                  '256-Bit SSL Encrypted • Powered by Razorpay',
                  style: TextStyle(fontSize: 11, color: AppColors.inkBlack),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pay Action CTA Button
            SketchyButton(
              text: 'PAY ₹${widget.tier.priceINR} & SUBSCRIBE ✦',
              onPressed: () {
                Navigator.pop(context);
                widget.onPay(_selectedMethod, _detailController.text);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMethodLabel() {
    switch (_selectedMethod) {
      case PaymentMethodType.upi:
        return 'VPA / UPI ID';
      case PaymentMethodType.card:
        return 'Card Number (Mock Reference)';
      case PaymentMethodType.netbanking:
        return 'Selected Bank';
    }
  }

  Widget _buildMethodOption({
    required PaymentMethodType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required String hint,
  }) {
    final isSelected = _selectedMethod == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = type;
          if (type == PaymentMethodType.upi) {
            _detailController.text = 'user@upi';
          } else if (type == PaymentMethodType.card) {
            _detailController.text = '4111 •••• •••• 1111';
          } else {
            _detailController.text = 'HDFC Bank';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.inkBlack : AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inkBlack, width: 2),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.cream : AppColors.inkBlack,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? AppColors.cream : AppColors.inkBlack,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? AppColors.cream : AppColors.inkBlack,
                    ),
                  ),
                ],
              ),
            ),
            Radio<PaymentMethodType>(
              value: type,
              groupValue: _selectedMethod,
              activeColor: AppColors.cream,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedMethod = val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
