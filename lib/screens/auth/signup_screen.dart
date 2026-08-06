import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../utils/route_transitions.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';
import '../../config/dev_config.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/animated_auth_button.dart';
import 'auth_form_screen.dart';
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
      context.push('/otp');
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
        context.replace('/otp');
        break;

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
        _showSnackBar('An account with this email already exists. Redirecting to login...');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.replace('/login');
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
    return AuthFormScreen(
      title: 'Create Account',
      subtitle: 'Sign up with your college email to continue',
      fields: [
        AuthTextField(
          label: 'College ID',
          hintText: 'Enter your college mail',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        AuthTextField(
          label: 'Create Password',
          hintText: 'Min 8 chars, 1 special char',
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
        AuthTextField(
          label: 'Confirm Password',
          hintText: 'Confirm password',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
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
      ],
      submitButton: AnimatedAuthButton(
        text: 'SIGN UP',
        isLoading: _isLoading,
        onPressed: _onSignUp,
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account? ",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                SharedAxisPageRoute(
                  page: const LoginScreen(),
                  isForward: false,
                ),
              );
            },
            child: Text(
              'Log In',
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
