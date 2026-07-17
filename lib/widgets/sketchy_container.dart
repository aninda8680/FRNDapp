import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SketchyContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double borderWidth;

  const SketchyContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.lineBlack,
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }
}
