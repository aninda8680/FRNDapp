import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/top_notification.dart';
import '../../services/auth_service.dart';
import '../../config/dev_config.dart';
import 'login_success_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _onSignUp() async {
    // ── Dev bypass ────────────────────────────────────────────────────────────
    if (DevConfig.bypassAuth) {
      Navigator.pushNamed(context, '/otp');
      return;
    }

    // ── Validation ────────────────────────────────────────────────────────────
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    if (password.length < 8) {
      _showSnackBar('Password must be at least 8 characters long.');
      return;
    }

    final hasSpecialChar = RegExp(r'[^\w\s]').hasMatch(password);
    if (!hasSpecialChar) {
      _showSnackBar(r'Password must contain at least 1 special character (e.g. @, #, $, !).');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.signupOnly(email, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    switch (result) {
      case AuthResult.needsOtp:
        // New user → OTP was sent → open OTP verification screen
        Navigator.pushReplacementNamed(context, '/otp');
        break;

      case AuthResult.success:
        // Already existed and logged in
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
        _showSnackBar('An account with this email already exists. Redirecting to login...');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
        break;
      case AuthResult.userNotFound:
      case AuthResult.failure:
        _showSnackBar('Sign up failed. Please try again.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background illustration — blurs when keyboard is up
          Positioned(
            top: 165,
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
                height: 240,
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
                                'CREATE PASSWORD',
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
                                    hintText: 'min 8 chars with a special character',
                                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.grey.withOpacity(0.5),
                                          fontSize: 13,
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
                              const SizedBox(height: 14),

                              // Confirm Password field
                              Text(
                                'CONFIRM PASSWORD',
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
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'confirm password',
                                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
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
                            text: 'SIGN UP',
                            onPressed: _onSignUp,
                          ),

                        const SizedBox(height: 12),

                        // Link to Login
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                child: Text(
                                  'Log In',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF800000),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),

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
