import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sketchy_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/redTreebg.png',
              fit: BoxFit.fitWidth,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  // Hero illustration
                  Image.asset(
                    'assets/images/withme.png',
                    fit: BoxFit.contain,
                  ),
                  Text(
                    'Every Story starts somewhere !',
                    style: GoogleFonts.caveat(
                      textStyle: Theme.of(context).textTheme.displayMedium,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Text(
                  //   'Meet new people. Begin as strangers, stay as friends, and maybe find your person.',
                  //   style: Theme.of(context).textTheme.bodyLarge,
                  //   textAlign: TextAlign.center,
                  // ),

                  const Spacer(),
                  SketchyButton(
                    text: 'Create Account',
                    onPressed: () => context.push('/signup'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Text(
                          'Log In',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textColor2,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
