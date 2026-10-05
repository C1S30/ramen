import 'package:flutter/material.dart';

/// Minimalist, professional color palette adhering to the 70-30-10 rule:
/// - 70% Deep Void Black: Canvas, background, deep panels
/// - 30% Crisp Functional White: High-contrast typography, cards, structural borders
/// - 10% Crimson Red Accent: Action buttons, active tabs, progress bars, highlights
class AppColors {
  AppColors._();

  // 70% Deep Void Black & Surfaces
  static const Color background = Color(0xFF070709);
  static const Color surface = Color(0xFF101014);
  static const Color surfaceElevated = Color(0xFF16161B);
  static const Color surfaceHighlight = Color(0xFF1F1F26);

  // 30% Functional White & Structural Grays
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color border = Color(0xFF27272A);
  static const Color borderLight = Color(0xFF3F3F46);
  static const Color chipBackground = Color(0xFF18181E);

  // 10% Intense Crimson Red Accent
  static const Color accent = Color(0xFFE50914);
  static const Color accentBright = Color(0xFFFF2A2A);
  static const Color accentMuted = Color(0x33E50914);
  static const Color accentGlow = Color(0x4DE50914);

  // Status & Utility Accents
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
