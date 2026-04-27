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

/// A one-time license key for activating a Landfall Pro or Founding Member license.
/// Keys are generated after a Stripe purchase and emailed to the buyer.
/// Activation ties the key to a Serverpod auth user; one activation per key.
abstract class LicenseKey
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  LicenseKey._({
    this.id,
    required this.key,
    required this.tier,
    this.activatedByUserId,
    this.activatedAt,
    required this.purchasedAt,
    this.stripeSessionId,
    this.buyerEmail,
  });

  factory LicenseKey({
    int? id,
    required String key,
    required String tier,
    String? activatedByUserId,
    DateTime? activatedAt,
    required DateTime purchasedAt,
    String? stripeSessionId,
    String? buyerEmail,
  }) = _LicenseKeyImpl;

  factory LicenseKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return LicenseKey(
      id: jsonSerialization['id'] as int?,
      key: jsonSerialization['key'] as String,
      tier: jsonSerialization['tier'] as String,
      activatedByUserId: jsonSerialization['activatedByUserId'] as String?,
      activatedAt: jsonSerialization['activatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['activatedAt'],
            ),
      purchasedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['purchasedAt'],
      ),
      stripeSessionId: jsonSerialization['stripeSessionId'] as String?,
      buyerEmail: jsonSerialization['buyerEmail'] as String?,
    );
  }

  static final t = LicenseKeyTable();

  static const db = LicenseKeyRepository._();

  @override
  int? id;

  /// The license key as shown to the user (e.g. "LF-PRO-XXXX-XXXX").
  String key;

  /// License tier: 'pro' or 'founding_member'
  String tier;

  /// Serverpod auth user identifier (UUID string) that activated this key. Null = unactivated.
  String? activatedByUserId;

  /// When this key was activated.
  DateTime? activatedAt;

  /// When this key was created / purchased.
  DateTime purchasedAt;

  /// Stripe checkout session ID for audit trail. Null for manually issued keys.
  String? stripeSessionId;

  /// Buyer email captured by Stripe. Used for key delivery.
  String? buyerEmail;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [LicenseKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LicenseKey copyWith({
    int? id,
    String? key,
    String? tier,
    String? activatedByUserId,
    DateTime? activatedAt,
    DateTime? purchasedAt,
    String? stripeSessionId,
    String? buyerEmail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LicenseKey',
      if (id != null) 'id': id,
      'key': key,
      'tier': tier,
      if (activatedByUserId != null) 'activatedByUserId': activatedByUserId,
      if (activatedAt != null) 'activatedAt': activatedAt?.toJson(),
      'purchasedAt': purchasedAt.toJson(),
      if (stripeSessionId != null) 'stripeSessionId': stripeSessionId,
      if (buyerEmail != null) 'buyerEmail': buyerEmail,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LicenseKey',
      if (id != null) 'id': id,
      'key': key,
      'tier': tier,
      if (activatedByUserId != null) 'activatedByUserId': activatedByUserId,
      if (activatedAt != null) 'activatedAt': activatedAt?.toJson(),
      'purchasedAt': purchasedAt.toJson(),
      if (stripeSessionId != null) 'stripeSessionId': stripeSessionId,
      if (buyerEmail != null) 'buyerEmail': buyerEmail,
    };
  }

  static LicenseKeyInclude include() {
    return LicenseKeyInclude._();
  }

  static LicenseKeyIncludeList includeList({
    _i1.WhereExpressionBuilder<LicenseKeyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LicenseKeyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LicenseKeyTable>? orderByList,
    LicenseKeyInclude? include,
  }) {
    return LicenseKeyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LicenseKey.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LicenseKey.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LicenseKeyImpl extends LicenseKey {
  _LicenseKeyImpl({
    int? id,
    required String key,
    required String tier,
    String? activatedByUserId,
    DateTime? activatedAt,
    required DateTime purchasedAt,
    String? stripeSessionId,
    String? buyerEmail,
  }) : super._(
         id: id,
         key: key,
         tier: tier,
         activatedByUserId: activatedByUserId,
         activatedAt: activatedAt,
         purchasedAt: purchasedAt,
         stripeSessionId: stripeSessionId,
         buyerEmail: buyerEmail,
       );

  /// Returns a shallow copy of this [LicenseKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LicenseKey copyWith({
    Object? id = _Undefined,
    String? key,
    String? tier,
    Object? activatedByUserId = _Undefined,
    Object? activatedAt = _Undefined,
    DateTime? purchasedAt,
    Object? stripeSessionId = _Undefined,
    Object? buyerEmail = _Undefined,
  }) {
    return LicenseKey(
      id: id is int? ? id : this.id,
      key: key ?? this.key,
      tier: tier ?? this.tier,
      activatedByUserId: activatedByUserId is String?
          ? activatedByUserId
          : this.activatedByUserId,
      activatedAt: activatedAt is DateTime? ? activatedAt : this.activatedAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      stripeSessionId: stripeSessionId is String?
          ? stripeSessionId
          : this.stripeSessionId,
      buyerEmail: buyerEmail is String? ? buyerEmail : this.buyerEmail,
    );
  }
}

class LicenseKeyUpdateTable extends _i1.UpdateTable<LicenseKeyTable> {
  LicenseKeyUpdateTable(super.table);

  _i1.ColumnValue<String, String> key(String value) => _i1.ColumnValue(
    table.key,
    value,
  );

  _i1.ColumnValue<String, String> tier(String value) => _i1.ColumnValue(
    table.tier,
    value,
  );

  _i1.ColumnValue<String, String> activatedByUserId(String? value) =>
      _i1.ColumnValue(
        table.activatedByUserId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> activatedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.activatedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> purchasedAt(DateTime value) =>
      _i1.ColumnValue(
        table.purchasedAt,
        value,
      );

  _i1.ColumnValue<String, String> stripeSessionId(String? value) =>
      _i1.ColumnValue(
        table.stripeSessionId,
        value,
      );

  _i1.ColumnValue<String, String> buyerEmail(String? value) => _i1.ColumnValue(
    table.buyerEmail,
    value,
  );
}

class LicenseKeyTable extends _i1.Table<int?> {
  LicenseKeyTable({super.tableRelation}) : super(tableName: 'license_keys') {
    updateTable = LicenseKeyUpdateTable(this);
    key = _i1.ColumnString(
      'key',
      this,
    );
    tier = _i1.ColumnString(
      'tier',
      this,
    );
    activatedByUserId = _i1.ColumnString(
      'activatedByUserId',
      this,
    );
    activatedAt = _i1.ColumnDateTime(
      'activatedAt',
      this,
    );
    purchasedAt = _i1.ColumnDateTime(
      'purchasedAt',
      this,
    );
    stripeSessionId = _i1.ColumnString(
      'stripeSessionId',
      this,
    );
    buyerEmail = _i1.ColumnString(
      'buyerEmail',
      this,
    );
  }

  late final LicenseKeyUpdateTable updateTable;

  /// The license key as shown to the user (e.g. "LF-PRO-XXXX-XXXX").
  late final _i1.ColumnString key;

  /// License tier: 'pro' or 'founding_member'
  late final _i1.ColumnString tier;

  /// Serverpod auth user identifier (UUID string) that activated this key. Null = unactivated.
  late final _i1.ColumnString activatedByUserId;

  /// When this key was activated.
  late final _i1.ColumnDateTime activatedAt;

  /// When this key was created / purchased.
  late final _i1.ColumnDateTime purchasedAt;

  /// Stripe checkout session ID for audit trail. Null for manually issued keys.
  late final _i1.ColumnString stripeSessionId;

  /// Buyer email captured by Stripe. Used for key delivery.
  late final _i1.ColumnString buyerEmail;

  @override
  List<_i1.Column> get columns => [
    id,
    key,
    tier,
    activatedByUserId,
    activatedAt,
    purchasedAt,
    stripeSessionId,
    buyerEmail,
  ];
}

class LicenseKeyInclude extends _i1.IncludeObject {
  LicenseKeyInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => LicenseKey.t;
}

class LicenseKeyIncludeList extends _i1.IncludeList {
  LicenseKeyIncludeList._({
    _i1.WhereExpressionBuilder<LicenseKeyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LicenseKey.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => LicenseKey.t;
}

class LicenseKeyRepository {
  const LicenseKeyRepository._();

  /// Returns a list of [LicenseKey]s matching the given query parameters.
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
  Future<List<LicenseKey>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LicenseKeyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LicenseKeyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LicenseKeyTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LicenseKey>(
      where: where?.call(LicenseKey.t),
      orderBy: orderBy?.call(LicenseKey.t),
      orderByList: orderByList?.call(LicenseKey.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LicenseKey] matching the given query parameters.
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
  Future<LicenseKey?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LicenseKeyTable>? where,
    int? offset,
    _i1.OrderByBuilder<LicenseKeyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LicenseKeyTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LicenseKey>(
      where: where?.call(LicenseKey.t),
      orderBy: orderBy?.call(LicenseKey.t),
      orderByList: orderByList?.call(LicenseKey.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LicenseKey] by its [id] or null if no such row exists.
  Future<LicenseKey?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LicenseKey>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LicenseKey]s in the list and returns the inserted rows.
  ///
  /// The returned [LicenseKey]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<LicenseKey>> insert(
    _i1.DatabaseSession session,
    List<LicenseKey> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<LicenseKey>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [LicenseKey] and returns the inserted row.
  ///
  /// The returned [LicenseKey] will have its `id` field set.
  Future<LicenseKey> insertRow(
    _i1.DatabaseSession session,
    LicenseKey row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LicenseKey>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LicenseKey]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LicenseKey>> update(
    _i1.DatabaseSession session,
    List<LicenseKey> rows, {
    _i1.ColumnSelections<LicenseKeyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LicenseKey>(
      rows,
      columns: columns?.call(LicenseKey.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LicenseKey]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LicenseKey> updateRow(
    _i1.DatabaseSession session,
    LicenseKey row, {
    _i1.ColumnSelections<LicenseKeyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LicenseKey>(
      row,
      columns: columns?.call(LicenseKey.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LicenseKey] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LicenseKey?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<LicenseKeyUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<LicenseKey>(
      id,
      columnValues: columnValues(LicenseKey.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LicenseKey]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<LicenseKey>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<LicenseKeyUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<LicenseKeyTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LicenseKeyTable>? orderBy,
    _i1.OrderByListBuilder<LicenseKeyTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<LicenseKey>(
      columnValues: columnValues(LicenseKey.t.updateTable),
      where: where(LicenseKey.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LicenseKey.t),
      orderByList: orderByList?.call(LicenseKey.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [LicenseKey]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LicenseKey>> delete(
    _i1.DatabaseSession session,
    List<LicenseKey> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LicenseKey>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LicenseKey].
  Future<LicenseKey> deleteRow(
    _i1.DatabaseSession session,
    LicenseKey row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LicenseKey>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LicenseKey>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LicenseKeyTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LicenseKey>(
      where: where(LicenseKey.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LicenseKeyTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LicenseKey>(
      where: where?.call(LicenseKey.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LicenseKey] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LicenseKeyTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LicenseKey>(
      where: where(LicenseKey.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
