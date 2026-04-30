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

/// A named dashboard profile — layout, theme, agent card filter, and optional schedule.
/// Replaces the LayoutPresetType enum with a flexible named entity.
/// One row has isActive=true — that is the profile currently shown on the display.
abstract class DashboardProfile implements _i1.SerializableModel {
  DashboardProfile._({
    this.id,
    required this.name,
    required this.slug,
    bool? isActive,
    this.themeId,
    String? cardFilterJson,
    this.scheduleJson,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    required this.cardsJson,
    required this.createdAt,
  }) : isActive = isActive ?? false,
       cardFilterJson = cardFilterJson ?? '{}',
       sortOrder = sortOrder ?? 0,
       columnsCount = columnsCount ?? 12,
       rowsCount = rowsCount ?? 8;

  factory DashboardProfile({
    int? id,
    required String name,
    required String slug,
    bool? isActive,
    String? themeId,
    String? cardFilterJson,
    String? scheduleJson,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    required String cardsJson,
    required DateTime createdAt,
  }) = _DashboardProfileImpl;

  factory DashboardProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return DashboardProfile(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      slug: jsonSerialization['slug'] as String,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      themeId: jsonSerialization['themeId'] as String?,
      cardFilterJson: jsonSerialization['cardFilterJson'] as String?,
      scheduleJson: jsonSerialization['scheduleJson'] as String?,
      sortOrder: jsonSerialization['sortOrder'] as int?,
      columnsCount: jsonSerialization['columnsCount'] as int?,
      rowsCount: jsonSerialization['rowsCount'] as int?,
      cardsJson: jsonSerialization['cardsJson'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// User-facing name (e.g. "Weekday", "Party Mode", "Night Stand").
  String name;

  /// URL-safe slug derived from name. Used by agent LayoutSchema API.
  String slug;

  /// True when this is the profile currently shown on the display.
  bool isActive;

  /// Optional theme identifier. Null = default theme.
  String? themeId;

  /// JSON-encoded ProfileCardFilter. Controls which agent cards are shown.
  String cardFilterJson;

  /// JSON-encoded ProfileSchedule. Null = no automatic scheduling.
  String? scheduleJson;

  /// Sort order for the profile list. Lower = first.
  int sortOrder;

  /// Number of grid columns.
  int columnsCount;

  /// Number of grid rows.
  int rowsCount;

  /// JSON-encoded List<CardConfig> — the card layout for this profile.
  String cardsJson;

  /// When this profile was created.
  DateTime createdAt;

  /// Returns a shallow copy of this [DashboardProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DashboardProfile copyWith({
    int? id,
    String? name,
    String? slug,
    bool? isActive,
    String? themeId,
    String? cardFilterJson,
    String? scheduleJson,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    String? cardsJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DashboardProfile',
      if (id != null) 'id': id,
      'name': name,
      'slug': slug,
      'isActive': isActive,
      if (themeId != null) 'themeId': themeId,
      'cardFilterJson': cardFilterJson,
      if (scheduleJson != null) 'scheduleJson': scheduleJson,
      'sortOrder': sortOrder,
      'columnsCount': columnsCount,
      'rowsCount': rowsCount,
      'cardsJson': cardsJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DashboardProfileImpl extends DashboardProfile {
  _DashboardProfileImpl({
    int? id,
    required String name,
    required String slug,
    bool? isActive,
    String? themeId,
    String? cardFilterJson,
    String? scheduleJson,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    required String cardsJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         name: name,
         slug: slug,
         isActive: isActive,
         themeId: themeId,
         cardFilterJson: cardFilterJson,
         scheduleJson: scheduleJson,
         sortOrder: sortOrder,
         columnsCount: columnsCount,
         rowsCount: rowsCount,
         cardsJson: cardsJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DashboardProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DashboardProfile copyWith({
    Object? id = _Undefined,
    String? name,
    String? slug,
    bool? isActive,
    Object? themeId = _Undefined,
    String? cardFilterJson,
    Object? scheduleJson = _Undefined,
    int? sortOrder,
    int? columnsCount,
    int? rowsCount,
    String? cardsJson,
    DateTime? createdAt,
  }) {
    return DashboardProfile(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isActive: isActive ?? this.isActive,
      themeId: themeId is String? ? themeId : this.themeId,
      cardFilterJson: cardFilterJson ?? this.cardFilterJson,
      scheduleJson: scheduleJson is String? ? scheduleJson : this.scheduleJson,
      sortOrder: sortOrder ?? this.sortOrder,
      columnsCount: columnsCount ?? this.columnsCount,
      rowsCount: rowsCount ?? this.rowsCount,
      cardsJson: cardsJson ?? this.cardsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
