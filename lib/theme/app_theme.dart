import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.cream,
      primaryColor: AppColors.inkBlack,
      colorScheme: const ColorScheme.light(
        primary: AppColors.inkBlack,
        secondary: AppColors.inkBlack,
        surface: AppColors.cream,
        error: AppColors.inkBlack,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.inkBlack,
        onError: AppColors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.inkBlack,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.inkBlack,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          color: AppColors.inkBlack,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.inkBlack,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          color: AppColors.inkBlack,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.inkBlack,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.inter(color: AppColors.inkBlack),
        bodyMedium: GoogleFonts.inter(color: AppColors.inkBlack),
        labelLarge: GoogleFonts.spaceMono(color: AppColors.inkBlack),
        labelSmall: GoogleFonts.spaceMono(color: AppColors.inkBlack),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.inkBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.inkBlack,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: AppColors.inkBlack),
      ),
      useMaterial3: true,
    );
  }
}
