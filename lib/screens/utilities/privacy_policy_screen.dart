import 'package:flutter/material.dart';
import '../../widgets/sketchy_container.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFFA41534)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFFA41534), // Burgundy color
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.5,
          color: Color(0xFF333333),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA41534),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF4E5), // Cream background
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFA41534).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.privacy_tip_outlined,
                color: Color(0xFFA41534),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PRIVACY POLICY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(height: 1.0, color: const Color(0x121A1A1A)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SketchyContainer(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildText('We value your privacy and implement comprehensive security measures to protect your personal information and interactions on FRND Campus.'),

                const Divider(height: 20, thickness: 1, color: Color(0x1F000000)),

                _buildSectionTitle('Information We Collect', icon: Icons.folder_open_outlined),
                _buildText('We collect information you provide directly to us and information we obtain automatically when you use our services.'),
                
                _buildSubTitle('Personal Information:'),
                _buildBulletPoint('Phone number and/or Email address (via Authentication)'),
                _buildBulletPoint('Display name, age, gender, and profile pictures'),
                _buildBulletPoint('Educational information (School/College, Course) for verification'),
                _buildBulletPoint('Account creation, last login timestamps, and user preferences'),

                _buildSubTitle('Payment Information:'),
                _buildBulletPoint('Payment transaction IDs (via Google Play Billing)'),
                _buildBulletPoint('Payment status and subscription details (Silver and Gold Passes)'),
                _buildBulletPoint('Billing information processed by Google Play'),
                _buildBulletPoint('Payment timestamps and amounts'),

                _buildSubTitle('Usage Information:'),
                _buildBulletPoint('Swipe history (Likes, Superlikes, Passes) and Matches'),
                _buildBulletPoint('Feature usage patterns (e.g., anonymous posts, chat frequency)'),
                _buildBulletPoint('Device information and app version'),
                _buildBulletPoint('IP address and general location data for distance calculations'),

                _buildSectionTitle('How We Use Your Information', icon: Icons.insights_outlined),
                _buildBulletPoint('To provide and maintain our campus socializing and matching services'),
                _buildBulletPoint('To process payments and manage premium subscriptions via Google Play Billing'),
                _buildBulletPoint('To manage your account, daily swipe quotas, and subscription status'),
                _buildBulletPoint('To communicate with you about your account, matches, and service updates'),
                _buildBulletPoint('To verify student identity and ensure a safe community environment'),
                _buildBulletPoint('To comply with legal obligations and prevent fraud or abuse'),
                _buildBulletPoint('To provide customer support and technical assistance'),
                _buildBulletPoint('To analyze usage patterns for service optimization and better match recommendations'),

                _buildSectionTitle('Payment Processing', icon: Icons.payment_outlined),
                _buildText('All premium subscription payments are processed exclusively through Google Play Billing. Google Play is PCI DSS compliant and follows industry best practices for secure payment handling.'),
                
                _buildSubTitle('Payment Data Handling:'),
                _buildBulletPoint('We do not store your complete payment card or bank details'),
                _buildBulletPoint('Google Play securely processes all payment information and manages subscription renewals'),
                _buildBulletPoint('We only store purchase tokens, subscription status, and payment logs'),
                _buildBulletPoint('All payment data is encrypted in transit and at rest'),
                _buildBulletPoint('Refunds are handled through Google Play\'s standard refund process'),

                _buildSectionTitle('Data Security & Privacy', icon: Icons.security_outlined),
                _buildText('We implement comprehensive security measures to protect your personal information and ensure the privacy of your interactions on Frnd.'),

                _buildSubTitle('Data Protection & Anonymity:'),
                _buildBulletPoint('Private chat messages are securely transmitted and stored'),
                _buildBulletPoint('Anonymous posts and confessions are kept strictly disassociated from your public profile'),
                _buildBulletPoint('Profile pictures and data are accessible only to other verified users within the platform'),
                _buildBulletPoint('Strict access controls prevent unauthorized access to your account data'),

                _buildSubTitle('Data Protection:'),
                _buildBulletPoint('Robust backend security rules prevent unauthorized access to user data'),
                _buildBulletPoint('All data transmission uses HTTPS/TLS encryption'),
                _buildBulletPoint('Regular security audits, monitoring, and automated moderation for safety'),
                _buildBulletPoint('Compliance with applicable data protection and privacy regulations'),

                _buildSectionTitle('Your Rights & Choices', icon: Icons.rule_outlined),
                _buildBulletPoint('Access and review your personal information'),
                _buildBulletPoint('Request correction of inaccurate data'),
                _buildBulletPoint('Delete your account and associated data'),
                _buildBulletPoint('Opt-out of non-essential communications'),
                _buildBulletPoint('Request data portability in machine-readable format'),
                _buildBulletPoint('Withdraw consent for data processing'),
                _buildBulletPoint('File complaints with data protection authorities'),

                _buildSectionTitle('Data Retention & Sharing', icon: Icons.dataset_outlined),
                _buildSubTitle('Data Retention:'),
                _buildBulletPoint('Account data and matches retained while your account is active'),
                _buildBulletPoint('Payment records kept for 7 years for compliance'),
                _buildBulletPoint('Usage logs and chat history retained according to our data policies for service improvement and safety'),
                _buildBulletPoint('Deleted account data purged within 30 days'),

                _buildSubTitle('Data Sharing:'),
                _buildBulletPoint('We do not sell personal information to third parties'),
                _buildBulletPoint('Payment data shared only with Google Play for processing'),
                _buildBulletPoint('Legal compliance or safety investigations may require data disclosure'),
                _buildBulletPoint('Service providers bound by strict confidentiality agreements'),

                _buildSectionTitle('Contact Us', icon: Icons.contact_support_outlined),
                _buildText('If you have questions about this Privacy Policy or our data practices, please contact us:'),
                _buildText('Email: contact@frnd.buzz\nAddress: Barasat, Kolkata 700126'),
                _buildText('We will respond to privacy inquiries within 30 days.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
