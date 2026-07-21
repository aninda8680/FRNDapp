import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sparkle_accent.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Artificial minimum delay for the splash animation
    final minimumDelay = Future.delayed(const Duration(seconds: 2));
    
    await AuthService.init();
    
    // Check if we are logged in (i.e. if we have a profile we can fetch)
    // The profile fetch itself will fail if the cookie is expired/missing
    final profile = await AuthService.getProfile();
    
    await minimumDelay;
    
    if (!mounted) return;
    
    if (profile == null) {
      // Not logged in or session expired
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      // Logged in
      if (AuthService.isProfileComplete(profile)) {
        // Profile is complete, go to main
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        // Profile needs setup
        Navigator.pushReplacementNamed(context, '/setup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SparkleAccent(size: 32),
                const SizedBox(width: 16),
                Image.asset(
                  'assets/images/frndlogo.png',
                  height: 120,
                ),
                const SizedBox(width: 16),
                const SparkleAccent(size: 32),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'level up your social life',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textColor1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
