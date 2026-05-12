import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ui_kit/src/theme/landfall_colors.dart';
import 'package:ui_kit/src/theme/landfall_spacing.dart';
import 'package:ui_kit/src/theme/landfall_typography.dart';

/// Landfall's Flutter [ThemeData].
///
/// Apply via [MaterialApp.theme]:
/// ```dart
/// MaterialApp(
///   theme: LandfallTheme.dark,
/// )
/// ```
abstract final class LandfallTheme {
  /// The primary dark theme for all Landfall display screens.
  static ThemeData get dark {
    final interFamily = GoogleFonts.inter().fontFamily;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: interFamily,
      scaffoldBackgroundColor: LandfallColors.background,
      colorScheme: const ColorScheme.dark(
        primary: LandfallColors.accent,
        onPrimary: LandfallColors.textPrimary,
        secondary: LandfallColors.accentMuted,
        onSecondary: LandfallColors.textPrimary,
        surface: LandfallColors.surface,
        onSurface: LandfallColors.textPrimary,
        error: LandfallColors.alert,
        onError: LandfallColors.textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: LandfallTypography.timeDisplay,
        displayMedium: LandfallTypography.weatherTemp,
        displaySmall: LandfallTypography.dateLabel,
        headlineMedium: LandfallTypography.cardTitle,
        headlineSmall: LandfallTypography.widgetHeading,
        bodyLarge: LandfallTypography.body,
        bodyMedium: LandfallTypography.cardBody,
        bodySmall: LandfallTypography.caption,
        labelLarge: LandfallTypography.button,
        labelSmall: LandfallTypography.cardSource,
      ),
      cardTheme: CardThemeData(
        color: LandfallColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(LandfallSpacing.cardRadius),
          side: const BorderSide(
            color: LandfallColors.cardBorder,
            width: LandfallSpacing.cardBorderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: LandfallColors.divider,
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(
        color: LandfallColors.textSecondary,
        size: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LandfallColors.accent,
          foregroundColor: LandfallColors.textPrimary,
          textStyle: LandfallTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: LandfallSpacing.xl,
            vertical: LandfallSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LandfallSpacing.sm),
          ),
        ),
      ),
      focusColor: LandfallColors.accentMuted,
    );
  }
}
