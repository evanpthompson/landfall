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

/// A stored theme — metadata plus the fully-resolved token set as JSON.
/// Built-in themes have isBuiltIn=true and cannot be deleted.
abstract class LandfallTheme
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  LandfallTheme._({
    this.id,
    required this.slug,
    required this.name,
    required this.schemaVersion,
    this.author,
    this.description,
    this.previewUrl,
    String? tagsJson,
    required this.tokensJson,
    required this.resolvedJson,
    bool? isBuiltIn,
    required this.createdAt,
  }) : tagsJson = tagsJson ?? '[]',
       isBuiltIn = isBuiltIn ?? false;

  factory LandfallTheme({
    int? id,
    required String slug,
    required String name,
    required String schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    String? tagsJson,
    required String tokensJson,
    required String resolvedJson,
    bool? isBuiltIn,
    required DateTime createdAt,
  }) = _LandfallThemeImpl;

  factory LandfallTheme.fromJson(Map<String, dynamic> jsonSerialization) {
    return LandfallTheme(
      id: jsonSerialization['id'] as int?,
      slug: jsonSerialization['slug'] as String,
      name: jsonSerialization['name'] as String,
      schemaVersion: jsonSerialization['schemaVersion'] as String,
      author: jsonSerialization['author'] as String?,
      description: jsonSerialization['description'] as String?,
      previewUrl: jsonSerialization['previewUrl'] as String?,
      tagsJson: jsonSerialization['tagsJson'] as String?,
      tokensJson: jsonSerialization['tokensJson'] as String,
      resolvedJson: jsonSerialization['resolvedJson'] as String,
      isBuiltIn: jsonSerialization['isBuiltIn'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isBuiltIn']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = LandfallThemeTable();

  static const db = LandfallThemeRepository._();

  @override
  int? id;

  /// URL-safe slug, e.g. "default-dark" or "neon-arcade". Unique.
  String slug;

  /// User-facing display name.
  String name;

  /// ThemeSchema version the theme was authored against (e.g. "1.0").
  String schemaVersion;

  /// Optional theme author handle or name.
  String? author;

  /// One or two sentence description.
  String? description;

  /// HTTPS URL to a 1920x1080 PNG preview image.
  String? previewUrl;

  /// JSON-encoded List<String> of marketplace tags.
  String tagsJson;

  /// The raw theme YAML/JSON as a normalised JSON string (post-parse, pre-resolve).
  String tokensJson;

  /// The fully resolved flat token map as a JSON string (derived values filled in).
  String resolvedJson;

  /// True for the 5 built-in themes seeded at startup. Cannot be deleted.
  bool isBuiltIn;

  /// When this theme was created.
  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [LandfallTheme]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LandfallTheme copyWith({
    int? id,
    String? slug,
    String? name,
    String? schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    String? tagsJson,
    String? tokensJson,
    String? resolvedJson,
    bool? isBuiltIn,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LandfallTheme',
      if (id != null) 'id': id,
      'slug': slug,
      'name': name,
      'schemaVersion': schemaVersion,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (previewUrl != null) 'previewUrl': previewUrl,
      'tagsJson': tagsJson,
      'tokensJson': tokensJson,
      'resolvedJson': resolvedJson,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LandfallTheme',
      if (id != null) 'id': id,
      'slug': slug,
      'name': name,
      'schemaVersion': schemaVersion,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (previewUrl != null) 'previewUrl': previewUrl,
      'tagsJson': tagsJson,
      'tokensJson': tokensJson,
      'resolvedJson': resolvedJson,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toJson(),
    };
  }

  static LandfallThemeInclude include() {
    return LandfallThemeInclude._();
  }

  static LandfallThemeIncludeList includeList({
    _i1.WhereExpressionBuilder<LandfallThemeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LandfallThemeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LandfallThemeTable>? orderByList,
    LandfallThemeInclude? include,
  }) {
    return LandfallThemeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LandfallTheme.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LandfallTheme.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LandfallThemeImpl extends LandfallTheme {
  _LandfallThemeImpl({
    int? id,
    required String slug,
    required String name,
    required String schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    String? tagsJson,
    required String tokensJson,
    required String resolvedJson,
    bool? isBuiltIn,
    required DateTime createdAt,
  }) : super._(
         id: id,
         slug: slug,
         name: name,
         schemaVersion: schemaVersion,
         author: author,
         description: description,
         previewUrl: previewUrl,
         tagsJson: tagsJson,
         tokensJson: tokensJson,
         resolvedJson: resolvedJson,
         isBuiltIn: isBuiltIn,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LandfallTheme]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LandfallTheme copyWith({
    Object? id = _Undefined,
    String? slug,
    String? name,
    String? schemaVersion,
    Object? author = _Undefined,
    Object? description = _Undefined,
    Object? previewUrl = _Undefined,
    String? tagsJson,
    String? tokensJson,
    String? resolvedJson,
    bool? isBuiltIn,
    DateTime? createdAt,
  }) {
    return LandfallTheme(
      id: id is int? ? id : this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      author: author is String? ? author : this.author,
      description: description is String? ? description : this.description,
      previewUrl: previewUrl is String? ? previewUrl : this.previewUrl,
      tagsJson: tagsJson ?? this.tagsJson,
      tokensJson: tokensJson ?? this.tokensJson,
      resolvedJson: resolvedJson ?? this.resolvedJson,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LandfallThemeUpdateTable extends _i1.UpdateTable<LandfallThemeTable> {
  LandfallThemeUpdateTable(super.table);

  _i1.ColumnValue<String, String> slug(String value) => _i1.ColumnValue(
    table.slug,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> schemaVersion(String value) =>
      _i1.ColumnValue(
        table.schemaVersion,
        value,
      );

  _i1.ColumnValue<String, String> author(String? value) => _i1.ColumnValue(
    table.author,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<String, String> previewUrl(String? value) => _i1.ColumnValue(
    table.previewUrl,
    value,
  );

  _i1.ColumnValue<String, String> tagsJson(String value) => _i1.ColumnValue(
    table.tagsJson,
    value,
  );

  _i1.ColumnValue<String, String> tokensJson(String value) => _i1.ColumnValue(
    table.tokensJson,
    value,
  );

  _i1.ColumnValue<String, String> resolvedJson(String value) => _i1.ColumnValue(
    table.resolvedJson,
    value,
  );

  _i1.ColumnValue<bool, bool> isBuiltIn(bool value) => _i1.ColumnValue(
    table.isBuiltIn,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class LandfallThemeTable extends _i1.Table<int?> {
  LandfallThemeTable({super.tableRelation}) : super(tableName: 'themes') {
    updateTable = LandfallThemeUpdateTable(this);
    slug = _i1.ColumnString(
      'slug',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    schemaVersion = _i1.ColumnString(
      'schemaVersion',
      this,
    );
    author = _i1.ColumnString(
      'author',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    previewUrl = _i1.ColumnString(
      'previewUrl',
      this,
    );
    tagsJson = _i1.ColumnString(
      'tagsJson',
      this,
      hasDefault: true,
    );
    tokensJson = _i1.ColumnString(
      'tokensJson',
      this,
    );
    resolvedJson = _i1.ColumnString(
      'resolvedJson',
      this,
    );
    isBuiltIn = _i1.ColumnBool(
      'isBuiltIn',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final LandfallThemeUpdateTable updateTable;

  /// URL-safe slug, e.g. "default-dark" or "neon-arcade". Unique.
  late final _i1.ColumnString slug;

  /// User-facing display name.
  late final _i1.ColumnString name;

  /// ThemeSchema version the theme was authored against (e.g. "1.0").
  late final _i1.ColumnString schemaVersion;

  /// Optional theme author handle or name.
  late final _i1.ColumnString author;

  /// One or two sentence description.
  late final _i1.ColumnString description;

  /// HTTPS URL to a 1920x1080 PNG preview image.
  late final _i1.ColumnString previewUrl;

  /// JSON-encoded List<String> of marketplace tags.
  late final _i1.ColumnString tagsJson;

  /// The raw theme YAML/JSON as a normalised JSON string (post-parse, pre-resolve).
  late final _i1.ColumnString tokensJson;

  /// The fully resolved flat token map as a JSON string (derived values filled in).
  late final _i1.ColumnString resolvedJson;

  /// True for the 5 built-in themes seeded at startup. Cannot be deleted.
  late final _i1.ColumnBool isBuiltIn;

  /// When this theme was created.
  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    slug,
    name,
    schemaVersion,
    author,
    description,
    previewUrl,
    tagsJson,
    tokensJson,
    resolvedJson,
    isBuiltIn,
    createdAt,
  ];
}

class LandfallThemeInclude extends _i1.IncludeObject {
  LandfallThemeInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => LandfallTheme.t;
}

class LandfallThemeIncludeList extends _i1.IncludeList {
  LandfallThemeIncludeList._({
    _i1.WhereExpressionBuilder<LandfallThemeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LandfallTheme.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => LandfallTheme.t;
}

class LandfallThemeRepository {
  const LandfallThemeRepository._();

  /// Returns a list of [LandfallTheme]s matching the given query parameters.
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
  Future<List<LandfallTheme>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LandfallThemeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LandfallThemeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LandfallThemeTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LandfallTheme>(
      where: where?.call(LandfallTheme.t),
      orderBy: orderBy?.call(LandfallTheme.t),
      orderByList: orderByList?.call(LandfallTheme.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LandfallTheme] matching the given query parameters.
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
  Future<LandfallTheme?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LandfallThemeTable>? where,
    int? offset,
    _i1.OrderByBuilder<LandfallThemeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LandfallThemeTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LandfallTheme>(
      where: where?.call(LandfallTheme.t),
      orderBy: orderBy?.call(LandfallTheme.t),
      orderByList: orderByList?.call(LandfallTheme.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LandfallTheme] by its [id] or null if no such row exists.
  Future<LandfallTheme?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LandfallTheme>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LandfallTheme]s in the list and returns the inserted rows.
  ///
  /// The returned [LandfallTheme]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<LandfallTheme>> insert(
    _i1.DatabaseSession session,
    List<LandfallTheme> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<LandfallTheme>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [LandfallTheme] and returns the inserted row.
  ///
  /// The returned [LandfallTheme] will have its `id` field set.
  Future<LandfallTheme> insertRow(
    _i1.DatabaseSession session,
    LandfallTheme row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LandfallTheme>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LandfallTheme]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LandfallTheme>> update(
    _i1.DatabaseSession session,
    List<LandfallTheme> rows, {
    _i1.ColumnSelections<LandfallThemeTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LandfallTheme>(
      rows,
      columns: columns?.call(LandfallTheme.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LandfallTheme]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LandfallTheme> updateRow(
    _i1.DatabaseSession session,
    LandfallTheme row, {
    _i1.ColumnSelections<LandfallThemeTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LandfallTheme>(
      row,
      columns: columns?.call(LandfallTheme.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LandfallTheme] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LandfallTheme?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<LandfallThemeUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<LandfallTheme>(
      id,
      columnValues: columnValues(LandfallTheme.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LandfallTheme]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<LandfallTheme>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<LandfallThemeUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<LandfallThemeTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LandfallThemeTable>? orderBy,
    _i1.OrderByListBuilder<LandfallThemeTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<LandfallTheme>(
      columnValues: columnValues(LandfallTheme.t.updateTable),
      where: where(LandfallTheme.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LandfallTheme.t),
      orderByList: orderByList?.call(LandfallTheme.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [LandfallTheme]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LandfallTheme>> delete(
    _i1.DatabaseSession session,
    List<LandfallTheme> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LandfallTheme>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LandfallTheme].
  Future<LandfallTheme> deleteRow(
    _i1.DatabaseSession session,
    LandfallTheme row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LandfallTheme>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LandfallTheme>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LandfallThemeTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LandfallTheme>(
      where: where(LandfallTheme.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LandfallThemeTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LandfallTheme>(
      where: where?.call(LandfallTheme.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LandfallTheme] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LandfallThemeTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LandfallTheme>(
      where: where(LandfallTheme.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
