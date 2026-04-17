import 'package:test/test.dart';
import 'package:landfall_shared/landfall_shared.dart';

void main() {
  final t = DateTime(2026, 4, 17, 9, 30, 45);

  group('ClockEntity', () {
    test('stores the DateTime', () {
      final entity = ClockEntity(t);
      expect(entity.now, t);
    });

    test('equality is value-based', () {
      expect(ClockEntity(t), equals(ClockEntity(t)));
      expect(
        ClockEntity(t),
        isNot(equals(ClockEntity(t.add(const Duration(seconds: 1))))),
      );
    });

    test('hashCode is consistent with equality', () {
      expect(ClockEntity(t).hashCode, ClockEntity(t).hashCode);
    });

    test('toString includes the time', () {
      expect(ClockEntity(t).toString(), contains('09:30'));
    });
  });
}
