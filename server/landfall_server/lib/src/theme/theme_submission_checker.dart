/// A single safe-zone violation found by [ThemeSubmissionChecker].
class SafeZoneViolation {
  const SafeZoneViolation({required this.tokenPath, required this.message});

  /// Dot-separated token path (e.g. "color.alert").
  final String tokenPath;

  /// Human-readable description of the violation.
  final String message;

  @override
  String toString() => '$tokenPath: $message';
}

/// Checks a fully-resolved token map for safe-zone violations.
///
/// Safe-zone rules protect semantic color tokens from being overridden in ways
/// that break their meaning (e.g. making alert colors blue, or primary text
/// invisible). These checks run on top of [ThemeValidator.validate] and only
/// apply to marketplace submissions — locally-uploaded themes skip them.
class ThemeSubmissionChecker {
  ThemeSubmissionChecker._();

  /// Runs all safe-zone checks on [resolvedTokens] and returns any violations.
  /// An empty list means the theme passes all checks.
  static List<SafeZoneViolation> checkSafeZones(
    Map<String, dynamic> resolvedTokens,
  ) {
    final violations = <SafeZoneViolation>[];

    _checkTextPrimary(resolvedTokens, violations);
    _checkSemanticColor(
      resolvedTokens,
      violations,
      token: 'color.alert',
      hueLabel: 'red',
      isCorrectHue: _isReddish,
    );
    _checkSemanticColor(
      resolvedTokens,
      violations,
      token: 'color.success',
      hueLabel: 'green',
      isCorrectHue: _isGreenish,
    );
    _checkSemanticColor(
      resolvedTokens,
      violations,
      token: 'color.warning',
      hueLabel: 'orange or yellow',
      isCorrectHue: _isWarmish,
    );

    return violations;
  }

  // ── individual checks ───────────────────────────────────────────────────────

  static void _checkTextPrimary(
    Map<String, dynamic> tokens,
    List<SafeZoneViolation> violations,
  ) {
    final raw = tokens['color.text.primary'] as String?;
    if (raw == null) return;

    // Hex colors are always fully opaque — no violation.
    if (raw.startsWith('#')) return;

    final alpha = _parseRgbaAlpha(raw);
    if (alpha != null && alpha < 0.8) {
      violations.add(SafeZoneViolation(
        tokenPath: 'color.text.primary',
        message:
            'color.text.primary alpha is $alpha, but it must be at least 0.8 '
            'so primary text remains legible. '
            'Got: "$raw".',
      ));
    }
  }

  static void _checkSemanticColor(
    Map<String, dynamic> tokens,
    List<SafeZoneViolation> violations, {
    required String token,
    required String hueLabel,
    required bool Function(int r, int g, int b) isCorrectHue,
  }) {
    final raw = tokens[token] as String?;
    if (raw == null) return;

    final rgb = _parseRgb(raw);
    if (rgb == null) return; // Malformed — ThemeValidator already caught it.

    if (!isCorrectHue(rgb.$1, rgb.$2, rgb.$3)) {
      violations.add(SafeZoneViolation(
        tokenPath: token,
        message:
            '$token must be a $hueLabel color so it carries its semantic '
            'meaning across all themes. Got: "$raw".',
      ));
    }
  }

  // ── hue predicates ──────────────────────────────────────────────────────────

  /// Red: R dominant, clearly more than G and B.
  static bool _isReddish(int r, int g, int b) =>
      r > 150 && r > g + 60 && r > b + 60;

  /// Green: G dominant, clearly more than R and B.
  static bool _isGreenish(int r, int g, int b) =>
      g > 100 && g > r + 30 && g > b + 10;

  /// Warm (orange/yellow): R high, G moderate-to-high, B low.
  static bool _isWarmish(int r, int g, int b) =>
      r > 150 && g >= 80 && b < 100 && r > b + 80;

  // ── color parsers ───────────────────────────────────────────────────────────

  static final _hexRe = RegExp(r'^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$');
  static final _rgbaRe = RegExp(
    r'^rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9]*\.?[0-9]+)\s*\)$',
  );

  /// Returns (r, g, b) from a hex or rgba string, or null if unparseable.
  static (int, int, int)? _parseRgb(String value) {
    if (_hexRe.hasMatch(value)) {
      final clean = value.substring(1);
      final expanded = clean.length == 3
          ? clean.split('').map((c) => '$c$c').join()
          : clean;
      return (
        int.parse(expanded.substring(0, 2), radix: 16),
        int.parse(expanded.substring(2, 4), radix: 16),
        int.parse(expanded.substring(4, 6), radix: 16),
      );
    }
    final m = _rgbaRe.firstMatch(value);
    if (m != null) {
      return (int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    }
    return null;
  }

  /// Returns the alpha component from an rgba string, or null if not rgba.
  static double? _parseRgbaAlpha(String value) {
    final m = _rgbaRe.firstMatch(value);
    return m != null ? double.parse(m.group(4)!) : null;
  }
}
