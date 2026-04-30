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

/// A named dashboard profile — layout, theme, agent card filter, and optional schedule.
/// Replaces the LayoutPresetType enum with a flexible named entity.
/// One row has isActive=true — that is the profile currently shown on the display.
abstract class DashboardProfile
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  DashboardProfile._({
    this.id,
    required this.name,
    required this.slug,
    bool? isActive,
    this.themeId,
    String? cardFilterJson,
    this.scheduleJson,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    required this.cardsJson,
    required this.createdAt,
  }) : isActive = isActive ?? false,
       cardFilterJson = cardFilterJson ?? '{}',
       sortOrder = sortOrder ?? 0,
       columnsCount = columnsCount ?? 12,
       rowsCount = rowsCount ?? 8;

  factory DashboardProfile({
    int? id,
    required String name,
    required String slug,
    bool? isActive,
    String? themeId,
    String? cardFilterJson,
    String? scheduleJson,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    required String cardsJson,
    required DateTime createdAt,
  }) = _DashboardProfileImpl;

  factory DashboardProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return DashboardProfile(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      slug: jsonSerialization['slug'] as String,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      themeId: jsonSerialization['themeId'] as String?,
      cardFilterJson: jsonSerialization['cardFilterJson'] as String?,
      scheduleJson: jsonSerialization['scheduleJson'] as String?,
      sortOrder: jsonSerialization['sortOrder'] as int?,
      columnsCount: jsonSerialization['columnsCount'] as int?,
      rowsCount: jsonSerialization['rowsCount'] as int?,
      cardsJson: jsonSerialization['cardsJson'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = DashboardProfileTable();

  static const db = DashboardProfileRepository._();

  @override
  int? id;

  /// User-facing name (e.g. "Weekday", "Party Mode", "Night Stand").
  String name;

  /// URL-safe slug derived from name. Used by agent LayoutSchema API.
  String slug;

  /// True when this is the profile currently shown on the display.
  bool isActive;

  /// Optional theme identifier. Null = default theme.
  String? themeId;

  /// JSON-encoded ProfileCardFilter. Controls which agent cards are shown.
  String cardFilterJson;

  /// JSON-encoded ProfileSchedule. Null = no automatic scheduling.
  String? scheduleJson;

  /// Sort order for the profile list. Lower = first.
  int sortOrder;

  /// Number of grid columns.
  int columnsCount;

  /// Number of grid rows.
  int rowsCount;

  /// JSON-encoded List<CardConfig> — the card layout for this profile.
  String cardsJson;

  /// When this profile was created.
  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [DashboardProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DashboardProfile copyWith({
    int? id,
    String? name,
    String? slug,
    bool? isActive,
    String? themeId,
    String? cardFilterJson,
    String? scheduleJson,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    String? cardsJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DashboardProfile',
      if (id != null) 'id': id,
      'name': name,
      'slug': slug,
      'isActive': isActive,
      if (themeId != null) 'themeId': themeId,
      'cardFilterJson': cardFilterJson,
      if (scheduleJson != null) 'scheduleJson': scheduleJson,
      'sortOrder': sortOrder,
      'columnsCount': columnsCount,
      'rowsCount': rowsCount,
      'cardsJson': cardsJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DashboardProfile',
      if (id != null) 'id': id,
      'name': name,
      'slug': slug,
      'isActive': isActive,
      if (themeId != null) 'themeId': themeId,
      'cardFilterJson': cardFilterJson,
      if (scheduleJson != null) 'scheduleJson': scheduleJson,
      'sortOrder': sortOrder,
      'columnsCount': columnsCount,
      'rowsCount': rowsCount,
      'cardsJson': cardsJson,
      'createdAt': createdAt.toJson(),
    };
  }

  static DashboardProfileInclude include() {
    return DashboardProfileInclude._();
  }

  static DashboardProfileIncludeList includeList({
    _i1.WhereExpressionBuilder<DashboardProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DashboardProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DashboardProfileTable>? orderByList,
    DashboardProfileInclude? include,
  }) {
    return DashboardProfileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DashboardProfile.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(DashboardProfile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DashboardProfileImpl extends DashboardProfile {
  _DashboardProfileImpl({
    int? id,
    required String name,
    required String slug,
    bool? isActive,
    String? themeId,
    String? cardFilterJson,
    String? scheduleJson,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    required String cardsJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         name: name,
         slug: slug,
         isActive: isActive,
         themeId: themeId,
         cardFilterJson: cardFilterJson,
         scheduleJson: scheduleJson,
         sortOrder: sortOrder,
         columnsCount: columnsCount,
         rowsCount: rowsCount,
         cardsJson: cardsJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DashboardProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DashboardProfile copyWith({
    Object? id = _Undefined,
    String? name,
    String? slug,
    bool? isActive,
    Object? themeId = _Undefined,
    String? cardFilterJson,
    Object? scheduleJson = _Undefined,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    String? cardsJson,
    DateTime? createdAt,
  }) {
    return DashboardProfile(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isActive: isActive ?? this.isActive,
      themeId: themeId is String? ? themeId : this.themeId,
      cardFilterJson: cardFilterJson ?? this.cardFilterJson,
      scheduleJson: scheduleJson is String? ? scheduleJson : this.scheduleJson,
      sortOrder: sortOrder ?? this.sortOrder,
      columnsCount: columnsCount ?? this.columnsCount,
      rowsCount: rowsCount ?? this.rowsCount,
      cardsJson: cardsJson ?? this.cardsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DashboardProfileUpdateTable
    extends _i1.UpdateTable<DashboardProfileTable> {
  DashboardProfileUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> slug(String value) => _i1.ColumnValue(
    table.slug,
    value,
  );

  _i1.ColumnValue<bool, bool> isActive(bool value) => _i1.ColumnValue(
    table.isActive,
    value,
  );

  _i1.ColumnValue<String, String> themeId(String? value) => _i1.ColumnValue(
    table.themeId,
    value,
  );

  _i1.ColumnValue<String, String> cardFilterJson(String value) =>
      _i1.ColumnValue(
        table.cardFilterJson,
        value,
      );

  _i1.ColumnValue<String, String> scheduleJson(String? value) =>
      _i1.ColumnValue(
        table.scheduleJson,
        value,
      );

  _i1.ColumnValue<int, int> sortOrder(int value) => _i1.ColumnValue(
    table.sortOrder,
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

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class DashboardProfileTable extends _i1.Table<int?> {
  DashboardProfileTable({super.tableRelation})
    : super(tableName: 'dashboard_profiles') {
    updateTable = DashboardProfileUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    slug = _i1.ColumnString(
      'slug',
      this,
    );
    isActive = _i1.ColumnBool(
      'isActive',
      this,
      hasDefault: true,
    );
    themeId = _i1.ColumnString(
      'themeId',
      this,
    );
    cardFilterJson = _i1.ColumnString(
      'cardFilterJson',
      this,
      hasDefault: true,
    );
    scheduleJson = _i1.ColumnString(
      'scheduleJson',
      this,
    );
    sortOrder = _i1.ColumnInt(
      'sortOrder',
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
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DashboardProfileUpdateTable updateTable;

  /// User-facing name (e.g. "Weekday", "Party Mode", "Night Stand").
  late final _i1.ColumnString name;

  /// URL-safe slug derived from name. Used by agent LayoutSchema API.
  late final _i1.ColumnString slug;

  /// True when this is the profile currently shown on the display.
  late final _i1.ColumnBool isActive;

  /// Optional theme identifier. Null = default theme.
  late final _i1.ColumnString themeId;

  /// JSON-encoded ProfileCardFilter. Controls which agent cards are shown.
  late final _i1.ColumnString cardFilterJson;

  /// JSON-encoded ProfileSchedule. Null = no automatic scheduling.
  late final _i1.ColumnString scheduleJson;

  /// Sort order for the profile list. Lower = first.
  late final _i1.ColumnInt sortOrder;

  /// Number of grid columns.
  late final _i1.ColumnInt columnsCount;

  /// Number of grid rows.
  late final _i1.ColumnInt rowsCount;

  /// JSON-encoded List<CardConfig> — the card layout for this profile.
  late final _i1.ColumnString cardsJson;

  /// When this profile was created.
  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    slug,
    isActive,
    themeId,
    cardFilterJson,
    scheduleJson,
    sortOrder,
    columnsCount,
    rowsCount,
    cardsJson,
    createdAt,
  ];
}

class DashboardProfileInclude extends _i1.IncludeObject {
  DashboardProfileInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => DashboardProfile.t;
}

class DashboardProfileIncludeList extends _i1.IncludeList {
  DashboardProfileIncludeList._({
    _i1.WhereExpressionBuilder<DashboardProfileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DashboardProfile.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => DashboardProfile.t;
}

class DashboardProfileRepository {
  const DashboardProfileRepository._();

  /// Returns a list of [DashboardProfile]s matching the given query parameters.
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
  Future<List<DashboardProfile>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DashboardProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DashboardProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DashboardProfileTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DashboardProfile>(
      where: where?.call(DashboardProfile.t),
      orderBy: orderBy?.call(DashboardProfile.t),
      orderByList: orderByList?.call(DashboardProfile.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DashboardProfile] matching the given query parameters.
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
  Future<DashboardProfile?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DashboardProfileTable>? where,
    int? offset,
    _i1.OrderByBuilder<DashboardProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DashboardProfileTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DashboardProfile>(
      where: where?.call(DashboardProfile.t),
      orderBy: orderBy?.call(DashboardProfile.t),
      orderByList: orderByList?.call(DashboardProfile.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DashboardProfile] by its [id] or null if no such row exists.
  Future<DashboardProfile?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DashboardProfile>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DashboardProfile]s in the list and returns the inserted rows.
  ///
  /// The returned [DashboardProfile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<DashboardProfile>> insert(
    _i1.DatabaseSession session,
    List<DashboardProfile> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<DashboardProfile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [DashboardProfile] and returns the inserted row.
  ///
  /// The returned [DashboardProfile] will have its `id` field set.
  Future<DashboardProfile> insertRow(
    _i1.DatabaseSession session,
    DashboardProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<DashboardProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [DashboardProfile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<DashboardProfile>> update(
    _i1.DatabaseSession session,
    List<DashboardProfile> rows, {
    _i1.ColumnSelections<DashboardProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<DashboardProfile>(
      rows,
      columns: columns?.call(DashboardProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DashboardProfile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DashboardProfile> updateRow(
    _i1.DatabaseSession session,
    DashboardProfile row, {
    _i1.ColumnSelections<DashboardProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<DashboardProfile>(
      row,
      columns: columns?.call(DashboardProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DashboardProfile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DashboardProfile?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<DashboardProfileUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<DashboardProfile>(
      id,
      columnValues: columnValues(DashboardProfile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DashboardProfile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<DashboardProfile>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<DashboardProfileUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<DashboardProfileTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DashboardProfileTable>? orderBy,
    _i1.OrderByListBuilder<DashboardProfileTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<DashboardProfile>(
      columnValues: columnValues(DashboardProfile.t.updateTable),
      where: where(DashboardProfile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DashboardProfile.t),
      orderByList: orderByList?.call(DashboardProfile.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [DashboardProfile]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<DashboardProfile>> delete(
    _i1.DatabaseSession session,
    List<DashboardProfile> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<DashboardProfile>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [DashboardProfile].
  Future<DashboardProfile> deleteRow(
    _i1.DatabaseSession session,
    DashboardProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DashboardProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<DashboardProfile>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DashboardProfileTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<DashboardProfile>(
      where: where(DashboardProfile.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DashboardProfileTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<DashboardProfile>(
      where: where?.call(DashboardProfile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DashboardProfile] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DashboardProfileTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DashboardProfile>(
      where: where(DashboardProfile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
