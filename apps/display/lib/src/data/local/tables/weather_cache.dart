import 'package:drift/drift.dart';

/// Cached current weather conditions. Single row — always upserted with id = 1.
class WeatherCurrentCacheEntries extends Table {
  IntColumn get id => integer()();
  TextColumn get locationName => text()();
  RealColumn get tempC => real()();
  RealColumn get feelsLikeC => real()();
  TextColumn get condition => text()();
  TextColumn get iconCode => text()();
  IntColumn get humidity => integer()();
  RealColumn get windSpeedMs => real()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Cached forecast days. All rows are replaced wholesale on each successful
/// server fetch. Rows are keyed by forecastDate for ordering.
class WeatherForecastDayCacheEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get locationName => text()();
  DateTimeColumn get forecastDate => dateTime()();
  RealColumn get minTempC => real()();
  RealColumn get maxTempC => real()();
  TextColumn get condition => text()();
  TextColumn get iconCode => text()();
}
