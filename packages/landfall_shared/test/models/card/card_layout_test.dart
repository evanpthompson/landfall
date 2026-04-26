import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  group('CardLayout', () {
    group('isMultiCell', () {
      test('small returns false', () {
        expect(CardLayout.small.isMultiCell, isFalse);
      });

      test('medium returns true', () {
        expect(CardLayout.medium.isMultiCell, isTrue);
      });

      test('large returns true', () {
        expect(CardLayout.large.isMultiCell, isTrue);
      });

      test('full returns true', () {
        expect(CardLayout.full.isMultiCell, isTrue);
      });

      test('ticker returns false — not a grid card', () {
        expect(CardLayout.ticker.isMultiCell, isFalse);
      });
    });

    group('isTickerLayout', () {
      test('ticker returns true', () {
        expect(CardLayout.ticker.isTickerLayout, isTrue);
      });

      test('all grid layouts return false', () {
        for (final l in [
          CardLayout.small,
          CardLayout.medium,
          CardLayout.large,
          CardLayout.full,
        ]) {
          expect(l.isTickerLayout, isFalse, reason: '$l should not be ticker');
        }
      });
    });

    test('ticker is a valid enum value', () {
      expect(CardLayout.values, contains(CardLayout.ticker));
    });
  });
}
