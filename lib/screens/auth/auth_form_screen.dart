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

class _AuthFormScreenState extends State<AuthFormScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background now managed by ShellRoute
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
                        const SizedBox(height: 60), // Reduced from 100 to leave more room
                        
                        // Container for the whole form
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Headline
                              Text(
                                widget.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300, // Lighter weight
                                  color: Colors.white, // White text
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Subtitle
                              Text(
                                widget.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white70, // White70 text
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24), // Reduced from 32
                              
                              // Staggered fields (now statically rendered)
                              ...widget.fields.map((field) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20.0),
                                  child: field,
                                );
                              }),
                            ],
                          ),
                        ),

                        const Spacer(), // Pushes the button to a consistent bottom position
                        
                        // Submit Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: widget.submitButton,
                        ),

                        const SizedBox(height: 16),
                        
                        // Footer
                        widget.footer,
                        
                        const SizedBox(height: 60), // Consistent bottom padding
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
