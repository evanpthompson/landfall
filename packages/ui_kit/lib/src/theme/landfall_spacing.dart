/// Landfall spacing scale.
///
/// All values are multiples of the 4dp base grid.
/// Use named constants rather than hardcoded numbers throughout the codebase.
abstract final class LandfallSpacing {
  /// 4dp — minimum unit. Tight internal padding.
  static const double xs = 4;

  /// 8dp — compact spacing. Icon padding, tight row gaps.
  static const double sm = 8;

  /// 12dp — small spacing. Between related elements.
  static const double md = 12;

  /// 16dp — base spacing. Default internal card padding.
  static const double lg = 16;

  /// 24dp — comfortable spacing. Between distinct sections.
  static const double xl = 24;

  /// 32dp — generous spacing. Card-to-card gaps, section separators.
  static const double xxl = 32;

  /// 48dp — large spacing. Screen edge margins, major section breaks.
  static const double xxxl = 48;

  /// 64dp — display-scale spacing. Full-bleed section padding.
  static const double display = 64;

  // ── Card ───────────────────────────────────────────────────────────────────

  /// Internal padding for a standard card.
  static const double cardPadding = lg;

  /// Internal padding for a compact (small) card.
  static const double cardPaddingCompact = md;

  /// Border radius for cards.
  static const double cardRadius = 12;

  /// Border width for cards.
  static const double cardBorderWidth = 1;

  // ── Grid ───────────────────────────────────────────────────────────────────

  /// Gap between cards in the display grid.
  static const double gridGap = xl;

  /// Screen edge margin on the display.
  static const double screenMargin = xxxl;
}
