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

/// An integration pack in the Landfall marketplace catalog.
/// Seeded at deployment time; updated by re-running the seed migration.
abstract class IntegrationPack
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  IntegrationPack._({
    this.id,
    required this.packId,
    required this.name,
    required this.description,
    required this.version,
    required this.priceUsd,
    required this.authorName,
    this.iconUrl,
    this.stripePaymentLink,
    bool? isActive,
  }) : isActive = isActive ?? true;

  factory IntegrationPack({
    int? id,
    required String packId,
    required String name,
    required String description,
    required String version,
    required double priceUsd,
    required String authorName,
    String? iconUrl,
    String? stripePaymentLink,
    bool? isActive,
  }) = _IntegrationPackImpl;

  factory IntegrationPack.fromJson(Map<String, dynamic> jsonSerialization) {
    return IntegrationPack(
      id: jsonSerialization['id'] as int?,
      packId: jsonSerialization['packId'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      version: jsonSerialization['version'] as String,
      priceUsd: (jsonSerialization['priceUsd'] as num).toDouble(),
      authorName: jsonSerialization['authorName'] as String,
      iconUrl: jsonSerialization['iconUrl'] as String?,
      stripePaymentLink: jsonSerialization['stripePaymentLink'] as String?,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
    );
  }

  static final t = IntegrationPackTable();

  static const db = IntegrationPackRepository._();

  @override
  int? id;

  /// Stable slug used as the primary identifier (e.g. 'sports_scores').
  String packId;

  /// User-facing display name.
  String name;

  /// Short description shown in the pack browser.
  String description;

  /// Semantic version string.
  String version;

  /// Price in USD.
  double priceUsd;

  /// Pack author name.
  String authorName;

  /// Optional icon URL.
  String? iconUrl;

  /// Stripe payment link for purchasing this pack. Null = not yet set up.
  String? stripePaymentLink;

  /// Whether this pack is listed in the marketplace.
  bool isActive;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [IntegrationPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IntegrationPack copyWith({
    int? id,
    String? packId,
    String? name,
    String? description,
    String? version,
    double? priceUsd,
    String? authorName,
    String? iconUrl,
    String? stripePaymentLink,
    bool? isActive,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IntegrationPack',
      if (id != null) 'id': id,
      'packId': packId,
      'name': name,
      'description': description,
      'version': version,
      'priceUsd': priceUsd,
      'authorName': authorName,
      if (iconUrl != null) 'iconUrl': iconUrl,
      if (stripePaymentLink != null) 'stripePaymentLink': stripePaymentLink,
      'isActive': isActive,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IntegrationPack',
      if (id != null) 'id': id,
      'packId': packId,
      'name': name,
      'description': description,
      'version': version,
      'priceUsd': priceUsd,
      'authorName': authorName,
      if (iconUrl != null) 'iconUrl': iconUrl,
      if (stripePaymentLink != null) 'stripePaymentLink': stripePaymentLink,
      'isActive': isActive,
    };
  }

  static IntegrationPackInclude include() {
    return IntegrationPackInclude._();
  }

  static IntegrationPackIncludeList includeList({
    _i1.WhereExpressionBuilder<IntegrationPackTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IntegrationPackTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IntegrationPackTable>? orderByList,
    IntegrationPackInclude? include,
  }) {
    return IntegrationPackIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IntegrationPack.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(IntegrationPack.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IntegrationPackImpl extends IntegrationPack {
  _IntegrationPackImpl({
    int? id,
    required String packId,
    required String name,
    required String description,
    required String version,
    required double priceUsd,
    required String authorName,
    String? iconUrl,
    String? stripePaymentLink,
    bool? isActive,
  }) : super._(
         id: id,
         packId: packId,
         name: name,
         description: description,
         version: version,
         priceUsd: priceUsd,
         authorName: authorName,
         iconUrl: iconUrl,
         stripePaymentLink: stripePaymentLink,
         isActive: isActive,
       );

  /// Returns a shallow copy of this [IntegrationPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IntegrationPack copyWith({
    Object? id = _Undefined,
    String? packId,
    String? name,
    String? description,
    String? version,
    double? priceUsd,
    String? authorName,
    Object? iconUrl = _Undefined,
    Object? stripePaymentLink = _Undefined,
    bool? isActive,
  }) {
    return IntegrationPack(
      id: id is int? ? id : this.id,
      packId: packId ?? this.packId,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      priceUsd: priceUsd ?? this.priceUsd,
      authorName: authorName ?? this.authorName,
      iconUrl: iconUrl is String? ? iconUrl : this.iconUrl,
      stripePaymentLink: stripePaymentLink is String?
          ? stripePaymentLink
          : this.stripePaymentLink,
      isActive: isActive ?? this.isActive,
    );
  }
}

class IntegrationPackUpdateTable extends _i1.UpdateTable<IntegrationPackTable> {
  IntegrationPackUpdateTable(super.table);

  _i1.ColumnValue<String, String> packId(String value) => _i1.ColumnValue(
    table.packId,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> description(String value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<String, String> version(String value) => _i1.ColumnValue(
    table.version,
    value,
  );

  _i1.ColumnValue<double, double> priceUsd(double value) => _i1.ColumnValue(
    table.priceUsd,
    value,
  );

  _i1.ColumnValue<String, String> authorName(String value) => _i1.ColumnValue(
    table.authorName,
    value,
  );

  _i1.ColumnValue<String, String> iconUrl(String? value) => _i1.ColumnValue(
    table.iconUrl,
    value,
  );

  _i1.ColumnValue<String, String> stripePaymentLink(String? value) =>
      _i1.ColumnValue(
        table.stripePaymentLink,
        value,
      );

  _i1.ColumnValue<bool, bool> isActive(bool value) => _i1.ColumnValue(
    table.isActive,
    value,
  );
}

class IntegrationPackTable extends _i1.Table<int?> {
  IntegrationPackTable({super.tableRelation})
    : super(tableName: 'integration_packs') {
    updateTable = IntegrationPackUpdateTable(this);
    packId = _i1.ColumnString(
      'packId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    version = _i1.ColumnString(
      'version',
      this,
    );
    priceUsd = _i1.ColumnDouble(
      'priceUsd',
      this,
    );
    authorName = _i1.ColumnString(
      'authorName',
      this,
    );
    iconUrl = _i1.ColumnString(
      'iconUrl',
      this,
    );
    stripePaymentLink = _i1.ColumnString(
      'stripePaymentLink',
      this,
    );
    isActive = _i1.ColumnBool(
      'isActive',
      this,
      hasDefault: true,
    );
  }

  late final IntegrationPackUpdateTable updateTable;

  /// Stable slug used as the primary identifier (e.g. 'sports_scores').
  late final _i1.ColumnString packId;

  /// User-facing display name.
  late final _i1.ColumnString name;

  /// Short description shown in the pack browser.
  late final _i1.ColumnString description;

  /// Semantic version string.
  late final _i1.ColumnString version;

  /// Price in USD.
  late final _i1.ColumnDouble priceUsd;

  /// Pack author name.
  late final _i1.ColumnString authorName;

  /// Optional icon URL.
  late final _i1.ColumnString iconUrl;

  /// Stripe payment link for purchasing this pack. Null = not yet set up.
  late final _i1.ColumnString stripePaymentLink;

  /// Whether this pack is listed in the marketplace.
  late final _i1.ColumnBool isActive;

  @override
  List<_i1.Column> get columns => [
    id,
    packId,
    name,
    description,
    version,
    priceUsd,
    authorName,
    iconUrl,
    stripePaymentLink,
    isActive,
  ];
}

class IntegrationPackInclude extends _i1.IncludeObject {
  IntegrationPackInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => IntegrationPack.t;
}

class IntegrationPackIncludeList extends _i1.IncludeList {
  IntegrationPackIncludeList._({
    _i1.WhereExpressionBuilder<IntegrationPackTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(IntegrationPack.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => IntegrationPack.t;
}

class IntegrationPackRepository {
  const IntegrationPackRepository._();

  /// Returns a list of [IntegrationPack]s matching the given query parameters.
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
  Future<List<IntegrationPack>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<IntegrationPackTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IntegrationPackTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IntegrationPackTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<IntegrationPack>(
      where: where?.call(IntegrationPack.t),
      orderBy: orderBy?.call(IntegrationPack.t),
      orderByList: orderByList?.call(IntegrationPack.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [IntegrationPack] matching the given query parameters.
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
  Future<IntegrationPack?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<IntegrationPackTable>? where,
    int? offset,
    _i1.OrderByBuilder<IntegrationPackTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IntegrationPackTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<IntegrationPack>(
      where: where?.call(IntegrationPack.t),
      orderBy: orderBy?.call(IntegrationPack.t),
      orderByList: orderByList?.call(IntegrationPack.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [IntegrationPack] by its [id] or null if no such row exists.
  Future<IntegrationPack?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<IntegrationPack>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [IntegrationPack]s in the list and returns the inserted rows.
  ///
  /// The returned [IntegrationPack]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<IntegrationPack>> insert(
    _i1.DatabaseSession session,
    List<IntegrationPack> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<IntegrationPack>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [IntegrationPack] and returns the inserted row.
  ///
  /// The returned [IntegrationPack] will have its `id` field set.
  Future<IntegrationPack> insertRow(
    _i1.DatabaseSession session,
    IntegrationPack row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<IntegrationPack>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [IntegrationPack]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<IntegrationPack>> update(
    _i1.DatabaseSession session,
    List<IntegrationPack> rows, {
    _i1.ColumnSelections<IntegrationPackTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<IntegrationPack>(
      rows,
      columns: columns?.call(IntegrationPack.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IntegrationPack]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<IntegrationPack> updateRow(
    _i1.DatabaseSession session,
    IntegrationPack row, {
    _i1.ColumnSelections<IntegrationPackTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<IntegrationPack>(
      row,
      columns: columns?.call(IntegrationPack.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IntegrationPack] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<IntegrationPack?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<IntegrationPackUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<IntegrationPack>(
      id,
      columnValues: columnValues(IntegrationPack.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [IntegrationPack]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<IntegrationPack>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<IntegrationPackUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<IntegrationPackTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IntegrationPackTable>? orderBy,
    _i1.OrderByListBuilder<IntegrationPackTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<IntegrationPack>(
      columnValues: columnValues(IntegrationPack.t.updateTable),
      where: where(IntegrationPack.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IntegrationPack.t),
      orderByList: orderByList?.call(IntegrationPack.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [IntegrationPack]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<IntegrationPack>> delete(
    _i1.DatabaseSession session,
    List<IntegrationPack> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<IntegrationPack>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [IntegrationPack].
  Future<IntegrationPack> deleteRow(
    _i1.DatabaseSession session,
    IntegrationPack row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<IntegrationPack>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<IntegrationPack>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<IntegrationPackTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<IntegrationPack>(
      where: where(IntegrationPack.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<IntegrationPackTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<IntegrationPack>(
      where: where?.call(IntegrationPack.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [IntegrationPack] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<IntegrationPackTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<IntegrationPack>(
      where: where(IntegrationPack.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
