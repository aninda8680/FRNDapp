import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/sketchy_button.dart';
import '../setup/profile_created_screen.dart'; // To reuse ProfileBuildingIndicator
import 'dart:math' as math;

class LoginSuccessScreen extends StatefulWidget {
  final Future<String> processFuture; // Returns the next route name

  const LoginSuccessScreen({super.key, required this.processFuture});

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen> {
  String _headline = 'Authenticating';
  String _subtitle = 'Unlocking your world...';
  bool _isDone = false;
  bool _isSuccess = false;
  bool _showEnterWorld = false;
  String _nextRoute = '/main';

  @override
  void initState() {
    super.initState();
    _handleProcess();
  }

  Future<void> _handleProcess() async {
    // Ensure the loading state shows for at least 3 seconds
    try {
      final results = await Future.wait([
        widget.processFuture,
        Future.delayed(const Duration(seconds: 3)),
      ]);
      
      final nextRoute = results[0] as String;
      
      if (mounted) {
        setState(() {
          _isDone = true;
          _isSuccess = true;
          _nextRoute = nextRoute;
          _headline = nextRoute == '/setup' ? 'Verification complete' : 'Welcome back';
          _subtitle = nextRoute == '/setup' 
              ? 'Let\'s set up your profile.' 
              : 'Step in — your story continues.';
          _showEnterWorld = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDone = true;
          _isSuccess = false;
          _headline = 'Something went wrong';
          _subtitle = 'Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textColor2, // Crimson background like setup
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

              if (_showEnterWorld)
                Padding(
                  padding: EdgeInsets.only(bottom: math.max(60.0, MediaQuery.of(context).padding.bottom + 32.0)),
                  child: SketchyButton(
                    text: nextRoute == '/setup' ? 'CONTINUE' : 'ENTER WORLD',
                    onPressed: () {
                      context.go(_nextRoute);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get nextRoute => _nextRoute;
}
