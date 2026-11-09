import 'package:flutter/material.dart';

/// Pure Black & White Minimalist Monochrome Color Palette:
/// - Canvas & Surfaces: Pure OLED Black (#000000) to Carbon Obsidian (#1C1C1C)
/// - Typography & Accents: Pure Crisp White (#FFFFFF) to Muted Zinc (#525252)
/// - High-Contrast Inversion: White-on-Black cards, Black-on-White primary actions
class AppColors {
  AppColors._();

  // Deep Monochrome Canvas & Surfaces
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceElevated = Color(0xFF121212);
  static const Color surfaceHighlight = Color(0xFF1C1C1C);

  // Crisp Monochrome Typography & Hairline Borders
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textMuted = Color(0xFF525252);
  static const Color border = Color(0xFF1F1F1F);
  static const Color borderLight = Color(0xFF333333);
  static const Color chipBackground = Color(0xFF0F0F0F);

  // High-Contrast Pure White Accent & Inverted Foreground
  static const Color accent = Color(0xFFFFFFFF);
  static const Color accentBright = Color(0xFFFFFFFF);
  static const Color onAccent = Color(0xFF000000);
  static const Color accentMuted = Color(0x1AFFFFFF);
  static const Color accentGlow = Color(0x26FFFFFF);

  // Minimalist Semantic Status Accents
  static const Color success = Color(0xFFE5E5E5);
  static const Color warning = Color(0xFFD4D4D4);
  static const Color error = Color(0xFFF87171);
}
