import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../services/auth_service.dart';
import '../../config/dev_config.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  bool _isVerifying = false;
  bool _isResending = false;

  // Resend limits: 2-min cooldown, max 3 resends
  static const int _cooldownSeconds = 120;
  static const int _maxResends = 3;
  int _resendCount = 0;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── OTP verification ────────────────────────────────────────────────────────
  Future<void> _onVerify() async {
    if (DevConfig.bypassAuth) {
      Navigator.pushReplacementNamed(context, '/setup');
      return;
    }

    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showSnackBar('Please enter the code sent to your email.');
      return;
    }

    setState(() => _isVerifying = true);
    final success = await AuthService.verifyOtp(otp);
    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/setup');
    } else {
      _showSnackBar('Incorrect code. Please try again.');
    }
  }

  // ── Resend OTP ──────────────────────────────────────────────────────────────
  Future<void> _onResend() async {
    if (_resendCount >= _maxResends) {
      _showSnackBar('Maximum resends reached. Please restart the sign-up process.');
      return;
    }
    if (_cooldownRemaining > 0) return; // button is disabled, safety guard

    setState(() => _isResending = true);
    final success = await AuthService.resendOtp();
    setState(() => _isResending = false);

    if (!mounted) return;

    if (success) {
      setState(() {
        _resendCount++;
        _cooldownRemaining = _cooldownSeconds;
      });
      _startCooldown();
      _showSnackBar('A new code has been sent to your email.');
    } else {
      _showSnackBar('Could not resend code. Please try again later.');
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownRemaining--);
      if (_cooldownRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String get _resendButtonLabel {
    final int left = _maxResends - _resendCount;
    if (left <= 0) return 'No resends left';
    if (_cooldownRemaining > 0) {
      final mins = _cooldownRemaining ~/ 60;
      final secs = _cooldownRemaining % 60;
      final timeStr = mins > 0
          ? '${mins}m ${secs.toString().padLeft(2, '0')}s'
          : '${secs}s';
      return 'Resend in $timeStr ($left left)';
    }
    return "Didn't get the code? Resend ($left left)";
  }

  bool get _canResend =>
      _cooldownRemaining <= 0 && _resendCount < _maxResends && !_isResending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VERIFY')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CHECK YOUR EMAIL',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit verification code to your college email.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cooldown: 2 minutes • Maximum 3 resends',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6) ?? Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Text(
                'ENTER SECRET CODE',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              SketchyContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '- - - - - -',
                    counterText: '',
                  ),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 16),

              // Resend OTP link
              Center(
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _canResend ? _onResend : null,
                        child: Text(
                          _resendButtonLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _canResend
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).disabledColor,
                              ),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              if (_isVerifying)
                const Center(child: CircularProgressIndicator())
              else
                SketchyButton(
                  text: 'VERIFY & ENTER',
                  onPressed: _onVerify,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
