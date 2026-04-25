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

/// A photo entry synced from an external provider (e.g. Google Drive).
///
/// Each row represents one image file available for the photo frame slideshow.
/// Photo bytes are not stored here — they are fetched on demand via the
/// provider service and proxied through the photo serve route.
abstract class Photo implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Photo._({
    this.id,
    required this.credentialId,
    required this.providerFileId,
    required this.filename,
    required this.mimeType,
    required this.fetchedAt,
  });

  factory Photo({
    int? id,
    required int credentialId,
    required String providerFileId,
    required String filename,
    required String mimeType,
    required DateTime fetchedAt,
  }) = _PhotoImpl;

  factory Photo.fromJson(Map<String, dynamic> jsonSerialization) {
    return Photo(
      id: jsonSerialization['id'] as int?,
      credentialId: jsonSerialization['credentialId'] as int,
      providerFileId: jsonSerialization['providerFileId'] as String,
      filename: jsonSerialization['filename'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  static final t = PhotoTable();

  static const db = PhotoRepository._();

  @override
  int? id;

  /// The LinkedCredential used to access this photo.
  int credentialId;

  /// Provider-assigned file identifier. Opaque to the client — used server-side
  /// when proxying image bytes from the upstream provider.
  String providerFileId;

  /// Original filename, e.g. "IMG_1234.jpg".
  String filename;

  /// MIME type, e.g. "image/jpeg", "image/png".
  String mimeType;

  /// When this photo entry was last synced from the upstream provider.
  DateTime fetchedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Photo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Photo copyWith({
    int? id,
    int? credentialId,
    String? providerFileId,
    String? filename,
    String? mimeType,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Photo',
      if (id != null) 'id': id,
      'credentialId': credentialId,
      'providerFileId': providerFileId,
      'filename': filename,
      'mimeType': mimeType,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Photo',
      if (id != null) 'id': id,
      'credentialId': credentialId,
      'providerFileId': providerFileId,
      'filename': filename,
      'mimeType': mimeType,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  static PhotoInclude include() {
    return PhotoInclude._();
  }

  static PhotoIncludeList includeList({
    _i1.WhereExpressionBuilder<PhotoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PhotoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PhotoTable>? orderByList,
    PhotoInclude? include,
  }) {
    return PhotoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Photo.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Photo.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PhotoImpl extends Photo {
  _PhotoImpl({
    int? id,
    required int credentialId,
    required String providerFileId,
    required String filename,
    required String mimeType,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         credentialId: credentialId,
         providerFileId: providerFileId,
         filename: filename,
         mimeType: mimeType,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [Photo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Photo copyWith({
    Object? id = _Undefined,
    int? credentialId,
    String? providerFileId,
    String? filename,
    String? mimeType,
    DateTime? fetchedAt,
  }) {
    return Photo(
      id: id is int? ? id : this.id,
      credentialId: credentialId ?? this.credentialId,
      providerFileId: providerFileId ?? this.providerFileId,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class PhotoUpdateTable extends _i1.UpdateTable<PhotoTable> {
  PhotoUpdateTable(super.table);

  _i1.ColumnValue<int, int> credentialId(int value) => _i1.ColumnValue(
    table.credentialId,
    value,
  );

  _i1.ColumnValue<String, String> providerFileId(String value) =>
      _i1.ColumnValue(
        table.providerFileId,
        value,
      );

  _i1.ColumnValue<String, String> filename(String value) => _i1.ColumnValue(
    table.filename,
    value,
  );

  _i1.ColumnValue<String, String> mimeType(String value) => _i1.ColumnValue(
    table.mimeType,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> fetchedAt(DateTime value) =>
      _i1.ColumnValue(
        table.fetchedAt,
        value,
      );
}

class PhotoTable extends _i1.Table<int?> {
  PhotoTable({super.tableRelation}) : super(tableName: 'photos') {
    updateTable = PhotoUpdateTable(this);
    credentialId = _i1.ColumnInt(
      'credentialId',
      this,
    );
    providerFileId = _i1.ColumnString(
      'providerFileId',
      this,
    );
    filename = _i1.ColumnString(
      'filename',
      this,
    );
    mimeType = _i1.ColumnString(
      'mimeType',
      this,
    );
    fetchedAt = _i1.ColumnDateTime(
      'fetchedAt',
      this,
    );
  }

  late final PhotoUpdateTable updateTable;

  /// The LinkedCredential used to access this photo.
  late final _i1.ColumnInt credentialId;

  /// Provider-assigned file identifier. Opaque to the client — used server-side
  /// when proxying image bytes from the upstream provider.
  late final _i1.ColumnString providerFileId;

  /// Original filename, e.g. "IMG_1234.jpg".
  late final _i1.ColumnString filename;

  /// MIME type, e.g. "image/jpeg", "image/png".
  late final _i1.ColumnString mimeType;

  /// When this photo entry was last synced from the upstream provider.
  late final _i1.ColumnDateTime fetchedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    credentialId,
    providerFileId,
    filename,
    mimeType,
    fetchedAt,
  ];
}

class PhotoInclude extends _i1.IncludeObject {
  PhotoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Photo.t;
}

class PhotoIncludeList extends _i1.IncludeList {
  PhotoIncludeList._({
    _i1.WhereExpressionBuilder<PhotoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Photo.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Photo.t;
}

class PhotoRepository {
  const PhotoRepository._();

  /// Returns a list of [Photo]s matching the given query parameters.
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
  Future<List<Photo>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PhotoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PhotoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PhotoTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Photo>(
      where: where?.call(Photo.t),
      orderBy: orderBy?.call(Photo.t),
      orderByList: orderByList?.call(Photo.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Photo] matching the given query parameters.
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
  Future<Photo?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PhotoTable>? where,
    int? offset,
    _i1.OrderByBuilder<PhotoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PhotoTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Photo>(
      where: where?.call(Photo.t),
      orderBy: orderBy?.call(Photo.t),
      orderByList: orderByList?.call(Photo.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Photo] by its [id] or null if no such row exists.
  Future<Photo?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Photo>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Photo]s in the list and returns the inserted rows.
  ///
  /// The returned [Photo]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Photo>> insert(
    _i1.DatabaseSession session,
    List<Photo> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Photo>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Photo] and returns the inserted row.
  ///
  /// The returned [Photo] will have its `id` field set.
  Future<Photo> insertRow(
    _i1.DatabaseSession session,
    Photo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Photo>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Photo]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Photo>> update(
    _i1.DatabaseSession session,
    List<Photo> rows, {
    _i1.ColumnSelections<PhotoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Photo>(
      rows,
      columns: columns?.call(Photo.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Photo]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Photo> updateRow(
    _i1.DatabaseSession session,
    Photo row, {
    _i1.ColumnSelections<PhotoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Photo>(
      row,
      columns: columns?.call(Photo.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Photo] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Photo?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<PhotoUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Photo>(
      id,
      columnValues: columnValues(Photo.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Photo]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Photo>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<PhotoUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<PhotoTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PhotoTable>? orderBy,
    _i1.OrderByListBuilder<PhotoTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Photo>(
      columnValues: columnValues(Photo.t.updateTable),
      where: where(Photo.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Photo.t),
      orderByList: orderByList?.call(Photo.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Photo]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Photo>> delete(
    _i1.DatabaseSession session,
    List<Photo> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Photo>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Photo].
  Future<Photo> deleteRow(
    _i1.DatabaseSession session,
    Photo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Photo>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Photo>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PhotoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Photo>(
      where: where(Photo.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PhotoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Photo>(
      where: where?.call(Photo.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Photo] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PhotoTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Photo>(
      where: where(Photo.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
