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

/// Tracks the email → authUserId mapping for OTP-authenticated users.
/// Created on first successful OTP verification for an email address.
abstract class OtpAccount
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  OtpAccount._({
    this.id,
    required this.email,
    required this.authUserId,
  });

  factory OtpAccount({
    int? id,
    required String email,
    required _i1.UuidValue authUserId,
  }) = _OtpAccountImpl;

  factory OtpAccount.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtpAccount(
      id: jsonSerialization['id'] as int?,
      email: jsonSerialization['email'] as String,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
    );
  }

  static final t = OtpAccountTable();

  static const db = OtpAccountRepository._();

  @override
  int? id;

  /// The email address that was verified.
  String email;

  /// The Serverpod auth user ID linked to this email.
  _i1.UuidValue authUserId;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [OtpAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtpAccount copyWith({
    int? id,
    String? email,
    _i1.UuidValue? authUserId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OtpAccount',
      if (id != null) 'id': id,
      'email': email,
      'authUserId': authUserId.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OtpAccount',
      if (id != null) 'id': id,
      'email': email,
      'authUserId': authUserId.toJson(),
    };
  }

  static OtpAccountInclude include() {
    return OtpAccountInclude._();
  }

  static OtpAccountIncludeList includeList({
    _i1.WhereExpressionBuilder<OtpAccountTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtpAccountTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtpAccountTable>? orderByList,
    OtpAccountInclude? include,
  }) {
    return OtpAccountIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OtpAccount.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(OtpAccount.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtpAccountImpl extends OtpAccount {
  _OtpAccountImpl({
    int? id,
    required String email,
    required _i1.UuidValue authUserId,
  }) : super._(
         id: id,
         email: email,
         authUserId: authUserId,
       );

  /// Returns a shallow copy of this [OtpAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtpAccount copyWith({
    Object? id = _Undefined,
    String? email,
    _i1.UuidValue? authUserId,
  }) {
    return OtpAccount(
      id: id is int? ? id : this.id,
      email: email ?? this.email,
      authUserId: authUserId ?? this.authUserId,
    );
  }
}

class OtpAccountUpdateTable extends _i1.UpdateTable<OtpAccountTable> {
  OtpAccountUpdateTable(super.table);

  _i1.ColumnValue<String, String> email(String value) => _i1.ColumnValue(
    table.email,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );
}

class OtpAccountTable extends _i1.Table<int?> {
  OtpAccountTable({super.tableRelation})
    : super(tableName: 'landfall_otp_accounts') {
    updateTable = OtpAccountUpdateTable(this);
    email = _i1.ColumnString(
      'email',
      this,
    );
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
  }

  late final OtpAccountUpdateTable updateTable;

  /// The email address that was verified.
  late final _i1.ColumnString email;

  /// The Serverpod auth user ID linked to this email.
  late final _i1.ColumnUuid authUserId;

  @override
  List<_i1.Column> get columns => [
    id,
    email,
    authUserId,
  ];
}

class OtpAccountInclude extends _i1.IncludeObject {
  OtpAccountInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => OtpAccount.t;
}

class OtpAccountIncludeList extends _i1.IncludeList {
  OtpAccountIncludeList._({
    _i1.WhereExpressionBuilder<OtpAccountTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OtpAccount.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => OtpAccount.t;
}

class OtpAccountRepository {
  const OtpAccountRepository._();

  /// Returns a list of [OtpAccount]s matching the given query parameters.
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
  Future<List<OtpAccount>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OtpAccountTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtpAccountTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtpAccountTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<OtpAccount>(
      where: where?.call(OtpAccount.t),
      orderBy: orderBy?.call(OtpAccount.t),
      orderByList: orderByList?.call(OtpAccount.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [OtpAccount] matching the given query parameters.
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
  Future<OtpAccount?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OtpAccountTable>? where,
    int? offset,
    _i1.OrderByBuilder<OtpAccountTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OtpAccountTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<OtpAccount>(
      where: where?.call(OtpAccount.t),
      orderBy: orderBy?.call(OtpAccount.t),
      orderByList: orderByList?.call(OtpAccount.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [OtpAccount] by its [id] or null if no such row exists.
  Future<OtpAccount?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<OtpAccount>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [OtpAccount]s in the list and returns the inserted rows.
  ///
  /// The returned [OtpAccount]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<OtpAccount>> insert(
    _i1.DatabaseSession session,
    List<OtpAccount> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<OtpAccount>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [OtpAccount] and returns the inserted row.
  ///
  /// The returned [OtpAccount] will have its `id` field set.
  Future<OtpAccount> insertRow(
    _i1.DatabaseSession session,
    OtpAccount row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<OtpAccount>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [OtpAccount]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<OtpAccount>> update(
    _i1.DatabaseSession session,
    List<OtpAccount> rows, {
    _i1.ColumnSelections<OtpAccountTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<OtpAccount>(
      rows,
      columns: columns?.call(OtpAccount.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OtpAccount]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OtpAccount> updateRow(
    _i1.DatabaseSession session,
    OtpAccount row, {
    _i1.ColumnSelections<OtpAccountTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<OtpAccount>(
      row,
      columns: columns?.call(OtpAccount.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OtpAccount] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<OtpAccount?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<OtpAccountUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<OtpAccount>(
      id,
      columnValues: columnValues(OtpAccount.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [OtpAccount]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<OtpAccount>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<OtpAccountUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<OtpAccountTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OtpAccountTable>? orderBy,
    _i1.OrderByListBuilder<OtpAccountTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<OtpAccount>(
      columnValues: columnValues(OtpAccount.t.updateTable),
      where: where(OtpAccount.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OtpAccount.t),
      orderByList: orderByList?.call(OtpAccount.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [OtpAccount]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<OtpAccount>> delete(
    _i1.DatabaseSession session,
    List<OtpAccount> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<OtpAccount>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [OtpAccount].
  Future<OtpAccount> deleteRow(
    _i1.DatabaseSession session,
    OtpAccount row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OtpAccount>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<OtpAccount>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<OtpAccountTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<OtpAccount>(
      where: where(OtpAccount.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OtpAccountTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<OtpAccount>(
      where: where?.call(OtpAccount.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [OtpAccount] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<OtpAccountTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<OtpAccount>(
      where: where(OtpAccount.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
