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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LayoutEntriesTable layoutEntries = $LayoutEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [layoutEntries];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LayoutEntriesTableTableManager get layoutEntries =>
      $$LayoutEntriesTableTableManager(_db, _db.layoutEntries);
}
