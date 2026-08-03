import 'package:flutter/material.dart';
import '../../widgets/sketchy_container.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Color(0xFFA41534), // Burgundy color
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFA41534))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
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
        title: const Text(
          'TERMS OF SERVICE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: 2.0,
          ),
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms of Service & Mutual Accountability',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildText('FRND Campus is built exclusively for verified university students who demand an elevated, transparent academic network. We assume strict operational accountability for platform security, transparent Autopay mechanics, and unconditional 24-hour refunds.'),
                
                _buildSectionTitle('01. Student Eligibility & Authenticity'),
                _buildText('FRND Campus is a private academic community. Access is strictly forbidden to non-students, general public accounts, and automated advertisers. Admission demands complete adherence to real identity verification.'),
                _buildSubTitle('Active University Enrollment'),
                _buildText('You must be aged 18 or above and actively enrolled in an accredited college or university. All registrations must be completed using an official institutional university email verified via live OTP challenge.'),
                _buildSubTitle('Strict Anti-Forgery Policy'),
                _buildText('Submitting fabricated student ID cards, altered institutional letters, or stolen photographs is treated as fraudulent imitation. We assume full operational responsibility to execute immediate hardware and network expulsion.'),

                _buildSectionTitle('02. Zero-Tolerance Conduct & Moderation'),
                _buildText('We accept proactive operational responsibility to monitor and eliminate harassment from our campus ecosystem. Engaging in any of the following strictly prohibited violations results in instantaneous account termination:'),
                _buildSubTitle('A. Harassment & Intimidation'),
                _buildText('Unwelcome advances, cyberstalking, discriminatory insults, or threats carry zero tolerance. We hold ourselves responsible for preserving incident transcripts to assist affected students in official university discipline or legal investigations.'),
                _buildSubTitle('B. Non-Consensual & Explicit Media'),
                _buildText('Sharing explicit imagery without explicit mutual consent or uploading illegal media results in automated blacklisting across device IMEIs and network signatures.'),
                _buildSubTitle('C. Bot Automation & Commercial Spam'),
                _buildText('Deploying automated swiping scripts, data scraping crawlers, or utilizing student feeds to advertise commercial MLMs, surveys, or external merchandise is strictly forbidden.'),

                _buildSectionTitle('03. 24-Hour Refund & Financial Policy'),
                _buildSubTitle('Unconditional 24-Hour Cooling-Off Period'),
                _buildText('We stand against financial traps. If you activate a Silver Pass or Gold Pass and determine within the first 24 hours that the service does not meet your expectations, you are entitled to request an immediate, unconditional 100% full refund—no questions asked. Refunds process in 5 to 7 days via Razorpay.'),
                _buildSubTitle('When Refunds ARE Granted (100% Guaranteed Reversal)'),
                _buildBulletPoint('Within the 24-Hour Grace Period: Any subscription refund requested within the initial 24 hours of checkout is automatically verified.'),
                _buildBulletPoint('Technical Double-Billing Anomalies: Duplicate debits due to network glitches are fully refunded within 5 to 7 business days.'),
                _buildBulletPoint('Server Provisioning Latency: If cloud latency prevents your premium privileges from unlocking within 24 hours of settlement, you are guaranteed an automated full financial reversal.'),
                _buildSubTitle('When Refunds ARE NOT Granted (Strict Service Exceptions)'),
                _buildBulletPoint('Post-24 Hour Window & Active Consumption: Once the initial 24-hour cooling-off window expires and digital allowances have been actively utilized, the fee becomes non-refundable.'),
                _buildBulletPoint('Subjective Social Match Volume: Because romantic matching relies on mutual interpersonal spark, refunds cannot be granted based on subjective romantic connection counts.'),
                _buildBulletPoint('Disciplinary Safety Expulsion: If an account is suspended or terminated due to documented harassment or hate speech, any unused remaining pass time is immediately forfeited.'),

                _buildSectionTitle('04. Cancellation Reasoning & Protocol'),
                _buildText('You retain complete operational authority over your subscription mandates without predatory lock-in mechanics. Silver and Gold Passes run on a recurring 30-day mandate for uninterrupted campus visibility.'),
                _buildSubTitle('No Mid-Month Pro-Rating'),
                _buildText('When a 30-day cycle starts, compute and exposure allowances are provisioned upfront upon settlement. Fractional refunds cannot be calculated mid-cycle. When canceled, benefits remain fully active until the final minute of Day 30.'),
                _buildSubTitle('3-Step Instant Autopay Termination'),
                _buildBulletPoint('01. Open Profile Settings.'),
                _buildBulletPoint('02. Select Manage Subscription (Active Silver/Gold Pass & Autopay Mandate).'),
                _buildBulletPoint('03. Select Cancel Autopay. Razorpay immediately revokes recurring debit mandates.'),

                _buildSectionTitle('05. Offline Safety & Liability Bounds'),
                _buildText('While FRND assumes absolute operational accountability for applying rigorous software encryption and rapid moderation within our software bounds, we cannot exercise direct supervision over off-platform interactions or physical real-world campus encounters.'),
                _buildSubTitle('Mandatory Student Safety Protocol'),
                _buildBulletPoint('Always arrange introductory meetings in well-lit, publicly visible campus zones.'),
                _buildBulletPoint('Never disclose sensitive residence hall room numbers, private building entry access codes, or financial passwords to new peers.'),
                _buildBulletPoint('Notify roommates or trusted friends of your meetup schedule and contact campus emergency services immediately if an interaction ever feels coercive or unsafe.'),

                _buildSectionTitle('06. Governing Law & Jurisdiction'),
                _buildText('This binding legal covenant and all functional interactions within FRND Campus are governed strictly by the legislation of the Republic of India. Any disputation arising from platform utilization shall rest under the sole, exclusive jurisdiction of the competent courts in Kolkata, West Bengal, India.'),

                _buildSectionTitle('Frequently Asked Queries'),
                _buildSubTitle('How does the 24-hour refund policy work if I change my mind after purchasing?'),
                _buildText('We honor an unconditional 24-hour refund window starting from the exact timestamp of your purchase. You can request an immediate refund via app settings or our support desk. Razorpay will reverse the transaction directly to your source bank account or UPI wallet within 5 to 7 business days.'),
                _buildSubTitle('If I cancel my Autopay subscription mid-cycle, what happens to my privileges?'),
                _buildText('Your Silver or Gold Pass benefits remain completely active and uninterrupted until Day 30 at 11:59 PM. Canceling Autopay simply ensures your card or UPI will not be automatically debited for the subsequent monthly cycle.'),
                _buildSubTitle('Why don\'t you offer prorated partial refunds if I stop using the app after week one?'),
                _buildText('Because network server compute and matching slot priorities are provisioned upfront upon settlement, partial fractional refunds cannot be calculated once the initial 24-hour cooling-off grace period has expired.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
