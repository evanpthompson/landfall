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

/// A card displayed on a Landfall board.
/// Named CardRow to distinguish from the client-side Card domain model.
abstract class CardRow implements _i1.SerializableModel {
  CardRow._({
    this.id,
    required this.externalId,
    required this.source,
    required this.title,
    this.body,
    this.dataJson,
    this.actionsJson,
    String? layout,
    String? priority,
    this.expiresAt,
    bool? persistent,
    this.dismissedAt,
    required this.createdAt,
  }) : layout = layout ?? 'medium',
       priority = priority ?? 'normal',
       persistent = persistent ?? false;

  factory CardRow({
    int? id,
    required String externalId,
    required String source,
    required String title,
    String? body,
    String? dataJson,
    String? actionsJson,
    String? layout,
    String? priority,
    DateTime? expiresAt,
    bool? persistent,
    DateTime? dismissedAt,
    required DateTime createdAt,
  }) = _CardRowImpl;

  factory CardRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return CardRow(
      id: jsonSerialization['id'] as int?,
      externalId: jsonSerialization['externalId'] as String,
      source: jsonSerialization['source'] as String,
      title: jsonSerialization['title'] as String,
      body: jsonSerialization['body'] as String?,
      dataJson: jsonSerialization['dataJson'] as String?,
      actionsJson: jsonSerialization['actionsJson'] as String?,
      layout: jsonSerialization['layout'] as String?,
      priority: jsonSerialization['priority'] as String?,
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      persistent: jsonSerialization['persistent'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['persistent']),
      dismissedAt: jsonSerialization['dismissedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dismissedAt'],
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Agent-facing UUID. Stable across updates — re-pushing with the same
  /// externalId replaces the card rather than creating a duplicate.
  String externalId;

  /// Identifies the origin of this card.
  /// Convention: "system.<widget>" or "agent.<name>" or "skill.<name>"
  String source;

  /// Primary display text.
  String title;

  /// Secondary display text. Optional.
  String? body;

  /// Structured data for rich rendering, serialized as JSON string.
  String? dataJson;

  /// Card actions serialized as a JSON array of CardAction objects.
  String? actionsJson;

  /// Size hint for the display layout engine.
  /// Values: small | medium | large | full | ticker
  String layout;

  /// Controls default TTL when expiresAt is null and persistent is false.
  /// Values: ephemeral (2h) | normal (24h) | persistent (never)
  String priority;

  /// Explicit expiry timestamp. When set, overrides priority-based default TTL.
  DateTime? expiresAt;

  /// When true, never auto-expires. Overrides expiresAt and priority.
  bool persistent;

  /// Set when the user manually dismisses this card.
  /// Non-null = card is in history, not on active display.
  DateTime? dismissedAt;

  /// When this card was first created / pushed.
  DateTime createdAt;

  /// Returns a shallow copy of this [CardRow]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CardRow copyWith({
    int? id,
    String? externalId,
    String? source,
    String? title,
    String? body,
    String? dataJson,
    String? actionsJson,
    String? layout,
    String? priority,
    DateTime? expiresAt,
    bool? persistent,
    DateTime? dismissedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CardRow',
      if (id != null) 'id': id,
      'externalId': externalId,
      'source': source,
      'title': title,
      if (body != null) 'body': body,
      if (dataJson != null) 'dataJson': dataJson,
      if (actionsJson != null) 'actionsJson': actionsJson,
      'layout': layout,
      'priority': priority,
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      'persistent': persistent,
      if (dismissedAt != null) 'dismissedAt': dismissedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CardRowImpl extends CardRow {
  _CardRowImpl({
    int? id,
    required String externalId,
    required String source,
    required String title,
    String? body,
    String? dataJson,
    String? actionsJson,
    String? layout,
    String? priority,
    DateTime? expiresAt,
    bool? persistent,
    DateTime? dismissedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         externalId: externalId,
         source: source,
         title: title,
         body: body,
         dataJson: dataJson,
         actionsJson: actionsJson,
         layout: layout,
         priority: priority,
         expiresAt: expiresAt,
         persistent: persistent,
         dismissedAt: dismissedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [CardRow]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CardRow copyWith({
    Object? id = _Undefined,
    String? externalId,
    String? source,
    String? title,
    Object? body = _Undefined,
    Object? dataJson = _Undefined,
    Object? actionsJson = _Undefined,
    String? layout,
    String? priority,
    Object? expiresAt = _Undefined,
    bool? persistent,
    Object? dismissedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return CardRow(
      id: id is int? ? id : this.id,
      externalId: externalId ?? this.externalId,
      source: source ?? this.source,
      title: title ?? this.title,
      body: body is String? ? body : this.body,
      dataJson: dataJson is String? ? dataJson : this.dataJson,
      actionsJson: actionsJson is String? ? actionsJson : this.actionsJson,
      layout: layout ?? this.layout,
      priority: priority ?? this.priority,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      persistent: persistent ?? this.persistent,
      dismissedAt: dismissedAt is DateTime? ? dismissedAt : this.dismissedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
