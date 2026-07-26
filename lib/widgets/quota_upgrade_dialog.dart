import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'sketchy_button.dart';
import 'sketchy_container.dart';

class QuotaUpgradeDialog extends StatelessWidget {
  final String title;
  final String description;
  final String currentLimitText;

  const QuotaUpgradeDialog({
    super.key,
    required this.title,
    required this.description,
    required this.currentLimitText,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String description,
    required String currentLimitText,
  }) {
    return showDialog(
      context: context,
      builder: (context) => QuotaUpgradeDialog(
        title: title,
        description: description,
        currentLimitText: currentLimitText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.inkBlack, width: 2.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Star Icon
            const Center(
              child: Icon(
                Icons.stars_rounded,
                size: 48,
                color: AppColors.inkBlack,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.1,
                color: AppColors.inkBlack,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkBlack,
              ),
            ),
            const SizedBox(height: 16),

            // Quota Comparison Box
            SketchyContainer(
              backgroundColor: AppColors.inkBlack,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT LIMIT',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.cream,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        currentLimitText,
                        style: GoogleFonts.spaceMono(
                          color: AppColors.cream,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(color: AppColors.cream, height: 1),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GOLD PASS LIMIT',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.cream,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '50 LIKES / 12 SUPERLIKES ✦',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.cream,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action CTAs
            SketchyButton(
              text: 'UPGRADE TO GOLD PASS ✦',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription');
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'NOT NOW',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkBlack,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
