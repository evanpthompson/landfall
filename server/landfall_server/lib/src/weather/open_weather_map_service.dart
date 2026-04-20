import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Fetches weather data from the OpenWeatherMap API and persists it to the DB.
///
/// Configuration is read from Serverpod passwords:
///   openWeatherMapApiKey — OWM API key
///   weatherLatitude      — decimal latitude, e.g. "41.85"
///   weatherLongitude     — decimal longitude, e.g. "-87.65"
///   weatherLocationName  — display name, e.g. "Chicago"
///
/// [httpClient] is injectable for testing — pass a mock to avoid real HTTP.
class OpenWeatherMapService {
  OpenWeatherMapService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Fetches current conditions and a 5-day forecast, then upserts to the DB.
  ///
  /// Throws [StateError] if required passwords are not configured.
  Future<void> refreshWeather(Session session) async {
    final apiKey = session.passwords['openWeatherMapApiKey'];
    final lat = session.passwords['weatherLatitude'];
    final lon = session.passwords['weatherLongitude'];
    final locationName =
        session.passwords['weatherLocationName'] ?? 'Unknown Location';

    if (apiKey == null || lat == null || lon == null) {
      throw StateError(
        'Weather passwords not configured: openWeatherMapApiKey, '
        'weatherLatitude, and weatherLongitude are required in passwords.yaml.',
      );
    }

    final now = DateTime.now().toUtc();

    await Future.wait([
      _refreshCurrent(session, apiKey, lat, lon, locationName, now),
      _refreshForecast(session, apiKey, lat, lon, locationName, now),
    ]);
  }

  Future<void> _refreshCurrent(
    Session session,
    String apiKey,
    String lat,
    String lon,
    String locationName,
    DateTime now,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey',
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw StateError(
        'OWM current weather returned ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final row = parseCurrent(json, locationName, now);

    await WeatherCurrent.db.deleteWhere(
      session,
      where: (t) => t.locationName.equals(locationName),
    );
    await WeatherCurrent.db.insertRow(session, row);
  }

  Future<void> _refreshForecast(
    Session session,
    String apiKey,
    String lat,
    String lon,
    String locationName,
    DateTime now,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/forecast?lat=$lat&lon=$lon&units=metric&cnt=40&appid=$apiKey',
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw StateError(
        'OWM forecast returned ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = parseForecast(json, locationName, now);

    await WeatherForecast.db.deleteWhere(
      session,
      where: (t) => t.locationName.equals(locationName),
    );
    if (rows.isNotEmpty) {
      await WeatherForecast.db.insert(session, rows);
    }
  }

  /// Parses an OWM `/data/2.5/weather` response body into a [WeatherCurrent].
  ///
  /// Exposed as a static method so it can be tested without a real Session.
  static WeatherCurrent parseCurrent(
    Map<String, dynamic> json,
    String locationName,
    DateTime fetchedAt,
  ) {
    final main = json['main'] as Map<String, dynamic>;
    final weatherList = json['weather'] as List<dynamic>;
    final weather = weatherList.first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;

    return WeatherCurrent(
      locationName: locationName,
      tempC: (main['temp'] as num).toDouble(),
      feelsLikeC: (main['feels_like'] as num).toDouble(),
      condition: weather['description'] as String,
      iconCode: weather['icon'] as String,
      humidity: (main['humidity'] as num).toInt(),
      windSpeedMs: (wind['speed'] as num).toDouble(),
      fetchedAt: fetchedAt,
    );
  }

  /// Parses an OWM `/data/2.5/forecast` response body into daily forecast rows.
  ///
  /// Aggregates 3-hour slots into daily min/max temperature. Uses the noon
  /// slot (or last available) as the representative condition + icon.
  /// Returns up to 5 days ordered oldest-first.
  ///
  /// Exposed as a static method so it can be tested without a real Session.
  static List<WeatherForecast> parseForecast(
    Map<String, dynamic> json,
    String locationName,
    DateTime fetchedAt,
  ) {
    final list = json['list'] as List<dynamic>;

    final Map<String, _DayAccumulator> byDay = {};

    for (final item in list) {
      final entry = item as Map<String, dynamic>;
      final dt = DateTime.fromMillisecondsSinceEpoch(
        ((entry['dt'] as num).toInt()) * 1000,
        isUtc: true,
      );
      final dayKey =
          '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';

      final main = entry['main'] as Map<String, dynamic>;
      final weatherList = entry['weather'] as List<dynamic>;
      final weather = weatherList.first as Map<String, dynamic>;
      final temp = (main['temp'] as num).toDouble();

      final acc = byDay.putIfAbsent(dayKey, _DayAccumulator.new);
      if (temp < acc.minTemp) acc.minTemp = temp;
      if (temp > acc.maxTemp) acc.maxTemp = temp;

      // Use noon slot as the representative condition. If no noon slot
      // exists for this day, the first available slot is used as fallback.
      if (dt.hour == 12 || !acc.hasRepresentative) {
        acc.condition = weather['description'] as String;
        acc.iconCode = weather['icon'] as String;
        acc.hasRepresentative = true;
      }
    }

    final days = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return days.take(5).map((entry) {
      final parts = entry.key.split('-');
      final date = DateTime.utc(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final acc = entry.value;
      return WeatherForecast(
        locationName: locationName,
        forecastDate: date,
        minTempC: acc.minTemp,
        maxTempC: acc.maxTemp,
        condition: acc.condition,
        iconCode: acc.iconCode,
        fetchedAt: fetchedAt,
      );
    }).toList();
  }
}

class _DayAccumulator {
  double minTemp = double.infinity;
  double maxTemp = double.negativeInfinity;
  String condition = '';
  String iconCode = '';
  bool hasRepresentative = false;
}
