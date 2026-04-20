import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  group('WeatherEntity', () {
    final fetchedAt = DateTime.utc(2026, 4, 19, 12, 0);

    WeatherEntity make({
      String locationName = 'Chicago',
      double tempC = 18.5,
      double feelsLikeC = 17.0,
      String condition = 'Clear',
      String iconCode = '01d',
      int humidity = 55,
      double windSpeedMs = 3.2,
      DateTime? fetchedAt,
    }) =>
        WeatherEntity(
          locationName: locationName,
          tempC: tempC,
          feelsLikeC: feelsLikeC,
          condition: condition,
          iconCode: iconCode,
          humidity: humidity,
          windSpeedMs: windSpeedMs,
          fetchedAt: fetchedAt ?? DateTime.utc(2026, 4, 19, 12, 0),
        );

    test('stores all fields', () {
      final entity = make();
      expect(entity.locationName, equals('Chicago'));
      expect(entity.tempC, equals(18.5));
      expect(entity.feelsLikeC, equals(17.0));
      expect(entity.condition, equals('Clear'));
      expect(entity.iconCode, equals('01d'));
      expect(entity.humidity, equals(55));
      expect(entity.windSpeedMs, equals(3.2));
      expect(entity.fetchedAt, equals(fetchedAt));
    });

    test('equality holds for identical values', () {
      expect(make(), equals(make()));
    });

    test('equality fails when any field differs', () {
      expect(make(tempC: 20.0), isNot(equals(make(tempC: 18.5))));
      expect(make(iconCode: '09n'), isNot(equals(make(iconCode: '01d'))));
    });

    test('hashCode matches for equal instances', () {
      expect(make().hashCode, equals(make().hashCode));
    });

    test('toString includes location and temp', () {
      final s = make().toString();
      expect(s, contains('Chicago'));
      expect(s, contains('18.5'));
    });
  });
}
