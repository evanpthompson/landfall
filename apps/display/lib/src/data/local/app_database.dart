import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:display/src/data/local/tables/display_settings_table.dart';
import 'package:display/src/data/local/tables/layout_entries.dart';
import 'package:display/src/data/local/tables/weather_cache.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LayoutEntries,
  WeatherCurrentCacheEntries,
  WeatherForecastDayCacheEntries,
  DisplaySettingsEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for tests — pass an in-memory [QueryExecutor] directly.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(weatherCurrentCacheEntries);
            await m.createTable(weatherForecastDayCacheEntries);
          }
          if (from < 3) {
            await m.createTable(displaySettingsEntries);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'landfall.db'));
    return NativeDatabase.createInBackground(file);
  });
}
