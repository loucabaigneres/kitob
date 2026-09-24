import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary palette (Terracotta)
  static const Color primary = Color(0xFF9F3C16);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFBF542C);
  static const Color onPrimaryContainer = Color(0xFFFFF7F5);

  // Secondary palette (Sage Laurel)
  static const Color secondary = Color(0xFF376847);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFB6EDC2);
  static const Color onSecondaryContainer = Color(0xFF1E5031);

  // Tertiary palette (Warm Amber)
  static const Color tertiary = Color(0xFF8D4B00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFDCC3);
  static const Color onTertiaryContainer = Color(0xFF2F1500);

  // Neutral canvas & Surface layers (Unbleached Raw Paper)
  static const Color surface = Color(0xFFF6FBF5);
  static const Color surfaceContainerLow = Color(0xFFF0F5F0);
  static const Color surfaceContainer = Color(0xFFEBEFEA);
  static const Color surfaceContainerHigh = Color(0xFFE5E9E4);
  static const Color surfaceContainerHighest = Color(0xFFDFE4DF);
  static const Color onSurface = Color(0xFF181D1A);
  static const Color onSurfaceVariant = Color(0xFF57423B);

  // Outlines & Dividers
  static const Color outline = Color(0xFF8A726A);
  static const Color outlineVariant = Color(0xFFDEC0B7);

  // Status & Alert
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
}
