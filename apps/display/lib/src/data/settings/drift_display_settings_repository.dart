import 'package:drift/drift.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/local/app_database.dart';

/// Production [DisplaySettingsRepository] backed by the local Drift/SQLite DB.
///
/// Stores a single settings row (id = 1). Returns [DisplaySettings] defaults
/// on first read — settings are persisted only after an explicit [saveSettings].
class DriftDisplaySettingsRepository implements DisplaySettingsRepository {
  DriftDisplaySettingsRepository(this._db);

  static const _settingsId = 1;

  final AppDatabase _db;

  @override
  Future<DisplaySettings> getSettings() async {
    final entry = await (_db.select(_db.displaySettingsEntries)
          ..where((t) => t.id.equals(_settingsId)))
        .getSingleOrNull();

    if (entry == null) return const DisplaySettings();

    return DisplaySettings(
      dimEnabled: entry.dimEnabled,
      dimStartHour: entry.dimStartHour,
      dimEndHour: entry.dimEndHour,
      dimLevel: entry.dimLevel,
      locationName: entry.locationName,
      serverUrl: entry.serverUrl,
      wizardComplete: entry.wizardComplete,
    );
  }

  @override
  Future<void> saveSettings(DisplaySettings settings) async {
    await _db.into(_db.displaySettingsEntries).insertOnConflictUpdate(
          DisplaySettingsEntriesCompanion(
            id: const Value(_settingsId),
            dimEnabled: Value(settings.dimEnabled),
            dimStartHour: Value(settings.dimStartHour),
            dimEndHour: Value(settings.dimEndHour),
            dimLevel: Value(settings.dimLevel),
            locationName: Value(settings.locationName),
            serverUrl: Value(settings.serverUrl),
            wizardComplete: Value(settings.wizardComplete),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}
