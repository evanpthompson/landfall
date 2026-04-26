import 'package:drift/drift.dart';

/// Stores display settings as a single row (id = 1).
///
/// Uses [insertOnConflictUpdate] for upsert — read is a single `.getSingleOrNull()`.
class DisplaySettingsEntries extends Table {
  IntColumn get id => integer()();
  BoolColumn get dimEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get dimStartHour => integer().withDefault(const Constant(22))();
  IntColumn get dimEndHour => integer().withDefault(const Constant(7))();
  RealColumn get dimLevel => real().withDefault(const Constant(0.85))();
  TextColumn get locationName => text().withDefault(const Constant(''))();
  TextColumn get serverUrl => text().withDefault(const Constant(''))();
  BoolColumn get wizardComplete =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
