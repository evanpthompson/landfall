import 'package:flutter/material.dart';
import 'package:ui_kit/src/theme/landfall_colors.dart';

/// Landfall typography scale.
///
/// All sizes are calibrated for 1920×1080 viewed at ~8–10 feet.
/// The scale favors legibility over density — fewer, larger text elements
/// rather than information-dense small text.
abstract final class LandfallTypography {
  // ── Clock & Time ────────────────────────────────────────────────────────────

  /// Primary time display. The largest text on the display.
  /// Used for the clock widget hour:minute.
  static const TextStyle timeDisplay = TextStyle(
    fontSize: 144,
    fontWeight: FontWeight.w200,
    letterSpacing: -4,
    color: LandfallColors.textPrimary,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Seconds display. Companion to [timeDisplay].
  static const TextStyle timeSeconds = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w300,
    color: LandfallColors.textSecondary,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ── Date ────────────────────────────────────────────────────────────────────

  /// Date label below the clock. "Tuesday, April 14"
  static const TextStyle dateLabel = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: LandfallColors.textSecondary,
    height: 1.4,
  );

  // ── Card ────────────────────────────────────────────────────────────────────

  /// Card title. The primary heading of a content card.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: LandfallColors.textPrimary,
    height: 1.3,
  );

  /// Card body / secondary text within a card.
  static const TextStyle cardBody = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: LandfallColors.textSecondary,
    height: 1.5,
  );

  /// Card source label. Small badge identifying card origin.
  /// e.g. "agent.claude", "system.weather"
  static const TextStyle cardSource = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    color: LandfallColors.textTertiary,
    height: 1.4,
  );

  // ── Widget Headings ─────────────────────────────────────────────────────────

  /// Widget section heading. Used for labeled groups within a card.
  /// e.g. "5-Day Forecast", "Upcoming Events"
  static const TextStyle widgetHeading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: LandfallColors.textTertiary,
    height: 1.4,
  );

  // ── Weather ─────────────────────────────────────────────────────────────────

  /// Large weather temperature. Primary number in the weather card.
  static const TextStyle weatherTemp = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w200,
    color: LandfallColors.textPrimary,
    height: 1.0,
  );

  /// Weather condition label. "Partly Cloudy", "Sunny"
  static const TextStyle weatherCondition = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: LandfallColors.textSecondary,
    height: 1.4,
  );

  // ── Calendar ────────────────────────────────────────────────────────────────

  /// Calendar event title.
  static const TextStyle eventTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: LandfallColors.textPrimary,
    height: 1.3,
  );

  /// Calendar event time prefix. "2:00 PM"
  static const TextStyle eventTime = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: LandfallColors.textSecondary,
    height: 1.4,
  );

  // ── Settings & UI ──────────────────────────────────────────────────────────

  /// Standard body text for settings and UI screens.
  static const TextStyle body = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: LandfallColors.textPrimary,
    height: 1.5,
  );

  /// Caption / metadata text.
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: LandfallColors.textTertiary,
    height: 1.4,
  );

  /// Button label.
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: LandfallColors.textPrimary,
    height: 1.0,
  );
}
