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

/// Server-side record of a display's user-configurable settings.
/// Excludes device-local fields (serverUrl, wizardComplete, displayId-generation)
/// which have no meaning when edited remotely.
/// One row per displayId — upserted by the display app on startup and on every
/// TV-local edit; pulled by the web settings UI to populate WebDisplayTab.
abstract class RemoteDisplaySettings implements _i1.SerializableModel {
  RemoteDisplaySettings._({
    this.id,
    required this.displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    this.photoSourceJson,
    required this.updatedAt,
  }) : dimEnabled = dimEnabled ?? true,
       dimStartHour = dimStartHour ?? 22,
       dimEndHour = dimEndHour ?? 7,
       dimLevel = dimLevel ?? 0.85,
       locationName = locationName ?? '';

  factory RemoteDisplaySettings({
    int? id,
    required String displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    String? photoSourceJson,
    required DateTime updatedAt,
  }) = _RemoteDisplaySettingsImpl;

  factory RemoteDisplaySettings.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RemoteDisplaySettings(
      id: jsonSerialization['id'] as int?,
      displayId: jsonSerialization['displayId'] as String,
      dimEnabled: jsonSerialization['dimEnabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['dimEnabled']),
      dimStartHour: jsonSerialization['dimStartHour'] as int?,
      dimEndHour: jsonSerialization['dimEndHour'] as int?,
      dimLevel: (jsonSerialization['dimLevel'] as num?)?.toDouble(),
      locationName: jsonSerialization['locationName'] as String?,
      photoSourceJson: jsonSerialization['photoSourceJson'] as String?,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The stable display identifier this record belongs to.
  String displayId;

  /// Whether the scheduled dim mode is active.
  bool dimEnabled;

  /// Hour (0–23) at which dimming begins.
  int dimStartHour;

  /// Hour (0–23) at which dimming ends (display brightens).
  int dimEndHour;

  /// Opacity of the dim overlay (0.0 = transparent, 1.0 = fully black).
  double dimLevel;

  /// Optional display-name override for the weather card location label.
  String locationName;

  /// JSON-encoded PhotoSource. Null = default (Serverpod).
  String? photoSourceJson;

  /// When this record was last written. Used for last-write-wins conflict resolution.
  DateTime updatedAt;

  /// Returns a shallow copy of this [RemoteDisplaySettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RemoteDisplaySettings copyWith({
    int? id,
    String? displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    String? photoSourceJson,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RemoteDisplaySettings',
      if (id != null) 'id': id,
      'displayId': displayId,
      'dimEnabled': dimEnabled,
      'dimStartHour': dimStartHour,
      'dimEndHour': dimEndHour,
      'dimLevel': dimLevel,
      'locationName': locationName,
      if (photoSourceJson != null) 'photoSourceJson': photoSourceJson,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RemoteDisplaySettingsImpl extends RemoteDisplaySettings {
  _RemoteDisplaySettingsImpl({
    int? id,
    required String displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    String? photoSourceJson,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         displayId: displayId,
         dimEnabled: dimEnabled,
         dimStartHour: dimStartHour,
         dimEndHour: dimEndHour,
         dimLevel: dimLevel,
         locationName: locationName,
         photoSourceJson: photoSourceJson,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [RemoteDisplaySettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RemoteDisplaySettings copyWith({
    Object? id = _Undefined,
    String? displayId,
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    Object? photoSourceJson = _Undefined,
    DateTime? updatedAt,
  }) {
    return RemoteDisplaySettings(
      id: id is int? ? id : this.id,
      displayId: displayId ?? this.displayId,
      dimEnabled: dimEnabled ?? this.dimEnabled,
      dimStartHour: dimStartHour ?? this.dimStartHour,
      dimEndHour: dimEndHour ?? this.dimEndHour,
      dimLevel: dimLevel ?? this.dimLevel,
      locationName: locationName ?? this.locationName,
      photoSourceJson: photoSourceJson is String?
          ? photoSourceJson
          : this.photoSourceJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
