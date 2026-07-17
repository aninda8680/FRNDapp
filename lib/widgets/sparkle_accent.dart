import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SparkleAccent extends StatelessWidget {
  final double size;
  const SparkleAccent({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SparklePainter(),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkBlack
      ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final cx = width / 2;
    final cy = height / 2;

    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy * 0.8, width, cy);
    path.quadraticBezierTo(cx, cy * 1.2, cx, height);
    path.quadraticBezierTo(cx, cy * 0.8, 0, cy);
    path.quadraticBezierTo(cx, cy * 0.8, cx, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
