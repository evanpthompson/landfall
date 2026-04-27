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

/// A pack owned by a Serverpod auth user.
/// Created on Stripe webhook completion or via Founding Member auto-grant.
abstract class OwnedPack
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  OwnedPack._({
    this.id,
    required this.userId,
    required this.packId,
    required this.grantedAt,
    this.stripeSessionId,
  });

  factory OwnedPack({
    int? id,
    required String userId,
    required String packId,
    required DateTime grantedAt,
    String? stripeSessionId,
  }) = _OwnedPackImpl;

  factory OwnedPack.fromJson(Map<String, dynamic> jsonSerialization) {
    return OwnedPack(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      packId: jsonSerialization['packId'] as String,
      grantedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['grantedAt'],
      ),
      stripeSessionId: jsonSerialization['stripeSessionId'] as String?,
    );
  }

  static final t = OwnedPackTable();

  static const db = OwnedPackRepository._();

  @override
  int? id;

  /// Serverpod auth user identifier (UUID string).
  String userId;

  /// References IntegrationPack.packId.
  String packId;

  /// When this pack was granted.
  DateTime grantedAt;

  /// Stripe checkout session ID. Null for Founding Member auto-grants.
  String? stripeSessionId;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [OwnedPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OwnedPack copyWith({
    int? id,
    String? userId,
    String? packId,
    DateTime? grantedAt,
    String? stripeSessionId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OwnedPack',
      if (id != null) 'id': id,
      'userId': userId,
      'packId': packId,
      'grantedAt': grantedAt.toJson(),
      if (stripeSessionId != null) 'stripeSessionId': stripeSessionId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OwnedPack',
      if (id != null) 'id': id,
      'userId': userId,
      'packId': packId,
      'grantedAt': grantedAt.toJson(),
      if (stripeSessionId != null) 'stripeSessionId': stripeSessionId,
    };
  }

  static OwnedPackInclude include() {
    return OwnedPackInclude._();
  }

  static OwnedPackIncludeList includeList({
    _i1.WhereExpressionBuilder<OwnedPackTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OwnedPackTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OwnedPackTable>? orderByList,
    OwnedPackInclude? include,
  }) {
    return OwnedPackIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OwnedPack.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(OwnedPack.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OwnedPackImpl extends OwnedPack {
  _OwnedPackImpl({
    int? id,
    required String userId,
    required String packId,
    required DateTime grantedAt,
    String? stripeSessionId,
  }) : super._(
         id: id,
         userId: userId,
         packId: packId,
         grantedAt: grantedAt,
         stripeSessionId: stripeSessionId,
       );

  /// Returns a shallow copy of this [OwnedPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OwnedPack copyWith({
    Object? id = _Undefined,
    String? userId,
    String? packId,
    DateTime? grantedAt,
    Object? stripeSessionId = _Undefined,
  }) {
    return OwnedPack(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      packId: packId ?? this.packId,
      grantedAt: grantedAt ?? this.grantedAt,
      stripeSessionId: stripeSessionId is String?
          ? stripeSessionId
          : this.stripeSessionId,
    );
  }
}

class OwnedPackUpdateTable extends _i1.UpdateTable<OwnedPackTable> {
  OwnedPackUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> packId(String value) => _i1.ColumnValue(
    table.packId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> grantedAt(DateTime value) =>
      _i1.ColumnValue(
        table.grantedAt,
        value,
      );

  _i1.ColumnValue<String, String> stripeSessionId(String? value) =>
      _i1.ColumnValue(
        table.stripeSessionId,
        value,
      );
}

class OwnedPackTable extends _i1.Table<int?> {
  OwnedPackTable({super.tableRelation}) : super(tableName: 'owned_packs') {
    updateTable = OwnedPackUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    packId = _i1.ColumnString(
      'packId',
      this,
    );
    grantedAt = _i1.ColumnDateTime(
      'grantedAt',
      this,
    );
    stripeSessionId = _i1.ColumnString(
      'stripeSessionId',
      this,
    );
  }

  late final OwnedPackUpdateTable updateTable;

  /// Serverpod auth user identifier (UUID string).
  late final _i1.ColumnString userId;

  /// References IntegrationPack.packId.
  late final _i1.ColumnString packId;

  /// When this pack was granted.
  late final _i1.ColumnDateTime grantedAt;

  /// Stripe checkout session ID. Null for Founding Member auto-grants.
  late final _i1.ColumnString stripeSessionId;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    packId,
    grantedAt,
    stripeSessionId,
  ];
}

class OwnedPackInclude extends _i1.IncludeObject {
  OwnedPackInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => OwnedPack.t;
}

class OwnedPackIncludeList extends _i1.IncludeList {
  OwnedPackIncludeList._({
    _i1.WhereExpressionBuilder<OwnedPackTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OwnedPack.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => OwnedPack.t;
}

class OwnedPackRepository {
  const OwnedPackRepository._();

  /// Returns a list of [OwnedPack]s matching the given query parameters.
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
  Future<List<OwnedPack>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OwnedPackTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OwnedPackTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OwnedPackTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<OwnedPack>(
      where: where?.call(OwnedPack.t),
      orderBy: orderBy?.call(OwnedPack.t),
      orderByList: orderByList?.call(OwnedPack.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [OwnedPack] matching the given query parameters.
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
  Future<OwnedPack?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OwnedPackTable>? where,
    int? offset,
    _i1.OrderByBuilder<OwnedPackTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OwnedPackTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<OwnedPack>(
      where: where?.call(OwnedPack.t),
      orderBy: orderBy?.call(OwnedPack.t),
      orderByList: orderByList?.call(OwnedPack.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [OwnedPack] by its [id] or null if no such row exists.
  Future<OwnedPack?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<OwnedPack>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [OwnedPack]s in the list and returns the inserted rows.
  ///
  /// The returned [OwnedPack]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<OwnedPack>> insert(
    _i1.DatabaseSession session,
    List<OwnedPack> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<OwnedPack>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [OwnedPack] and returns the inserted row.
  ///
  /// The returned [OwnedPack] will have its `id` field set.
  Future<OwnedPack> insertRow(
    _i1.DatabaseSession session,
    OwnedPack row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<OwnedPack>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [OwnedPack]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<OwnedPack>> update(
    _i1.DatabaseSession session,
    List<OwnedPack> rows, {
    _i1.ColumnSelections<OwnedPackTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<OwnedPack>(
      rows,
      columns: columns?.call(OwnedPack.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OwnedPack]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OwnedPack> updateRow(
    _i1.DatabaseSession session,
    OwnedPack row, {
    _i1.ColumnSelections<OwnedPackTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<OwnedPack>(
      row,
      columns: columns?.call(OwnedPack.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OwnedPack] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<OwnedPack?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<OwnedPackUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<OwnedPack>(
      id,
      columnValues: columnValues(OwnedPack.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [OwnedPack]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<OwnedPack>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<OwnedPackUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<OwnedPackTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OwnedPackTable>? orderBy,
    _i1.OrderByListBuilder<OwnedPackTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<OwnedPack>(
      columnValues: columnValues(OwnedPack.t.updateTable),
      where: where(OwnedPack.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OwnedPack.t),
      orderByList: orderByList?.call(OwnedPack.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [OwnedPack]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<OwnedPack>> delete(
    _i1.DatabaseSession session,
    List<OwnedPack> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<OwnedPack>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [OwnedPack].
  Future<OwnedPack> deleteRow(
    _i1.DatabaseSession session,
    OwnedPack row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OwnedPack>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<OwnedPack>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<OwnedPackTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<OwnedPack>(
      where: where(OwnedPack.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OwnedPackTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<OwnedPack>(
      where: where?.call(OwnedPack.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [OwnedPack] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<OwnedPackTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<OwnedPack>(
      where: where(OwnedPack.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
