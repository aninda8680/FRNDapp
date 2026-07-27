import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../services/auth_service.dart';
import '../../config/dev_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _showForgotPassword = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TopNotification(
        message: message,
        onDismissed: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _onSignUpLogin() async {
    // ── Dev bypass ────────────────────────────────────────────────────────────
    if (DevConfig.bypassAuth) {
      Navigator.pushNamed(context, '/otp');
      return;
    }

    // ── Validation ────────────────────────────────────────────────────────────
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter your college email and password.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.signupOrLogin(email, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    switch (result) {
      case AuthResult.success:
        // Existing user, correct password
        // Fetch profile to see if it's fully setup
        final profile = await AuthService.getProfile();
        if (!mounted) return;
        
        if (AuthService.isProfileComplete(profile)) {
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          Navigator.pushReplacementNamed(context, '/setup');
        }
        break;

      case AuthResult.wrongPassword:
        // Existing user, wrong password → tell them & reveal forgot-password link
        _showSnackBar('Wrong password. Please try again.');
        setState(() => _showForgotPassword = true);
        break;

      case AuthResult.needsOtp:
        // New user → OTP was sent → open OTP verification screen
        Navigator.pushReplacementNamed(context, '/otp');
        break;

      case AuthResult.failure:
        _showSnackBar('Something went wrong. Please try again.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Get Verified')),
      body: SafeArea(
        child: Stack(
          children: [
            // Background illustration — blurs when keyboard is up
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: isKeyboardVisible ? 6.0 : 0.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, blurValue, child) {
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: blurValue.clamp(0.001, 10.0),
                      sigmaY: blurValue.clamp(0.001, 10.0),
                    ),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/login.png',
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Form content
            CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 5),

                        // Email field
                        Text(
                          'ENTER COLLEGE ID',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        SketchyContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'student@college.edu',
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        Text(
                          'PASSWORD',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        SketchyContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter password',
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),

                        const Spacer(),

                        // Action button
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          SketchyButton(
                            text: 'SIGN UP / LOGIN',
                            onPressed: _onSignUpLogin,
                          ),

                        // Forgot password — only visible after a wrong-password attempt
                        if (_showForgotPassword) ...[  
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () async {
                                final email = _emailController.text.trim();
                                if (email.isEmpty) {
                                  _showSnackBar('Enter your email above first.');
                                  return;
                                }
                                final sent = await AuthService.forgotPassword(email);
                                if (!mounted) return;
                                _showSnackBar(
                                  sent
                                      ? 'If that email is registered, a reset link has been sent.'
                                      : 'Could not send reset link. Please try again.',
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TopNotification extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;

  const TopNotification({
    super.key,
    required this.message,
    required this.onDismissed,
  });

  @override
  State<TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<TopNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF323232), // Standard SnackBar dark gray
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Text(
              widget.message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

