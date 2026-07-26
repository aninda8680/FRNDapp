import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'sparkle_accent.dart';

class SketchyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool showSparkles;

  const SketchyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.showSparkles = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSparkles) const SparkleAccent(size: 20),
          if (showSparkles) const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inkBlack,
                borderRadius: BorderRadius.circular(999),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
          if (showSparkles) const SizedBox(width: 6),
          if (showSparkles) const SparkleAccent(size: 20),
        ],
      ),
    );
  }
}
