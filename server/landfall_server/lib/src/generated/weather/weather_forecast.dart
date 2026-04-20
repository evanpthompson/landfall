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

/// One row per forecast day cached from OpenWeatherMap.
/// Five rows (today+4) are replaced wholesale on each refresh.
abstract class WeatherForecast
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WeatherForecast._({
    this.id,
    required this.locationName,
    required this.forecastDate,
    required this.minTempC,
    required this.maxTempC,
    required this.condition,
    required this.iconCode,
    required this.fetchedAt,
  });

  factory WeatherForecast({
    int? id,
    required String locationName,
    required DateTime forecastDate,
    required double minTempC,
    required double maxTempC,
    required String condition,
    required String iconCode,
    required DateTime fetchedAt,
  }) = _WeatherForecastImpl;

  factory WeatherForecast.fromJson(Map<String, dynamic> jsonSerialization) {
    return WeatherForecast(
      id: jsonSerialization['id'] as int?,
      locationName: jsonSerialization['locationName'] as String,
      forecastDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['forecastDate'],
      ),
      minTempC: (jsonSerialization['minTempC'] as num).toDouble(),
      maxTempC: (jsonSerialization['maxTempC'] as num).toDouble(),
      condition: jsonSerialization['condition'] as String,
      iconCode: jsonSerialization['iconCode'] as String,
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  static final t = WeatherForecastTable();

  static const db = WeatherForecastRepository._();

  @override
  int? id;

  /// Location this forecast belongs to.
  String locationName;

  /// Midnight UTC for the forecast date.
  DateTime forecastDate;

  /// Low temperature in Celsius.
  double minTempC;

  /// High temperature in Celsius.
  double maxTempC;

  /// Short text description, e.g. "Light rain".
  String condition;

  /// OpenWeatherMap icon code for the representative period of the day.
  String iconCode;

  /// When this row was last fetched from the upstream API.
  DateTime fetchedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WeatherForecast]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WeatherForecast copyWith({
    int? id,
    String? locationName,
    DateTime? forecastDate,
    double? minTempC,
    double? maxTempC,
    String? condition,
    String? iconCode,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WeatherForecast',
      if (id != null) 'id': id,
      'locationName': locationName,
      'forecastDate': forecastDate.toJson(),
      'minTempC': minTempC,
      'maxTempC': maxTempC,
      'condition': condition,
      'iconCode': iconCode,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WeatherForecast',
      if (id != null) 'id': id,
      'locationName': locationName,
      'forecastDate': forecastDate.toJson(),
      'minTempC': minTempC,
      'maxTempC': maxTempC,
      'condition': condition,
      'iconCode': iconCode,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  static WeatherForecastInclude include() {
    return WeatherForecastInclude._();
  }

  static WeatherForecastIncludeList includeList({
    _i1.WhereExpressionBuilder<WeatherForecastTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WeatherForecastTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WeatherForecastTable>? orderByList,
    WeatherForecastInclude? include,
  }) {
    return WeatherForecastIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WeatherForecast.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(WeatherForecast.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WeatherForecastImpl extends WeatherForecast {
  _WeatherForecastImpl({
    int? id,
    required String locationName,
    required DateTime forecastDate,
    required double minTempC,
    required double maxTempC,
    required String condition,
    required String iconCode,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         locationName: locationName,
         forecastDate: forecastDate,
         minTempC: minTempC,
         maxTempC: maxTempC,
         condition: condition,
         iconCode: iconCode,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [WeatherForecast]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WeatherForecast copyWith({
    Object? id = _Undefined,
    String? locationName,
    DateTime? forecastDate,
    double? minTempC,
    double? maxTempC,
    String? condition,
    String? iconCode,
    DateTime? fetchedAt,
  }) {
    return WeatherForecast(
      id: id is int? ? id : this.id,
      locationName: locationName ?? this.locationName,
      forecastDate: forecastDate ?? this.forecastDate,
      minTempC: minTempC ?? this.minTempC,
      maxTempC: maxTempC ?? this.maxTempC,
      condition: condition ?? this.condition,
      iconCode: iconCode ?? this.iconCode,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class WeatherForecastUpdateTable extends _i1.UpdateTable<WeatherForecastTable> {
  WeatherForecastUpdateTable(super.table);

  _i1.ColumnValue<String, String> locationName(String value) => _i1.ColumnValue(
    table.locationName,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> forecastDate(DateTime value) =>
      _i1.ColumnValue(
        table.forecastDate,
        value,
      );

  _i1.ColumnValue<double, double> minTempC(double value) => _i1.ColumnValue(
    table.minTempC,
    value,
  );

  _i1.ColumnValue<double, double> maxTempC(double value) => _i1.ColumnValue(
    table.maxTempC,
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

  _i1.ColumnValue<DateTime, DateTime> fetchedAt(DateTime value) =>
      _i1.ColumnValue(
        table.fetchedAt,
        value,
      );
}

class WeatherForecastTable extends _i1.Table<int?> {
  WeatherForecastTable({super.tableRelation})
    : super(tableName: 'weather_forecasts') {
    updateTable = WeatherForecastUpdateTable(this);
    locationName = _i1.ColumnString(
      'locationName',
      this,
    );
    forecastDate = _i1.ColumnDateTime(
      'forecastDate',
      this,
    );
    minTempC = _i1.ColumnDouble(
      'minTempC',
      this,
    );
    maxTempC = _i1.ColumnDouble(
      'maxTempC',
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
    fetchedAt = _i1.ColumnDateTime(
      'fetchedAt',
      this,
    );
  }

  late final WeatherForecastUpdateTable updateTable;

  /// Location this forecast belongs to.
  late final _i1.ColumnString locationName;

  /// Midnight UTC for the forecast date.
  late final _i1.ColumnDateTime forecastDate;

  /// Low temperature in Celsius.
  late final _i1.ColumnDouble minTempC;

  /// High temperature in Celsius.
  late final _i1.ColumnDouble maxTempC;

  /// Short text description, e.g. "Light rain".
  late final _i1.ColumnString condition;

  /// OpenWeatherMap icon code for the representative period of the day.
  late final _i1.ColumnString iconCode;

  /// When this row was last fetched from the upstream API.
  late final _i1.ColumnDateTime fetchedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    locationName,
    forecastDate,
    minTempC,
    maxTempC,
    condition,
    iconCode,
    fetchedAt,
  ];
}

class WeatherForecastInclude extends _i1.IncludeObject {
  WeatherForecastInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WeatherForecast.t;
}

class WeatherForecastIncludeList extends _i1.IncludeList {
  WeatherForecastIncludeList._({
    _i1.WhereExpressionBuilder<WeatherForecastTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WeatherForecast.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WeatherForecast.t;
}

class WeatherForecastRepository {
  const WeatherForecastRepository._();

  /// Returns a list of [WeatherForecast]s matching the given query parameters.
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
  Future<List<WeatherForecast>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WeatherForecastTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WeatherForecastTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WeatherForecastTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WeatherForecast>(
      where: where?.call(WeatherForecast.t),
      orderBy: orderBy?.call(WeatherForecast.t),
      orderByList: orderByList?.call(WeatherForecast.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WeatherForecast] matching the given query parameters.
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
  Future<WeatherForecast?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WeatherForecastTable>? where,
    int? offset,
    _i1.OrderByBuilder<WeatherForecastTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WeatherForecastTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WeatherForecast>(
      where: where?.call(WeatherForecast.t),
      orderBy: orderBy?.call(WeatherForecast.t),
      orderByList: orderByList?.call(WeatherForecast.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WeatherForecast] by its [id] or null if no such row exists.
  Future<WeatherForecast?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WeatherForecast>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WeatherForecast]s in the list and returns the inserted rows.
  ///
  /// The returned [WeatherForecast]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<WeatherForecast>> insert(
    _i1.DatabaseSession session,
    List<WeatherForecast> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<WeatherForecast>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [WeatherForecast] and returns the inserted row.
  ///
  /// The returned [WeatherForecast] will have its `id` field set.
  Future<WeatherForecast> insertRow(
    _i1.DatabaseSession session,
    WeatherForecast row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WeatherForecast>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [WeatherForecast]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<WeatherForecast>> update(
    _i1.DatabaseSession session,
    List<WeatherForecast> rows, {
    _i1.ColumnSelections<WeatherForecastTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<WeatherForecast>(
      rows,
      columns: columns?.call(WeatherForecast.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WeatherForecast]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WeatherForecast> updateRow(
    _i1.DatabaseSession session,
    WeatherForecast row, {
    _i1.ColumnSelections<WeatherForecastTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WeatherForecast>(
      row,
      columns: columns?.call(WeatherForecast.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WeatherForecast] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WeatherForecast?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WeatherForecastUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WeatherForecast>(
      id,
      columnValues: columnValues(WeatherForecast.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WeatherForecast]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<WeatherForecast>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WeatherForecastUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<WeatherForecastTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WeatherForecastTable>? orderBy,
    _i1.OrderByListBuilder<WeatherForecastTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<WeatherForecast>(
      columnValues: columnValues(WeatherForecast.t.updateTable),
      where: where(WeatherForecast.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WeatherForecast.t),
      orderByList: orderByList?.call(WeatherForecast.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [WeatherForecast]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<WeatherForecast>> delete(
    _i1.DatabaseSession session,
    List<WeatherForecast> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<WeatherForecast>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [WeatherForecast].
  Future<WeatherForecast> deleteRow(
    _i1.DatabaseSession session,
    WeatherForecast row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WeatherForecast>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<WeatherForecast>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WeatherForecastTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<WeatherForecast>(
      where: where(WeatherForecast.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WeatherForecastTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WeatherForecast>(
      where: where?.call(WeatherForecast.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WeatherForecast] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WeatherForecastTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WeatherForecast>(
      where: where(WeatherForecast.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
