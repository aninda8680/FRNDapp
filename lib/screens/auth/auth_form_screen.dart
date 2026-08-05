import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthFormScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final Widget submitButton;
  final Widget footer;

  const AuthFormScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.submitButton,
    required this.footer,
  });

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late List<Animation<double>> _fadeAnimations;
  late Animation<double> _containerFade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _containerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _setupAnimations();
    _entranceController.forward();
  }

  void _setupAnimations() {
    _fadeAnimations = [];
    final int totalItems = widget.fields.length + 2; // +2 for button and footer
    final double step = 0.6 / totalItems;

    for (int i = 0; i < totalItems; i++) {
      final double start = 0.4 + (i * step);
      final double end = (start + step * 2).clamp(0.0, 1.0);
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(AuthFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields.length != widget.fields.length) {
      _setupAnimations();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF800000), // Burgundy background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // White icons for dark bg
      ),
      body: Stack(
        children: [

          // Form content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 3),
                        
                        // Animated Container for the whole form
                        FadeTransition(
                          opacity: _containerFade,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF4E1), // Cream
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF800000).withValues(alpha: 0.08), // Diffused burgundy tint
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Headline
                                Text(
                                  widget.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300, // Lighter weight
                                    color: Colors.black87,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Subtitle
                                Text(
                                  widget.subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Staggered fields
                                ...List.generate(widget.fields.length, (index) {
                                  return FadeTransition(
                                    opacity: _fadeAnimations[index],
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 20.0),
                                      child: widget.fields[index],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Submit Button
                        FadeTransition(
                          opacity: _fadeAnimations[widget.fields.length],
                          child: widget.submitButton,
                        ),

                        const SizedBox(height: 16),
                        
                        // Footer
                        FadeTransition(
                          opacity: _fadeAnimations[widget.fields.length + 1],
                          child: widget.footer,
                        ),
                        
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
