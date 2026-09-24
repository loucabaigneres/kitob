import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTypography {
  static TextTheme createTextTheme() {
    return TextTheme(
      // Editorial serif headers (Newsreader)
      displayLarge: GoogleFonts.newsreader(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.25,
        letterSpacing: -0.01,
        color: AppColors.onSurface,
      ),
      headlineLarge: GoogleFonts.newsreader(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.25,
        letterSpacing: -0.01,
        color: AppColors.onSurface,
      ),
      headlineMedium: GoogleFonts.newsreader(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.36,
        color: AppColors.onSurface,
      ),
      headlineSmall: GoogleFonts.newsreader(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.44,
        color: AppColors.onSurface,
      ),

      // Interface & Body copy (Inter)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.57,
        color: AppColors.onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurfaceVariant,
      ),

      // Micro-controls & Badges (Inter)
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.38,
        letterSpacing: 0.02,
        color: AppColors.onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.45,
        letterSpacing: 0.02,
        color: AppColors.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: 0.06,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
