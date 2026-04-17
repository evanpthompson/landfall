import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('LandfallColors', () {
    test('background is dark', () {
      // Background should be near-black (luminance < 0.05)
      expect(LandfallColors.background.computeLuminance(), lessThan(0.05));
    });

    test('surface is darker than surfaceElevated', () {
      expect(
        LandfallColors.surface.computeLuminance(),
        lessThan(LandfallColors.surfaceElevated.computeLuminance()),
      );
    });

    test('textPrimary is bright (legible on dark background)', () {
      expect(LandfallColors.textPrimary.computeLuminance(), greaterThan(0.8));
    });

    test('textSecondary is dimmer than textPrimary', () {
      expect(
        LandfallColors.textSecondary.computeLuminance(),
        lessThan(LandfallColors.textPrimary.computeLuminance()),
      );
    });

    test('textTertiary is dimmer than textSecondary', () {
      expect(
        LandfallColors.textTertiary.computeLuminance(),
        lessThan(LandfallColors.textSecondary.computeLuminance()),
      );
    });

    test('accent is fully opaque', () {
      expect((LandfallColors.accent.a * 255.0).round(), equals(255));
    });

    test('accentMuted has reduced opacity', () {
      expect((LandfallColors.accentMuted.a * 255.0).round(), lessThan(255));
    });

    test('all semantic colors are distinct', () {
      final colors = {
        LandfallColors.alert,
        LandfallColors.success,
        LandfallColors.warning,
      };
      expect(colors.length, equals(3));
    });
  });
}
