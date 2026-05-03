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

/// Records a theme purchase by a Serverpod auth user.
/// Created on Stripe checkout.session.completed with purchase_type=theme.
abstract class ThemePurchase
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ThemePurchase._({
    this.id,
    required this.userId,
    required this.themeId,
    required this.purchasedAt,
    this.stripePaymentIntentId,
  });

  factory ThemePurchase({
    int? id,
    required String userId,
    required int themeId,
    required DateTime purchasedAt,
    String? stripePaymentIntentId,
  }) = _ThemePurchaseImpl;

  factory ThemePurchase.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThemePurchase(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      themeId: jsonSerialization['themeId'] as int,
      purchasedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['purchasedAt'],
      ),
      stripePaymentIntentId:
          jsonSerialization['stripePaymentIntentId'] as String?,
    );
  }

  static final t = ThemePurchaseTable();

  static const db = ThemePurchaseRepository._();

  @override
  int? id;

  /// Serverpod auth user identifier (UUID string).
  String userId;

  /// References LandfallTheme.id.
  int themeId;

  /// When this theme was purchased.
  DateTime purchasedAt;

  /// Stripe checkout session ID. Used for idempotency on webhook replay.
  String? stripePaymentIntentId;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ThemePurchase]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ThemePurchase copyWith({
    int? id,
    String? userId,
    int? themeId,
    DateTime? purchasedAt,
    String? stripePaymentIntentId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemePurchase',
      if (id != null) 'id': id,
      'userId': userId,
      'themeId': themeId,
      'purchasedAt': purchasedAt.toJson(),
      if (stripePaymentIntentId != null)
        'stripePaymentIntentId': stripePaymentIntentId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ThemePurchase',
      if (id != null) 'id': id,
      'userId': userId,
      'themeId': themeId,
      'purchasedAt': purchasedAt.toJson(),
      if (stripePaymentIntentId != null)
        'stripePaymentIntentId': stripePaymentIntentId,
    };
  }

  static ThemePurchaseInclude include() {
    return ThemePurchaseInclude._();
  }

  static ThemePurchaseIncludeList includeList({
    _i1.WhereExpressionBuilder<ThemePurchaseTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ThemePurchaseTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ThemePurchaseTable>? orderByList,
    ThemePurchaseInclude? include,
  }) {
    return ThemePurchaseIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ThemePurchase.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ThemePurchase.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThemePurchaseImpl extends ThemePurchase {
  _ThemePurchaseImpl({
    int? id,
    required String userId,
    required int themeId,
    required DateTime purchasedAt,
    String? stripePaymentIntentId,
  }) : super._(
         id: id,
         userId: userId,
         themeId: themeId,
         purchasedAt: purchasedAt,
         stripePaymentIntentId: stripePaymentIntentId,
       );

  /// Returns a shallow copy of this [ThemePurchase]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ThemePurchase copyWith({
    Object? id = _Undefined,
    String? userId,
    int? themeId,
    DateTime? purchasedAt,
    Object? stripePaymentIntentId = _Undefined,
  }) {
    return ThemePurchase(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      themeId: themeId ?? this.themeId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      stripePaymentIntentId: stripePaymentIntentId is String?
          ? stripePaymentIntentId
          : this.stripePaymentIntentId,
    );
  }
}

class ThemePurchaseUpdateTable extends _i1.UpdateTable<ThemePurchaseTable> {
  ThemePurchaseUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<int, int> themeId(int value) => _i1.ColumnValue(
    table.themeId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> purchasedAt(DateTime value) =>
      _i1.ColumnValue(
        table.purchasedAt,
        value,
      );

  _i1.ColumnValue<String, String> stripePaymentIntentId(String? value) =>
      _i1.ColumnValue(
        table.stripePaymentIntentId,
        value,
      );
}

class ThemePurchaseTable extends _i1.Table<int?> {
  ThemePurchaseTable({super.tableRelation})
    : super(tableName: 'theme_purchases') {
    updateTable = ThemePurchaseUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    themeId = _i1.ColumnInt(
      'themeId',
      this,
    );
    purchasedAt = _i1.ColumnDateTime(
      'purchasedAt',
      this,
    );
    stripePaymentIntentId = _i1.ColumnString(
      'stripePaymentIntentId',
      this,
    );
  }

  late final ThemePurchaseUpdateTable updateTable;

  /// Serverpod auth user identifier (UUID string).
  late final _i1.ColumnString userId;

  /// References LandfallTheme.id.
  late final _i1.ColumnInt themeId;

  /// When this theme was purchased.
  late final _i1.ColumnDateTime purchasedAt;

  /// Stripe checkout session ID. Used for idempotency on webhook replay.
  late final _i1.ColumnString stripePaymentIntentId;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    themeId,
    purchasedAt,
    stripePaymentIntentId,
  ];
}

class ThemePurchaseInclude extends _i1.IncludeObject {
  ThemePurchaseInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ThemePurchase.t;
}

class ThemePurchaseIncludeList extends _i1.IncludeList {
  ThemePurchaseIncludeList._({
    _i1.WhereExpressionBuilder<ThemePurchaseTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ThemePurchase.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ThemePurchase.t;
}

class ThemePurchaseRepository {
  const ThemePurchaseRepository._();

  /// Returns a list of [ThemePurchase]s matching the given query parameters.
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
  Future<List<ThemePurchase>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ThemePurchaseTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ThemePurchaseTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ThemePurchaseTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ThemePurchase>(
      where: where?.call(ThemePurchase.t),
      orderBy: orderBy?.call(ThemePurchase.t),
      orderByList: orderByList?.call(ThemePurchase.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ThemePurchase] matching the given query parameters.
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
  Future<ThemePurchase?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ThemePurchaseTable>? where,
    int? offset,
    _i1.OrderByBuilder<ThemePurchaseTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ThemePurchaseTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ThemePurchase>(
      where: where?.call(ThemePurchase.t),
      orderBy: orderBy?.call(ThemePurchase.t),
      orderByList: orderByList?.call(ThemePurchase.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ThemePurchase] by its [id] or null if no such row exists.
  Future<ThemePurchase?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ThemePurchase>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ThemePurchase]s in the list and returns the inserted rows.
  ///
  /// The returned [ThemePurchase]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ThemePurchase>> insert(
    _i1.DatabaseSession session,
    List<ThemePurchase> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ThemePurchase>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ThemePurchase] and returns the inserted row.
  ///
  /// The returned [ThemePurchase] will have its `id` field set.
  Future<ThemePurchase> insertRow(
    _i1.DatabaseSession session,
    ThemePurchase row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ThemePurchase>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ThemePurchase]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ThemePurchase>> update(
    _i1.DatabaseSession session,
    List<ThemePurchase> rows, {
    _i1.ColumnSelections<ThemePurchaseTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ThemePurchase>(
      rows,
      columns: columns?.call(ThemePurchase.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ThemePurchase]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ThemePurchase> updateRow(
    _i1.DatabaseSession session,
    ThemePurchase row, {
    _i1.ColumnSelections<ThemePurchaseTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ThemePurchase>(
      row,
      columns: columns?.call(ThemePurchase.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ThemePurchase] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ThemePurchase?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ThemePurchaseUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ThemePurchase>(
      id,
      columnValues: columnValues(ThemePurchase.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ThemePurchase]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ThemePurchase>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ThemePurchaseUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ThemePurchaseTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ThemePurchaseTable>? orderBy,
    _i1.OrderByListBuilder<ThemePurchaseTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ThemePurchase>(
      columnValues: columnValues(ThemePurchase.t.updateTable),
      where: where(ThemePurchase.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ThemePurchase.t),
      orderByList: orderByList?.call(ThemePurchase.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ThemePurchase]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ThemePurchase>> delete(
    _i1.DatabaseSession session,
    List<ThemePurchase> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ThemePurchase>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ThemePurchase].
  Future<ThemePurchase> deleteRow(
    _i1.DatabaseSession session,
    ThemePurchase row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ThemePurchase>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ThemePurchase>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ThemePurchaseTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ThemePurchase>(
      where: where(ThemePurchase.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ThemePurchaseTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ThemePurchase>(
      where: where?.call(ThemePurchase.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ThemePurchase] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ThemePurchaseTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ThemePurchase>(
      where: where(ThemePurchase.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
