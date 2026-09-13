import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../config/dev_config.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/auth_text_field.dart';
import 'login_success_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool startOnSignUp;

  const AuthScreen({super.key, this.startOnSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isSignUp;

  // Login controllers
  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();

  // Sign up controllers
  final _emailSignUpController = TextEditingController();
  final _passwordSignUpController = TextEditingController();
  final _confirmPasswordSignUpController = TextEditingController();

  bool _isLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureConfirmPassword = true;
  bool _showForgotPassword = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.startOnSignUp;
  }

  @override
  void dispose() {
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _emailSignUpController.dispose();
    _passwordSignUpController.dispose();
    _confirmPasswordSignUpController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TopNotification(
        message: message,
        onDismissed: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _switchMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _showForgotPassword = false;
    });
  }

  Future<void> _onLogin() async {
    if (DevConfig.bypassAuth) {
      context.push('/otp');
      return;
    }
    final email = _emailLoginController.text.trim();
    final password = _passwordLoginController.text;
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
        // nextRouteAfterAuth enforces the full gating chain:
        // unverified → /otp, incomplete profile → /setup, else /main.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginSuccessScreen(
              processFuture: AuthService.nextRouteAfterAuth(),
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
          if (mounted) setState(() => _isSignUp = true);
        });
        break;
      case AuthResult.needsOtp:
        context.replace('/otp');
        break;
      case AuthResult.failure:
        _showSnackBar(AuthService.lastError ??
            'Could not log in. Please check your credentials or try again.');
        break;
    }
  }

  Future<void> _onSignUp() async {
    if (DevConfig.bypassAuth) {
      context.push('/otp');
      return;
    }
    final email = _emailSignUpController.text.trim();
    final password = _passwordSignUpController.text;
    final confirmPassword = _confirmPasswordSignUpController.text;
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
        // Existing account signed straight in (or OTP-exempt email):
        // route through the same verified/profile gating as login.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginSuccessScreen(
              processFuture: AuthService.nextRouteAfterAuth(),
            ),
          ),
        );
        break;
      case AuthResult.wrongPassword:
        _showSnackBar('An account with this email already exists. Redirecting to login...');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _isSignUp = false);
        });
        break;
      case AuthResult.userNotFound:
      case AuthResult.failure:
        _showSnackBar(AuthService.lastError ?? 'Sign up failed. Please try again.');
        break;
    }
  }

  Widget _buildLoginContent() {
    return _AuthFormContent(
      key: const ValueKey('login'),
      title: 'Welcome back',
      subtitle: 'Log in with your college email to continue',
      fields: [
        AuthTextField(
          label: 'College ID',
          hintText: 'Enter your college mail',
          controller: _emailLoginController,
          keyboardType: TextInputType.emailAddress,
        ),
        AuthTextField(
          label: 'Password',
          hintText: 'Enter password',
          controller: _passwordLoginController,
          obscureText: _obscureLoginPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
          ),
        ),
        if (_showForgotPassword)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                final email = _emailLoginController.text.trim();
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
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
      onSubmit: _onLogin,
      isLoading: _isLoading,
      submitLabel: 'LOG IN',
      footerText: "Don't have an account? ",
      footerActionText: 'Sign Up',
      onFooterTap: _switchMode,
    );
  }

  Widget _buildSignUpContent() {
    return _AuthFormContent(
      key: const ValueKey('signup'),
      title: 'Create Account',
      subtitle: 'Sign up with your college email to continue',
      fields: [
        AuthTextField(
          label: 'College ID',
          hintText: 'Enter your college mail',
          controller: _emailSignUpController,
          keyboardType: TextInputType.emailAddress,
        ),
        AuthTextField(
          label: 'Create Password',
          hintText: 'Min 8 chars, 1 special char',
          controller: _passwordSignUpController,
          obscureText: _obscureSignUpPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSignUpPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () => setState(() => _obscureSignUpPassword = !_obscureSignUpPassword),
          ),
        ),
        AuthTextField(
          label: 'Confirm Password',
          hintText: 'Confirm password',
          controller: _confirmPasswordSignUpController,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
      ],
      onSubmit: _onSignUp,
      isLoading: _isLoading,
      submitLabel: 'SIGN UP',
      footerText: 'Already have an account? ',
      footerActionText: 'Log In',
      onFooterTap: _switchMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF800000), // Burgundy
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Static city skyline at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/login/citybg.png',
              fit: BoxFit.fitWidth,
            ),
          ),
          // Animated form content switcher — no route transition, no overlap!
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _isSignUp ? _buildSignUpContent() : _buildLoginContent(),
          ),
        ],
      ),
    );
  }
}

// Private stateless form content widget
class _AuthFormContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String submitLabel;
  final String footerText;
  final String footerActionText;
  final VoidCallback onFooterTap;

  const _AuthFormContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.onSubmit,
    required this.isLoading,
    required this.submitLabel,
    required this.footerText,
    required this.footerActionText,
    required this.onFooterTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...fields.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: f,
                            )),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Submit button
                  _AuthButton(
                    label: submitLabel,
                    onPressed: onSubmit,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        footerText,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: onFooterTap,
                        child: Text(
                          footerActionText,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120), // Adjusted to position text perfectly
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _AuthButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading) {
          HapticFeedback.lightImpact();
          _ctrl.forward();
        }
      },
      onTapUp: (_) {
        if (!widget.isLoading) {
          _ctrl.reverse();
          widget.onPressed();
        }
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.label,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
