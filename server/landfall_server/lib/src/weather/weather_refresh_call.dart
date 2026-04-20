// ignore_for_file: deprecated_member_use

import 'package:serverpod/serverpod.dart';

import 'open_weather_map_service.dart';

const _refreshInterval = Duration(minutes: 10);

/// Periodically fetches weather from OpenWeatherMap and caches it in the DB.
///
/// Registered with Serverpod as 'weatherRefresh'. Because this class overrides
/// [invoke] directly (executable FutureCall), it uses the registration API
/// rather than the Serverpod-generated dispatcher. The generated dispatcher
/// only applies to spec/abstract FutureCalls.
///
/// The call reschedules itself on every run so the refresh cadence is
/// self-healing — a transient API failure doesn't stop future refreshes.
class WeatherRefreshCall extends FutureCall<SerializableModel> {
  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      await OpenWeatherMapService().refreshWeather(session);
    } catch (e, stackTrace) {
      session.log(
        'Weather refresh failed: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    } finally {
      // Always reschedule after each run (success or failure) so the
      // 10-minute cadence continues uninterrupted.
      await session.serverpod.futureCallWithDelay(
        'weatherRefresh',
        null,
        _refreshInterval,
      );
    }
  }
}
