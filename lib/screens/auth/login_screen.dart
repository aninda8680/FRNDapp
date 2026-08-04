import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/top_notification.dart';
import '../../services/auth_service.dart';
import '../../config/dev_config.dart';
import 'login_success_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _showForgotPassword = false;
  bool _obscurePassword = true;

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

  Future<void> _onLogin() async {
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

    final result = await AuthService.loginOnly(email, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    switch (result) {
      case AuthResult.success:
        // Existing user, correct password
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginSuccessScreen(
              processFuture: () async {
                final profile = await AuthService.getProfile();
                return AuthService.isProfileComplete(profile) ? '/main' : '/setup';
              }(),
            ),
          ),
        );
        break;

      case AuthResult.wrongPassword:
        // Existing user, wrong password (or non-existent email returning 401)
        _showSnackBar('Invalid email or password. Please try again or sign up.');
        setState(() => _showForgotPassword = true);
        break;

      case AuthResult.userNotFound:
        _showSnackBar('No such mail exists. Redirecting to Sign Up...');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/signup');
          }
        });
        break;

      case AuthResult.needsOtp:
        Navigator.pushReplacementNamed(context, '/otp');
        break;

      case AuthResult.failure:
        _showSnackBar('Could not log in. Please check your credentials or try again.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Log In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background illustration — blurs when keyboard is up
          Positioned(
            top: 180,
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
          SafeArea(
            child: CustomScrollView(
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

                        // Background box wrapping form fields
                        SketchyContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: const Color(0xFFFAF4E1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
                              Text(
                                'ENTER COLLEGE ID',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: const Color(0xFF800000),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              SketchyContainer(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'enter your college mail',
                                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Password field
                              Text(
                                'PASSWORD',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: const Color(0xFF800000),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              SketchyContainer(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'enter password',
                                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action button
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          SketchyButton(
                            text: 'LOG IN',
                            onPressed: _onLogin,
                          ),

                        const SizedBox(height: 12),

                        // Link to Sign Up
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(context, '/signup');
                                },
                                child: Text(
                                  'Sign Up',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF800000),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
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
          ),
        ],
      ),
    );
  }
}
