// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LayoutEntriesTable extends LayoutEntries
    with TableInfo<$LayoutEntriesTable, LayoutEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LayoutEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _columnsCountMeta = const VerificationMeta(
    'columnsCount',
  );
  @override
  late final GeneratedColumn<int> columnsCount = GeneratedColumn<int>(
    'columns_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowsCountMeta = const VerificationMeta(
    'rowsCount',
  );
  @override
  late final GeneratedColumn<int> rowsCount = GeneratedColumn<int>(
    'rows_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardsJsonMeta = const VerificationMeta(
    'cardsJson',
  );
  @override
  late final GeneratedColumn<String> cardsJson = GeneratedColumn<String>(
    'cards_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    columnsCount,
    rowsCount,
    cardsJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'layout_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LayoutEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('columns_count')) {
      context.handle(
        _columnsCountMeta,
        columnsCount.isAcceptableOrUnknown(
          data['columns_count']!,
          _columnsCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_columnsCountMeta);
    }
    if (data.containsKey('rows_count')) {
      context.handle(
        _rowsCountMeta,
        rowsCount.isAcceptableOrUnknown(data['rows_count']!, _rowsCountMeta),
      );
    } else if (isInserting) {
      context.missing(_rowsCountMeta);
    }
    if (data.containsKey('cards_json')) {
      context.handle(
        _cardsJsonMeta,
        cardsJson.isAcceptableOrUnknown(data['cards_json']!, _cardsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_cardsJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LayoutEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LayoutEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      columnsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}columns_count'],
      )!,
      rowsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rows_count'],
      )!,
      cardsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cards_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LayoutEntriesTable createAlias(String alias) {
    return $LayoutEntriesTable(attachedDatabase, alias);
  }
}

class LayoutEntry extends DataClass implements Insertable<LayoutEntry> {
  final int id;
  final String name;
  final int columnsCount;
  final int rowsCount;

  /// JSON-encoded `List<CardConfig>`.
  final String cardsJson;
  final DateTime updatedAt;
  const LayoutEntry({
    required this.id,
    required this.name,
    required this.columnsCount,
    required this.rowsCount,
    required this.cardsJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['columns_count'] = Variable<int>(columnsCount);
    map['rows_count'] = Variable<int>(rowsCount);
    map['cards_json'] = Variable<String>(cardsJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LayoutEntriesCompanion toCompanion(bool nullToAbsent) {
    return LayoutEntriesCompanion(
      id: Value(id),
      name: Value(name),
      columnsCount: Value(columnsCount),
      rowsCount: Value(rowsCount),
      cardsJson: Value(cardsJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory LayoutEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LayoutEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      columnsCount: serializer.fromJson<int>(json['columnsCount']),
      rowsCount: serializer.fromJson<int>(json['rowsCount']),
      cardsJson: serializer.fromJson<String>(json['cardsJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'columnsCount': serializer.toJson<int>(columnsCount),
      'rowsCount': serializer.toJson<int>(rowsCount),
      'cardsJson': serializer.toJson<String>(cardsJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LayoutEntry copyWith({
    int? id,
    String? name,
    int? columnsCount,
    int? rowsCount,
    String? cardsJson,
    DateTime? updatedAt,
  }) => LayoutEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    columnsCount: columnsCount ?? this.columnsCount,
    rowsCount: rowsCount ?? this.rowsCount,
    cardsJson: cardsJson ?? this.cardsJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LayoutEntry copyWithCompanion(LayoutEntriesCompanion data) {
    return LayoutEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      columnsCount: data.columnsCount.present
          ? data.columnsCount.value
          : this.columnsCount,
      rowsCount: data.rowsCount.present ? data.rowsCount.value : this.rowsCount,
      cardsJson: data.cardsJson.present ? data.cardsJson.value : this.cardsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LayoutEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('columnsCount: $columnsCount, ')
          ..write('rowsCount: $rowsCount, ')
          ..write('cardsJson: $cardsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, columnsCount, rowsCount, cardsJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LayoutEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.columnsCount == this.columnsCount &&
          other.rowsCount == this.rowsCount &&
          other.cardsJson == this.cardsJson &&
          other.updatedAt == this.updatedAt);
}

class LayoutEntriesCompanion extends UpdateCompanion<LayoutEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> columnsCount;
  final Value<int> rowsCount;
  final Value<String> cardsJson;
  final Value<DateTime> updatedAt;
  const LayoutEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.columnsCount = const Value.absent(),
    this.rowsCount = const Value.absent(),
    this.cardsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LayoutEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int columnsCount,
    required int rowsCount,
    required String cardsJson,
    required DateTime updatedAt,
  }) : name = Value(name),
       columnsCount = Value(columnsCount),
       rowsCount = Value(rowsCount),
       cardsJson = Value(cardsJson),
       updatedAt = Value(updatedAt);
  static Insertable<LayoutEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? columnsCount,
    Expression<int>? rowsCount,
    Expression<String>? cardsJson,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (columnsCount != null) 'columns_count': columnsCount,
      if (rowsCount != null) 'rows_count': rowsCount,
      if (cardsJson != null) 'cards_json': cardsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LayoutEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? columnsCount,
    Value<int>? rowsCount,
    Value<String>? cardsJson,
    Value<DateTime>? updatedAt,
  }) {
    return LayoutEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      columnsCount: columnsCount ?? this.columnsCount,
      rowsCount: rowsCount ?? this.rowsCount,
      cardsJson: cardsJson ?? this.cardsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (columnsCount.present) {
      map['columns_count'] = Variable<int>(columnsCount.value);
    }
    if (rowsCount.present) {
      map['rows_count'] = Variable<int>(rowsCount.value);
    }
    if (cardsJson.present) {
      map['cards_json'] = Variable<String>(cardsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LayoutEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('columnsCount: $columnsCount, ')
          ..write('rowsCount: $rowsCount, ')
          ..write('cardsJson: $cardsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WeatherCurrentCacheEntriesTable extends WeatherCurrentCacheEntries
    with TableInfo<$WeatherCurrentCacheEntriesTable, WeatherCurrentCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherCurrentCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempCMeta = const VerificationMeta('tempC');
  @override
  late final GeneratedColumn<double> tempC = GeneratedColumn<double>(
    'temp_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feelsLikeCMeta = const VerificationMeta(
    'feelsLikeC',
  );
  @override
  late final GeneratedColumn<double> feelsLikeC = GeneratedColumn<double>(
    'feels_like_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<String> iconCode = GeneratedColumn<String>(
    'icon_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _humidityMeta = const VerificationMeta(
    'humidity',
  );
  @override
  late final GeneratedColumn<int> humidity = GeneratedColumn<int>(
    'humidity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windSpeedMsMeta = const VerificationMeta(
    'windSpeedMs',
  );
  @override
  late final GeneratedColumn<double> windSpeedMs = GeneratedColumn<double>(
    'wind_speed_ms',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
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
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_current_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherCurrentCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationNameMeta);
    }
    if (data.containsKey('temp_c')) {
      context.handle(
        _tempCMeta,
        tempC.isAcceptableOrUnknown(data['temp_c']!, _tempCMeta),
      );
    } else if (isInserting) {
      context.missing(_tempCMeta);
    }
    if (data.containsKey('feels_like_c')) {
      context.handle(
        _feelsLikeCMeta,
        feelsLikeC.isAcceptableOrUnknown(
          data['feels_like_c']!,
          _feelsLikeCMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_feelsLikeCMeta);
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    } else if (isInserting) {
      context.missing(_conditionMeta);
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_iconCodeMeta);
    }
    if (data.containsKey('humidity')) {
      context.handle(
        _humidityMeta,
        humidity.isAcceptableOrUnknown(data['humidity']!, _humidityMeta),
      );
    } else if (isInserting) {
      context.missing(_humidityMeta);
    }
    if (data.containsKey('wind_speed_ms')) {
      context.handle(
        _windSpeedMsMeta,
        windSpeedMs.isAcceptableOrUnknown(
          data['wind_speed_ms']!,
          _windSpeedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_windSpeedMsMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeatherCurrentCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherCurrentCacheEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      )!,
      tempC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temp_c'],
      )!,
      feelsLikeC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}feels_like_c'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      )!,
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_code'],
      )!,
      humidity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}humidity'],
      )!,
      windSpeedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}wind_speed_ms'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $WeatherCurrentCacheEntriesTable createAlias(String alias) {
    return $WeatherCurrentCacheEntriesTable(attachedDatabase, alias);
  }
}

class WeatherCurrentCacheEntry extends DataClass
    implements Insertable<WeatherCurrentCacheEntry> {
  final int id;
  final String locationName;
  final double tempC;
  final double feelsLikeC;
  final String condition;
  final String iconCode;
  final int humidity;
  final double windSpeedMs;
  final DateTime fetchedAt;
  const WeatherCurrentCacheEntry({
    required this.id,
    required this.locationName,
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.iconCode,
    required this.humidity,
    required this.windSpeedMs,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['location_name'] = Variable<String>(locationName);
    map['temp_c'] = Variable<double>(tempC);
    map['feels_like_c'] = Variable<double>(feelsLikeC);
    map['condition'] = Variable<String>(condition);
    map['icon_code'] = Variable<String>(iconCode);
    map['humidity'] = Variable<int>(humidity);
    map['wind_speed_ms'] = Variable<double>(windSpeedMs);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  WeatherCurrentCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeatherCurrentCacheEntriesCompanion(
      id: Value(id),
      locationName: Value(locationName),
      tempC: Value(tempC),
      feelsLikeC: Value(feelsLikeC),
      condition: Value(condition),
      iconCode: Value(iconCode),
      humidity: Value(humidity),
      windSpeedMs: Value(windSpeedMs),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory WeatherCurrentCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherCurrentCacheEntry(
      id: serializer.fromJson<int>(json['id']),
      locationName: serializer.fromJson<String>(json['locationName']),
      tempC: serializer.fromJson<double>(json['tempC']),
      feelsLikeC: serializer.fromJson<double>(json['feelsLikeC']),
      condition: serializer.fromJson<String>(json['condition']),
      iconCode: serializer.fromJson<String>(json['iconCode']),
      humidity: serializer.fromJson<int>(json['humidity']),
      windSpeedMs: serializer.fromJson<double>(json['windSpeedMs']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'locationName': serializer.toJson<String>(locationName),
      'tempC': serializer.toJson<double>(tempC),
      'feelsLikeC': serializer.toJson<double>(feelsLikeC),
      'condition': serializer.toJson<String>(condition),
      'iconCode': serializer.toJson<String>(iconCode),
      'humidity': serializer.toJson<int>(humidity),
      'windSpeedMs': serializer.toJson<double>(windSpeedMs),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  WeatherCurrentCacheEntry copyWith({
    int? id,
    String? locationName,
    double? tempC,
    double? feelsLikeC,
    String? condition,
    String? iconCode,
    int? humidity,
    double? windSpeedMs,
    DateTime? fetchedAt,
  }) => WeatherCurrentCacheEntry(
    id: id ?? this.id,
    locationName: locationName ?? this.locationName,
    tempC: tempC ?? this.tempC,
    feelsLikeC: feelsLikeC ?? this.feelsLikeC,
    condition: condition ?? this.condition,
    iconCode: iconCode ?? this.iconCode,
    humidity: humidity ?? this.humidity,
    windSpeedMs: windSpeedMs ?? this.windSpeedMs,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  WeatherCurrentCacheEntry copyWithCompanion(
    WeatherCurrentCacheEntriesCompanion data,
  ) {
    return WeatherCurrentCacheEntry(
      id: data.id.present ? data.id.value : this.id,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      tempC: data.tempC.present ? data.tempC.value : this.tempC,
      feelsLikeC: data.feelsLikeC.present
          ? data.feelsLikeC.value
          : this.feelsLikeC,
      condition: data.condition.present ? data.condition.value : this.condition,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      humidity: data.humidity.present ? data.humidity.value : this.humidity,
      windSpeedMs: data.windSpeedMs.present
          ? data.windSpeedMs.value
          : this.windSpeedMs,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCurrentCacheEntry(')
          ..write('id: $id, ')
          ..write('locationName: $locationName, ')
          ..write('tempC: $tempC, ')
          ..write('feelsLikeC: $feelsLikeC, ')
          ..write('condition: $condition, ')
          ..write('iconCode: $iconCode, ')
          ..write('humidity: $humidity, ')
          ..write('windSpeedMs: $windSpeedMs, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    locationName,
    tempC,
    feelsLikeC,
    condition,
    iconCode,
    humidity,
    windSpeedMs,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherCurrentCacheEntry &&
          other.id == this.id &&
          other.locationName == this.locationName &&
          other.tempC == this.tempC &&
          other.feelsLikeC == this.feelsLikeC &&
          other.condition == this.condition &&
          other.iconCode == this.iconCode &&
          other.humidity == this.humidity &&
          other.windSpeedMs == this.windSpeedMs &&
          other.fetchedAt == this.fetchedAt);
}

class WeatherCurrentCacheEntriesCompanion
    extends UpdateCompanion<WeatherCurrentCacheEntry> {
  final Value<int> id;
  final Value<String> locationName;
  final Value<double> tempC;
  final Value<double> feelsLikeC;
  final Value<String> condition;
  final Value<String> iconCode;
  final Value<int> humidity;
  final Value<double> windSpeedMs;
  final Value<DateTime> fetchedAt;
  const WeatherCurrentCacheEntriesCompanion({
    this.id = const Value.absent(),
    this.locationName = const Value.absent(),
    this.tempC = const Value.absent(),
    this.feelsLikeC = const Value.absent(),
    this.condition = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.humidity = const Value.absent(),
    this.windSpeedMs = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  WeatherCurrentCacheEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String locationName,
    required double tempC,
    required double feelsLikeC,
    required String condition,
    required String iconCode,
    required int humidity,
    required double windSpeedMs,
    required DateTime fetchedAt,
  }) : locationName = Value(locationName),
       tempC = Value(tempC),
       feelsLikeC = Value(feelsLikeC),
       condition = Value(condition),
       iconCode = Value(iconCode),
       humidity = Value(humidity),
       windSpeedMs = Value(windSpeedMs),
       fetchedAt = Value(fetchedAt);
  static Insertable<WeatherCurrentCacheEntry> custom({
    Expression<int>? id,
    Expression<String>? locationName,
    Expression<double>? tempC,
    Expression<double>? feelsLikeC,
    Expression<String>? condition,
    Expression<String>? iconCode,
    Expression<int>? humidity,
    Expression<double>? windSpeedMs,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (locationName != null) 'location_name': locationName,
      if (tempC != null) 'temp_c': tempC,
      if (feelsLikeC != null) 'feels_like_c': feelsLikeC,
      if (condition != null) 'condition': condition,
      if (iconCode != null) 'icon_code': iconCode,
      if (humidity != null) 'humidity': humidity,
      if (windSpeedMs != null) 'wind_speed_ms': windSpeedMs,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  WeatherCurrentCacheEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? locationName,
    Value<double>? tempC,
    Value<double>? feelsLikeC,
    Value<String>? condition,
    Value<String>? iconCode,
    Value<int>? humidity,
    Value<double>? windSpeedMs,
    Value<DateTime>? fetchedAt,
  }) {
    return WeatherCurrentCacheEntriesCompanion(
      id: id ?? this.id,
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

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (tempC.present) {
      map['temp_c'] = Variable<double>(tempC.value);
    }
    if (feelsLikeC.present) {
      map['feels_like_c'] = Variable<double>(feelsLikeC.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<String>(iconCode.value);
    }
    if (humidity.present) {
      map['humidity'] = Variable<int>(humidity.value);
    }
    if (windSpeedMs.present) {
      map['wind_speed_ms'] = Variable<double>(windSpeedMs.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCurrentCacheEntriesCompanion(')
          ..write('id: $id, ')
          ..write('locationName: $locationName, ')
          ..write('tempC: $tempC, ')
          ..write('feelsLikeC: $feelsLikeC, ')
          ..write('condition: $condition, ')
          ..write('iconCode: $iconCode, ')
          ..write('humidity: $humidity, ')
          ..write('windSpeedMs: $windSpeedMs, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $WeatherForecastDayCacheEntriesTable
    extends WeatherForecastDayCacheEntries
    with
        TableInfo<
          $WeatherForecastDayCacheEntriesTable,
          WeatherForecastDayCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherForecastDayCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _forecastDateMeta = const VerificationMeta(
    'forecastDate',
  );
  @override
  late final GeneratedColumn<DateTime> forecastDate = GeneratedColumn<DateTime>(
    'forecast_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minTempCMeta = const VerificationMeta(
    'minTempC',
  );
  @override
  late final GeneratedColumn<double> minTempC = GeneratedColumn<double>(
    'min_temp_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxTempCMeta = const VerificationMeta(
    'maxTempC',
  );
  @override
  late final GeneratedColumn<double> maxTempC = GeneratedColumn<double>(
    'max_temp_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<String> iconCode = GeneratedColumn<String>(
    'icon_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    locationName,
    forecastDate,
    minTempC,
    maxTempC,
    condition,
    iconCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_forecast_day_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherForecastDayCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationNameMeta);
    }
    if (data.containsKey('forecast_date')) {
      context.handle(
        _forecastDateMeta,
        forecastDate.isAcceptableOrUnknown(
          data['forecast_date']!,
          _forecastDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_forecastDateMeta);
    }
    if (data.containsKey('min_temp_c')) {
      context.handle(
        _minTempCMeta,
        minTempC.isAcceptableOrUnknown(data['min_temp_c']!, _minTempCMeta),
      );
    } else if (isInserting) {
      context.missing(_minTempCMeta);
    }
    if (data.containsKey('max_temp_c')) {
      context.handle(
        _maxTempCMeta,
        maxTempC.isAcceptableOrUnknown(data['max_temp_c']!, _maxTempCMeta),
      );
    } else if (isInserting) {
      context.missing(_maxTempCMeta);
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    } else if (isInserting) {
      context.missing(_conditionMeta);
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_iconCodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeatherForecastDayCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherForecastDayCacheEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      )!,
      forecastDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}forecast_date'],
      )!,
      minTempC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_temp_c'],
      )!,
      maxTempC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_temp_c'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      )!,
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_code'],
      )!,
    );
  }

  @override
  $WeatherForecastDayCacheEntriesTable createAlias(String alias) {
    return $WeatherForecastDayCacheEntriesTable(attachedDatabase, alias);
  }
}

class WeatherForecastDayCacheEntry extends DataClass
    implements Insertable<WeatherForecastDayCacheEntry> {
  final int id;
  final String locationName;
  final DateTime forecastDate;
  final double minTempC;
  final double maxTempC;
  final String condition;
  final String iconCode;
  const WeatherForecastDayCacheEntry({
    required this.id,
    required this.locationName,
    required this.forecastDate,
    required this.minTempC,
    required this.maxTempC,
    required this.condition,
    required this.iconCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['location_name'] = Variable<String>(locationName);
    map['forecast_date'] = Variable<DateTime>(forecastDate);
    map['min_temp_c'] = Variable<double>(minTempC);
    map['max_temp_c'] = Variable<double>(maxTempC);
    map['condition'] = Variable<String>(condition);
    map['icon_code'] = Variable<String>(iconCode);
    return map;
  }

  WeatherForecastDayCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeatherForecastDayCacheEntriesCompanion(
      id: Value(id),
      locationName: Value(locationName),
      forecastDate: Value(forecastDate),
      minTempC: Value(minTempC),
      maxTempC: Value(maxTempC),
      condition: Value(condition),
      iconCode: Value(iconCode),
    );
  }

  factory WeatherForecastDayCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherForecastDayCacheEntry(
      id: serializer.fromJson<int>(json['id']),
      locationName: serializer.fromJson<String>(json['locationName']),
      forecastDate: serializer.fromJson<DateTime>(json['forecastDate']),
      minTempC: serializer.fromJson<double>(json['minTempC']),
      maxTempC: serializer.fromJson<double>(json['maxTempC']),
      condition: serializer.fromJson<String>(json['condition']),
      iconCode: serializer.fromJson<String>(json['iconCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'locationName': serializer.toJson<String>(locationName),
      'forecastDate': serializer.toJson<DateTime>(forecastDate),
      'minTempC': serializer.toJson<double>(minTempC),
      'maxTempC': serializer.toJson<double>(maxTempC),
      'condition': serializer.toJson<String>(condition),
      'iconCode': serializer.toJson<String>(iconCode),
    };
  }

  WeatherForecastDayCacheEntry copyWith({
    int? id,
    String? locationName,
    DateTime? forecastDate,
    double? minTempC,
    double? maxTempC,
    String? condition,
    String? iconCode,
  }) => WeatherForecastDayCacheEntry(
    id: id ?? this.id,
    locationName: locationName ?? this.locationName,
    forecastDate: forecastDate ?? this.forecastDate,
    minTempC: minTempC ?? this.minTempC,
    maxTempC: maxTempC ?? this.maxTempC,
    condition: condition ?? this.condition,
    iconCode: iconCode ?? this.iconCode,
  );
  WeatherForecastDayCacheEntry copyWithCompanion(
    WeatherForecastDayCacheEntriesCompanion data,
  ) {
    return WeatherForecastDayCacheEntry(
      id: data.id.present ? data.id.value : this.id,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      forecastDate: data.forecastDate.present
          ? data.forecastDate.value
          : this.forecastDate,
      minTempC: data.minTempC.present ? data.minTempC.value : this.minTempC,
      maxTempC: data.maxTempC.present ? data.maxTempC.value : this.maxTempC,
      condition: data.condition.present ? data.condition.value : this.condition,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherForecastDayCacheEntry(')
          ..write('id: $id, ')
          ..write('locationName: $locationName, ')
          ..write('forecastDate: $forecastDate, ')
          ..write('minTempC: $minTempC, ')
          ..write('maxTempC: $maxTempC, ')
          ..write('condition: $condition, ')
          ..write('iconCode: $iconCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    locationName,
    forecastDate,
    minTempC,
    maxTempC,
    condition,
    iconCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherForecastDayCacheEntry &&
          other.id == this.id &&
          other.locationName == this.locationName &&
          other.forecastDate == this.forecastDate &&
          other.minTempC == this.minTempC &&
          other.maxTempC == this.maxTempC &&
          other.condition == this.condition &&
          other.iconCode == this.iconCode);
}

class WeatherForecastDayCacheEntriesCompanion
    extends UpdateCompanion<WeatherForecastDayCacheEntry> {
  final Value<int> id;
  final Value<String> locationName;
  final Value<DateTime> forecastDate;
  final Value<double> minTempC;
  final Value<double> maxTempC;
  final Value<String> condition;
  final Value<String> iconCode;
  const WeatherForecastDayCacheEntriesCompanion({
    this.id = const Value.absent(),
    this.locationName = const Value.absent(),
    this.forecastDate = const Value.absent(),
    this.minTempC = const Value.absent(),
    this.maxTempC = const Value.absent(),
    this.condition = const Value.absent(),
    this.iconCode = const Value.absent(),
  });
  WeatherForecastDayCacheEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String locationName,
    required DateTime forecastDate,
    required double minTempC,
    required double maxTempC,
    required String condition,
    required String iconCode,
  }) : locationName = Value(locationName),
       forecastDate = Value(forecastDate),
       minTempC = Value(minTempC),
       maxTempC = Value(maxTempC),
       condition = Value(condition),
       iconCode = Value(iconCode);
  static Insertable<WeatherForecastDayCacheEntry> custom({
    Expression<int>? id,
    Expression<String>? locationName,
    Expression<DateTime>? forecastDate,
    Expression<double>? minTempC,
    Expression<double>? maxTempC,
    Expression<String>? condition,
    Expression<String>? iconCode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (locationName != null) 'location_name': locationName,
      if (forecastDate != null) 'forecast_date': forecastDate,
      if (minTempC != null) 'min_temp_c': minTempC,
      if (maxTempC != null) 'max_temp_c': maxTempC,
      if (condition != null) 'condition': condition,
      if (iconCode != null) 'icon_code': iconCode,
    });
  }

  WeatherForecastDayCacheEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? locationName,
    Value<DateTime>? forecastDate,
    Value<double>? minTempC,
    Value<double>? maxTempC,
    Value<String>? condition,
    Value<String>? iconCode,
  }) {
    return WeatherForecastDayCacheEntriesCompanion(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      forecastDate: forecastDate ?? this.forecastDate,
      minTempC: minTempC ?? this.minTempC,
      maxTempC: maxTempC ?? this.maxTempC,
      condition: condition ?? this.condition,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (forecastDate.present) {
      map['forecast_date'] = Variable<DateTime>(forecastDate.value);
    }
    if (minTempC.present) {
      map['min_temp_c'] = Variable<double>(minTempC.value);
    }
    if (maxTempC.present) {
      map['max_temp_c'] = Variable<double>(maxTempC.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<String>(iconCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherForecastDayCacheEntriesCompanion(')
          ..write('id: $id, ')
          ..write('locationName: $locationName, ')
          ..write('forecastDate: $forecastDate, ')
          ..write('minTempC: $minTempC, ')
          ..write('maxTempC: $maxTempC, ')
          ..write('condition: $condition, ')
          ..write('iconCode: $iconCode')
          ..write(')'))
        .toString();
  }
}

class $DisplaySettingsEntriesTable extends DisplaySettingsEntries
    with TableInfo<$DisplaySettingsEntriesTable, DisplaySettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisplaySettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dimEnabledMeta = const VerificationMeta(
    'dimEnabled',
  );
  @override
  late final GeneratedColumn<bool> dimEnabled = GeneratedColumn<bool>(
    'dim_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dim_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _dimStartHourMeta = const VerificationMeta(
    'dimStartHour',
  );
  @override
  late final GeneratedColumn<int> dimStartHour = GeneratedColumn<int>(
    'dim_start_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(22),
  );
  static const VerificationMeta _dimEndHourMeta = const VerificationMeta(
    'dimEndHour',
  );
  @override
  late final GeneratedColumn<int> dimEndHour = GeneratedColumn<int>(
    'dim_end_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _dimLevelMeta = const VerificationMeta(
    'dimLevel',
  );
  @override
  late final GeneratedColumn<double> dimLevel = GeneratedColumn<double>(
    'dim_level',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.85),
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dimEnabled,
    dimStartHour,
    dimEndHour,
    dimLevel,
    locationName,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'display_settings_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisplaySettingsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dim_enabled')) {
      context.handle(
        _dimEnabledMeta,
        dimEnabled.isAcceptableOrUnknown(data['dim_enabled']!, _dimEnabledMeta),
      );
    }
    if (data.containsKey('dim_start_hour')) {
      context.handle(
        _dimStartHourMeta,
        dimStartHour.isAcceptableOrUnknown(
          data['dim_start_hour']!,
          _dimStartHourMeta,
        ),
      );
    }
    if (data.containsKey('dim_end_hour')) {
      context.handle(
        _dimEndHourMeta,
        dimEndHour.isAcceptableOrUnknown(
          data['dim_end_hour']!,
          _dimEndHourMeta,
        ),
      );
    }
    if (data.containsKey('dim_level')) {
      context.handle(
        _dimLevelMeta,
        dimLevel.isAcceptableOrUnknown(data['dim_level']!, _dimLevelMeta),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DisplaySettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisplaySettingsEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dimEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dim_enabled'],
      )!,
      dimStartHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dim_start_hour'],
      )!,
      dimEndHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dim_end_hour'],
      )!,
      dimLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dim_level'],
      )!,
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DisplaySettingsEntriesTable createAlias(String alias) {
    return $DisplaySettingsEntriesTable(attachedDatabase, alias);
  }
}

class DisplaySettingsEntry extends DataClass
    implements Insertable<DisplaySettingsEntry> {
  final int id;
  final bool dimEnabled;
  final int dimStartHour;
  final int dimEndHour;
  final double dimLevel;
  final String locationName;
  final DateTime updatedAt;
  const DisplaySettingsEntry({
    required this.id,
    required this.dimEnabled,
    required this.dimStartHour,
    required this.dimEndHour,
    required this.dimLevel,
    required this.locationName,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dim_enabled'] = Variable<bool>(dimEnabled);
    map['dim_start_hour'] = Variable<int>(dimStartHour);
    map['dim_end_hour'] = Variable<int>(dimEndHour);
    map['dim_level'] = Variable<double>(dimLevel);
    map['location_name'] = Variable<String>(locationName);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DisplaySettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return DisplaySettingsEntriesCompanion(
      id: Value(id),
      dimEnabled: Value(dimEnabled),
      dimStartHour: Value(dimStartHour),
      dimEndHour: Value(dimEndHour),
      dimLevel: Value(dimLevel),
      locationName: Value(locationName),
      updatedAt: Value(updatedAt),
    );
  }

  factory DisplaySettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisplaySettingsEntry(
      id: serializer.fromJson<int>(json['id']),
      dimEnabled: serializer.fromJson<bool>(json['dimEnabled']),
      dimStartHour: serializer.fromJson<int>(json['dimStartHour']),
      dimEndHour: serializer.fromJson<int>(json['dimEndHour']),
      dimLevel: serializer.fromJson<double>(json['dimLevel']),
      locationName: serializer.fromJson<String>(json['locationName']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dimEnabled': serializer.toJson<bool>(dimEnabled),
      'dimStartHour': serializer.toJson<int>(dimStartHour),
      'dimEndHour': serializer.toJson<int>(dimEndHour),
      'dimLevel': serializer.toJson<double>(dimLevel),
      'locationName': serializer.toJson<String>(locationName),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DisplaySettingsEntry copyWith({
    int? id,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    DateTime? updatedAt,
  }) => DisplaySettingsEntry(
    id: id ?? this.id,
    dimEnabled: dimEnabled ?? this.dimEnabled,
    dimStartHour: dimStartHour ?? this.dimStartHour,
    dimEndHour: dimEndHour ?? this.dimEndHour,
    dimLevel: dimLevel ?? this.dimLevel,
    locationName: locationName ?? this.locationName,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DisplaySettingsEntry copyWithCompanion(DisplaySettingsEntriesCompanion data) {
    return DisplaySettingsEntry(
      id: data.id.present ? data.id.value : this.id,
      dimEnabled: data.dimEnabled.present
          ? data.dimEnabled.value
          : this.dimEnabled,
      dimStartHour: data.dimStartHour.present
          ? data.dimStartHour.value
          : this.dimStartHour,
      dimEndHour: data.dimEndHour.present
          ? data.dimEndHour.value
          : this.dimEndHour,
      dimLevel: data.dimLevel.present ? data.dimLevel.value : this.dimLevel,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisplaySettingsEntry(')
          ..write('id: $id, ')
          ..write('dimEnabled: $dimEnabled, ')
          ..write('dimStartHour: $dimStartHour, ')
          ..write('dimEndHour: $dimEndHour, ')
          ..write('dimLevel: $dimLevel, ')
          ..write('locationName: $locationName, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dimEnabled,
    dimStartHour,
    dimEndHour,
    dimLevel,
    locationName,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisplaySettingsEntry &&
          other.id == this.id &&
          other.dimEnabled == this.dimEnabled &&
          other.dimStartHour == this.dimStartHour &&
          other.dimEndHour == this.dimEndHour &&
          other.dimLevel == this.dimLevel &&
          other.locationName == this.locationName &&
          other.updatedAt == this.updatedAt);
}

class DisplaySettingsEntriesCompanion
    extends UpdateCompanion<DisplaySettingsEntry> {
  final Value<int> id;
  final Value<bool> dimEnabled;
  final Value<int> dimStartHour;
  final Value<int> dimEndHour;
  final Value<double> dimLevel;
  final Value<String> locationName;
  final Value<DateTime> updatedAt;
  const DisplaySettingsEntriesCompanion({
    this.id = const Value.absent(),
    this.dimEnabled = const Value.absent(),
    this.dimStartHour = const Value.absent(),
    this.dimEndHour = const Value.absent(),
    this.dimLevel = const Value.absent(),
    this.locationName = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DisplaySettingsEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.dimEnabled = const Value.absent(),
    this.dimStartHour = const Value.absent(),
    this.dimEndHour = const Value.absent(),
    this.dimLevel = const Value.absent(),
    this.locationName = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<DisplaySettingsEntry> custom({
    Expression<int>? id,
    Expression<bool>? dimEnabled,
    Expression<int>? dimStartHour,
    Expression<int>? dimEndHour,
    Expression<double>? dimLevel,
    Expression<String>? locationName,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dimEnabled != null) 'dim_enabled': dimEnabled,
      if (dimStartHour != null) 'dim_start_hour': dimStartHour,
      if (dimEndHour != null) 'dim_end_hour': dimEndHour,
      if (dimLevel != null) 'dim_level': dimLevel,
      if (locationName != null) 'location_name': locationName,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DisplaySettingsEntriesCompanion copyWith({
    Value<int>? id,
    Value<bool>? dimEnabled,
    Value<int>? dimStartHour,
    Value<int>? dimEndHour,
    Value<double>? dimLevel,
    Value<String>? locationName,
    Value<DateTime>? updatedAt,
  }) {
    return DisplaySettingsEntriesCompanion(
      id: id ?? this.id,
      dimEnabled: dimEnabled ?? this.dimEnabled,
      dimStartHour: dimStartHour ?? this.dimStartHour,
      dimEndHour: dimEndHour ?? this.dimEndHour,
      dimLevel: dimLevel ?? this.dimLevel,
      locationName: locationName ?? this.locationName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dimEnabled.present) {
      map['dim_enabled'] = Variable<bool>(dimEnabled.value);
    }
    if (dimStartHour.present) {
      map['dim_start_hour'] = Variable<int>(dimStartHour.value);
    }
    if (dimEndHour.present) {
      map['dim_end_hour'] = Variable<int>(dimEndHour.value);
    }
    if (dimLevel.present) {
      map['dim_level'] = Variable<double>(dimLevel.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisplaySettingsEntriesCompanion(')
          ..write('id: $id, ')
          ..write('dimEnabled: $dimEnabled, ')
          ..write('dimStartHour: $dimStartHour, ')
          ..write('dimEndHour: $dimEndHour, ')
          ..write('dimLevel: $dimLevel, ')
          ..write('locationName: $locationName, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LayoutEntriesTable layoutEntries = $LayoutEntriesTable(this);
  late final $WeatherCurrentCacheEntriesTable weatherCurrentCacheEntries =
      $WeatherCurrentCacheEntriesTable(this);
  late final $WeatherForecastDayCacheEntriesTable
  weatherForecastDayCacheEntries = $WeatherForecastDayCacheEntriesTable(this);
  late final $DisplaySettingsEntriesTable displaySettingsEntries =
      $DisplaySettingsEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    layoutEntries,
    weatherCurrentCacheEntries,
    weatherForecastDayCacheEntries,
    displaySettingsEntries,
  ];
}

typedef $$LayoutEntriesTableCreateCompanionBuilder =
    LayoutEntriesCompanion Function({
      Value<int> id,
      required String name,
      required int columnsCount,
      required int rowsCount,
      required String cardsJson,
      required DateTime updatedAt,
    });
typedef $$LayoutEntriesTableUpdateCompanionBuilder =
    LayoutEntriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> columnsCount,
      Value<int> rowsCount,
      Value<String> cardsJson,
      Value<DateTime> updatedAt,
    });

class $$LayoutEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LayoutEntriesTable> {
  $$LayoutEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get columnsCount => $composableBuilder(
    column: $table.columnsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowsCount => $composableBuilder(
    column: $table.rowsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardsJson => $composableBuilder(
    column: $table.cardsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LayoutEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LayoutEntriesTable> {
  $$LayoutEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get columnsCount => $composableBuilder(
    column: $table.columnsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowsCount => $composableBuilder(
    column: $table.rowsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardsJson => $composableBuilder(
    column: $table.cardsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LayoutEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LayoutEntriesTable> {
  $$LayoutEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get columnsCount => $composableBuilder(
    column: $table.columnsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowsCount =>
      $composableBuilder(column: $table.rowsCount, builder: (column) => column);

  GeneratedColumn<String> get cardsJson =>
      $composableBuilder(column: $table.cardsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LayoutEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LayoutEntriesTable,
          LayoutEntry,
          $$LayoutEntriesTableFilterComposer,
          $$LayoutEntriesTableOrderingComposer,
          $$LayoutEntriesTableAnnotationComposer,
          $$LayoutEntriesTableCreateCompanionBuilder,
          $$LayoutEntriesTableUpdateCompanionBuilder,
          (
            LayoutEntry,
            BaseReferences<_$AppDatabase, $LayoutEntriesTable, LayoutEntry>,
          ),
          LayoutEntry,
          PrefetchHooks Function()
        > {
  $$LayoutEntriesTableTableManager(_$AppDatabase db, $LayoutEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LayoutEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LayoutEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LayoutEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> columnsCount = const Value.absent(),
                Value<int> rowsCount = const Value.absent(),
                Value<String> cardsJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LayoutEntriesCompanion(
                id: id,
                name: name,
                columnsCount: columnsCount,
                rowsCount: rowsCount,
                cardsJson: cardsJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int columnsCount,
                required int rowsCount,
                required String cardsJson,
                required DateTime updatedAt,
              }) => LayoutEntriesCompanion.insert(
                id: id,
                name: name,
                columnsCount: columnsCount,
                rowsCount: rowsCount,
                cardsJson: cardsJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LayoutEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LayoutEntriesTable,
      LayoutEntry,
      $$LayoutEntriesTableFilterComposer,
      $$LayoutEntriesTableOrderingComposer,
      $$LayoutEntriesTableAnnotationComposer,
      $$LayoutEntriesTableCreateCompanionBuilder,
      $$LayoutEntriesTableUpdateCompanionBuilder,
      (
        LayoutEntry,
        BaseReferences<_$AppDatabase, $LayoutEntriesTable, LayoutEntry>,
      ),
      LayoutEntry,
      PrefetchHooks Function()
    >;
typedef $$WeatherCurrentCacheEntriesTableCreateCompanionBuilder =
    WeatherCurrentCacheEntriesCompanion Function({
      Value<int> id,
      required String locationName,
      required double tempC,
      required double feelsLikeC,
      required String condition,
      required String iconCode,
      required int humidity,
      required double windSpeedMs,
      required DateTime fetchedAt,
    });
typedef $$WeatherCurrentCacheEntriesTableUpdateCompanionBuilder =
    WeatherCurrentCacheEntriesCompanion Function({
      Value<int> id,
      Value<String> locationName,
      Value<double> tempC,
      Value<double> feelsLikeC,
      Value<String> condition,
      Value<String> iconCode,
      Value<int> humidity,
      Value<double> windSpeedMs,
      Value<DateTime> fetchedAt,
    });

class $$WeatherCurrentCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherCurrentCacheEntriesTable> {
  $$WeatherCurrentCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tempC => $composableBuilder(
    column: $table.tempC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get feelsLikeC => $composableBuilder(
    column: $table.feelsLikeC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get windSpeedMs => $composableBuilder(
    column: $table.windSpeedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeatherCurrentCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherCurrentCacheEntriesTable> {
  $$WeatherCurrentCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tempC => $composableBuilder(
    column: $table.tempC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get feelsLikeC => $composableBuilder(
    column: $table.feelsLikeC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get windSpeedMs => $composableBuilder(
    column: $table.windSpeedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeatherCurrentCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherCurrentCacheEntriesTable> {
  $$WeatherCurrentCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tempC =>
      $composableBuilder(column: $table.tempC, builder: (column) => column);

  GeneratedColumn<double> get feelsLikeC => $composableBuilder(
    column: $table.feelsLikeC,
    builder: (column) => column,
  );

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<int> get humidity =>
      $composableBuilder(column: $table.humidity, builder: (column) => column);

  GeneratedColumn<double> get windSpeedMs => $composableBuilder(
    column: $table.windSpeedMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$WeatherCurrentCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherCurrentCacheEntriesTable,
          WeatherCurrentCacheEntry,
          $$WeatherCurrentCacheEntriesTableFilterComposer,
          $$WeatherCurrentCacheEntriesTableOrderingComposer,
          $$WeatherCurrentCacheEntriesTableAnnotationComposer,
          $$WeatherCurrentCacheEntriesTableCreateCompanionBuilder,
          $$WeatherCurrentCacheEntriesTableUpdateCompanionBuilder,
          (
            WeatherCurrentCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $WeatherCurrentCacheEntriesTable,
              WeatherCurrentCacheEntry
            >,
          ),
          WeatherCurrentCacheEntry,
          PrefetchHooks Function()
        > {
  $$WeatherCurrentCacheEntriesTableTableManager(
    _$AppDatabase db,
    $WeatherCurrentCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherCurrentCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WeatherCurrentCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WeatherCurrentCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> locationName = const Value.absent(),
                Value<double> tempC = const Value.absent(),
                Value<double> feelsLikeC = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<String> iconCode = const Value.absent(),
                Value<int> humidity = const Value.absent(),
                Value<double> windSpeedMs = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => WeatherCurrentCacheEntriesCompanion(
                id: id,
                locationName: locationName,
                tempC: tempC,
                feelsLikeC: feelsLikeC,
                condition: condition,
                iconCode: iconCode,
                humidity: humidity,
                windSpeedMs: windSpeedMs,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String locationName,
                required double tempC,
                required double feelsLikeC,
                required String condition,
                required String iconCode,
                required int humidity,
                required double windSpeedMs,
                required DateTime fetchedAt,
              }) => WeatherCurrentCacheEntriesCompanion.insert(
                id: id,
                locationName: locationName,
                tempC: tempC,
                feelsLikeC: feelsLikeC,
                condition: condition,
                iconCode: iconCode,
                humidity: humidity,
                windSpeedMs: windSpeedMs,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeatherCurrentCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherCurrentCacheEntriesTable,
      WeatherCurrentCacheEntry,
      $$WeatherCurrentCacheEntriesTableFilterComposer,
      $$WeatherCurrentCacheEntriesTableOrderingComposer,
      $$WeatherCurrentCacheEntriesTableAnnotationComposer,
      $$WeatherCurrentCacheEntriesTableCreateCompanionBuilder,
      $$WeatherCurrentCacheEntriesTableUpdateCompanionBuilder,
      (
        WeatherCurrentCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $WeatherCurrentCacheEntriesTable,
          WeatherCurrentCacheEntry
        >,
      ),
      WeatherCurrentCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$WeatherForecastDayCacheEntriesTableCreateCompanionBuilder =
    WeatherForecastDayCacheEntriesCompanion Function({
      Value<int> id,
      required String locationName,
      required DateTime forecastDate,
      required double minTempC,
      required double maxTempC,
      required String condition,
      required String iconCode,
    });
typedef $$WeatherForecastDayCacheEntriesTableUpdateCompanionBuilder =
    WeatherForecastDayCacheEntriesCompanion Function({
      Value<int> id,
      Value<String> locationName,
      Value<DateTime> forecastDate,
      Value<double> minTempC,
      Value<double> maxTempC,
      Value<String> condition,
      Value<String> iconCode,
    });

class $$WeatherForecastDayCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherForecastDayCacheEntriesTable> {
  $$WeatherForecastDayCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get forecastDate => $composableBuilder(
    column: $table.forecastDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minTempC => $composableBuilder(
    column: $table.minTempC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxTempC => $composableBuilder(
    column: $table.maxTempC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeatherForecastDayCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherForecastDayCacheEntriesTable> {
  $$WeatherForecastDayCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get forecastDate => $composableBuilder(
    column: $table.forecastDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minTempC => $composableBuilder(
    column: $table.minTempC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxTempC => $composableBuilder(
    column: $table.maxTempC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeatherForecastDayCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherForecastDayCacheEntriesTable> {
  $$WeatherForecastDayCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get forecastDate => $composableBuilder(
    column: $table.forecastDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minTempC =>
      $composableBuilder(column: $table.minTempC, builder: (column) => column);

  GeneratedColumn<double> get maxTempC =>
      $composableBuilder(column: $table.maxTempC, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);
}

class $$WeatherForecastDayCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherForecastDayCacheEntriesTable,
          WeatherForecastDayCacheEntry,
          $$WeatherForecastDayCacheEntriesTableFilterComposer,
          $$WeatherForecastDayCacheEntriesTableOrderingComposer,
          $$WeatherForecastDayCacheEntriesTableAnnotationComposer,
          $$WeatherForecastDayCacheEntriesTableCreateCompanionBuilder,
          $$WeatherForecastDayCacheEntriesTableUpdateCompanionBuilder,
          (
            WeatherForecastDayCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $WeatherForecastDayCacheEntriesTable,
              WeatherForecastDayCacheEntry
            >,
          ),
          WeatherForecastDayCacheEntry,
          PrefetchHooks Function()
        > {
  $$WeatherForecastDayCacheEntriesTableTableManager(
    _$AppDatabase db,
    $WeatherForecastDayCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherForecastDayCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WeatherForecastDayCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WeatherForecastDayCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> locationName = const Value.absent(),
                Value<DateTime> forecastDate = const Value.absent(),
                Value<double> minTempC = const Value.absent(),
                Value<double> maxTempC = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<String> iconCode = const Value.absent(),
              }) => WeatherForecastDayCacheEntriesCompanion(
                id: id,
                locationName: locationName,
                forecastDate: forecastDate,
                minTempC: minTempC,
                maxTempC: maxTempC,
                condition: condition,
                iconCode: iconCode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String locationName,
                required DateTime forecastDate,
                required double minTempC,
                required double maxTempC,
                required String condition,
                required String iconCode,
              }) => WeatherForecastDayCacheEntriesCompanion.insert(
                id: id,
                locationName: locationName,
                forecastDate: forecastDate,
                minTempC: minTempC,
                maxTempC: maxTempC,
                condition: condition,
                iconCode: iconCode,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeatherForecastDayCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherForecastDayCacheEntriesTable,
      WeatherForecastDayCacheEntry,
      $$WeatherForecastDayCacheEntriesTableFilterComposer,
      $$WeatherForecastDayCacheEntriesTableOrderingComposer,
      $$WeatherForecastDayCacheEntriesTableAnnotationComposer,
      $$WeatherForecastDayCacheEntriesTableCreateCompanionBuilder,
      $$WeatherForecastDayCacheEntriesTableUpdateCompanionBuilder,
      (
        WeatherForecastDayCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $WeatherForecastDayCacheEntriesTable,
          WeatherForecastDayCacheEntry
        >,
      ),
      WeatherForecastDayCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$DisplaySettingsEntriesTableCreateCompanionBuilder =
    DisplaySettingsEntriesCompanion Function({
      Value<int> id,
      Value<bool> dimEnabled,
      Value<int> dimStartHour,
      Value<int> dimEndHour,
      Value<double> dimLevel,
      Value<String> locationName,
      required DateTime updatedAt,
    });
typedef $$DisplaySettingsEntriesTableUpdateCompanionBuilder =
    DisplaySettingsEntriesCompanion Function({
      Value<int> id,
      Value<bool> dimEnabled,
      Value<int> dimStartHour,
      Value<int> dimEndHour,
      Value<double> dimLevel,
      Value<String> locationName,
      Value<DateTime> updatedAt,
    });

class $$DisplaySettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DisplaySettingsEntriesTable> {
  $$DisplaySettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dimEnabled => $composableBuilder(
    column: $table.dimEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dimStartHour => $composableBuilder(
    column: $table.dimStartHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dimEndHour => $composableBuilder(
    column: $table.dimEndHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dimLevel => $composableBuilder(
    column: $table.dimLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DisplaySettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DisplaySettingsEntriesTable> {
  $$DisplaySettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dimEnabled => $composableBuilder(
    column: $table.dimEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dimStartHour => $composableBuilder(
    column: $table.dimStartHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dimEndHour => $composableBuilder(
    column: $table.dimEndHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dimLevel => $composableBuilder(
    column: $table.dimLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DisplaySettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DisplaySettingsEntriesTable> {
  $$DisplaySettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get dimEnabled => $composableBuilder(
    column: $table.dimEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dimStartHour => $composableBuilder(
    column: $table.dimStartHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dimEndHour => $composableBuilder(
    column: $table.dimEndHour,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dimLevel =>
      $composableBuilder(column: $table.dimLevel, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DisplaySettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DisplaySettingsEntriesTable,
          DisplaySettingsEntry,
          $$DisplaySettingsEntriesTableFilterComposer,
          $$DisplaySettingsEntriesTableOrderingComposer,
          $$DisplaySettingsEntriesTableAnnotationComposer,
          $$DisplaySettingsEntriesTableCreateCompanionBuilder,
          $$DisplaySettingsEntriesTableUpdateCompanionBuilder,
          (
            DisplaySettingsEntry,
            BaseReferences<
              _$AppDatabase,
              $DisplaySettingsEntriesTable,
              DisplaySettingsEntry
            >,
          ),
          DisplaySettingsEntry,
          PrefetchHooks Function()
        > {
  $$DisplaySettingsEntriesTableTableManager(
    _$AppDatabase db,
    $DisplaySettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisplaySettingsEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DisplaySettingsEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DisplaySettingsEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> dimEnabled = const Value.absent(),
                Value<int> dimStartHour = const Value.absent(),
                Value<int> dimEndHour = const Value.absent(),
                Value<double> dimLevel = const Value.absent(),
                Value<String> locationName = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DisplaySettingsEntriesCompanion(
                id: id,
                dimEnabled: dimEnabled,
                dimStartHour: dimStartHour,
                dimEndHour: dimEndHour,
                dimLevel: dimLevel,
                locationName: locationName,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> dimEnabled = const Value.absent(),
                Value<int> dimStartHour = const Value.absent(),
                Value<int> dimEndHour = const Value.absent(),
                Value<double> dimLevel = const Value.absent(),
                Value<String> locationName = const Value.absent(),
                required DateTime updatedAt,
              }) => DisplaySettingsEntriesCompanion.insert(
                id: id,
                dimEnabled: dimEnabled,
                dimStartHour: dimStartHour,
                dimEndHour: dimEndHour,
                dimLevel: dimLevel,
                locationName: locationName,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DisplaySettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DisplaySettingsEntriesTable,
      DisplaySettingsEntry,
      $$DisplaySettingsEntriesTableFilterComposer,
      $$DisplaySettingsEntriesTableOrderingComposer,
      $$DisplaySettingsEntriesTableAnnotationComposer,
      $$DisplaySettingsEntriesTableCreateCompanionBuilder,
      $$DisplaySettingsEntriesTableUpdateCompanionBuilder,
      (
        DisplaySettingsEntry,
        BaseReferences<
          _$AppDatabase,
          $DisplaySettingsEntriesTable,
          DisplaySettingsEntry
        >,
      ),
      DisplaySettingsEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LayoutEntriesTableTableManager get layoutEntries =>
      $$LayoutEntriesTableTableManager(_db, _db.layoutEntries);
  $$WeatherCurrentCacheEntriesTableTableManager
  get weatherCurrentCacheEntries =>
      $$WeatherCurrentCacheEntriesTableTableManager(
        _db,
        _db.weatherCurrentCacheEntries,
      );
  $$WeatherForecastDayCacheEntriesTableTableManager
  get weatherForecastDayCacheEntries =>
      $$WeatherForecastDayCacheEntriesTableTableManager(
        _db,
        _db.weatherForecastDayCacheEntries,
      );
  $$DisplaySettingsEntriesTableTableManager get displaySettingsEntries =>
      $$DisplaySettingsEntriesTableTableManager(
        _db,
        _db.displaySettingsEntries,
      );
}
