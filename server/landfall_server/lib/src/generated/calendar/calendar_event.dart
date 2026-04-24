/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

/// A calendar event cached from an external provider.
///
/// Events are scoped to a LinkedCredential + calendarId pair.
/// On each refresh, all events for a given credential are replaced.
/// All-day events have startTime and endTime set to midnight UTC of the event date.
abstract class CalendarEvent
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  CalendarEvent._({
    this.id,
    required this.credentialId,
    required this.calendarId,
    required this.calendarName,
    required this.externalEventId,
    required this.title,
    required this.startTime,
    required this.endTime,
    bool? isAllDay,
    this.location,
    this.description,
    required this.fetchedAt,
  }) : isAllDay = isAllDay ?? false;

  factory CalendarEvent({
    int? id,
    required int credentialId,
    required String calendarId,
    required String calendarName,
    required String externalEventId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    bool? isAllDay,
    String? location,
    String? description,
    required DateTime fetchedAt,
  }) = _CalendarEventImpl;

  factory CalendarEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return CalendarEvent(
      id: jsonSerialization['id'] as int?,
      credentialId: jsonSerialization['credentialId'] as int,
      calendarId: jsonSerialization['calendarId'] as String,
      calendarName: jsonSerialization['calendarName'] as String,
      externalEventId: jsonSerialization['externalEventId'] as String,
      title: jsonSerialization['title'] as String,
      startTime: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['startTime'],
      ),
      endTime: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endTime']),
      isAllDay: jsonSerialization['isAllDay'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isAllDay']),
      location: jsonSerialization['location'] as String?,
      description: jsonSerialization['description'] as String?,
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  static final t = CalendarEventTable();

  static const db = CalendarEventRepository._();

  @override
  int? id;

  /// The LinkedCredential this event was fetched from.
  int credentialId;

  /// Provider-assigned calendar ID within the account.
  /// e.g. "primary", "user@example.com", or a long opaque Google calendar ID.
  String calendarId;

  /// Human-readable calendar name, e.g. "Work", "Family", "Shared".
  String calendarName;

  /// Provider-assigned event ID. Stable across refreshes for the same event.
  String externalEventId;

  /// Event title / summary.
  String title;

  /// Start time in UTC. For all-day events, midnight UTC of the event date.
  DateTime startTime;

  /// End time in UTC. For all-day events, midnight UTC of the day after the event.
  DateTime endTime;

  /// True for all-day events (no specific time).
  bool isAllDay;

  /// Optional location string.
  String? location;

  /// Optional event description / notes.
  String? description;

  /// When this event was last fetched from the upstream provider.
  DateTime fetchedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [CalendarEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CalendarEvent copyWith({
    int? id,
    int? credentialId,
    String? calendarId,
    String? calendarName,
    String? externalEventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? location,
    String? description,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CalendarEvent',
      if (id != null) 'id': id,
      'credentialId': credentialId,
      'calendarId': calendarId,
      'calendarName': calendarName,
      'externalEventId': externalEventId,
      'title': title,
      'startTime': startTime.toJson(),
      'endTime': endTime.toJson(),
      'isAllDay': isAllDay,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CalendarEvent',
      if (id != null) 'id': id,
      'credentialId': credentialId,
      'calendarId': calendarId,
      'calendarName': calendarName,
      'externalEventId': externalEventId,
      'title': title,
      'startTime': startTime.toJson(),
      'endTime': endTime.toJson(),
      'isAllDay': isAllDay,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  static CalendarEventInclude include() {
    return CalendarEventInclude._();
  }

  static CalendarEventIncludeList includeList({
    _i1.WhereExpressionBuilder<CalendarEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CalendarEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CalendarEventTable>? orderByList,
    CalendarEventInclude? include,
  }) {
    return CalendarEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CalendarEvent.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(CalendarEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CalendarEventImpl extends CalendarEvent {
  _CalendarEventImpl({
    int? id,
    required int credentialId,
    required String calendarId,
    required String calendarName,
    required String externalEventId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    bool? isAllDay,
    String? location,
    String? description,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         credentialId: credentialId,
         calendarId: calendarId,
         calendarName: calendarName,
         externalEventId: externalEventId,
         title: title,
         startTime: startTime,
         endTime: endTime,
         isAllDay: isAllDay,
         location: location,
         description: description,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [CalendarEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CalendarEvent copyWith({
    Object? id = _Undefined,
    int? credentialId,
    String? calendarId,
    String? calendarName,
    String? externalEventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    Object? location = _Undefined,
    Object? description = _Undefined,
    DateTime? fetchedAt,
  }) {
    return CalendarEvent(
      id: id is int? ? id : this.id,
      credentialId: credentialId ?? this.credentialId,
      calendarId: calendarId ?? this.calendarId,
      calendarName: calendarName ?? this.calendarName,
      externalEventId: externalEventId ?? this.externalEventId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location is String? ? location : this.location,
      description: description is String? ? description : this.description,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class CalendarEventUpdateTable extends _i1.UpdateTable<CalendarEventTable> {
  CalendarEventUpdateTable(super.table);

  _i1.ColumnValue<int, int> credentialId(int value) => _i1.ColumnValue(
    table.credentialId,
    value,
  );

  _i1.ColumnValue<String, String> calendarId(String value) => _i1.ColumnValue(
    table.calendarId,
    value,
  );

  _i1.ColumnValue<String, String> calendarName(String value) => _i1.ColumnValue(
    table.calendarName,
    value,
  );

  _i1.ColumnValue<String, String> externalEventId(String value) =>
      _i1.ColumnValue(
        table.externalEventId,
        value,
      );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> startTime(DateTime value) =>
      _i1.ColumnValue(
        table.startTime,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> endTime(DateTime value) =>
      _i1.ColumnValue(
        table.endTime,
        value,
      );

  _i1.ColumnValue<bool, bool> isAllDay(bool value) => _i1.ColumnValue(
    table.isAllDay,
    value,
  );

  _i1.ColumnValue<String, String> location(String? value) => _i1.ColumnValue(
    table.location,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> fetchedAt(DateTime value) =>
      _i1.ColumnValue(
        table.fetchedAt,
        value,
      );
}

class CalendarEventTable extends _i1.Table<int?> {
  CalendarEventTable({super.tableRelation})
    : super(tableName: 'calendar_events') {
    updateTable = CalendarEventUpdateTable(this);
    credentialId = _i1.ColumnInt(
      'credentialId',
      this,
    );
    calendarId = _i1.ColumnString(
      'calendarId',
      this,
    );
    calendarName = _i1.ColumnString(
      'calendarName',
      this,
    );
    externalEventId = _i1.ColumnString(
      'externalEventId',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    startTime = _i1.ColumnDateTime(
      'startTime',
      this,
    );
    endTime = _i1.ColumnDateTime(
      'endTime',
      this,
    );
    isAllDay = _i1.ColumnBool(
      'isAllDay',
      this,
      hasDefault: true,
    );
    location = _i1.ColumnString(
      'location',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    fetchedAt = _i1.ColumnDateTime(
      'fetchedAt',
      this,
    );
  }

  late final CalendarEventUpdateTable updateTable;

  /// The LinkedCredential this event was fetched from.
  late final _i1.ColumnInt credentialId;

  /// Provider-assigned calendar ID within the account.
  /// e.g. "primary", "user@example.com", or a long opaque Google calendar ID.
  late final _i1.ColumnString calendarId;

  /// Human-readable calendar name, e.g. "Work", "Family", "Shared".
  late final _i1.ColumnString calendarName;

  /// Provider-assigned event ID. Stable across refreshes for the same event.
  late final _i1.ColumnString externalEventId;

  /// Event title / summary.
  late final _i1.ColumnString title;

  /// Start time in UTC. For all-day events, midnight UTC of the event date.
  late final _i1.ColumnDateTime startTime;

  /// End time in UTC. For all-day events, midnight UTC of the day after the event.
  late final _i1.ColumnDateTime endTime;

  /// True for all-day events (no specific time).
  late final _i1.ColumnBool isAllDay;

  /// Optional location string.
  late final _i1.ColumnString location;

  /// Optional event description / notes.
  late final _i1.ColumnString description;

  /// When this event was last fetched from the upstream provider.
  late final _i1.ColumnDateTime fetchedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    credentialId,
    calendarId,
    calendarName,
    externalEventId,
    title,
    startTime,
    endTime,
    isAllDay,
    location,
    description,
    fetchedAt,
  ];
}

class CalendarEventInclude extends _i1.IncludeObject {
  CalendarEventInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => CalendarEvent.t;
}

class CalendarEventIncludeList extends _i1.IncludeList {
  CalendarEventIncludeList._({
    _i1.WhereExpressionBuilder<CalendarEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CalendarEvent.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => CalendarEvent.t;
}

class CalendarEventRepository {
  const CalendarEventRepository._();

  /// Returns a list of [CalendarEvent]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<CalendarEvent>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CalendarEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CalendarEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CalendarEventTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CalendarEvent>(
      where: where?.call(CalendarEvent.t),
      orderBy: orderBy?.call(CalendarEvent.t),
      orderByList: orderByList?.call(CalendarEvent.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [CalendarEvent] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<CalendarEvent?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CalendarEventTable>? where,
    int? offset,
    _i1.OrderByBuilder<CalendarEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CalendarEventTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CalendarEvent>(
      where: where?.call(CalendarEvent.t),
      orderBy: orderBy?.call(CalendarEvent.t),
      orderByList: orderByList?.call(CalendarEvent.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CalendarEvent] by its [id] or null if no such row exists.
  Future<CalendarEvent?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CalendarEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CalendarEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [CalendarEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<CalendarEvent>> insert(
    _i1.DatabaseSession session,
    List<CalendarEvent> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<CalendarEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [CalendarEvent] and returns the inserted row.
  ///
  /// The returned [CalendarEvent] will have its `id` field set.
  Future<CalendarEvent> insertRow(
    _i1.DatabaseSession session,
    CalendarEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<CalendarEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [CalendarEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<CalendarEvent>> update(
    _i1.DatabaseSession session,
    List<CalendarEvent> rows, {
    _i1.ColumnSelections<CalendarEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<CalendarEvent>(
      rows,
      columns: columns?.call(CalendarEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CalendarEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CalendarEvent> updateRow(
    _i1.DatabaseSession session,
    CalendarEvent row, {
    _i1.ColumnSelections<CalendarEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<CalendarEvent>(
      row,
      columns: columns?.call(CalendarEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CalendarEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CalendarEvent?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<CalendarEventUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<CalendarEvent>(
      id,
      columnValues: columnValues(CalendarEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CalendarEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<CalendarEvent>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<CalendarEventUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<CalendarEventTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CalendarEventTable>? orderBy,
    _i1.OrderByListBuilder<CalendarEventTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<CalendarEvent>(
      columnValues: columnValues(CalendarEvent.t.updateTable),
      where: where(CalendarEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CalendarEvent.t),
      orderByList: orderByList?.call(CalendarEvent.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [CalendarEvent]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<CalendarEvent>> delete(
    _i1.DatabaseSession session,
    List<CalendarEvent> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<CalendarEvent>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [CalendarEvent].
  Future<CalendarEvent> deleteRow(
    _i1.DatabaseSession session,
    CalendarEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CalendarEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<CalendarEvent>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<CalendarEventTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<CalendarEvent>(
      where: where(CalendarEvent.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CalendarEventTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<CalendarEvent>(
      where: where?.call(CalendarEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CalendarEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<CalendarEventTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CalendarEvent>(
      where: where(CalendarEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
