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

/// A saved display layout configuration.
/// One row per named layout (weekday, weekend, night, custom).
/// isActive marks which layout is currently shown on the display.
abstract class LayoutConfig
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  LayoutConfig._({
    this.id,
    required this.name,
    String? presetType,
    int? columnsCount,
    int? rowsCount,
    required this.cardsJson,
    bool? isActive,
    required this.updatedAt,
  }) : presetType = presetType ?? 'custom',
       columnsCount = columnsCount ?? 12,
       rowsCount = rowsCount ?? 8,
       isActive = isActive ?? false;

  factory LayoutConfig({
    int? id,
    required String name,
    String? presetType,
    int? columnsCount,
    int? rowsCount,
    required String cardsJson,
    bool? isActive,
    required DateTime updatedAt,
  }) = _LayoutConfigImpl;

  factory LayoutConfig.fromJson(Map<String, dynamic> jsonSerialization) {
    return LayoutConfig(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      presetType: jsonSerialization['presetType'] as String?,
      columnsCount: jsonSerialization['columnsCount'] as int?,
      rowsCount: jsonSerialization['rowsCount'] as int?,
      cardsJson: jsonSerialization['cardsJson'] as String,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = LayoutConfigTable();

  static const db = LayoutConfigRepository._();

  @override
  int? id;

  /// User-facing name (e.g. "Weekday", "Night", "My Custom").
  String name;

  /// Preset category: weekday | weekend | night | custom
  String presetType;

  /// Number of columns in the grid.
  int columnsCount;

  /// Number of rows in the grid.
  int rowsCount;

  /// JSON-encoded List<CardConfig>.
  String cardsJson;

  /// True when this is the layout currently shown on the display.
  bool isActive;

  /// Last modified timestamp.
  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [LayoutConfig]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LayoutConfig copyWith({
    int? id,
    String? name,
    String? presetType,
    int? columnsCount,
    int? rowsCount,
    String? cardsJson,
    bool? isActive,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LayoutConfig',
      if (id != null) 'id': id,
      'name': name,
      'presetType': presetType,
      'columnsCount': columnsCount,
      'rowsCount': rowsCount,
      'cardsJson': cardsJson,
      'isActive': isActive,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LayoutConfig',
      if (id != null) 'id': id,
      'name': name,
      'presetType': presetType,
      'columnsCount': columnsCount,
      'rowsCount': rowsCount,
      'cardsJson': cardsJson,
      'isActive': isActive,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static LayoutConfigInclude include() {
    return LayoutConfigInclude._();
  }

  static LayoutConfigIncludeList includeList({
    _i1.WhereExpressionBuilder<LayoutConfigTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LayoutConfigTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LayoutConfigTable>? orderByList,
    LayoutConfigInclude? include,
  }) {
    return LayoutConfigIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LayoutConfig.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LayoutConfig.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LayoutConfigImpl extends LayoutConfig {
  _LayoutConfigImpl({
    int? id,
    required String name,
    String? presetType,
    int? columnsCount,
    int? rowsCount,
    required String cardsJson,
    bool? isActive,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         name: name,
         presetType: presetType,
         columnsCount: columnsCount,
         rowsCount: rowsCount,
         cardsJson: cardsJson,
         isActive: isActive,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [LayoutConfig]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LayoutConfig copyWith({
    Object? id = _Undefined,
    String? name,
    String? presetType,
    int? columnsCount,
    int? rowsCount,
    String? cardsJson,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return LayoutConfig(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      presetType: presetType ?? this.presetType,
      columnsCount: columnsCount ?? this.columnsCount,
      rowsCount: rowsCount ?? this.rowsCount,
      cardsJson: cardsJson ?? this.cardsJson,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LayoutConfigUpdateTable extends _i1.UpdateTable<LayoutConfigTable> {
  LayoutConfigUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> presetType(String value) => _i1.ColumnValue(
    table.presetType,
    value,
  );

  _i1.ColumnValue<int, int> columnsCount(int value) => _i1.ColumnValue(
    table.columnsCount,
    value,
  );

  _i1.ColumnValue<int, int> rowsCount(int value) => _i1.ColumnValue(
    table.rowsCount,
    value,
  );

  _i1.ColumnValue<String, String> cardsJson(String value) => _i1.ColumnValue(
    table.cardsJson,
    value,
  );

  _i1.ColumnValue<bool, bool> isActive(bool value) => _i1.ColumnValue(
    table.isActive,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class LayoutConfigTable extends _i1.Table<int?> {
  LayoutConfigTable({super.tableRelation})
    : super(tableName: 'layout_configs') {
    updateTable = LayoutConfigUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    presetType = _i1.ColumnString(
      'presetType',
      this,
      hasDefault: true,
    );
    columnsCount = _i1.ColumnInt(
      'columnsCount',
      this,
      hasDefault: true,
    );
    rowsCount = _i1.ColumnInt(
      'rowsCount',
      this,
      hasDefault: true,
    );
    cardsJson = _i1.ColumnString(
      'cardsJson',
      this,
    );
    isActive = _i1.ColumnBool(
      'isActive',
      this,
      hasDefault: true,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final LayoutConfigUpdateTable updateTable;

  /// User-facing name (e.g. "Weekday", "Night", "My Custom").
  late final _i1.ColumnString name;

  /// Preset category: weekday | weekend | night | custom
  late final _i1.ColumnString presetType;

  /// Number of columns in the grid.
  late final _i1.ColumnInt columnsCount;

  /// Number of rows in the grid.
  late final _i1.ColumnInt rowsCount;

  /// JSON-encoded List<CardConfig>.
  late final _i1.ColumnString cardsJson;

  /// True when this is the layout currently shown on the display.
  late final _i1.ColumnBool isActive;

  /// Last modified timestamp.
  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    presetType,
    columnsCount,
    rowsCount,
    cardsJson,
    isActive,
    updatedAt,
  ];
}

class LayoutConfigInclude extends _i1.IncludeObject {
  LayoutConfigInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => LayoutConfig.t;
}

class LayoutConfigIncludeList extends _i1.IncludeList {
  LayoutConfigIncludeList._({
    _i1.WhereExpressionBuilder<LayoutConfigTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LayoutConfig.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => LayoutConfig.t;
}

class LayoutConfigRepository {
  const LayoutConfigRepository._();

  /// Returns a list of [LayoutConfig]s matching the given query parameters.
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
  Future<List<LayoutConfig>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LayoutConfigTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LayoutConfigTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LayoutConfigTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LayoutConfig>(
      where: where?.call(LayoutConfig.t),
      orderBy: orderBy?.call(LayoutConfig.t),
      orderByList: orderByList?.call(LayoutConfig.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LayoutConfig] matching the given query parameters.
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
  Future<LayoutConfig?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LayoutConfigTable>? where,
    int? offset,
    _i1.OrderByBuilder<LayoutConfigTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LayoutConfigTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LayoutConfig>(
      where: where?.call(LayoutConfig.t),
      orderBy: orderBy?.call(LayoutConfig.t),
      orderByList: orderByList?.call(LayoutConfig.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LayoutConfig] by its [id] or null if no such row exists.
  Future<LayoutConfig?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LayoutConfig>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LayoutConfig]s in the list and returns the inserted rows.
  ///
  /// The returned [LayoutConfig]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<LayoutConfig>> insert(
    _i1.DatabaseSession session,
    List<LayoutConfig> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<LayoutConfig>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [LayoutConfig] and returns the inserted row.
  ///
  /// The returned [LayoutConfig] will have its `id` field set.
  Future<LayoutConfig> insertRow(
    _i1.DatabaseSession session,
    LayoutConfig row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LayoutConfig>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LayoutConfig]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LayoutConfig>> update(
    _i1.DatabaseSession session,
    List<LayoutConfig> rows, {
    _i1.ColumnSelections<LayoutConfigTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LayoutConfig>(
      rows,
      columns: columns?.call(LayoutConfig.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LayoutConfig]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LayoutConfig> updateRow(
    _i1.DatabaseSession session,
    LayoutConfig row, {
    _i1.ColumnSelections<LayoutConfigTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LayoutConfig>(
      row,
      columns: columns?.call(LayoutConfig.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LayoutConfig] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LayoutConfig?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<LayoutConfigUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<LayoutConfig>(
      id,
      columnValues: columnValues(LayoutConfig.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LayoutConfig]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<LayoutConfig>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<LayoutConfigUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<LayoutConfigTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LayoutConfigTable>? orderBy,
    _i1.OrderByListBuilder<LayoutConfigTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<LayoutConfig>(
      columnValues: columnValues(LayoutConfig.t.updateTable),
      where: where(LayoutConfig.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LayoutConfig.t),
      orderByList: orderByList?.call(LayoutConfig.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [LayoutConfig]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LayoutConfig>> delete(
    _i1.DatabaseSession session,
    List<LayoutConfig> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LayoutConfig>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LayoutConfig].
  Future<LayoutConfig> deleteRow(
    _i1.DatabaseSession session,
    LayoutConfig row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LayoutConfig>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LayoutConfig>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LayoutConfigTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LayoutConfig>(
      where: where(LayoutConfig.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LayoutConfigTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LayoutConfig>(
      where: where?.call(LayoutConfig.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LayoutConfig] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LayoutConfigTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LayoutConfig>(
      where: where(LayoutConfig.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
