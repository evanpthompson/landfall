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

/// The companion creature assigned to a display.
/// One row per display, identified by displayId (the client-generated UUID).
/// Rarity, species, name, and traits are seeded once at creation and are fixed
/// forever. Evolution stage advances over time via the nightly evolution job.
abstract class CompanionEntity
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  CompanionEntity._({
    this.id,
    required this.displayId,
    required this.seed,
    required this.rarityTier,
    required this.speciesId,
    required this.name,
    required this.traits,
    int? evolutionStage,
    required this.createdAt,
    this.assetCredit,
    this.lastEvolutionAt,
  }) : evolutionStage = evolutionStage ?? 0;

  factory CompanionEntity({
    int? id,
    required String displayId,
    required int seed,
    required String rarityTier,
    required String speciesId,
    required String name,
    required String traits,
    int? evolutionStage,
    required DateTime createdAt,
    String? assetCredit,
    DateTime? lastEvolutionAt,
  }) = _CompanionEntityImpl;

  factory CompanionEntity.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanionEntity(
      id: jsonSerialization['id'] as int?,
      displayId: jsonSerialization['displayId'] as String,
      seed: jsonSerialization['seed'] as int,
      rarityTier: jsonSerialization['rarityTier'] as String,
      speciesId: jsonSerialization['speciesId'] as String,
      name: jsonSerialization['name'] as String,
      traits: jsonSerialization['traits'] as String,
      evolutionStage: jsonSerialization['evolutionStage'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      assetCredit: jsonSerialization['assetCredit'] as String?,
      lastEvolutionAt: jsonSerialization['lastEvolutionAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastEvolutionAt'],
            ),
    );
  }

  static final t = CompanionEntityTable();

  static const db = CompanionEntityRepository._();

  @override
  int? id;

  /// The display's stable UUID. One companion per display.
  String displayId;

  /// Deterministic seed derived from displayId — used by xrandom to pick
  /// species/rarity/name. Stored so future seeded draws stay reproducible.
  int seed;

  /// Rarity bucket: common | uncommon | rare | epic | legendary.
  String rarityTier;

  /// Identifies the creature template (e.g. "lumen", "axolotl").
  String speciesId;

  /// Display name — procedurally generated from seed, fixed forever.
  String name;

  /// Personality traits as a comma-separated list (e.g. "curious,gentle").
  /// Maps to PersonalityTrait enum in the client.
  String traits;

  /// 0 = Baby, 1 = Juvenile, 2 = Adult, 3 = Elder. Advances over time.
  int evolutionStage;

  /// When the companion was first created for this display.
  DateTime createdAt;

  /// Optional attribution string for the sprite artist.
  String? assetCredit;

  /// Last time the evolution stage changed. Null if never evolved.
  DateTime? lastEvolutionAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [CompanionEntity]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CompanionEntity copyWith({
    int? id,
    String? displayId,
    int? seed,
    String? rarityTier,
    String? speciesId,
    String? name,
    String? traits,
    int? evolutionStage,
    DateTime? createdAt,
    String? assetCredit,
    DateTime? lastEvolutionAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanionEntity',
      if (id != null) 'id': id,
      'displayId': displayId,
      'seed': seed,
      'rarityTier': rarityTier,
      'speciesId': speciesId,
      'name': name,
      'traits': traits,
      'evolutionStage': evolutionStage,
      'createdAt': createdAt.toJson(),
      if (assetCredit != null) 'assetCredit': assetCredit,
      if (lastEvolutionAt != null) 'lastEvolutionAt': lastEvolutionAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanionEntity',
      if (id != null) 'id': id,
      'displayId': displayId,
      'seed': seed,
      'rarityTier': rarityTier,
      'speciesId': speciesId,
      'name': name,
      'traits': traits,
      'evolutionStage': evolutionStage,
      'createdAt': createdAt.toJson(),
      if (assetCredit != null) 'assetCredit': assetCredit,
      if (lastEvolutionAt != null) 'lastEvolutionAt': lastEvolutionAt?.toJson(),
    };
  }

  static CompanionEntityInclude include() {
    return CompanionEntityInclude._();
  }

  static CompanionEntityIncludeList includeList({
    _i1.WhereExpressionBuilder<CompanionEntityTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CompanionEntityTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CompanionEntityTable>? orderByList,
    CompanionEntityInclude? include,
  }) {
    return CompanionEntityIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CompanionEntity.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(CompanionEntity.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanionEntityImpl extends CompanionEntity {
  _CompanionEntityImpl({
    int? id,
    required String displayId,
    required int seed,
    required String rarityTier,
    required String speciesId,
    required String name,
    required String traits,
    int? evolutionStage,
    required DateTime createdAt,
    String? assetCredit,
    DateTime? lastEvolutionAt,
  }) : super._(
         id: id,
         displayId: displayId,
         seed: seed,
         rarityTier: rarityTier,
         speciesId: speciesId,
         name: name,
         traits: traits,
         evolutionStage: evolutionStage,
         createdAt: createdAt,
         assetCredit: assetCredit,
         lastEvolutionAt: lastEvolutionAt,
       );

  /// Returns a shallow copy of this [CompanionEntity]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CompanionEntity copyWith({
    Object? id = _Undefined,
    String? displayId,
    int? seed,
    String? rarityTier,
    String? speciesId,
    String? name,
    String? traits,
    int? evolutionStage,
    DateTime? createdAt,
    Object? assetCredit = _Undefined,
    Object? lastEvolutionAt = _Undefined,
  }) {
    return CompanionEntity(
      id: id is int? ? id : this.id,
      displayId: displayId ?? this.displayId,
      seed: seed ?? this.seed,
      rarityTier: rarityTier ?? this.rarityTier,
      speciesId: speciesId ?? this.speciesId,
      name: name ?? this.name,
      traits: traits ?? this.traits,
      evolutionStage: evolutionStage ?? this.evolutionStage,
      createdAt: createdAt ?? this.createdAt,
      assetCredit: assetCredit is String? ? assetCredit : this.assetCredit,
      lastEvolutionAt: lastEvolutionAt is DateTime?
          ? lastEvolutionAt
          : this.lastEvolutionAt,
    );
  }
}

class CompanionEntityUpdateTable extends _i1.UpdateTable<CompanionEntityTable> {
  CompanionEntityUpdateTable(super.table);

  _i1.ColumnValue<String, String> displayId(String value) => _i1.ColumnValue(
    table.displayId,
    value,
  );

  _i1.ColumnValue<int, int> seed(int value) => _i1.ColumnValue(
    table.seed,
    value,
  );

  _i1.ColumnValue<String, String> rarityTier(String value) => _i1.ColumnValue(
    table.rarityTier,
    value,
  );

  _i1.ColumnValue<String, String> speciesId(String value) => _i1.ColumnValue(
    table.speciesId,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> traits(String value) => _i1.ColumnValue(
    table.traits,
    value,
  );

  _i1.ColumnValue<int, int> evolutionStage(int value) => _i1.ColumnValue(
    table.evolutionStage,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<String, String> assetCredit(String? value) => _i1.ColumnValue(
    table.assetCredit,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastEvolutionAt(DateTime? value) =>
      _i1.ColumnValue(
        table.lastEvolutionAt,
        value,
      );
}

class CompanionEntityTable extends _i1.Table<int?> {
  CompanionEntityTable({super.tableRelation})
    : super(tableName: 'companion_entities') {
    updateTable = CompanionEntityUpdateTable(this);
    displayId = _i1.ColumnString(
      'displayId',
      this,
    );
    seed = _i1.ColumnInt(
      'seed',
      this,
    );
    rarityTier = _i1.ColumnString(
      'rarityTier',
      this,
    );
    speciesId = _i1.ColumnString(
      'speciesId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    traits = _i1.ColumnString(
      'traits',
      this,
    );
    evolutionStage = _i1.ColumnInt(
      'evolutionStage',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    assetCredit = _i1.ColumnString(
      'assetCredit',
      this,
    );
    lastEvolutionAt = _i1.ColumnDateTime(
      'lastEvolutionAt',
      this,
    );
  }

  late final CompanionEntityUpdateTable updateTable;

  /// The display's stable UUID. One companion per display.
  late final _i1.ColumnString displayId;

  /// Deterministic seed derived from displayId — used by xrandom to pick
  /// species/rarity/name. Stored so future seeded draws stay reproducible.
  late final _i1.ColumnInt seed;

  /// Rarity bucket: common | uncommon | rare | epic | legendary.
  late final _i1.ColumnString rarityTier;

  /// Identifies the creature template (e.g. "lumen", "axolotl").
  late final _i1.ColumnString speciesId;

  /// Display name — procedurally generated from seed, fixed forever.
  late final _i1.ColumnString name;

  /// Personality traits as a comma-separated list (e.g. "curious,gentle").
  /// Maps to PersonalityTrait enum in the client.
  late final _i1.ColumnString traits;

  /// 0 = Baby, 1 = Juvenile, 2 = Adult, 3 = Elder. Advances over time.
  late final _i1.ColumnInt evolutionStage;

  /// When the companion was first created for this display.
  late final _i1.ColumnDateTime createdAt;

  /// Optional attribution string for the sprite artist.
  late final _i1.ColumnString assetCredit;

  /// Last time the evolution stage changed. Null if never evolved.
  late final _i1.ColumnDateTime lastEvolutionAt;

  @override
  List<_i1.Column> get columns => [
    id,
    displayId,
    seed,
    rarityTier,
    speciesId,
    name,
    traits,
    evolutionStage,
    createdAt,
    assetCredit,
    lastEvolutionAt,
  ];
}

class CompanionEntityInclude extends _i1.IncludeObject {
  CompanionEntityInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => CompanionEntity.t;
}

class CompanionEntityIncludeList extends _i1.IncludeList {
  CompanionEntityIncludeList._({
    _i1.WhereExpressionBuilder<CompanionEntityTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CompanionEntity.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => CompanionEntity.t;
}

class CompanionEntityRepository {
  const CompanionEntityRepository._();

  /// Returns a list of [CompanionEntity]s matching the given query parameters.
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
  Future<List<CompanionEntity>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CompanionEntityTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CompanionEntityTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CompanionEntityTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CompanionEntity>(
      where: where?.call(CompanionEntity.t),
      orderBy: orderBy?.call(CompanionEntity.t),
      orderByList: orderByList?.call(CompanionEntity.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [CompanionEntity] matching the given query parameters.
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
  Future<CompanionEntity?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CompanionEntityTable>? where,
    int? offset,
    _i1.OrderByBuilder<CompanionEntityTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<CompanionEntityTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CompanionEntity>(
      where: where?.call(CompanionEntity.t),
      orderBy: orderBy?.call(CompanionEntity.t),
      orderByList: orderByList?.call(CompanionEntity.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CompanionEntity] by its [id] or null if no such row exists.
  Future<CompanionEntity?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CompanionEntity>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CompanionEntity]s in the list and returns the inserted rows.
  ///
  /// The returned [CompanionEntity]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<CompanionEntity>> insert(
    _i1.DatabaseSession session,
    List<CompanionEntity> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<CompanionEntity>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [CompanionEntity] and returns the inserted row.
  ///
  /// The returned [CompanionEntity] will have its `id` field set.
  Future<CompanionEntity> insertRow(
    _i1.DatabaseSession session,
    CompanionEntity row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<CompanionEntity>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [CompanionEntity]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<CompanionEntity>> update(
    _i1.DatabaseSession session,
    List<CompanionEntity> rows, {
    _i1.ColumnSelections<CompanionEntityTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<CompanionEntity>(
      rows,
      columns: columns?.call(CompanionEntity.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CompanionEntity]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CompanionEntity> updateRow(
    _i1.DatabaseSession session,
    CompanionEntity row, {
    _i1.ColumnSelections<CompanionEntityTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<CompanionEntity>(
      row,
      columns: columns?.call(CompanionEntity.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CompanionEntity] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CompanionEntity?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<CompanionEntityUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<CompanionEntity>(
      id,
      columnValues: columnValues(CompanionEntity.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CompanionEntity]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<CompanionEntity>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<CompanionEntityUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<CompanionEntityTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CompanionEntityTable>? orderBy,
    _i1.OrderByListBuilder<CompanionEntityTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<CompanionEntity>(
      columnValues: columnValues(CompanionEntity.t.updateTable),
      where: where(CompanionEntity.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CompanionEntity.t),
      orderByList: orderByList?.call(CompanionEntity.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [CompanionEntity]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<CompanionEntity>> delete(
    _i1.DatabaseSession session,
    List<CompanionEntity> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<CompanionEntity>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [CompanionEntity].
  Future<CompanionEntity> deleteRow(
    _i1.DatabaseSession session,
    CompanionEntity row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CompanionEntity>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<CompanionEntity>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<CompanionEntityTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<CompanionEntity>(
      where: where(CompanionEntity.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CompanionEntityTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<CompanionEntity>(
      where: where?.call(CompanionEntity.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CompanionEntity] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<CompanionEntityTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CompanionEntity>(
      where: where(CompanionEntity.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
