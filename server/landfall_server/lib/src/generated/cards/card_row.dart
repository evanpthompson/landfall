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

/// A card displayed on a Landfall board.
/// Named CardRow to distinguish from the client-side Card domain model.
abstract class CardRow
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  CardRow._({
    this.id,
    required this.externalId,
    required this.source,
    required this.title,
    this.body,
    this.dataJson,
    this.actionsJson,
    String? layout,
    String? priority,
    this.expiresAt,
    bool? persistent,
    this.dismissedAt,
    required this.createdAt,
  }) : layout = layout ?? 'medium',
       priority = priority ?? 'normal',
       persistent = persistent ?? false;

  factory CardRow({
    int? id,
    required String externalId,
    required String source,
    required String title,
    String? body,
    String? dataJson,
    String? actionsJson,
    String? layout,
    String? priority,
    DateTime? expiresAt,
    bool? persistent,
    DateTime? dismissedAt,
    required DateTime createdAt,
  }) = _CardRowImpl;

  factory CardRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return CardRow(
      id: jsonSerialization['id'] as int?,
      externalId: jsonSerialization['externalId'] as String,
      source: jsonSerialization['source'] as String,
      title: jsonSerialization['title'] as String,
      body: jsonSerialization['body'] as String?,
      dataJson: jsonSerialization['dataJson'] as String?,
      actionsJson: jsonSerialization['actionsJson'] as String?,
      layout: jsonSerialization['layout'] as String?,
      priority: jsonSerialization['priority'] as String?,
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      persistent: jsonSerialization['persistent'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['persistent']),
      dismissedAt: jsonSerialization['dismissedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dismissedAt'],
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = CardRowTable();

  static const db = CardRowRepository._();

  @override
  int? id;

  /// Agent-facing UUID. Stable across updates — re-pushing with the same
  /// externalId replaces the card rather than creating a duplicate.
  String externalId;

  /// Identifies the origin of this card.
  /// Convention: "system.<widget>" or "agent.<name>" or "skill.<name>"
  String source;

  /// Primary display text.
  String title;

  /// Secondary display text. Optional.
  String? body;

  /// Structured data for rich rendering, serialized as JSON string.
  String? dataJson;

  /// Card actions serialized as a JSON array of CardAction objects.
  /// Null means no actions. Set by the agent when pushing the card.
  String? actionsJson;

  /// Size hint for the display layout engine.
  /// Values: small | medium | large | full | ticker
  String layout;

  /// Controls default TTL when expiresAt is null and persistent is false.
  /// Values: ephemeral (2h) | normal (24h) | persistent (never)
  String priority;

  /// Explicit expiry timestamp. When set, overrides priority-based default TTL.
  DateTime? expiresAt;

  /// When true, never auto-expires. Overrides expiresAt and priority.
  bool persistent;

  /// Set when the user manually dismisses this card.
  /// Non-null = card is in history, not on active display.
  DateTime? dismissedAt;

  /// When this card was first created / pushed.
  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [CardRow]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CardRow copyWith({
    int? id,
    String? externalId,
    String? source,
    String? title,
    String? body,
    String? dataJson,
    String? actionsJson,
    String? layout,
    String? priority,
    DateTime? expiresAt,
    bool? persistent,
    DateTime? dismissedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CardRow',
      if (id != null) 'id': id,
      'externalId': externalId,
      'source': source,
      'title': title,
      if (body != null) 'body': body,
      if (dataJson != null) 'dataJson': dataJson,
      if (actionsJson != null) 'actionsJson': actionsJson,
      'layout': layout,
      'priority': priority,
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      'persistent': persistent,
      if (dismissedAt != null) 'dismissedAt': dismissedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CardRow',
      if (id != null) 'id': id,
      'externalId': externalId,
      'source': source,
      'title': title,
      if (body != null) 'body': body,
      if (dataJson != null) 'dataJson': dataJson,
      if (actionsJson != null) 'actionsJson': actionsJson,
      'layout': layout,
      'priority': priority,
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      'persistent': persistent,
      if (dismissedAt != null) 'dismissedAt': dismissedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static CardRowInclude include() {
    return CardRowInclude._();
  }

  static CardRowIncludeList includeList({
    _i1.WhereExpressionBuilder<CardRowTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CardRowTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CardRowTable>? orderByList,
    CardRowInclude? include,
  }) {
    return CardRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CardRow.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(CardRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CardRowImpl extends CardRow {
  _CardRowImpl({
    int? id,
    required String externalId,
    required String source,
    required String title,
    String? body,
    String? dataJson,
    String? actionsJson,
    String? layout,
    String? priority,
    DateTime? expiresAt,
    bool? persistent,
    DateTime? dismissedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         externalId: externalId,
         source: source,
         title: title,
         body: body,
         dataJson: dataJson,
         actionsJson: actionsJson,
         layout: layout,
         priority: priority,
         expiresAt: expiresAt,
         persistent: persistent,
         dismissedAt: dismissedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [CardRow]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CardRow copyWith({
    Object? id = _Undefined,
    String? externalId,
    String? source,
    String? title,
    Object? body = _Undefined,
    Object? dataJson = _Undefined,
    Object? actionsJson = _Undefined,
    String? layout,
    String? priority,
    Object? expiresAt = _Undefined,
    bool? persistent,
    Object? dismissedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return CardRow(
      id: id is int? ? id : this.id,
      externalId: externalId ?? this.externalId,
      source: source ?? this.source,
      title: title ?? this.title,
      body: body is String? ? body : this.body,
      dataJson: dataJson is String? ? dataJson : this.dataJson,
      actionsJson: actionsJson is String? ? actionsJson : this.actionsJson,
      layout: layout ?? this.layout,
      priority: priority ?? this.priority,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      persistent: persistent ?? this.persistent,
      dismissedAt: dismissedAt is DateTime? ? dismissedAt : this.dismissedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CardRowUpdateTable extends _i1.UpdateTable<CardRowTable> {
  CardRowUpdateTable(super.table);

  _i1.ColumnValue<String, String> externalId(String value) => _i1.ColumnValue(
    table.externalId,
    value,
  );

  _i1.ColumnValue<String, String> source(String value) => _i1.ColumnValue(
    table.source,
    value,
  );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<String, String> body(String? value) => _i1.ColumnValue(
    table.body,
    value,
  );

  _i1.ColumnValue<String, String> dataJson(String? value) => _i1.ColumnValue(
    table.dataJson,
    value,
  );

  _i1.ColumnValue<String, String> actionsJson(String? value) => _i1.ColumnValue(
    table.actionsJson,
    value,
  );

  _i1.ColumnValue<String, String> layout(String value) => _i1.ColumnValue(
    table.layout,
    value,
  );

  _i1.ColumnValue<String, String> priority(String value) => _i1.ColumnValue(
    table.priority,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime? value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );

  _i1.ColumnValue<bool, bool> persistent(bool value) => _i1.ColumnValue(
    table.persistent,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> dismissedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.dismissedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class CardRowTable extends _i1.Table<int?> {
  CardRowTable({super.tableRelation}) : super(tableName: 'cards') {
    updateTable = CardRowUpdateTable(this);
    externalId = _i1.ColumnString(
      'externalId',
      this,
    );
    source = _i1.ColumnString(
      'source',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    body = _i1.ColumnString(
      'body',
      this,
    );
    dataJson = _i1.ColumnString(
      'dataJson',
      this,
    );
    actionsJson = _i1.ColumnString(
      'actionsJson',
      this,
    );
    layout = _i1.ColumnString(
      'layout',
      this,
      hasDefault: true,
    );
    priority = _i1.ColumnString(
      'priority',
      this,
      hasDefault: true,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
    persistent = _i1.ColumnBool(
      'persistent',
      this,
      hasDefault: true,
    );
    dismissedAt = _i1.ColumnDateTime(
      'dismissedAt',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final CardRowUpdateTable updateTable;

  /// Agent-facing UUID. Stable across updates — re-pushing with the same
  /// externalId replaces the card rather than creating a duplicate.
  late final _i1.ColumnString externalId;

  /// Identifies the origin of this card.
  /// Convention: "system.<widget>" or "agent.<name>" or "skill.<name>"
  late final _i1.ColumnString source;

  /// Primary display text.
  late final _i1.ColumnString title;

  /// Secondary display text. Optional.
  late final _i1.ColumnString body;

  /// Structured data for rich rendering, serialized as JSON string.
  late final _i1.ColumnString dataJson;

  /// Card actions serialized as a JSON array of CardAction objects.
  /// Null means no actions. Set by the agent when pushing the card.
  late final _i1.ColumnString actionsJson;

  /// Size hint for the display layout engine.
  /// Values: small | medium | large | full | ticker
  late final _i1.ColumnString layout;

  /// Controls default TTL when expiresAt is null and persistent is false.
  /// Values: ephemeral (2h) | normal (24h) | persistent (never)
  late final _i1.ColumnString priority;

  /// Explicit expiry timestamp. When set, overrides priority-based default TTL.
  late final _i1.ColumnDateTime expiresAt;

  /// When true, never auto-expires. Overrides expiresAt and priority.
  late final _i1.ColumnBool persistent;

  /// Set when the user manually dismisses this card.
  /// Non-null = card is in history, not on active display.
  late final _i1.ColumnDateTime dismissedAt;

  /// When this card was first created / pushed.
  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    externalId,
    source,
    title,
    body,
    dataJson,
    actionsJson,
    layout,
    priority,
    expiresAt,
    persistent,
    dismissedAt,
    createdAt,
  ];
}

class CardRowInclude extends _i1.IncludeObject {
  CardRowInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => CardRow.t;
}

class CardRowIncludeList extends _i1.IncludeList {
  CardRowIncludeList._({
    _i1.WhereExpressionBuilder<CardRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CardRow.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => CardRow.t;
}

class CardRowRepository {
  const CardRowRepository._();

  /// Returns a list of [CardRow]s matching the given query parameters.
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
  Future<List<CardRow>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CardRowTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CardRowTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CardRowTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CardRow>(
      where: where?.call(CardRow.t),
      orderBy: orderBy?.call(CardRow.t),
      orderByList: orderByList?.call(CardRow.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [CardRow] matching the given query parameters.
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
  Future<CardRow?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CardRowTable>? where,
    int? offset,
    _i1.OrderByBuilder<CardRowTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CardRowTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CardRow>(
      where: where?.call(CardRow.t),
      orderBy: orderBy?.call(CardRow.t),
      orderByList: orderByList?.call(CardRow.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CardRow] by its [id] or null if no such row exists.
  Future<CardRow?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CardRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CardRow]s in the list and returns the inserted rows.
  ///
  /// The returned [CardRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<CardRow>> insert(
    _i1.DatabaseSession session,
    List<CardRow> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<CardRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [CardRow] and returns the inserted row.
  ///
  /// The returned [CardRow] will have its `id` field set.
  Future<CardRow> insertRow(
    _i1.DatabaseSession session,
    CardRow row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<CardRow>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [CardRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<CardRow>> update(
    _i1.DatabaseSession session,
    List<CardRow> rows, {
    _i1.ColumnSelections<CardRowTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<CardRow>(
      rows,
      columns: columns?.call(CardRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CardRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CardRow> updateRow(
    _i1.DatabaseSession session,
    CardRow row, {
    _i1.ColumnSelections<CardRowTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<CardRow>(
      row,
      columns: columns?.call(CardRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CardRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CardRow?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<CardRowUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<CardRow>(
      id,
      columnValues: columnValues(CardRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CardRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<CardRow>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<CardRowUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<CardRowTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CardRowTable>? orderBy,
    _i1.OrderByListBuilder<CardRowTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<CardRow>(
      columnValues: columnValues(CardRow.t.updateTable),
      where: where(CardRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CardRow.t),
      orderByList: orderByList?.call(CardRow.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [CardRow]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<CardRow>> delete(
    _i1.DatabaseSession session,
    List<CardRow> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<CardRow>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [CardRow].
  Future<CardRow> deleteRow(
    _i1.DatabaseSession session,
    CardRow row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CardRow>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<CardRow>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<CardRowTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<CardRow>(
      where: where(CardRow.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CardRowTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<CardRow>(
      where: where?.call(CardRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CardRow] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<CardRowTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CardRow>(
      where: where(CardRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
