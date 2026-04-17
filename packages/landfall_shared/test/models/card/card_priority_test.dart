import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  group('CardPriority', () {
    group('defaultTtl', () {
      test('ephemeral returns 2 hours', () {
        expect(CardPriority.ephemeral.defaultTtl, const Duration(hours: 2));
      });

      test('normal returns 24 hours', () {
        expect(CardPriority.normal.defaultTtl, const Duration(hours: 24));
      });

      test('persistent returns null', () {
        expect(CardPriority.persistent.defaultTtl, isNull);
      });
    });

    group('neverExpires', () {
      test('persistent returns true', () {
        expect(CardPriority.persistent.neverExpires, isTrue);
      });

      test('ephemeral returns false', () {
        expect(CardPriority.ephemeral.neverExpires, isFalse);
      });

      test('normal returns false', () {
        expect(CardPriority.normal.neverExpires, isFalse);
      });
    });
  });
}
