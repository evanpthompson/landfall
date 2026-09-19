import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('LandfallTypography', () {
    test('timeDisplay is the largest text size', () {
      final sizes = [
        LandfallTypography.timeDisplay.fontSize!,
        LandfallTypography.weatherTemp.fontSize!,
        LandfallTypography.dateLabel.fontSize!,
        LandfallTypography.cardTitle.fontSize!,
        LandfallTypography.cardBody.fontSize!,
        LandfallTypography.body.fontSize!,
        LandfallTypography.caption.fontSize!,
      ];
      expect(
        LandfallTypography.timeDisplay.fontSize,
        equals(sizes.reduce((a, b) => a > b ? a : b)),
      );
    });

    test('all styles have non-null fontSize', () {
      final styles = [
        LandfallTypography.timeDisplay,
        LandfallTypography.timeSeconds,
        LandfallTypography.dateLabel,
        LandfallTypography.cardTitle,
        LandfallTypography.cardBody,
        LandfallTypography.cardSource,
        LandfallTypography.widgetHeading,
        LandfallTypography.weatherTemp,
        LandfallTypography.weatherCondition,
        LandfallTypography.eventTitle,
        LandfallTypography.eventTime,
        LandfallTypography.body,
        LandfallTypography.caption,
        LandfallTypography.button,
      ];
      for (final style in styles) {
        expect(style.fontSize, isNotNull);
      }
    });

    test('caption is smaller than body', () {
      expect(
        LandfallTypography.caption.fontSize,
        lessThan(LandfallTypography.body.fontSize!),
      );
    });

    test('timeDisplay uses light weight for ambient legibility', () {
      // FontWeight.w300 = FontWeight.light — thin enough to look elegant at large sizes
      expect(
        LandfallTypography.timeDisplay.fontWeight,
        equals(FontWeight.w300),
      );
    });

    // BUG-04: tabular figures prevent per-tick size jitter as digit glyphs change width.
    test('timeDisplay has tabular figures font feature', () {
      expect(
        LandfallTypography.timeDisplay.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('timeSeconds has tabular figures font feature', () {
      expect(
        LandfallTypography.timeSeconds.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

    test('no style in the system falls below the legibility floor', () {
      // Landfall is read across a room. A style below this floor is not small
      // text, it is text nobody can read — and once one exists, it spreads by
      // copy-paste. See LandfallTypography.minChromeFontSize for the numbers.
      final styles = <String, TextStyle>{
        'timeDisplay': LandfallTypography.timeDisplay,
        'timeSeconds': LandfallTypography.timeSeconds,
        'dateLabel': LandfallTypography.dateLabel,
        'cardLabel': LandfallTypography.cardLabel,
        'cardTitle': LandfallTypography.cardTitle,
        'cardBody': LandfallTypography.cardBody,
        'cardSource': LandfallTypography.cardSource,
        'widgetHeading': LandfallTypography.widgetHeading,
        'weatherTemp': LandfallTypography.weatherTemp,
        'weatherCondition': LandfallTypography.weatherCondition,
        'eventTitle': LandfallTypography.eventTitle,
        'eventTime': LandfallTypography.eventTime,
        'calendarGroupLabel': LandfallTypography.calendarGroupLabel,
        'calendarDayHeader': LandfallTypography.calendarDayHeader,
        'calendarMeta': LandfallTypography.calendarMeta,
        'calendarGridEvent': LandfallTypography.calendarGridEvent,
        'body': LandfallTypography.body,
        'caption': LandfallTypography.caption,
        'button': LandfallTypography.button,
      };

      for (final entry in styles.entries) {
        expect(
          entry.value.fontSize,
          greaterThanOrEqualTo(LandfallTypography.minChromeFontSize),
          reason: '${entry.key} is ${entry.value.fontSize}px',
        );
      }
    });

}
