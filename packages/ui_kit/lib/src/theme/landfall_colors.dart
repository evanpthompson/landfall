import 'package:flutter/material.dart';

/// Landfall color tokens.
///
/// All colors are defined for a dark ambient display environment.
/// Viewed at couch distance on a TV — contrast and readability at distance
/// are the primary design constraints.
abstract final class LandfallColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────

  /// Primary display background — brand Navy.
  static const Color background = Color(0xFF0B1021);

  /// Card surface — brand Slate.
  static const Color surface = Color(0xFF1A2440);

  /// Elevated card surface. Used for modals, drawers, focused cards.
  static const Color surfaceElevated = Color(0xFF1E2C55);

  // ── Text ───────────────────────────────────────────────────────────────────

  /// Primary text. Used for titles, time display, key data.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text. Used for subtitles, body copy, metadata — brand Periwinkle.
  static const Color textSecondary = Color(0xFFA3B1FF);

  /// Tertiary text. Used for captions, source labels, timestamps — brand Steel.
  static const Color textTertiary = Color(0xFF778199);

  // ── Accent ─────────────────────────────────────────────────────────────────

  /// Primary accent — brand Violet. Solid colour for interactive elements.
  static const Color accent = Color(0xFF7861FF);

  /// Cyan highlight — brand Cyan. Used in gradients and glows.
  static const Color accentCyan = Color(0xFF00E5FF);

  /// Accent with reduced opacity — for hover/focus states and subtle highlights.
  static const Color accentMuted = Color(0x337861FF);

  // ── Semantic ───────────────────────────────────────────────────────────────

  /// Alert / warning. Used for urgent cards and error states.
  static const Color alert = Color(0xFFFF6B6B);

  /// Success / confirmation.
  static const Color success = Color(0xFF4CAF7D);

  /// Warning. Used for expiring cards, reconnect prompts.
  static const Color warning = Color(0xFFFFB347);

  // ── Card ───────────────────────────────────────────────────────────────────

  /// Default card border. Subtle separation from background.
  static const Color cardBorder = Color(0xFF232F56);

  /// Card border when focused or selected.
  static const Color cardBorderFocused = Color(0xFF7861FF);

  // ── Utility ────────────────────────────────────────────────────────────────

  /// Divider / separator lines.
  static const Color divider = Color(0xFF232F56);

  /// Scrim overlay for modals and dim mode.
  static const Color scrim = Color(0xCC000000);

  /// Transparent.
  static const Color transparent = Colors.transparent;
}
