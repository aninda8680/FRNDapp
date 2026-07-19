import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sparkle_accent.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
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
