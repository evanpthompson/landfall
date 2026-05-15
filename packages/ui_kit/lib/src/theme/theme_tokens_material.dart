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
          ? _isBundled(resolvedFont)
              ? null
              : GoogleFonts.getTextTheme(resolvedFont)
          : null,
      fontFamily: resolvedFont,
    );
  }

  /// Returns the canonical font family name for the token value, or null for
  /// system/unknown tokens. All returned names correspond to families declared
  /// under flutter.fonts in pubspec.yaml (bundled assets, no runtime fetch).
  static String? _resolveFont(String token) => switch (token.toLowerCase()) {
        'inter' => 'Inter',
        'roboto' => 'Roboto',
        'dm sans' || 'dm_sans' => 'DM Sans',
        'space grotesk' || 'space_grotesk' => 'Space Grotesk',
        'jetbrains mono' || 'jetbrains_mono' => 'JetBrains Mono',
        'playfair display' || 'playfair_display' => 'Playfair Display',
        'space mono' || 'space_mono' => 'Space Mono',
        'bebas neue' || 'bebas_neue' => 'Bebas Neue',
        'lexend' => 'Lexend',
        'lora' => 'Lora',
        'orbitron' => 'Orbitron',
        'outfit' => 'Outfit',
        'syne' => 'Syne',
        'system' || '' => null,
        _ => null,
      };

  /// True for every family in the Landfall font registry (architecture_decisions.md §22).
  /// All registry families are declared under flutter.fonts in pubspec.yaml so the
  /// engine resolves them from bundled assets — google_fonts network fetch never fires.
  static bool _isBundled(String family) => switch (family) {
        'Inter' ||
        'Roboto' ||
        'DM Sans' ||
        'Space Grotesk' ||
        'JetBrains Mono' ||
        'Playfair Display' ||
        'Space Mono' ||
        'Bebas Neue' ||
        'Lexend' ||
        'Lora' ||
        'Orbitron' ||
        'Outfit' ||
        'Syne' =>
          true,
        _ => false,
      };
}
