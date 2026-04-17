import 'package:drift/drift.dart';

/// Stores the active dashboard layout as a JSON snapshot.
///
/// This table holds a single row (id = 1). Reading returns the saved layout;
/// writing uses `insertOnConflictUpdate` to replace it in place.
///
/// The full card list is serialized as JSON rather than a relational schema
/// because layout configuration changes as an atomic unit — there is no use
/// case for querying individual card slots independently at this phase.
class LayoutEntries extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get columnsCount => integer()();
  IntColumn get rowsCount => integer()();

  /// JSON-encoded `List<CardConfig>`.
  TextColumn get cardsJson => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
