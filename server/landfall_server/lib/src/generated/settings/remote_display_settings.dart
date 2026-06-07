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

/// Server-side record of a display's user-configurable settings.
/// Excludes device-local fields (serverUrl, wizardComplete, displayId-generation)
/// which have no meaning when edited remotely.
/// One row per displayId — upserted by the display app on startup and on every
/// TV-local edit; pulled by the web settings UI to populate WebDisplayTab.
abstract class RemoteDisplaySettings
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  RemoteDisplaySettings._({
    this.id,
    required this.displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    this.photoSourceJson,
    required this.updatedAt,
  }) : dimEnabled = dimEnabled ?? true,
       dimStartHour = dimStartHour ?? 22,
       dimEndHour = dimEndHour ?? 7,
       dimLevel = dimLevel ?? 0.85,
       locationName = locationName ?? '';

  factory RemoteDisplaySettings({
    int? id,
    required String displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    String? photoSourceJson,
    required DateTime updatedAt,
  }) = _RemoteDisplaySettingsImpl;

  factory RemoteDisplaySettings.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RemoteDisplaySettings(
      id: jsonSerialization['id'] as int?,
      displayId: jsonSerialization['displayId'] as String,
      dimEnabled: jsonSerialization['dimEnabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['dimEnabled']),
      dimStartHour: jsonSerialization['dimStartHour'] as int?,
      dimEndHour: jsonSerialization['dimEndHour'] as int?,
      dimLevel: (jsonSerialization['dimLevel'] as num?)?.toDouble(),
      locationName: jsonSerialization['locationName'] as String?,
      photoSourceJson: jsonSerialization['photoSourceJson'] as String?,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = RemoteDisplaySettingsTable();

  static const db = RemoteDisplaySettingsRepository._();

  @override
  int? id;

  /// The stable display identifier this record belongs to.
  String displayId;

  /// Whether the scheduled dim mode is active.
  bool dimEnabled;

  /// Hour (0–23) at which dimming begins.
  int dimStartHour;

  /// Hour (0–23) at which dimming ends (display brightens).
  int dimEndHour;

  /// Opacity of the dim overlay (0.0 = transparent, 1.0 = fully black).
  double dimLevel;

  /// Optional display-name override for the weather card location label.
  String locationName;

  /// JSON-encoded PhotoSource. Null = default (Serverpod).
  String? photoSourceJson;

  /// When this record was last written. Used for last-write-wins conflict resolution.
  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [RemoteDisplaySettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RemoteDisplaySettings copyWith({
    int? id,
    String? displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    String? photoSourceJson,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RemoteDisplaySettings',
      if (id != null) 'id': id,
      'displayId': displayId,
      'dimEnabled': dimEnabled,
      'dimStartHour': dimStartHour,
      'dimEndHour': dimEndHour,
      'dimLevel': dimLevel,
      'locationName': locationName,
      if (photoSourceJson != null) 'photoSourceJson': photoSourceJson,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RemoteDisplaySettings',
      if (id != null) 'id': id,
      'displayId': displayId,
      'dimEnabled': dimEnabled,
      'dimStartHour': dimStartHour,
      'dimEndHour': dimEndHour,
      'dimLevel': dimLevel,
      'locationName': locationName,
      if (photoSourceJson != null) 'photoSourceJson': photoSourceJson,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static RemoteDisplaySettingsInclude include() {
    return RemoteDisplaySettingsInclude._();
  }

  static RemoteDisplaySettingsIncludeList includeList({
    _i1.WhereExpressionBuilder<RemoteDisplaySettingsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RemoteDisplaySettingsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<RemoteDisplaySettingsTable>? orderByList,
    RemoteDisplaySettingsInclude? include,
  }) {
    return RemoteDisplaySettingsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RemoteDisplaySettings.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(RemoteDisplaySettings.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RemoteDisplaySettingsImpl extends RemoteDisplaySettings {
  _RemoteDisplaySettingsImpl({
    int? id,
    required String displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    String? photoSourceJson,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         displayId: displayId,
         dimEnabled: dimEnabled,
         dimStartHour: dimStartHour,
         dimEndHour: dimEndHour,
         dimLevel: dimLevel,
         locationName: locationName,
         photoSourceJson: photoSourceJson,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [RemoteDisplaySettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RemoteDisplaySettings copyWith({
    Object? id = _Undefined,
    String? displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    Object? photoSourceJson = _Undefined,
    DateTime? updatedAt,
  }) {
    return RemoteDisplaySettings(
      id: id is int? ? id : this.id,
      displayId: displayId ?? this.displayId,
      dimEnabled: dimEnabled ?? this.dimEnabled,
      dimStartHour: dimStartHour ?? this.dimStartHour,
      dimEndHour: dimEndHour ?? this.dimEndHour,
      dimLevel: dimLevel ?? this.dimLevel,
      locationName: locationName ?? this.locationName,
      photoSourceJson: photoSourceJson is String?
          ? photoSourceJson
          : this.photoSourceJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RemoteDisplaySettingsUpdateTable
    extends _i1.UpdateTable<RemoteDisplaySettingsTable> {
  RemoteDisplaySettingsUpdateTable(super.table);

  _i1.ColumnValue<String, String> displayId(String value) => _i1.ColumnValue(
    table.displayId,
    value,
  );

  _i1.ColumnValue<bool, bool> dimEnabled(bool value) => _i1.ColumnValue(
    table.dimEnabled,
    value,
  );

  _i1.ColumnValue<int, int> dimStartHour(int value) => _i1.ColumnValue(
    table.dimStartHour,
    value,
  );

  _i1.ColumnValue<int, int> dimEndHour(int value) => _i1.ColumnValue(
    table.dimEndHour,
    value,
  );

  _i1.ColumnValue<double, double> dimLevel(double value) => _i1.ColumnValue(
    table.dimLevel,
    value,
  );

  _i1.ColumnValue<String, String> locationName(String value) => _i1.ColumnValue(
    table.locationName,
    value,
  );

  _i1.ColumnValue<String, String> photoSourceJson(String? value) =>
      _i1.ColumnValue(
        table.photoSourceJson,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class RemoteDisplaySettingsTable extends _i1.Table<int?> {
  RemoteDisplaySettingsTable({super.tableRelation})
    : super(tableName: 'remote_display_settings') {
    updateTable = RemoteDisplaySettingsUpdateTable(this);
    displayId = _i1.ColumnString(
      'displayId',
      this,
    );
    dimEnabled = _i1.ColumnBool(
      'dimEnabled',
      this,
      hasDefault: true,
    );
    dimStartHour = _i1.ColumnInt(
      'dimStartHour',
      this,
      hasDefault: true,
    );
    dimEndHour = _i1.ColumnInt(
      'dimEndHour',
      this,
      hasDefault: true,
    );
    dimLevel = _i1.ColumnDouble(
      'dimLevel',
      this,
      hasDefault: true,
    );
    locationName = _i1.ColumnString(
      'locationName',
      this,
      hasDefault: true,
    );
    photoSourceJson = _i1.ColumnString(
      'photoSourceJson',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final RemoteDisplaySettingsUpdateTable updateTable;

  /// The stable display identifier this record belongs to.
  late final _i1.ColumnString displayId;

  /// Whether the scheduled dim mode is active.
  late final _i1.ColumnBool dimEnabled;

  /// Hour (0–23) at which dimming begins.
  late final _i1.ColumnInt dimStartHour;

  /// Hour (0–23) at which dimming ends (display brightens).
  late final _i1.ColumnInt dimEndHour;

  /// Opacity of the dim overlay (0.0 = transparent, 1.0 = fully black).
  late final _i1.ColumnDouble dimLevel;

  /// Optional display-name override for the weather card location label.
  late final _i1.ColumnString locationName;

  /// JSON-encoded PhotoSource. Null = default (Serverpod).
  late final _i1.ColumnString photoSourceJson;

  /// When this record was last written. Used for last-write-wins conflict resolution.
  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    displayId,
    dimEnabled,
    dimStartHour,
    dimEndHour,
    dimLevel,
    locationName,
    photoSourceJson,
    updatedAt,
  ];
}

class RemoteDisplaySettingsInclude extends _i1.IncludeObject {
  RemoteDisplaySettingsInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => RemoteDisplaySettings.t;
}

class RemoteDisplaySettingsIncludeList extends _i1.IncludeList {
  RemoteDisplaySettingsIncludeList._({
    _i1.WhereExpressionBuilder<RemoteDisplaySettingsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RemoteDisplaySettings.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => RemoteDisplaySettings.t;
}

class RemoteDisplaySettingsRepository {
  const RemoteDisplaySettingsRepository._();

  /// Returns a list of [RemoteDisplaySettings]s matching the given query parameters.
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
  Future<List<RemoteDisplaySettings>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<RemoteDisplaySettingsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RemoteDisplaySettingsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<RemoteDisplaySettingsTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RemoteDisplaySettings>(
      where: where?.call(RemoteDisplaySettings.t),
      orderBy: orderBy?.call(RemoteDisplaySettings.t),
      orderByList: orderByList?.call(RemoteDisplaySettings.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [RemoteDisplaySettings] matching the given query parameters.
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
  Future<RemoteDisplaySettings?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<RemoteDisplaySettingsTable>? where,
    int? offset,
    _i1.OrderByBuilder<RemoteDisplaySettingsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<RemoteDisplaySettingsTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RemoteDisplaySettings>(
      where: where?.call(RemoteDisplaySettings.t),
      orderBy: orderBy?.call(RemoteDisplaySettings.t),
      orderByList: orderByList?.call(RemoteDisplaySettings.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RemoteDisplaySettings] by its [id] or null if no such row exists.
  Future<RemoteDisplaySettings?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RemoteDisplaySettings>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RemoteDisplaySettings]s in the list and returns the inserted rows.
  ///
  /// The returned [RemoteDisplaySettings]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<RemoteDisplaySettings>> insert(
    _i1.DatabaseSession session,
    List<RemoteDisplaySettings> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<RemoteDisplaySettings>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [RemoteDisplaySettings] and returns the inserted row.
  ///
  /// The returned [RemoteDisplaySettings] will have its `id` field set.
  Future<RemoteDisplaySettings> insertRow(
    _i1.DatabaseSession session,
    RemoteDisplaySettings row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<RemoteDisplaySettings>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [RemoteDisplaySettings]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<RemoteDisplaySettings>> update(
    _i1.DatabaseSession session,
    List<RemoteDisplaySettings> rows, {
    _i1.ColumnSelections<RemoteDisplaySettingsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<RemoteDisplaySettings>(
      rows,
      columns: columns?.call(RemoteDisplaySettings.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RemoteDisplaySettings]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RemoteDisplaySettings> updateRow(
    _i1.DatabaseSession session,
    RemoteDisplaySettings row, {
    _i1.ColumnSelections<RemoteDisplaySettingsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<RemoteDisplaySettings>(
      row,
      columns: columns?.call(RemoteDisplaySettings.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RemoteDisplaySettings] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RemoteDisplaySettings?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<RemoteDisplaySettingsUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<RemoteDisplaySettings>(
      id,
      columnValues: columnValues(RemoteDisplaySettings.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RemoteDisplaySettings]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<RemoteDisplaySettings>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<RemoteDisplaySettingsUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<RemoteDisplaySettingsTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RemoteDisplaySettingsTable>? orderBy,
    _i1.OrderByListBuilder<RemoteDisplaySettingsTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<RemoteDisplaySettings>(
      columnValues: columnValues(RemoteDisplaySettings.t.updateTable),
      where: where(RemoteDisplaySettings.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RemoteDisplaySettings.t),
      orderByList: orderByList?.call(RemoteDisplaySettings.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [RemoteDisplaySettings]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<RemoteDisplaySettings>> delete(
    _i1.DatabaseSession session,
    List<RemoteDisplaySettings> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<RemoteDisplaySettings>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [RemoteDisplaySettings].
  Future<RemoteDisplaySettings> deleteRow(
    _i1.DatabaseSession session,
    RemoteDisplaySettings row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RemoteDisplaySettings>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<RemoteDisplaySettings>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<RemoteDisplaySettingsTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<RemoteDisplaySettings>(
      where: where(RemoteDisplaySettings.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<RemoteDisplaySettingsTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<RemoteDisplaySettings>(
      where: where?.call(RemoteDisplaySettings.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RemoteDisplaySettings] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<RemoteDisplaySettingsTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RemoteDisplaySettings>(
      where: where(RemoteDisplaySettings.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
