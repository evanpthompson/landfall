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
    fontWeight: FontWeight.w300,
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

  /// Card section label. Small ALL-CAPS eyebrow above card content.
  /// e.g. "CLOCK", "WEATHER", "CALENDAR — TODAY"
  static const TextStyle cardLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: LandfallColors.textTertiary,
    height: 1.0,
  );

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

  /// The floor for any text on a card, including chrome such as section
  /// labels.
  ///
  /// Landfall is read from across a room, not from a desk. A 1080p panel at
  /// roughly three metres puts a logical pixel at about half a millimetre of
  /// apparent height, and comfortable reading wants a cap height near ten
  /// millimetres — so text a viewer is expected to *read* starts around 18 px
  /// and content sits well above it. Anything below this floor is not small
  /// text, it is invisible text.
  static const double minChromeFontSize = 16;

  /// The floor for information the card exists to convey — an event title, a
  /// date, a temperature. See [minChromeFontSize] for where the numbers come
  /// from.
  static const double minContentFontSize = 18;

  /// Calendar event title. The thing you are trying to read from the sofa.
  static const TextStyle eventTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: LandfallColors.textPrimary,
    height: 1.25,
  );

  /// Calendar event time prefix. "2:00 PM"
  static const TextStyle eventTime = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: LandfallColors.textSecondary,
    height: 1.3,
  );

  /// Section label inside a calendar view — "TOMORROW", "THIS WEEK".
  static const TextStyle calendarGroupLabel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: LandfallColors.textTertiary,
  );

  /// Day-of-week heading in the weekly and monthly grids.
  static const TextStyle calendarDayHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: LandfallColors.textTertiary,
  );

  /// Supporting detail on an event — the calendar it came from, an empty-day
  /// note.
  static const TextStyle calendarMeta = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: LandfallColors.textTertiary,
  );

  /// Event title inside a dense grid cell, where a full-size title would fit
  /// two words. Still above [minContentFontSize].
  static const TextStyle calendarGridEvent = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: LandfallColors.textPrimary,
    height: 1.2,
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
