import 'package:drift/drift.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/local/app_database.dart';

/// Fetches weather from the Serverpod server and caches the result in Drift.
///
/// On a successful fetch the cache is updated and fresh entities are returned.
/// When the server is unreachable the last cached values are returned instead.
/// Returns null / empty list when neither server nor cache has data yet.
class ServerpodWeatherRepository implements WeatherRepository {
  ServerpodWeatherRepository(this._client, this._db);

  final Client _client;
  final AppDatabase _db;

  @override
  Future<WeatherEntity?> getCurrentWeather() async {
    try {
      final row = await _client.weather.getCurrentWeather();
      if (row == null) return _readCachedCurrent();
      await _writeCachedCurrent(row);
      return _toEntity(row);
    } catch (_) {
      return _readCachedCurrent();
    }
  }

  @override
  Future<List<ForecastDayEntity>> getForecast() async {
    try {
      final rows = await _client.weather.getForecast();
      if (rows.isEmpty) return _readCachedForecast();
      await _writeCachedForecast(rows);
      return rows.map(_toForecastEntity).toList();
    } catch (_) {
      return _readCachedForecast();
    }
  }

  // ── Cache reads ────────────────────────────────────────────────────────────

  Future<WeatherEntity?> _readCachedCurrent() async {
    final row = await (_db.select(_db.weatherCurrentCacheEntries)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row == null) return null;
    return WeatherEntity(
      locationName: row.locationName,
      tempC: row.tempC,
      feelsLikeC: row.feelsLikeC,
      condition: row.condition,
      iconCode: row.iconCode,
      humidity: row.humidity,
      windSpeedMs: row.windSpeedMs,
      fetchedAt: row.fetchedAt,
    );
  }

  Future<List<ForecastDayEntity>> _readCachedForecast() async {
    final rows = await (_db.select(_db.weatherForecastDayCacheEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.forecastDate)]))
        .get();
    return rows
        .map(
          (r) => ForecastDayEntity(
            date: r.forecastDate,
            minTempC: r.minTempC,
            maxTempC: r.maxTempC,
            condition: r.condition,
            iconCode: r.iconCode,
          ),
        )
        .toList();
  }

  // ── Cache writes ───────────────────────────────────────────────────────────

  Future<void> _writeCachedCurrent(WeatherCurrent row) async {
    await _db
        .into(_db.weatherCurrentCacheEntries)
        .insertOnConflictUpdate(
          WeatherCurrentCacheEntriesCompanion.insert(
            id: const Value(1),
            locationName: row.locationName,
            tempC: row.tempC,
            feelsLikeC: row.feelsLikeC,
            condition: row.condition,
            iconCode: row.iconCode,
            humidity: row.humidity,
            windSpeedMs: row.windSpeedMs,
            fetchedAt: row.fetchedAt,
          ),
        );
  }

  Future<void> _writeCachedForecast(List<WeatherForecast> rows) async {
    await _db.transaction(() async {
      await _db.delete(_db.weatherForecastDayCacheEntries).go();
      for (final row in rows) {
        await _db.into(_db.weatherForecastDayCacheEntries).insert(
              WeatherForecastDayCacheEntriesCompanion.insert(
                locationName: row.locationName,
                forecastDate: row.forecastDate,
                minTempC: row.minTempC,
                maxTempC: row.maxTempC,
                condition: row.condition,
                iconCode: row.iconCode,
              ),
            );
      }
    });
  }

  // ── Mappers ────────────────────────────────────────────────────────────────

  WeatherEntity _toEntity(WeatherCurrent row) => WeatherEntity(
        locationName: row.locationName,
        tempC: row.tempC,
        feelsLikeC: row.feelsLikeC,
        condition: row.condition,
        iconCode: row.iconCode,
        humidity: row.humidity,
        windSpeedMs: row.windSpeedMs,
        fetchedAt: row.fetchedAt,
      );

  ForecastDayEntity _toForecastEntity(WeatherForecast row) => ForecastDayEntity(
        date: row.forecastDate,
        minTempC: row.minTempC,
        maxTempC: row.maxTempC,
        condition: row.condition,
        iconCode: row.iconCode,
      );
}
