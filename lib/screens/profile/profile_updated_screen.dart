import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileUpdatedScreen extends StatefulWidget {
  final Future<bool> saveFuture;
  const ProfileUpdatedScreen({super.key, required this.saveFuture});

  @override
  State<ProfileUpdatedScreen> createState() => _ProfileUpdatedScreenState();
}

class _ProfileUpdatedScreenState extends State<ProfileUpdatedScreen> {
  String _headline = 'UPDATING...';
  String _subtitle = 'Please wait';
  bool _isDone = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _handleSave();
  }

  Future<void> _handleSave() async {
    final success = await widget.saveFuture;
    if (mounted) {
      setState(() {
        _isDone = true;
        _isSuccess = success;
        if (success) {
          _headline = 'PROFILE UPDATED';
          _subtitle = 'Your new look is live.';
        } else {
          _headline = 'UPDATE FAILED';
          _subtitle = 'Please try again later.';
        }
      });

      if (success) {
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context); // Go back to the main profile screen
          }
        });
      } else {
        // If failed, auto-pop after 3 seconds too, or let user tap back (we don't have a button, so auto-pop)
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textColor2, // Crimson background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Premium Geometric Animation
              Center(
                child: PremiumProgressIndicator(
                  isDone: _isDone,
                  isSuccess: _isSuccess,
                ),
              ),
              
              const SizedBox(height: 56),
              
              // Headline
              Text(
                _headline,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cream, // Cream text
                  letterSpacing: -0.5,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.cream.withOpacity(0.8), // Cream subtitle
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumProgressIndicator extends StatefulWidget {
  final bool isDone;
  final bool isSuccess;

  const PremiumProgressIndicator({
    super.key,
    required this.isDone,
    required this.isSuccess,
  });

  @override
  State<PremiumProgressIndicator> createState() => _PremiumProgressIndicatorState();
}

class _PremiumProgressIndicatorState extends State<PremiumProgressIndicator> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _transitionController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(PremiumProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone && !oldWidget.isDone) {
      _transitionController.forward();
      // Smoothly stop spinning
      _spinController.animateTo(
        _spinController.value + 0.1, 
        duration: const Duration(milliseconds: 800), 
        curve: Curves.easeOut
      );
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spinController, _transitionController]),
        builder: (context, child) {
          return CustomPaint(
            painter: PremiumProgressPainter(
              spinValue: _spinController.value,
              transitionValue: _transitionController.value,
              isSuccess: widget.isSuccess,
            ),
          );
        },
      ),
    );
  }
}

class PremiumProgressPainter extends CustomPainter {
  final double spinValue;
  final double transitionValue; // 0.0 = loading, 1.0 = success/done
  final bool isSuccess;

  PremiumProgressPainter({
    required this.spinValue,
    required this.transitionValue,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintBlack = Paint()
      ..color = AppColors.cream // Cream circle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final paintCrimson = Paint()
      ..color = AppColors.cream // Cream accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final paintCrimsonFill = Paint()
      ..color = AppColors.cream // Cream accent fill
      ..style = PaintingStyle.fill;

    // A circle with a small deliberate gap.
    const gapSize = math.pi / 3.5; 
    
    // We animate the sweep angle to close the gap on success.
    double sweepAngle = (2 * math.pi - gapSize);
    if (isSuccess) {
      sweepAngle += gapSize * Curves.easeInOut.transform(transitionValue);
    }
    
    // The starting angle spins during loading.
    final startAngle = (spinValue * 2 * math.pi) - math.pi / 2;

    // Draw the ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paintBlack,
    );

    // The crimson dot/tick
    if (transitionValue == 0.0) {
      // Just draw the crimson dot at the end of the arc
      final dotAngle = startAngle + sweepAngle + (gapSize / 2);
      final dotPos = Offset(
        center.dx + radius * math.cos(dotAngle),
        center.dy + radius * math.sin(dotAngle),
      );
      canvas.drawCircle(dotPos, 3.0, paintCrimsonFill);
    } else if (isSuccess) {
      // Transitioning to success: dot moves to center and morphs into a checkmark
      final dotAngle = startAngle + sweepAngle + (gapSize / 2); // Initial position
      final initialDotPos = Offset(
        center.dx + radius * math.cos(dotAngle),
        center.dy + radius * math.sin(dotAngle),
      );
      
      final checkCenter = center;
      
      // Move dot to center (0.0 to 0.5)
      // Grow checkmark (0.5 to 1.0)
      if (transitionValue < 0.5) {
        final t = Curves.easeIn.transform(transitionValue * 2);
        final currentPos = Offset.lerp(initialDotPos, checkCenter, t)!;
        canvas.drawCircle(currentPos, 3.0, paintCrimsonFill);
      } else {
        final t = Curves.easeOut.transform((transitionValue - 0.5) * 2);
        
        final path = Path();
        
        // checkmark points relative to center
        final p1 = checkCenter + const Offset(-12, 0);
        final p2 = checkCenter + const Offset(-4, 8);
        final p3 = checkCenter + const Offset(14, -10);
        
        final l1 = (p2 - p1).distance;
        final l2 = (p3 - p2).distance;
        final totalL = l1 + l2;
        
        final currentL = totalL * t;
        
        path.moveTo(p1.dx, p1.dy);
        if (currentL <= l1) {
          final frac = currentL / l1;
          path.lineTo(p1.dx + (p2.dx - p1.dx) * frac, p1.dy + (p2.dy - p1.dy) * frac);
        } else {
          path.lineTo(p2.dx, p2.dy);
          final frac = (currentL - l1) / l2;
          path.lineTo(p2.dx + (p3.dx - p2.dx) * frac, p2.dy + (p3.dy - p2.dy) * frac);
        }
        
        canvas.drawPath(path, paintCrimson);
      }
    } else {
      // If failed, just keep the dot where it is, fading out or something.
      final dotAngle = startAngle + sweepAngle + (gapSize / 2);
      final dotPos = Offset(
        center.dx + radius * math.cos(dotAngle),
        center.dy + radius * math.sin(dotAngle),
      );
      // Fade out
      final opacity = 1.0 - transitionValue;
      canvas.drawCircle(dotPos, 3.0, paintCrimsonFill..color = paintCrimsonFill.color.withOpacity(opacity.clamp(0.0, 1.0)));
    }
  }

  @override
  bool shouldRepaint(covariant PremiumProgressPainter oldDelegate) {
    return spinValue != oldDelegate.spinValue || 
           transitionValue != oldDelegate.transitionValue ||
           isSuccess != oldDelegate.isSuccess;
  }
}