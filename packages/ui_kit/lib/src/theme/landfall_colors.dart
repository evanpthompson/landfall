import 'package:flutter/material.dart';

/// Landfall color tokens.
///
/// All colors are defined for a dark ambient display environment.
/// Viewed at couch distance on a TV — contrast and readability at distance
/// are the primary design constraints.
abstract final class LandfallColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────

  /// Primary display background. Near-black with a slight warm tint.
  static const Color background = Color(0xFF0D0D0F);

  /// Card surface. Slightly elevated above background.
  static const Color surface = Color(0xFF1A1A1F);

  /// Elevated card surface. Used for modals, drawers, focused cards.
  static const Color surfaceElevated = Color(0xFF242429);

  // ── Text ───────────────────────────────────────────────────────────────────

  /// Primary text. Used for titles, time display, key data.
  static const Color textPrimary = Color(0xFFF2F2F7);

  /// Secondary text. Used for subtitles, body copy, metadata.
  static const Color textSecondary = Color(0xFF8E8E9A);

  /// Tertiary text. Used for captions, source labels, timestamps.
  static const Color textTertiary = Color(0xFF5A5A6A);

  // ── Accent ─────────────────────────────────────────────────────────────────

  /// Primary accent. Used for interactive elements, highlights, agent badges.
  static const Color accent = Color(0xFF4F8EF7);

  /// Accent with reduced opacity — for hover/focus states and subtle highlights.
  static const Color accentMuted = Color(0x334F8EF7);

  // ── Semantic ───────────────────────────────────────────────────────────────

  /// Alert / warning. Used for urgent cards and error states.
  static const Color alert = Color(0xFFFF6B6B);

  /// Success / confirmation.
  static const Color success = Color(0xFF4CAF7D);

  /// Warning. Used for expiring cards, reconnect prompts.
  static const Color warning = Color(0xFFFFB347);

  // ── Card ───────────────────────────────────────────────────────────────────

  /// Default card border. Subtle separation from background.
  static const Color cardBorder = Color(0xFF2C2C35);

  /// Card border when focused or selected.
  static const Color cardBorderFocused = Color(0xFF4F8EF7);

  // ── Utility ────────────────────────────────────────────────────────────────

  /// Divider / separator lines.
  static const Color divider = Color(0xFF2C2C35);

  /// Scrim overlay for modals and dim mode.
  static const Color scrim = Color(0xCC000000);

  /// Transparent.
  static const Color transparent = Colors.transparent;
}
