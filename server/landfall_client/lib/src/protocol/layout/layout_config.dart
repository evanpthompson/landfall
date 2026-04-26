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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// A saved display layout configuration.
abstract class LayoutConfig implements _i1.SerializableModel {
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

  int? id;
  String name;
  String presetType;
  int columnsCount;
  int rowsCount;
  String cardsJson;
  bool isActive;
  DateTime updatedAt;

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
    int? columnsCount,
    int? rowsCount,
    String? cardsJson,
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
