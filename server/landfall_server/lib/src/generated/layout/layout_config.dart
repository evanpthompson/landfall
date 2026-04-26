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

/// A saved display layout configuration.
/// One row per named layout (weekday, weekend, night, custom).
abstract class LayoutConfig
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  LayoutConfig._({
    this.id,
    required this.name,
    String? presetType,
    int? columnsCount,
    int? rowsCount,
    required this.cardsJson,
    bool? isActive,
    required this.updatedAt,
  })  : presetType = presetType ?? 'custom',
        columnsCount = columnsCount ?? 12,
        rowsCount = rowsCount ?? 8,
        isActive = isActive ?? false;

  factory LayoutConfig({
    int? id,
    required String name,
    String? presetType,
    int? columnsCount,
    int? rowsCount,
    required String cardsJson,
    bool? isActive,
    required DateTime updatedAt,
  }) = _LayoutConfigImpl;

  factory LayoutConfig.fromJson(Map<String, dynamic> jsonSerialization) {
    return LayoutConfig(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      presetType: jsonSerialization['presetType'] as String?,
      columnsCount: jsonSerialization['columnsCount'] as int?,
      rowsCount: jsonSerialization['rowsCount'] as int?,
      cardsJson: jsonSerialization['cardsJson'] as String,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = LayoutConfigTable();

  static const db = LayoutConfigRepository._();

  @override
  int? id;

  String name;
  String presetType;
  int columnsCount;
  int rowsCount;
  String cardsJson;
  bool isActive;
  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  @_i1.useResult
  LayoutConfig copyWith({
    int? id,
    String? name,
    String? presetType,
    int? columnsCount,
    int? rowsCount,
    String? cardsJson,
    bool? isActive,
    DateTime? updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LayoutConfig',
      if (id != null) 'id': id,
      'name': name,
      'presetType': presetType,
      'columnsCount': columnsCount,
      'rowsCount': rowsCount,
      'cardsJson': cardsJson,
      'isActive': isActive,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LayoutConfig',
      if (id != null) 'id': id,
      'name': name,
      'presetType': presetType,
      'columnsCount': columnsCount,
      'rowsCount': rowsCount,
      'cardsJson': cardsJson,
      'isActive': isActive,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LayoutConfigImpl extends LayoutConfig {
  _LayoutConfigImpl({
    int? id,
    required String name,
    String? presetType,
    int? columnsCount,
    int? rowsCount,
    required String cardsJson,
    bool? isActive,
    required DateTime updatedAt,
  }) : super._(
          id: id,
          name: name,
          presetType: presetType,
          columnsCount: columnsCount,
          rowsCount: rowsCount,
          cardsJson: cardsJson,
          isActive: isActive,
          updatedAt: updatedAt,
        );

  @_i1.useResult
  @override
  LayoutConfig copyWith({
    Object? id = _Undefined,
    String? name,
    String? presetType,
    String? cardsJson,
    int? columnsCount,
    int? rowsCount,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return LayoutConfig(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      presetType: presetType ?? this.presetType,
      columnsCount: columnsCount ?? this.columnsCount,
      rowsCount: rowsCount ?? this.rowsCount,
      cardsJson: cardsJson ?? this.cardsJson,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LayoutConfigUpdateTable extends _i1.UpdateTable<LayoutConfigTable> {
  LayoutConfigUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) =>
      _i1.ColumnValue(table.name, value);

  _i1.ColumnValue<String, String> presetType(String value) =>
      _i1.ColumnValue(table.presetType, value);

  _i1.ColumnValue<int, int> columnsCount(int value) =>
      _i1.ColumnValue(table.columnsCount, value);

  _i1.ColumnValue<int, int> rowsCount(int value) =>
      _i1.ColumnValue(table.rowsCount, value);

  _i1.ColumnValue<String, String> cardsJson(String value) =>
      _i1.ColumnValue(table.cardsJson, value);

  _i1.ColumnValue<bool, bool> isActive(bool value) =>
      _i1.ColumnValue(table.isActive, value);

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(table.updatedAt, value);
}

class LayoutConfigTable extends _i1.Table<int?> {
  LayoutConfigTable({super.tableRelation})
      : super(tableName: 'layout_configs') {
    updateTable = LayoutConfigUpdateTable(this);
    name = _i1.ColumnString('name', this);
    presetType = _i1.ColumnString('presetType', this, hasDefault: true);
    columnsCount = _i1.ColumnInt('columnsCount', this, hasDefault: true);
    rowsCount = _i1.ColumnInt('rowsCount', this, hasDefault: true);
    cardsJson = _i1.ColumnString('cardsJson', this);
    isActive = _i1.ColumnBool('isActive', this, hasDefault: true);
    updatedAt = _i1.ColumnDateTime('updatedAt', this);
  }

  late final LayoutConfigUpdateTable updateTable;
  late final _i1.ColumnString name;
  late final _i1.ColumnString presetType;
  late final _i1.ColumnInt columnsCount;
  late final _i1.ColumnInt rowsCount;
  late final _i1.ColumnString cardsJson;
  late final _i1.ColumnBool isActive;
  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
        id,
        name,
        presetType,
        columnsCount,
        rowsCount,
        cardsJson,
        isActive,
        updatedAt,
      ];
}

class LayoutConfigInclude extends _i1.IncludeObject {
  LayoutConfigInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => LayoutConfig.t;
}

class LayoutConfigIncludeList extends _i1.IncludeList {
  LayoutConfigIncludeList._({
    _i1.WhereExpressionBuilder<LayoutConfigTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LayoutConfig.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => LayoutConfig.t;
}

class LayoutConfigRepository {
  const LayoutConfigRepository._();

  Future<List<LayoutConfig>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LayoutConfigTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LayoutConfigTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LayoutConfigTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<LayoutConfig>(
      where: where?.call(LayoutConfig.t),
      orderBy: orderBy?.call(LayoutConfig.t),
      orderByList: orderByList?.call(LayoutConfig.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  Future<LayoutConfig?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LayoutConfigTable>? where,
    int? offset,
    _i1.OrderByBuilder<LayoutConfigTable>? orderBy,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<LayoutConfig>(
      where: where?.call(LayoutConfig.t),
      orderBy: orderBy?.call(LayoutConfig.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  Future<LayoutConfig> insertRow(
    _i1.DatabaseSession session,
    LayoutConfig row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LayoutConfig>(row, transaction: transaction);
  }

  Future<LayoutConfig> updateRow(
    _i1.DatabaseSession session,
    LayoutConfig row, {
    _i1.ColumnSelections<LayoutConfigTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LayoutConfig>(
      row,
      columns: columns?.call(LayoutConfig.t),
      transaction: transaction,
    );
  }

  Future<LayoutConfig> deleteRow(
    _i1.DatabaseSession session,
    LayoutConfig row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LayoutConfig>(row, transaction: transaction);
  }

  Future<List<LayoutConfig>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LayoutConfigTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LayoutConfig>(
      where: where(LayoutConfig.t),
      transaction: transaction,
    );
  }
}
