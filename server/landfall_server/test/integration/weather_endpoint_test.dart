import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

final _fetchedAt = DateTime.utc(2026, 4, 19, 12, 0);

WeatherCurrent _current({
  String locationName = 'Chicago',
  double tempC = 18.5,
  double feelsLikeC = 17.0,
  String condition = 'Clear sky',
  String iconCode = '01d',
  int humidity = 55,
  double windSpeedMs = 3.2,
  DateTime? fetchedAt,
}) =>
    WeatherCurrent(
      locationName: locationName,
      tempC: tempC,
      feelsLikeC: feelsLikeC,
      condition: condition,
      iconCode: iconCode,
      humidity: humidity,
      windSpeedMs: windSpeedMs,
      fetchedAt: fetchedAt ?? _fetchedAt,
    );

WeatherForecast _forecast({
  String locationName = 'Chicago',
  required DateTime forecastDate,
  double minTempC = 10.0,
  double maxTempC = 22.0,
  String condition = 'Partly cloudy',
  String iconCode = '02d',
}) =>
    WeatherForecast(
      locationName: locationName,
      forecastDate: forecastDate,
      minTempC: minTempC,
      maxTempC: maxTempC,
      condition: condition,
      iconCode: iconCode,
      fetchedAt: _fetchedAt,
    );

void main() {
  withServerpod('Given WeatherEndpoint', (sessionBuilder, endpoints) {
    setUp(() async {
      final session = sessionBuilder.build();
      await WeatherCurrent.db.deleteWhere(
        session,
        where: (t) => t.id > 0,
      );
      await WeatherForecast.db.deleteWhere(
        session,
        where: (t) => t.id > 0,
      );
      await session.close();
    });

    group('getCurrentWeather', () {
      test('returns null when no data has been cached', () async {
        final result =
            await endpoints.weather.getCurrentWeather(sessionBuilder);
        expect(result, isNull);
      });

      test('returns the cached current conditions after insert', () async {
        final session = sessionBuilder.build();
        await WeatherCurrent.db.insertRow(session, _current());
        await session.close();

        final result =
            await endpoints.weather.getCurrentWeather(sessionBuilder);

        expect(result, isNotNull);
        expect(result!.locationName, equals('Chicago'));
        expect(result.tempC, equals(18.5));
        expect(result.condition, equals('Clear sky'));
        expect(result.iconCode, equals('01d'));
        expect(result.humidity, equals(55));
      });

      test('returns the most recently fetched row when multiple exist',
          () async {
        final session = sessionBuilder.build();
        await WeatherCurrent.db.insertRow(session, _current());
        await WeatherCurrent.db.insertRow(
          session,
          _current(
            tempC: 5.0,
            condition: 'Old data',
            fetchedAt: DateTime.utc(2026, 4, 18), // yesterday
          ),
        );
        await session.close();

        final result =
            await endpoints.weather.getCurrentWeather(sessionBuilder);
        // Should return the newer row (fetchedAt = 2026-04-19).
        expect(result!.tempC, equals(18.5));
        expect(result.condition, equals('Clear sky'));
      });
    });

    group('getForecast', () {
      test('returns empty list when no forecast data exists', () async {
        final result = await endpoints.weather.getForecast(sessionBuilder);
        expect(result, isEmpty);
      });

      test('returns cached forecast rows ordered by date', () async {
        final session = sessionBuilder.build();
        await WeatherForecast.db.insert(session, [
          _forecast(forecastDate: DateTime.utc(2026, 4, 21)),
          _forecast(forecastDate: DateTime.utc(2026, 4, 19)),
          _forecast(forecastDate: DateTime.utc(2026, 4, 20)),
        ]);
        await session.close();

        final result = await endpoints.weather.getForecast(sessionBuilder);

        expect(result.length, equals(3));
        expect(result[0].forecastDate, equals(DateTime.utc(2026, 4, 19)));
        expect(result[1].forecastDate, equals(DateTime.utc(2026, 4, 20)));
        expect(result[2].forecastDate, equals(DateTime.utc(2026, 4, 21)));
      });

      test('returns all forecast fields', () async {
        final session = sessionBuilder.build();
        await WeatherForecast.db.insertRow(
          session,
          _forecast(
            forecastDate: DateTime.utc(2026, 4, 20),
            minTempC: 8.0,
            maxTempC: 23.0,
            condition: 'Light rain',
            iconCode: '10d',
          ),
        );
        await session.close();

        final result = await endpoints.weather.getForecast(sessionBuilder);

        expect(result.first.minTempC, equals(8.0));
        expect(result.first.maxTempC, equals(23.0));
        expect(result.first.condition, equals('Light rain'));
        expect(result.first.iconCode, equals('10d'));
      });
    });
  });
}
