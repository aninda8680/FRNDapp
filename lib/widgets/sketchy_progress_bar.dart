import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';

class SketchyProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String leftLabel;
  final String rightLabel;
  final Color? textColor;

  const SketchyProgressBar({
    super.key,
    required this.progress,
    required this.leftLabel,
    required this.rightLabel,
    this.textColor,
  });

  @override
  State<SketchyProgressBar> createState() => _SketchyProgressBarState();
}

class _SketchyProgressBarState extends State<SketchyProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _previousProgress = widget.progress;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void didUpdateWidget(SketchyProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = widget.textColor ?? AppColors.progressBarColor;
    
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
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: _previousProgress,
                end: widget.progress.clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              builder: (context, progressValue, child) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: LiquidPainter(
                        wavePhase: _waveController.value,
                        progress: progressValue,
                        color: AppColors.progressBarColor,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.leftLabel,
              style: GoogleFonts.spaceMono(
                color: effectiveTextColor,
                fontSize: 12,
              ),
            ),
            Text(
              widget.rightLabel,
              style: GoogleFonts.spaceMono(
                color: effectiveTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class LiquidPainter extends CustomPainter {
  final double wavePhase;
  final double progress;
  final Color color;

  LiquidPainter({
    required this.wavePhase,
    required this.progress,
    required this.color,
  });

  /// Build a path that fills from the left up to a wavy right boundary.
  /// The wave scrolls along the Y axis to simulate water at the leading edge.
  Path _buildWavePath(Size size, double fillX, double amp, double phase) {
    final path = Path();
    path.moveTo(0, size.height); // bottom-left
    path.lineTo(fillX, size.height); // along bottom to fill boundary

    // Trace the wavy right edge from bottom to top
    for (double y = size.height; y >= 0; y -= 0.6) {
      final double normY = y / size.height;
      // sin wave scrolling upward over time
      final double wave = amp * math.sin(normY * math.pi * 2.5 - phase * 2 * math.pi);
      // Bell taper so wave is 0 at very top & bottom edges (avoids corner spikes)
      final double taper = math.sin(normY * math.pi);
      path.lineTo(fillX + wave * taper, y);
    }

    path.lineTo(0, 0); // top-left
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1 || progress <= 0) return;

    final double fillX = size.width * progress;
    // Amplitude: ~45 % of bar height so the wave is visible but not excessive
    final double amp = size.height * 0.45;

    // --- Back wave (lighter, offset phase) ---
    final backPath = _buildWavePath(size, fillX, amp * 0.65, wavePhase + 0.35);
    canvas.drawPath(
      backPath,
      Paint()
        ..color = color.withOpacity(0.38)
        ..style = PaintingStyle.fill,
    );

    // --- Front wave (full opacity) ---
    final frontPath = _buildWavePath(size, fillX, amp, wavePhase);
    canvas.drawPath(
      frontPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // --- Shimmer streak (light reflection) ---
    if (fillX > 10) {
      final double shimmerX = (wavePhase * fillX * 1.3) % (fillX + 16) - 8;
      final shimmerPath = Path()
        ..moveTo(shimmerX - 6, 0)
        ..lineTo(shimmerX + 4, 0)
        ..lineTo(shimmerX + 1, size.height)
        ..lineTo(shimmerX - 9, size.height)
        ..close();
      canvas.drawPath(
        shimmerPath,
        Paint()
          ..color = Colors.white.withOpacity(0.14)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LiquidPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
