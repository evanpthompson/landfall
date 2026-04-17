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
    });
  });
}
