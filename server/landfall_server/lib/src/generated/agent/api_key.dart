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

/// An API key for agent clients pushing cards to the display.
/// The plaintext key is never stored — only the SHA-256 hash.
abstract class ApiKey implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ApiKey._({
    this.id,
    required this.name,
    required this.keyHash,
    required this.prefix,
    required this.createdAt,
    this.lastUsedAt,
    this.lastUsedIp,
    this.revokedAt,
    int? dailyLimit,
    int? usageCount,
    required this.usageResetAt,
  }) : dailyLimit = dailyLimit ?? 500,
       usageCount = usageCount ?? 0;

  factory ApiKey({
    int? id,
    required String name,
    required String keyHash,
    required String prefix,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    String? lastUsedIp,
    DateTime? revokedAt,
    int? dailyLimit,
    int? usageCount,
    required DateTime usageResetAt,
  }) = _ApiKeyImpl;

  factory ApiKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiKey(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      keyHash: jsonSerialization['keyHash'] as String,
      prefix: jsonSerialization['prefix'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastUsedAt: jsonSerialization['lastUsedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsedAt']),
      lastUsedIp: jsonSerialization['lastUsedIp'] as String?,
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
      dailyLimit: jsonSerialization['dailyLimit'] as int?,
      usageCount: jsonSerialization['usageCount'] as int?,
      usageResetAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['usageResetAt'],
      ),
    );
  }

  static final t = ApiKeyTable();

  static const db = ApiKeyRepository._();

  @override
  int? id;

  /// Human-readable label for this key.
  String name;

  /// SHA-256 hex digest of the plaintext key. Never expose this to clients.
  String keyHash;

  /// First 8 characters of the plaintext key, for display/identification.
  String prefix;

  /// When this key was created.
  DateTime createdAt;

  /// When this key was last used to authenticate a request.
  DateTime? lastUsedAt;

  /// IP address of the most recent authenticated request. A07:2025.
  String? lastUsedIp;

  /// When this key was revoked. Non-null = key is inactive.
  DateTime? revokedAt;

  /// Maximum pushCard calls per day. Resets at UTC midnight.
  int dailyLimit;

  /// Number of pushCard calls made since usageResetAt.
  int usageCount;

  /// Next time usageCount resets to zero (UTC midnight).
  DateTime usageResetAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ApiKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ApiKey copyWith({
    int? id,
    String? name,
    String? keyHash,
    String? prefix,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    String? lastUsedIp,
    DateTime? revokedAt,
    int? dailyLimit,
    int? usageCount,
    DateTime? usageResetAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiKey',
      if (id != null) 'id': id,
      'name': name,
      'keyHash': keyHash,
      'prefix': prefix,
      'createdAt': createdAt.toJson(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt?.toJson(),
      if (lastUsedIp != null) 'lastUsedIp': lastUsedIp,
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
      'dailyLimit': dailyLimit,
      'usageCount': usageCount,
      'usageResetAt': usageResetAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ApiKey',
      if (id != null) 'id': id,
      'name': name,
      'keyHash': keyHash,
      'prefix': prefix,
      'createdAt': createdAt.toJson(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt?.toJson(),
      if (lastUsedIp != null) 'lastUsedIp': lastUsedIp,
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
      'dailyLimit': dailyLimit,
      'usageCount': usageCount,
      'usageResetAt': usageResetAt.toJson(),
    };
  }

  static ApiKeyInclude include() {
    return ApiKeyInclude._();
  }

  static ApiKeyIncludeList includeList({
    _i1.WhereExpressionBuilder<ApiKeyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ApiKeyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ApiKeyTable>? orderByList,
    ApiKeyInclude? include,
  }) {
    return ApiKeyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ApiKey.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ApiKey.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ApiKeyImpl extends ApiKey {
  _ApiKeyImpl({
    int? id,
    required String name,
    required String keyHash,
    required String prefix,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    String? lastUsedIp,
    DateTime? revokedAt,
    int? dailyLimit,
    int? usageCount,
    required DateTime usageResetAt,
  }) : super._(
         id: id,
         name: name,
         keyHash: keyHash,
         prefix: prefix,
         createdAt: createdAt,
         lastUsedAt: lastUsedAt,
         lastUsedIp: lastUsedIp,
         revokedAt: revokedAt,
         dailyLimit: dailyLimit,
         usageCount: usageCount,
         usageResetAt: usageResetAt,
       );

  /// Returns a shallow copy of this [ApiKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ApiKey copyWith({
    Object? id = _Undefined,
    String? name,
    String? keyHash,
    String? prefix,
    DateTime? createdAt,
    Object? lastUsedAt = _Undefined,
    Object? lastUsedIp = _Undefined,
    Object? revokedAt = _Undefined,
    int? dailyLimit,
    int? usageCount,
    DateTime? usageResetAt,
  }) {
    return ApiKey(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      keyHash: keyHash ?? this.keyHash,
      prefix: prefix ?? this.prefix,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt is DateTime? ? lastUsedAt : this.lastUsedAt,
      lastUsedIp: lastUsedIp is String? ? lastUsedIp : this.lastUsedIp,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      usageCount: usageCount ?? this.usageCount,
      usageResetAt: usageResetAt ?? this.usageResetAt,
    );
  }
}

class ApiKeyUpdateTable extends _i1.UpdateTable<ApiKeyTable> {
  ApiKeyUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> keyHash(String value) => _i1.ColumnValue(
    table.keyHash,
    value,
  );

  _i1.ColumnValue<String, String> prefix(String value) => _i1.ColumnValue(
    table.prefix,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastUsedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.lastUsedAt,
        value,
      );

  _i1.ColumnValue<String, String> lastUsedIp(String? value) => _i1.ColumnValue(
    table.lastUsedIp,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> revokedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.revokedAt,
        value,
      );

  _i1.ColumnValue<int, int> dailyLimit(int value) => _i1.ColumnValue(
    table.dailyLimit,
    value,
  );

  _i1.ColumnValue<int, int> usageCount(int value) => _i1.ColumnValue(
    table.usageCount,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> usageResetAt(DateTime value) =>
      _i1.ColumnValue(
        table.usageResetAt,
        value,
      );
}

class ApiKeyTable extends _i1.Table<int?> {
  ApiKeyTable({super.tableRelation}) : super(tableName: 'api_keys') {
    updateTable = ApiKeyUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    keyHash = _i1.ColumnString(
      'keyHash',
      this,
    );
    prefix = _i1.ColumnString(
      'prefix',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    lastUsedAt = _i1.ColumnDateTime(
      'lastUsedAt',
      this,
    );
    lastUsedIp = _i1.ColumnString(
      'lastUsedIp',
      this,
    );
    revokedAt = _i1.ColumnDateTime(
      'revokedAt',
      this,
    );
    dailyLimit = _i1.ColumnInt(
      'dailyLimit',
      this,
      hasDefault: true,
    );
    usageCount = _i1.ColumnInt(
      'usageCount',
      this,
      hasDefault: true,
    );
    usageResetAt = _i1.ColumnDateTime(
      'usageResetAt',
      this,
    );
  }

  late final ApiKeyUpdateTable updateTable;

  /// Human-readable label for this key.
  late final _i1.ColumnString name;

  /// SHA-256 hex digest of the plaintext key. Never expose this to clients.
  late final _i1.ColumnString keyHash;

  /// First 8 characters of the plaintext key, for display/identification.
  late final _i1.ColumnString prefix;

  /// When this key was created.
  late final _i1.ColumnDateTime createdAt;

  /// When this key was last used to authenticate a request.
  late final _i1.ColumnDateTime lastUsedAt;

  /// IP address of the most recent authenticated request. A07:2025.
  late final _i1.ColumnString lastUsedIp;

  /// When this key was revoked. Non-null = key is inactive.
  late final _i1.ColumnDateTime revokedAt;

  /// Maximum pushCard calls per day. Resets at UTC midnight.
  late final _i1.ColumnInt dailyLimit;

  /// Number of pushCard calls made since usageResetAt.
  late final _i1.ColumnInt usageCount;

  /// Next time usageCount resets to zero (UTC midnight).
  late final _i1.ColumnDateTime usageResetAt;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    keyHash,
    prefix,
    createdAt,
    lastUsedAt,
    lastUsedIp,
    revokedAt,
    dailyLimit,
    usageCount,
    usageResetAt,
  ];
}

class ApiKeyInclude extends _i1.IncludeObject {
  ApiKeyInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ApiKey.t;
}

class ApiKeyIncludeList extends _i1.IncludeList {
  ApiKeyIncludeList._({
    _i1.WhereExpressionBuilder<ApiKeyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ApiKey.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ApiKey.t;
}

class ApiKeyRepository {
  const ApiKeyRepository._();

  /// Returns a list of [ApiKey]s matching the given query parameters.
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
  Future<List<ApiKey>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ApiKeyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ApiKeyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ApiKeyTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ApiKey>(
      where: where?.call(ApiKey.t),
      orderBy: orderBy?.call(ApiKey.t),
      orderByList: orderByList?.call(ApiKey.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ApiKey] matching the given query parameters.
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
  Future<ApiKey?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ApiKeyTable>? where,
    int? offset,
    _i1.OrderByBuilder<ApiKeyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ApiKeyTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ApiKey>(
      where: where?.call(ApiKey.t),
      orderBy: orderBy?.call(ApiKey.t),
      orderByList: orderByList?.call(ApiKey.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ApiKey] by its [id] or null if no such row exists.
  Future<ApiKey?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ApiKey>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ApiKey]s in the list and returns the inserted rows.
  ///
  /// The returned [ApiKey]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ApiKey>> insert(
    _i1.DatabaseSession session,
    List<ApiKey> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ApiKey>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ApiKey] and returns the inserted row.
  ///
  /// The returned [ApiKey] will have its `id` field set.
  Future<ApiKey> insertRow(
    _i1.DatabaseSession session,
    ApiKey row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ApiKey>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ApiKey]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ApiKey>> update(
    _i1.DatabaseSession session,
    List<ApiKey> rows, {
    _i1.ColumnSelections<ApiKeyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ApiKey>(
      rows,
      columns: columns?.call(ApiKey.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ApiKey]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ApiKey> updateRow(
    _i1.DatabaseSession session,
    ApiKey row, {
    _i1.ColumnSelections<ApiKeyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ApiKey>(
      row,
      columns: columns?.call(ApiKey.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ApiKey] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ApiKey?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ApiKeyUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ApiKey>(
      id,
      columnValues: columnValues(ApiKey.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ApiKey]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ApiKey>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ApiKeyUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ApiKeyTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ApiKeyTable>? orderBy,
    _i1.OrderByListBuilder<ApiKeyTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ApiKey>(
      columnValues: columnValues(ApiKey.t.updateTable),
      where: where(ApiKey.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ApiKey.t),
      orderByList: orderByList?.call(ApiKey.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ApiKey]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ApiKey>> delete(
    _i1.DatabaseSession session,
    List<ApiKey> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ApiKey>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ApiKey].
  Future<ApiKey> deleteRow(
    _i1.DatabaseSession session,
    ApiKey row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ApiKey>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ApiKey>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ApiKeyTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ApiKey>(
      where: where(ApiKey.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ApiKeyTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ApiKey>(
      where: where?.call(ApiKey.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ApiKey] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ApiKeyTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ApiKey>(
      where: where(ApiKey.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
