import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SparkleAccent extends StatelessWidget {
  final double size;
  const SparkleAccent({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/star.jpg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
