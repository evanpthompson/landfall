import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'landfall_active_theme.dart';

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

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: tokenColor(colorDivider),
      useMaterial3: true,
    );
  }
}
