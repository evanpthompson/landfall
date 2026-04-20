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

/// A pending OTP challenge sent to an email address.
/// Records are kept after use for audit purposes; expired/used rows are
/// excluded from verification by the service layer.
abstract class OtpRequest
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  OtpRequest._({
    this.id,
    required this.email,
    required this.codeHash,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
  });

  factory OtpRequest({
    int? id,
    required String email,
    required String codeHash,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
  }) = _OtpRequestImpl;

  factory OtpRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtpRequest(
      id: jsonSerialization['id'] as int?,
      email: jsonSerialization['email'] as String,
      codeHash: jsonSerialization['codeHash'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
    );
  }

  static final t = OtpRequestTable();

  static const db = OtpRequestRepository._();

  @override
  int? id;

  /// The email address the code was sent to.
  String email;

  /// SHA-256 hex digest of the plaintext code.
  String codeHash;

  /// When this request was created.
  DateTime createdAt;

  /// When this code expires.
  DateTime expiresAt;

  /// Set when the code was successfully verified (fail-closed: can only be used once).
  DateTime? usedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [OtpRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtpRequest copyWith({
    int? id,
    String? email,
    String? codeHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OtpRequest',
      if (id != null) 'id': id,
      'email': email,
      'codeHash': codeHash,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OtpRequest',
      if (id != null) 'id': id,
      'email': email,
      'codeHash': codeHash,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
    };
  }

  static OtpRequestInclude include() {
    return OtpRequestInclude._();
  }

  static OtpRequestIncludeList includeList({
    _i1.WhereExpressionBuilder<OtpRequestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtpRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtpRequestTable>? orderByList,
    OtpRequestInclude? include,
  }) {
    return OtpRequestIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OtpRequest.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(OtpRequest.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtpRequestImpl extends OtpRequest {
  _OtpRequestImpl({
    int? id,
    required String email,
    required String codeHash,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
  }) : super._(
         id: id,
         email: email,
         codeHash: codeHash,
         createdAt: createdAt,
         expiresAt: expiresAt,
         usedAt: usedAt,
       );

  /// Returns a shallow copy of this [OtpRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtpRequest copyWith({
    Object? id = _Undefined,
    String? email,
    String? codeHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? usedAt = _Undefined,
  }) {
    return OtpRequest(
      id: id is int? ? id : this.id,
      email: email ?? this.email,
      codeHash: codeHash ?? this.codeHash,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt is DateTime? ? usedAt : this.usedAt,
    );
  }
}

class OtpRequestUpdateTable extends _i1.UpdateTable<OtpRequestTable> {
  OtpRequestUpdateTable(super.table);

  _i1.ColumnValue<String, String> email(String value) => _i1.ColumnValue(
    table.email,
    value,
  );

  _i1.ColumnValue<String, String> codeHash(String value) => _i1.ColumnValue(
    table.codeHash,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> usedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.usedAt,
        value,
      );
}

class OtpRequestTable extends _i1.Table<int?> {
  OtpRequestTable({super.tableRelation})
    : super(tableName: 'landfall_otp_requests') {
    updateTable = OtpRequestUpdateTable(this);
    email = _i1.ColumnString(
      'email',
      this,
    );
    codeHash = _i1.ColumnString(
      'codeHash',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
    usedAt = _i1.ColumnDateTime(
      'usedAt',
      this,
    );
  }

  late final OtpRequestUpdateTable updateTable;

  /// The email address the code was sent to.
  late final _i1.ColumnString email;

  /// SHA-256 hex digest of the plaintext code.
  late final _i1.ColumnString codeHash;

  /// When this request was created.
  late final _i1.ColumnDateTime createdAt;

  /// When this code expires.
  late final _i1.ColumnDateTime expiresAt;

  /// Set when the code was successfully verified (fail-closed: can only be used once).
  late final _i1.ColumnDateTime usedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    email,
    codeHash,
    createdAt,
    expiresAt,
    usedAt,
  ];
}

class OtpRequestInclude extends _i1.IncludeObject {
  OtpRequestInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => OtpRequest.t;
}

class OtpRequestIncludeList extends _i1.IncludeList {
  OtpRequestIncludeList._({
    _i1.WhereExpressionBuilder<OtpRequestTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OtpRequest.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => OtpRequest.t;
}

class OtpRequestRepository {
  const OtpRequestRepository._();

  /// Returns a list of [OtpRequest]s matching the given query parameters.
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
  Future<List<OtpRequest>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OtpRequestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtpRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtpRequestTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<OtpRequest>(
      where: where?.call(OtpRequest.t),
      orderBy: orderBy?.call(OtpRequest.t),
      orderByList: orderByList?.call(OtpRequest.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [OtpRequest] matching the given query parameters.
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
  Future<OtpRequest?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OtpRequestTable>? where,
    int? offset,
    _i1.OrderByBuilder<OtpRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtpRequestTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<OtpRequest>(
      where: where?.call(OtpRequest.t),
      orderBy: orderBy?.call(OtpRequest.t),
      orderByList: orderByList?.call(OtpRequest.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [OtpRequest] by its [id] or null if no such row exists.
  Future<OtpRequest?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<OtpRequest>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [OtpRequest]s in the list and returns the inserted rows.
  ///
  /// The returned [OtpRequest]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<OtpRequest>> insert(
    _i1.DatabaseSession session,
    List<OtpRequest> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<OtpRequest>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [OtpRequest] and returns the inserted row.
  ///
  /// The returned [OtpRequest] will have its `id` field set.
  Future<OtpRequest> insertRow(
    _i1.DatabaseSession session,
    OtpRequest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<OtpRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [OtpRequest]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<OtpRequest>> update(
    _i1.DatabaseSession session,
    List<OtpRequest> rows, {
    _i1.ColumnSelections<OtpRequestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<OtpRequest>(
      rows,
      columns: columns?.call(OtpRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OtpRequest]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OtpRequest> updateRow(
    _i1.DatabaseSession session,
    OtpRequest row, {
    _i1.ColumnSelections<OtpRequestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<OtpRequest>(
      row,
      columns: columns?.call(OtpRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OtpRequest] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<OtpRequest?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<OtpRequestUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<OtpRequest>(
      id,
      columnValues: columnValues(OtpRequest.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [OtpRequest]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<OtpRequest>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<OtpRequestUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<OtpRequestTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtpRequestTable>? orderBy,
    _i1.OrderByListBuilder<OtpRequestTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<OtpRequest>(
      columnValues: columnValues(OtpRequest.t.updateTable),
      where: where(OtpRequest.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OtpRequest.t),
      orderByList: orderByList?.call(OtpRequest.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [OtpRequest]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<OtpRequest>> delete(
    _i1.DatabaseSession session,
    List<OtpRequest> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<OtpRequest>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [OtpRequest].
  Future<OtpRequest> deleteRow(
    _i1.DatabaseSession session,
    OtpRequest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OtpRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<OtpRequest>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<OtpRequestTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<OtpRequest>(
      where: where(OtpRequest.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OtpRequestTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<OtpRequest>(
      where: where?.call(OtpRequest.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [OtpRequest] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<OtpRequestTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<OtpRequest>(
      where: where(OtpRequest.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
