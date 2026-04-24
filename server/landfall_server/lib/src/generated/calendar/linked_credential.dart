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

/// OAuth credentials (or app-specific password for CalDAV providers) linking
/// a Landfall user to an external calendar account.
///
/// provider values: "google" | "microsoft" | "apple"
///
/// For OAuth providers (google, microsoft):
///   accessToken  = short-lived Bearer token
///   refreshToken = long-lived token used to obtain new access tokens
///   tokenExpiresAt = when accessToken expires
///
/// For CalDAV providers (apple):
///   accessToken  = app-specific password (the secret used for Basic auth)
///   refreshToken = null (app passwords don't expire / rotate via API)
///   tokenExpiresAt = null
///
/// Access tokens are sensitive — this model is never exposed via any endpoint.
abstract class LinkedCredential
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  LinkedCredential._({
    this.id,
    required this.authUserId,
    required this.provider,
    required this.providerEmail,
    required this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.scopes,
    bool? isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : isActive = isActive ?? true;

  factory LinkedCredential({
    int? id,
    required _i1.UuidValue authUserId,
    required String provider,
    required String providerEmail,
    required String accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    String? scopes,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LinkedCredentialImpl;

  factory LinkedCredential.fromJson(Map<String, dynamic> jsonSerialization) {
    return LinkedCredential(
      id: jsonSerialization['id'] as int?,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      provider: jsonSerialization['provider'] as String,
      providerEmail: jsonSerialization['providerEmail'] as String,
      accessToken: jsonSerialization['accessToken'] as String,
      refreshToken: jsonSerialization['refreshToken'] as String?,
      tokenExpiresAt: jsonSerialization['tokenExpiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['tokenExpiresAt'],
            ),
      scopes: jsonSerialization['scopes'] as String?,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = LinkedCredentialTable();

  static const db = LinkedCredentialRepository._();

  @override
  int? id;

  /// The Landfall auth user who connected this account.
  _i1.UuidValue authUserId;

  /// Calendar provider identifier.
  /// Values: "google" | "microsoft" | "apple"
  String provider;

  /// The email address of the connected external account.
  /// For Apple/CalDAV this is also the CalDAV username.
  String providerEmail;

  /// OAuth Bearer token (Google/Microsoft) or app-specific password (Apple).
  /// Never expose this field via any client-facing endpoint.
  String accessToken;

  /// OAuth refresh token. Null for CalDAV providers.
  String? refreshToken;

  /// When the accessToken expires. Null for CalDAV providers.
  DateTime? tokenExpiresAt;

  /// Space-separated OAuth scopes granted. Null for CalDAV providers.
  String? scopes;

  /// When false, this credential is disabled and skipped during refresh.
  bool isActive;

  /// When this credential was first connected.
  DateTime createdAt;

  /// When this credential was last updated (e.g., token refreshed).
  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [LinkedCredential]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LinkedCredential copyWith({
    int? id,
    _i1.UuidValue? authUserId,
    String? provider,
    String? providerEmail,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    String? scopes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LinkedCredential',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      'provider': provider,
      'providerEmail': providerEmail,
      'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (tokenExpiresAt != null) 'tokenExpiresAt': tokenExpiresAt?.toJson(),
      if (scopes != null) 'scopes': scopes,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static LinkedCredentialInclude include() {
    return LinkedCredentialInclude._();
  }

  static LinkedCredentialIncludeList includeList({
    _i1.WhereExpressionBuilder<LinkedCredentialTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LinkedCredentialTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LinkedCredentialTable>? orderByList,
    LinkedCredentialInclude? include,
  }) {
    return LinkedCredentialIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LinkedCredential.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LinkedCredential.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LinkedCredentialImpl extends LinkedCredential {
  _LinkedCredentialImpl({
    int? id,
    required _i1.UuidValue authUserId,
    required String provider,
    required String providerEmail,
    required String accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    String? scopes,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         provider: provider,
         providerEmail: providerEmail,
         accessToken: accessToken,
         refreshToken: refreshToken,
         tokenExpiresAt: tokenExpiresAt,
         scopes: scopes,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [LinkedCredential]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LinkedCredential copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authUserId,
    String? provider,
    String? providerEmail,
    String? accessToken,
    Object? refreshToken = _Undefined,
    Object? tokenExpiresAt = _Undefined,
    Object? scopes = _Undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LinkedCredential(
      id: id is int? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      provider: provider ?? this.provider,
      providerEmail: providerEmail ?? this.providerEmail,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken is String? ? refreshToken : this.refreshToken,
      tokenExpiresAt: tokenExpiresAt is DateTime?
          ? tokenExpiresAt
          : this.tokenExpiresAt,
      scopes: scopes is String? ? scopes : this.scopes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LinkedCredentialUpdateTable
    extends _i1.UpdateTable<LinkedCredentialTable> {
  LinkedCredentialUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<String, String> provider(String value) => _i1.ColumnValue(
    table.provider,
    value,
  );

  _i1.ColumnValue<String, String> providerEmail(String value) =>
      _i1.ColumnValue(
        table.providerEmail,
        value,
      );

  _i1.ColumnValue<String, String> accessToken(String value) => _i1.ColumnValue(
    table.accessToken,
    value,
  );

  _i1.ColumnValue<String, String> refreshToken(String? value) =>
      _i1.ColumnValue(
        table.refreshToken,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> tokenExpiresAt(DateTime? value) =>
      _i1.ColumnValue(
        table.tokenExpiresAt,
        value,
      );

  _i1.ColumnValue<String, String> scopes(String? value) => _i1.ColumnValue(
    table.scopes,
    value,
  );

  _i1.ColumnValue<bool, bool> isActive(bool value) => _i1.ColumnValue(
    table.isActive,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class LinkedCredentialTable extends _i1.Table<int?> {
  LinkedCredentialTable({super.tableRelation})
    : super(tableName: 'calendar_linked_credentials') {
    updateTable = LinkedCredentialUpdateTable(this);
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    provider = _i1.ColumnString(
      'provider',
      this,
    );
    providerEmail = _i1.ColumnString(
      'providerEmail',
      this,
    );
    accessToken = _i1.ColumnString(
      'accessToken',
      this,
    );
    refreshToken = _i1.ColumnString(
      'refreshToken',
      this,
    );
    tokenExpiresAt = _i1.ColumnDateTime(
      'tokenExpiresAt',
      this,
    );
    scopes = _i1.ColumnString(
      'scopes',
      this,
    );
    isActive = _i1.ColumnBool(
      'isActive',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final LinkedCredentialUpdateTable updateTable;

  /// The Landfall auth user who connected this account.
  late final _i1.ColumnUuid authUserId;

  /// Calendar provider identifier.
  /// Values: "google" | "microsoft" | "apple"
  late final _i1.ColumnString provider;

  /// The email address of the connected external account.
  /// For Apple/CalDAV this is also the CalDAV username.
  late final _i1.ColumnString providerEmail;

  /// OAuth Bearer token (Google/Microsoft) or app-specific password (Apple).
  /// Never expose this field via any client-facing endpoint.
  late final _i1.ColumnString accessToken;

  /// OAuth refresh token. Null for CalDAV providers.
  late final _i1.ColumnString refreshToken;

  /// When the accessToken expires. Null for CalDAV providers.
  late final _i1.ColumnDateTime tokenExpiresAt;

  /// Space-separated OAuth scopes granted. Null for CalDAV providers.
  late final _i1.ColumnString scopes;

  /// When false, this credential is disabled and skipped during refresh.
  late final _i1.ColumnBool isActive;

  /// When this credential was first connected.
  late final _i1.ColumnDateTime createdAt;

  /// When this credential was last updated (e.g., token refreshed).
  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    authUserId,
    provider,
    providerEmail,
    accessToken,
    refreshToken,
    tokenExpiresAt,
    scopes,
    isActive,
    createdAt,
    updatedAt,
  ];
}

class LinkedCredentialInclude extends _i1.IncludeObject {
  LinkedCredentialInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => LinkedCredential.t;
}

class LinkedCredentialIncludeList extends _i1.IncludeList {
  LinkedCredentialIncludeList._({
    _i1.WhereExpressionBuilder<LinkedCredentialTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LinkedCredential.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => LinkedCredential.t;
}

class LinkedCredentialRepository {
  const LinkedCredentialRepository._();

  /// Returns a list of [LinkedCredential]s matching the given query parameters.
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
  Future<List<LinkedCredential>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LinkedCredentialTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LinkedCredentialTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LinkedCredentialTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LinkedCredential>(
      where: where?.call(LinkedCredential.t),
      orderBy: orderBy?.call(LinkedCredential.t),
      orderByList: orderByList?.call(LinkedCredential.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LinkedCredential] matching the given query parameters.
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
  Future<LinkedCredential?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LinkedCredentialTable>? where,
    int? offset,
    _i1.OrderByBuilder<LinkedCredentialTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LinkedCredentialTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LinkedCredential>(
      where: where?.call(LinkedCredential.t),
      orderBy: orderBy?.call(LinkedCredential.t),
      orderByList: orderByList?.call(LinkedCredential.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LinkedCredential] by its [id] or null if no such row exists.
  Future<LinkedCredential?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LinkedCredential>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LinkedCredential]s in the list and returns the inserted rows.
  ///
  /// The returned [LinkedCredential]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<LinkedCredential>> insert(
    _i1.DatabaseSession session,
    List<LinkedCredential> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<LinkedCredential>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [LinkedCredential] and returns the inserted row.
  ///
  /// The returned [LinkedCredential] will have its `id` field set.
  Future<LinkedCredential> insertRow(
    _i1.DatabaseSession session,
    LinkedCredential row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LinkedCredential>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LinkedCredential]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LinkedCredential>> update(
    _i1.DatabaseSession session,
    List<LinkedCredential> rows, {
    _i1.ColumnSelections<LinkedCredentialTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LinkedCredential>(
      rows,
      columns: columns?.call(LinkedCredential.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LinkedCredential]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LinkedCredential> updateRow(
    _i1.DatabaseSession session,
    LinkedCredential row, {
    _i1.ColumnSelections<LinkedCredentialTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LinkedCredential>(
      row,
      columns: columns?.call(LinkedCredential.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LinkedCredential] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LinkedCredential?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<LinkedCredentialUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<LinkedCredential>(
      id,
      columnValues: columnValues(LinkedCredential.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LinkedCredential]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<LinkedCredential>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<LinkedCredentialUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<LinkedCredentialTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LinkedCredentialTable>? orderBy,
    _i1.OrderByListBuilder<LinkedCredentialTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<LinkedCredential>(
      columnValues: columnValues(LinkedCredential.t.updateTable),
      where: where(LinkedCredential.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LinkedCredential.t),
      orderByList: orderByList?.call(LinkedCredential.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [LinkedCredential]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LinkedCredential>> delete(
    _i1.DatabaseSession session,
    List<LinkedCredential> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LinkedCredential>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LinkedCredential].
  Future<LinkedCredential> deleteRow(
    _i1.DatabaseSession session,
    LinkedCredential row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LinkedCredential>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LinkedCredential>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LinkedCredentialTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LinkedCredential>(
      where: where(LinkedCredential.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LinkedCredentialTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LinkedCredential>(
      where: where?.call(LinkedCredential.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LinkedCredential] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LinkedCredentialTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LinkedCredential>(
      where: where(LinkedCredential.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
