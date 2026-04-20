import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Serves cached weather data to the Flutter display client.
///
/// Data is populated by [WeatherRefreshCall] on a 10-minute schedule.
/// Endpoints return null / empty list gracefully if no data has been
/// cached yet (e.g., on a fresh server start before the first refresh).
class WeatherEndpoint extends Endpoint {
  /// Returns the most recently cached current conditions, or null if none.
  Future<WeatherCurrent?> getCurrentWeather(Session session) async {
    return WeatherCurrent.db.findFirstRow(
      session,
      orderBy: (t) => t.fetchedAt,
      orderDescending: true,
    );
  }

  /// Returns the cached 5-day forecast, oldest day first.
  ///
  /// Returns an empty list if no forecast data has been cached yet.
  Future<List<WeatherForecast>> getForecast(Session session) async {
    return WeatherForecast.db.find(
      session,
      orderBy: (t) => t.forecastDate,
      orderDescending: false,
    );
  }
}
