import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class SketchyProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String leftLabel;
  final String rightLabel;

  const SketchyProgressBar({
    super.key,
    required this.progress,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.lineBlack,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  color: AppColors.inkBlack,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: GoogleFonts.spaceMono(
                color: AppColors.inkBlack,
                fontSize: 12,
              ),
            ),
            Text(
              rightLabel,
              style: GoogleFonts.spaceMono(
                color: AppColors.inkBlack,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
