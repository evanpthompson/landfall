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

/// Current weather conditions cached from OpenWeatherMap.
/// A single row is maintained per location — the service upserts on each refresh.
abstract class WeatherCurrent
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WeatherCurrent._({
    this.id,
    required this.locationName,
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.iconCode,
    required this.humidity,
    required this.windSpeedMs,
    required this.fetchedAt,
  });

  factory WeatherCurrent({
    int? id,
    required String locationName,
    required double tempC,
    required double feelsLikeC,
    required String condition,
    required String iconCode,
    required int humidity,
    required double windSpeedMs,
    required DateTime fetchedAt,
  }) = _WeatherCurrentImpl;

  factory WeatherCurrent.fromJson(Map<String, dynamic> jsonSerialization) {
    return WeatherCurrent(
      id: jsonSerialization['id'] as int?,
      locationName: jsonSerialization['locationName'] as String,
      tempC: (jsonSerialization['tempC'] as num).toDouble(),
      feelsLikeC: (jsonSerialization['feelsLikeC'] as num).toDouble(),
      condition: jsonSerialization['condition'] as String,
      iconCode: jsonSerialization['iconCode'] as String,
      humidity: jsonSerialization['humidity'] as int,
      windSpeedMs: (jsonSerialization['windSpeedMs'] as num).toDouble(),
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  static final t = WeatherCurrentTable();

  static const db = WeatherCurrentRepository._();

  @override
  int? id;

  /// Human-readable location name, e.g. "Chicago".
  String locationName;

  /// Current temperature in Celsius.
  double tempC;

  /// "Feels like" temperature in Celsius.
  double feelsLikeC;

  /// Short text description, e.g. "Clear sky".
  String condition;

  /// OpenWeatherMap icon code, e.g. "01d". Used to resolve icon assets.
  String iconCode;

  /// Relative humidity, 0–100.
  int humidity;

  /// Wind speed in m/s.
  double windSpeedMs;

  /// When this row was last fetched from the upstream API.
  DateTime fetchedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WeatherCurrent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WeatherCurrent copyWith({
    int? id,
    String? locationName,
    double? tempC,
    double? feelsLikeC,
    String? condition,
    String? iconCode,
    int? humidity,
    double? windSpeedMs,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WeatherCurrent',
      if (id != null) 'id': id,
      'locationName': locationName,
      'tempC': tempC,
      'feelsLikeC': feelsLikeC,
      'condition': condition,
      'iconCode': iconCode,
      'humidity': humidity,
      'windSpeedMs': windSpeedMs,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WeatherCurrent',
      if (id != null) 'id': id,
      'locationName': locationName,
      'tempC': tempC,
      'feelsLikeC': feelsLikeC,
      'condition': condition,
      'iconCode': iconCode,
      'humidity': humidity,
      'windSpeedMs': windSpeedMs,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  static WeatherCurrentInclude include() {
    return WeatherCurrentInclude._();
  }

  static WeatherCurrentIncludeList includeList({
    _i1.WhereExpressionBuilder<WeatherCurrentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WeatherCurrentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WeatherCurrentTable>? orderByList,
    WeatherCurrentInclude? include,
  }) {
    return WeatherCurrentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WeatherCurrent.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(WeatherCurrent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WeatherCurrentImpl extends WeatherCurrent {
  _WeatherCurrentImpl({
    int? id,
    required String locationName,
    required double tempC,
    required double feelsLikeC,
    required String condition,
    required String iconCode,
    required int humidity,
    required double windSpeedMs,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         locationName: locationName,
         tempC: tempC,
         feelsLikeC: feelsLikeC,
         condition: condition,
         iconCode: iconCode,
         humidity: humidity,
         windSpeedMs: windSpeedMs,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [WeatherCurrent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WeatherCurrent copyWith({
    Object? id = _Undefined,
    String? locationName,
    double? tempC,
    double? feelsLikeC,
    String? condition,
    String? iconCode,
    int? humidity,
    double? windSpeedMs,
    DateTime? fetchedAt,
  }) {
    return WeatherCurrent(
      id: id is int? ? id : this.id,
      locationName: locationName ?? this.locationName,
      tempC: tempC ?? this.tempC,
      feelsLikeC: feelsLikeC ?? this.feelsLikeC,
      condition: condition ?? this.condition,
      iconCode: iconCode ?? this.iconCode,
      humidity: humidity ?? this.humidity,
      windSpeedMs: windSpeedMs ?? this.windSpeedMs,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class WeatherCurrentUpdateTable extends _i1.UpdateTable<WeatherCurrentTable> {
  WeatherCurrentUpdateTable(super.table);

  _i1.ColumnValue<String, String> locationName(String value) => _i1.ColumnValue(
    table.locationName,
    value,
  );

  _i1.ColumnValue<double, double> tempC(double value) => _i1.ColumnValue(
    table.tempC,
    value,
  );

  _i1.ColumnValue<double, double> feelsLikeC(double value) => _i1.ColumnValue(
    table.feelsLikeC,
    value,
  );

  _i1.ColumnValue<String, String> condition(String value) => _i1.ColumnValue(
    table.condition,
    value,
  );

  _i1.ColumnValue<String, String> iconCode(String value) => _i1.ColumnValue(
    table.iconCode,
    value,
  );

  _i1.ColumnValue<int, int> humidity(int value) => _i1.ColumnValue(
    table.humidity,
    value,
  );

  _i1.ColumnValue<double, double> windSpeedMs(double value) => _i1.ColumnValue(
    table.windSpeedMs,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> fetchedAt(DateTime value) =>
      _i1.ColumnValue(
        table.fetchedAt,
        value,
      );
}

class WeatherCurrentTable extends _i1.Table<int?> {
  WeatherCurrentTable({super.tableRelation})
    : super(tableName: 'weather_current') {
    updateTable = WeatherCurrentUpdateTable(this);
    locationName = _i1.ColumnString(
      'locationName',
      this,
    );
    tempC = _i1.ColumnDouble(
      'tempC',
      this,
    );
    feelsLikeC = _i1.ColumnDouble(
      'feelsLikeC',
      this,
    );
    condition = _i1.ColumnString(
      'condition',
      this,
    );
    iconCode = _i1.ColumnString(
      'iconCode',
      this,
    );
    humidity = _i1.ColumnInt(
      'humidity',
      this,
    );
    windSpeedMs = _i1.ColumnDouble(
      'windSpeedMs',
      this,
    );
    fetchedAt = _i1.ColumnDateTime(
      'fetchedAt',
      this,
    );
  }

  late final WeatherCurrentUpdateTable updateTable;

  /// Human-readable location name, e.g. "Chicago".
  late final _i1.ColumnString locationName;

  /// Current temperature in Celsius.
  late final _i1.ColumnDouble tempC;

  /// "Feels like" temperature in Celsius.
  late final _i1.ColumnDouble feelsLikeC;

  /// Short text description, e.g. "Clear sky".
  late final _i1.ColumnString condition;

  /// OpenWeatherMap icon code, e.g. "01d". Used to resolve icon assets.
  late final _i1.ColumnString iconCode;

  /// Relative humidity, 0–100.
  late final _i1.ColumnInt humidity;

  /// Wind speed in m/s.
  late final _i1.ColumnDouble windSpeedMs;

  /// When this row was last fetched from the upstream API.
  late final _i1.ColumnDateTime fetchedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    locationName,
    tempC,
    feelsLikeC,
    condition,
    iconCode,
    humidity,
    windSpeedMs,
    fetchedAt,
  ];
}

class WeatherCurrentInclude extends _i1.IncludeObject {
  WeatherCurrentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WeatherCurrent.t;
}

class WeatherCurrentIncludeList extends _i1.IncludeList {
  WeatherCurrentIncludeList._({
    _i1.WhereExpressionBuilder<WeatherCurrentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WeatherCurrent.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WeatherCurrent.t;
}

class WeatherCurrentRepository {
  const WeatherCurrentRepository._();

  /// Returns a list of [WeatherCurrent]s matching the given query parameters.
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
  Future<List<WeatherCurrent>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WeatherCurrentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WeatherCurrentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WeatherCurrentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WeatherCurrent>(
      where: where?.call(WeatherCurrent.t),
      orderBy: orderBy?.call(WeatherCurrent.t),
      orderByList: orderByList?.call(WeatherCurrent.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WeatherCurrent] matching the given query parameters.
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
  Future<WeatherCurrent?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WeatherCurrentTable>? where,
    int? offset,
    _i1.OrderByBuilder<WeatherCurrentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WeatherCurrentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WeatherCurrent>(
      where: where?.call(WeatherCurrent.t),
      orderBy: orderBy?.call(WeatherCurrent.t),
      orderByList: orderByList?.call(WeatherCurrent.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WeatherCurrent] by its [id] or null if no such row exists.
  Future<WeatherCurrent?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WeatherCurrent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WeatherCurrent]s in the list and returns the inserted rows.
  ///
  /// The returned [WeatherCurrent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<WeatherCurrent>> insert(
    _i1.DatabaseSession session,
    List<WeatherCurrent> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<WeatherCurrent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [WeatherCurrent] and returns the inserted row.
  ///
  /// The returned [WeatherCurrent] will have its `id` field set.
  Future<WeatherCurrent> insertRow(
    _i1.DatabaseSession session,
    WeatherCurrent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WeatherCurrent>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [WeatherCurrent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<WeatherCurrent>> update(
    _i1.DatabaseSession session,
    List<WeatherCurrent> rows, {
    _i1.ColumnSelections<WeatherCurrentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<WeatherCurrent>(
      rows,
      columns: columns?.call(WeatherCurrent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WeatherCurrent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WeatherCurrent> updateRow(
    _i1.DatabaseSession session,
    WeatherCurrent row, {
    _i1.ColumnSelections<WeatherCurrentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WeatherCurrent>(
      row,
      columns: columns?.call(WeatherCurrent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WeatherCurrent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WeatherCurrent?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WeatherCurrentUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WeatherCurrent>(
      id,
      columnValues: columnValues(WeatherCurrent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WeatherCurrent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<WeatherCurrent>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WeatherCurrentUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<WeatherCurrentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WeatherCurrentTable>? orderBy,
    _i1.OrderByListBuilder<WeatherCurrentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<WeatherCurrent>(
      columnValues: columnValues(WeatherCurrent.t.updateTable),
      where: where(WeatherCurrent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WeatherCurrent.t),
      orderByList: orderByList?.call(WeatherCurrent.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [WeatherCurrent]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<WeatherCurrent>> delete(
    _i1.DatabaseSession session,
    List<WeatherCurrent> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<WeatherCurrent>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [WeatherCurrent].
  Future<WeatherCurrent> deleteRow(
    _i1.DatabaseSession session,
    WeatherCurrent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WeatherCurrent>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<WeatherCurrent>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WeatherCurrentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<WeatherCurrent>(
      where: where(WeatherCurrent.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WeatherCurrentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WeatherCurrent>(
      where: where?.call(WeatherCurrent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WeatherCurrent] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WeatherCurrentTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WeatherCurrent>(
      where: where(WeatherCurrent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
