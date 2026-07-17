import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SketchyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool isSelected;

  const SketchyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.inkBlack : AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.lineBlack,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? AppColors.white : AppColors.inkBlack,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
