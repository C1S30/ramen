import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  AppStyles._();

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.6,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.jetBrainsMono(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      );

  static TextStyle get monoDisplay => GoogleFonts.jetBrainsMono(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get monoHeadline => GoogleFonts.jetBrainsMono(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.4,
      );

  static TextStyle get monoTitle => GoogleFonts.jetBrainsMono(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get monoLabel => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get monoAccent => GoogleFonts.jetBrainsMono(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppColors.accentBright,
      );

  // Theme Data configuration (Pure Black & White Minimalism)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.accentMuted,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.textSecondary,
        onSecondary: AppColors.onAccent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: monoHeadline.copyWith(
          fontSize: 14,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.surfaceElevated,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderLight, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onAccent;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.surfaceHighlight;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.borderLight;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onAccent),
        side: const BorderSide(color: AppColors.borderLight, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surfaceHighlight,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accentMuted,
        trackHeight: 2,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: monoSmall.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
