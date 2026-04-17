import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('LandfallSpacing', () {
    test('all values are multiples of 4', () {
      final values = [
        LandfallSpacing.xs,
        LandfallSpacing.sm,
        LandfallSpacing.md,
        LandfallSpacing.lg,
        LandfallSpacing.xl,
        LandfallSpacing.xxl,
        LandfallSpacing.xxxl,
        LandfallSpacing.display,
        LandfallSpacing.cardPadding,
        LandfallSpacing.cardPaddingCompact,
      ];
      for (final value in values) {
        expect(
          value % 4,
          equals(0),
          reason: '$value is not a multiple of 4',
        );
      }
    });

    test('scale is strictly ascending', () {
      final scale = [
        LandfallSpacing.xs,
        LandfallSpacing.sm,
        LandfallSpacing.md,
        LandfallSpacing.lg,
        LandfallSpacing.xl,
        LandfallSpacing.xxl,
        LandfallSpacing.xxxl,
        LandfallSpacing.display,
      ];
      for (var i = 0; i < scale.length - 1; i++) {
        expect(scale[i], lessThan(scale[i + 1]));
      }
    });

    test('cardRadius is positive', () {
      expect(LandfallSpacing.cardRadius, greaterThan(0));
    });

    test('screenMargin is larger than gridGap', () {
      expect(LandfallSpacing.screenMargin, greaterThan(LandfallSpacing.gridGap));
    });
  });
}
