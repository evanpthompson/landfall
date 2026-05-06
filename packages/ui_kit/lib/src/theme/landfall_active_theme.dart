import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// Propagates [LandfallThemeTokens] down the widget tree.
///
/// Wrap any subtree with this widget to make its system cards respond to the
/// active theme. Cards call [LandfallActiveTheme.of] to obtain the nearest
/// token set, falling back to [LandfallThemeTokens.defaults] when no ancestor
/// is present — so widgets are safe outside the theme tree.
class LandfallActiveTheme extends InheritedWidget {
  const LandfallActiveTheme({
    super.key,
    required this.tokens,
    required super.child,
  });

  final LandfallThemeTokens tokens;

  /// Returns the nearest [LandfallThemeTokens], or [LandfallThemeTokens.defaults]
  /// when no [LandfallActiveTheme] ancestor exists.
  static LandfallThemeTokens of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<LandfallActiveTheme>();
    return result?.tokens ?? LandfallThemeTokens.defaults();
  }

  @override
  bool updateShouldNotify(LandfallActiveTheme oldWidget) =>
      tokens != oldWidget.tokens;
}

/// Parses a token color string into a Flutter [Color].
///
/// Supports:
///   - `#RRGGBB` — fully opaque hex
///   - `#RRGGBBAA` — hex with alpha
///   - `rgba(r, g, b, a)` — CSS-style RGBA (alpha 0.0–1.0)
///
/// Returns opaque black for unrecognised formats.
Color tokenColor(String value) {
  final s = value.trim();

  if (s.startsWith('rgba(')) {
    final inner = s.substring(5, s.length - 1);
    final parts = inner.split(',').map((p) => p.trim()).toList();
    if (parts.length == 4) {
      final r = int.parse(parts[0]);
      final g = int.parse(parts[1]);
      final b = int.parse(parts[2]);
      final a = (double.parse(parts[3]) * 255).round().clamp(0, 255);
      return Color.fromARGB(a, r, g, b);
    }
  }

  if (s.startsWith('#')) {
    final hex = s.substring(1);
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    // CSS #RRGGBBAA → Flutter 0xAARRGGBB: move last two bytes to front.
    if (hex.length == 8) {
      final aa = hex.substring(6);
      final rrggbb = hex.substring(0, 6);
      return Color(int.parse('$aa$rrggbb', radix: 16));
    }
  }

  return const Color(0xFF000000);
}
