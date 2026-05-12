import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:ui_kit/src/theme/landfall_active_theme.dart';

extension LandfallThemeTokensMaterialX on LandfallThemeTokens {
  ThemeData toMaterialThemeData() {
    final bg = tokenColor(backgroundValue);
    final surface = tokenColor(cardFill);
    final onSurface = tokenColor(colorTextPrimary);
    final accent = tokenColor(colorAccent);
    final secondary = tokenColor(colorTextSecondary);

    final scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: onSurface,
      secondary: accent,
      onSecondary: onSurface,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: secondary,
    );

    final resolvedFont = _resolveFont(fontFamily);

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: tokenColor(colorDivider),
      useMaterial3: true,
      textTheme: resolvedFont != null
          ? GoogleFonts.getTextTheme(resolvedFont)
          : null,
      fontFamily: resolvedFont != null
          ? GoogleFonts.getFont(resolvedFont).fontFamily
          : null,
    );
  }

  /// Returns a google_fonts-registered name for the token value, or null to
  /// fall back to the system font.
  static String? _resolveFont(String token) => switch (token.toLowerCase()) {
        'inter' => 'Inter',
        'roboto' => 'Roboto',
        'dm sans' || 'dm_sans' => 'DM Sans',
        'space grotesk' || 'space_grotesk' => 'Space Grotesk',
        'system' || '' => null,
        _ => null,
      };
}
