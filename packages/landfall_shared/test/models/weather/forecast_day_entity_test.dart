import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  group('ForecastDayEntity', () {
    final date = DateTime.utc(2026, 4, 20);

    ForecastDayEntity make({
      DateTime? date,
      double minTempC = 10.0,
      double maxTempC = 22.0,
      String condition = 'Partly cloudy',
      String iconCode = '02d',
    }) =>
        ForecastDayEntity(
          date: date ?? DateTime.utc(2026, 4, 20),
          minTempC: minTempC,
          maxTempC: maxTempC,
          condition: condition,
          iconCode: iconCode,
        );

    test('stores all fields', () {
      final entity = make();
      expect(entity.date, equals(date));
      expect(entity.minTempC, equals(10.0));
      expect(entity.maxTempC, equals(22.0));
      expect(entity.condition, equals('Partly cloudy'));
      expect(entity.iconCode, equals('02d'));
    });

    test('equality holds for identical values', () {
      expect(make(), equals(make()));
    });

    test('equality fails when any field differs', () {
      expect(
        make(maxTempC: 25.0),
        isNot(equals(make(maxTempC: 22.0))),
      );
      expect(
        make(date: DateTime.utc(2026, 4, 21)),
        isNot(equals(make(date: DateTime.utc(2026, 4, 20)))),
      );
    });

    test('hashCode matches for equal instances', () {
      expect(make().hashCode, equals(make().hashCode));
    });

    test('toString includes date and temp range', () {
      final s = make().toString();
      expect(s, contains('2026-04-20'));
      expect(s, contains('10.0'));
      expect(s, contains('22.0'));
    });
  });
}
