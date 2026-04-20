import 'package:test/test.dart';

import 'package:landfall_server/src/weather/open_weather_map_service.dart';

// Minimal OWM /weather response fixture.
Map<String, dynamic> _currentFixture({
  double temp = 18.5,
  double feelsLike = 17.0,
  String description = 'clear sky',
  String icon = '01d',
  int humidity = 55,
  double windSpeed = 3.2,
}) =>
    {
      'main': {
        'temp': temp,
        'feels_like': feelsLike,
        'humidity': humidity,
      },
      'weather': [
        {'description': description, 'icon': icon},
      ],
      'wind': {'speed': windSpeed},
    };

// Builds a single 3-hour slot entry for the forecast list fixture.
Map<String, dynamic> _slot({
  required int epochSeconds,
  required double temp,
  String description = 'light rain',
  String icon = '10d',
}) =>
    {
      'dt': epochSeconds,
      'main': {'temp': temp},
      'weather': [
        {'description': description, 'icon': icon},
      ],
    };

// Epoch seconds for a specific UTC datetime (quick helper).
int _epoch(int year, int month, int day, int hour) =>
    DateTime.utc(year, month, day, hour).millisecondsSinceEpoch ~/ 1000;

void main() {
  final fetchedAt = DateTime.utc(2026, 4, 19, 12, 0);

  group('OpenWeatherMapService.parseCurrent', () {
    test('maps all fields from OWM current weather response', () {
      final row = OpenWeatherMapService.parseCurrent(
        _currentFixture(),
        'Chicago',
        fetchedAt,
      );

      expect(row.locationName, equals('Chicago'));
      expect(row.tempC, equals(18.5));
      expect(row.feelsLikeC, equals(17.0));
      expect(row.condition, equals('clear sky'));
      expect(row.iconCode, equals('01d'));
      expect(row.humidity, equals(55));
      expect(row.windSpeedMs, equals(3.2));
      expect(row.fetchedAt, equals(fetchedAt));
    });

    test('coerces integer temp to double', () {
      final row = OpenWeatherMapService.parseCurrent(
        _currentFixture(temp: 20, feelsLike: 18),
        'Chicago',
        fetchedAt,
      );
      expect(row.tempC, isA<double>());
      expect(row.tempC, equals(20.0));
    });
  });

  group('OpenWeatherMapService.parseForecast', () {
    test('aggregates 3-hour slots into daily min/max', () {
      // Day 1: three slots at 6h/12h/18h with temps 10, 20, 15.
      final json = {
        'list': [
          _slot(epochSeconds: _epoch(2026, 4, 20, 6), temp: 10),
          _slot(epochSeconds: _epoch(2026, 4, 20, 12), temp: 20, icon: 'noon'),
          _slot(epochSeconds: _epoch(2026, 4, 20, 18), temp: 15),
        ],
      };

      final rows = OpenWeatherMapService.parseForecast(
        json,
        'Chicago',
        fetchedAt,
      );

      expect(rows.length, equals(1));
      expect(rows.first.forecastDate, equals(DateTime.utc(2026, 4, 20)));
      expect(rows.first.minTempC, equals(10.0));
      expect(rows.first.maxTempC, equals(20.0));
    });

    test('uses noon slot as representative condition', () {
      final json = {
        'list': [
          _slot(
            epochSeconds: _epoch(2026, 4, 20, 6),
            temp: 10,
            description: 'early morning',
            icon: 'early',
          ),
          _slot(
            epochSeconds: _epoch(2026, 4, 20, 12),
            temp: 20,
            description: 'noon clouds',
            icon: 'noon',
          ),
          _slot(
            epochSeconds: _epoch(2026, 4, 20, 18),
            temp: 15,
            description: 'evening rain',
            icon: 'late',
          ),
        ],
      };

      final rows = OpenWeatherMapService.parseForecast(
        json,
        'Chicago',
        fetchedAt,
      );

      expect(rows.first.condition, equals('noon clouds'));
      expect(rows.first.iconCode, equals('noon'));
    });

    test('falls back to first available slot when no noon slot present', () {
      final json = {
        'list': [
          _slot(
            epochSeconds: _epoch(2026, 4, 20, 6),
            temp: 10,
            description: 'first',
            icon: 'a',
          ),
          _slot(
            epochSeconds: _epoch(2026, 4, 20, 9),
            temp: 15,
            description: 'second',
            icon: 'b',
          ),
        ],
      };

      final rows = OpenWeatherMapService.parseForecast(
        json,
        'Chicago',
        fetchedAt,
      );

      // No noon slot — first available slot is used.
      expect(rows.first.condition, equals('first'));
    });

    test('returns up to 5 days', () {
      // Build 6 days of single-slot data.
      final slots = <Map<String, dynamic>>[];
      for (var i = 0; i < 6; i++) {
        slots.add(_slot(
          epochSeconds: _epoch(2026, 4, 20 + i, 12),
          temp: 15.0 + i,
        ));
      }

      final rows = OpenWeatherMapService.parseForecast(
        {'list': slots},
        'Chicago',
        fetchedAt,
      );

      expect(rows.length, equals(5));
    });

    test('days are ordered oldest-first', () {
      final json = {
        'list': [
          _slot(epochSeconds: _epoch(2026, 4, 22, 12), temp: 20),
          _slot(epochSeconds: _epoch(2026, 4, 20, 12), temp: 18),
          _slot(epochSeconds: _epoch(2026, 4, 21, 12), temp: 19),
        ],
      };

      final rows = OpenWeatherMapService.parseForecast(
        json,
        'Chicago',
        fetchedAt,
      );

      expect(rows[0].forecastDate, equals(DateTime.utc(2026, 4, 20)));
      expect(rows[1].forecastDate, equals(DateTime.utc(2026, 4, 21)));
      expect(rows[2].forecastDate, equals(DateTime.utc(2026, 4, 22)));
    });

    test('sets locationName and fetchedAt on all rows', () {
      final json = {
        'list': [
          _slot(epochSeconds: _epoch(2026, 4, 20, 12), temp: 18),
          _slot(epochSeconds: _epoch(2026, 4, 21, 12), temp: 19),
        ],
      };

      final rows = OpenWeatherMapService.parseForecast(
        json,
        'Chicago',
        fetchedAt,
      );

      for (final row in rows) {
        expect(row.locationName, equals('Chicago'));
        expect(row.fetchedAt, equals(fetchedAt));
      }
    });
  });
}
