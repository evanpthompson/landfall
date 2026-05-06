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
      // FontWeight.w200 = index 1
      expect(
        LandfallTypography.timeDisplay.fontWeight,
        equals(FontWeight.w200),
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
}
