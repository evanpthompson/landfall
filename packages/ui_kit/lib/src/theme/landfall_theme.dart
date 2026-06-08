import 'package:flutter/material.dart';
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
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
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
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: Colors.white, width: 2.5);
            }
            return BorderSide.none;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: Colors.white, width: 2.5);
            }
            return BorderSide.none;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return LandfallColors.accent.withValues(alpha: 0.25);
            }
            return null;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: LandfallColors.accent, width: 1.5);
            }
            return null;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LandfallSpacing.sm),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return Colors.white.withValues(alpha: 0.12);
            }
            return null;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: Colors.white, width: 2);
            }
            return null;
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return LandfallColors.accent.withValues(alpha: 0.3);
            }
            return null;
          }),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return LandfallColors.accent.withValues(alpha: 0.2);
          }
          return null;
        }),
      ),
      focusColor: LandfallColors.accent.withValues(alpha: 0.25),
    );
  }
}
