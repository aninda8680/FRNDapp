import 'package:flutter/material.dart';
import '../../utils/route_transitions.dart';
import 'signup_screen.dart';
import '../../services/auth_service.dart';
import '../../config/dev_config.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/animated_auth_button.dart';
import 'auth_form_screen.dart';
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
    return AuthFormScreen(
      title: 'Welcome back',
      subtitle: 'Log in with your college email to continue',
      fields: [
        AuthTextField(
          label: 'College ID',
          hintText: 'Enter your college mail',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        AuthTextField(
          label: 'Password',
          hintText: 'Enter password',
          controller: _passwordController,
          obscureText: _obscurePassword,
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
        if (_showForgotPassword)
          Align(
            alignment: Alignment.centerRight,
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
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF800000),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
      submitButton: AnimatedAuthButton(
        text: 'LOG IN',
        isLoading: _isLoading,
        onPressed: _onLogin,
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                SharedAxisPageRoute(
                  page: const SignUpScreen(),
                  isForward: true,
                ),
              );
            },
            child: Text(
              'Sign Up',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
