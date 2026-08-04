import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../widgets/sketchy_button.dart';

class ProfileCreatedScreen extends StatefulWidget {
  final Future<bool> saveFuture;
  const ProfileCreatedScreen({super.key, required this.saveFuture});

  @override
  State<ProfileCreatedScreen> createState() => _ProfileCreatedScreenState();
}

class _ProfileCreatedScreenState extends State<ProfileCreatedScreen> {
  String _headline = 'Writing your first chapter';
  String _subtitle = 'New people are waiting. Some will become friends. One might become more.';
  bool _isDone = false;
  bool _isSuccess = false;
  bool _showEnterWorld = false;

  @override
  void initState() {
    super.initState();
    _handleCreate();
  }

  Future<void> _handleCreate() async {
    // Wait for the endpoint to finish creating the profile
    final success = await widget.saveFuture;
    
    if (mounted) {
      setState(() {
        _isDone = true;
        _isSuccess = success;
        if (success) {
          _headline = 'Profile created';
          _subtitle = 'Step in — your story starts now.';
        } else {
          _headline = 'Something went wrong';
          _subtitle = 'Please try again.';
        }
      });

      if (success) {
        // Show the 'Profile created' state for 3 seconds before auto-redirecting
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textColor2, // Crimson background
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              Center(
                child: ProfileBuildingIndicator(
                  isDone: _isDone,
                  isSuccess: _isSuccess,
                ),
              ),

              const SizedBox(height: 56),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _headline,
                  key: ValueKey(_headline),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cream,
                    letterSpacing: -0.4,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _subtitle,
                  key: ValueKey(_subtitle),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: AppColors.cream.withOpacity(0.8),
                  ),
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

/// A geometric profile creation animation.
/// Loading: A profile icon sits in the center while a progress ring spins around it.
/// Success: The ring completes, the profile icon turns fully opaque, and a checkmark badge appears.
class ProfileBuildingIndicator extends StatefulWidget {
  final bool isDone;
  final bool isSuccess;

  const ProfileBuildingIndicator({
    super.key,
    required this.isDone,
    required this.isSuccess,
  });

  @override
  State<ProfileBuildingIndicator> createState() => _ProfileBuildingIndicatorState();
}

class _ProfileBuildingIndicatorState extends State<ProfileBuildingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(ProfileBuildingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone && !oldWidget.isDone && widget.isSuccess) {
      // Smoothly halt the spin and animate success
      final currentSpin = _spinController.value;
      _spinController.stop();
      _spinController.animateTo(currentSpin + 0.1, duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
      _successController.forward();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spinController, _successController]),
        builder: (context, child) {
          return CustomPaint(
            painter: ProfileBuildingPainter(
              spinValue: _spinController.value,
              successValue: Curves.easeOutBack.transform(_successController.value),
              isSuccess: widget.isSuccess,
              isDone: widget.isDone,
            ),
          );
        },
      ),
    );
  }
}

class ProfileBuildingPainter extends CustomPainter {
  final double spinValue; 
  final double successValue; 
  final bool isSuccess;
  final bool isDone;

  ProfileBuildingPainter({
    required this.spinValue,
    required this.successValue,
    required this.isSuccess,
    required this.isDone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Profile Icon
    final profileOpacity = (isDone && isSuccess) ? (0.5 + 0.5 * successValue.clamp(0.0, 1.0)) : 0.5;
    final profilePaint = Paint()
      ..color = AppColors.cream.withOpacity(profileOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Head
    canvas.drawCircle(Offset(center.dx, center.dy - radius * 0.15), radius * 0.25, profilePaint);

    // Shoulders
    final shoulderPath = Path()
      ..moveTo(center.dx - radius * 0.45, center.dy + radius * 0.4)
      ..quadraticBezierTo(
        center.dx - radius * 0.45, center.dy + radius * 0.1,
        center.dx, center.dy + radius * 0.1,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.45, center.dy + radius * 0.1,
        center.dx + radius * 0.45, center.dy + radius * 0.4,
      );
    canvas.drawPath(shoulderPath, profilePaint);

    // 2. Draw Progress Ring
    final ringPaint = Paint()
      ..color = AppColors.cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final sweep = (isDone && isSuccess) ? (1.5 * math.pi) + (0.5 * math.pi * successValue.clamp(0.0, 1.0)) : 1.5 * math.pi;
    final start = spinValue * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      start,
      sweep,
      false,
      ringPaint,
    );

    // 3. Draw Checkmark Badge on success
    if (isDone && isSuccess && successValue > 0) {
      final badgeCenter = Offset(center.dx + radius * 0.5, center.dy + radius * 0.5);
      final badgeScale = successValue.clamp(0.0, 1.0);
      
      final badgePaint = Paint()
        ..color = AppColors.cream
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(badgeCenter, 14 * badgeScale, badgePaint);
      
      // Draw checkmark inside badge
      final checkPaint = Paint()
        ..color = AppColors.textColor2 // Cut out / background color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
        
      final path = Path()
        ..moveTo(badgeCenter.dx - 5 * badgeScale, badgeCenter.dy)
        ..lineTo(badgeCenter.dx - 1 * badgeScale, badgeCenter.dy + 4 * badgeScale)
        ..lineTo(badgeCenter.dx + 6 * badgeScale, badgeCenter.dy - 4 * badgeScale);
        
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ProfileBuildingPainter oldDelegate) {
    return spinValue != oldDelegate.spinValue ||
        successValue != oldDelegate.successValue ||
        isSuccess != oldDelegate.isSuccess ||
        isDone != oldDelegate.isDone;
  }
}
