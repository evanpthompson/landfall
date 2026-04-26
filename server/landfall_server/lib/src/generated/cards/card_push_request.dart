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

/// Request payload for pushing a card to the display.
/// All fields except source and title are optional.
abstract class CardPushRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CardPushRequest._({
    required this.source,
    required this.title,
    this.body,
    this.dataJson,
    this.actionsJson,
    this.layout,
    this.priority,
    this.expiresAt,
    this.persistent,
    this.externalId,
  });

  factory CardPushRequest({
    required String source,
    required String title,
    String? body,
    String? dataJson,
    String? actionsJson,
    String? layout,
    String? priority,
    DateTime? expiresAt,
    bool? persistent,
    String? externalId,
  }) = _CardPushRequestImpl;

  factory CardPushRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return CardPushRequest(
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
      externalId: jsonSerialization['externalId'] as String?,
    );
  }

  /// Identifies the origin. Convention: "agent.<name>" or "skill.<name>"
  String source;

  /// Primary display text.
  String title;

  /// Secondary display text.
  String? body;

  /// Structured data for rich rendering, serialized as JSON string.
  String? dataJson;

  /// Card actions serialized as a JSON array of CardAction objects.
  String? actionsJson;

  /// Size hint. Values: small | medium | large | full | ticker. Defaults to medium.
  String? layout;

  /// Priority tier. Values: ephemeral | normal | persistent. Defaults to normal.
  String? priority;

  /// Explicit expiry timestamp. Omit to use priority-based default TTL.
  DateTime? expiresAt;

  /// When true, card never auto-expires. Defaults to false.
  bool? persistent;

  /// Optional stable ID. When provided, re-pushing replaces the existing card.
  /// When omitted, a new UUID is generated server-side.
  String? externalId;

  /// Returns a shallow copy of this [CardPushRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CardPushRequest copyWith({
    String? source,
    String? title,
    String? body,
    String? dataJson,
    String? actionsJson,
    String? layout,
    String? priority,
    DateTime? expiresAt,
    bool? persistent,
    String? externalId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CardPushRequest',
      'source': source,
      'title': title,
      if (body != null) 'body': body,
      if (dataJson != null) 'dataJson': dataJson,
      if (actionsJson != null) 'actionsJson': actionsJson,
      if (layout != null) 'layout': layout,
      if (priority != null) 'priority': priority,
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (persistent != null) 'persistent': persistent,
      if (externalId != null) 'externalId': externalId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CardPushRequest',
      'source': source,
      'title': title,
      if (body != null) 'body': body,
      if (dataJson != null) 'dataJson': dataJson,
      if (actionsJson != null) 'actionsJson': actionsJson,
      if (layout != null) 'layout': layout,
      if (priority != null) 'priority': priority,
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (persistent != null) 'persistent': persistent,
      if (externalId != null) 'externalId': externalId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CardPushRequestImpl extends CardPushRequest {
  _CardPushRequestImpl({
    required String source,
    required String title,
    String? body,
    String? dataJson,
    String? actionsJson,
    String? layout,
    String? priority,
    DateTime? expiresAt,
    bool? persistent,
    String? externalId,
  }) : super._(
         source: source,
         title: title,
         body: body,
         dataJson: dataJson,
         actionsJson: actionsJson,
         layout: layout,
         priority: priority,
         expiresAt: expiresAt,
         persistent: persistent,
         externalId: externalId,
       );

  /// Returns a shallow copy of this [CardPushRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CardPushRequest copyWith({
    String? source,
    String? title,
    Object? body = _Undefined,
    Object? dataJson = _Undefined,
    Object? actionsJson = _Undefined,
    Object? layout = _Undefined,
    Object? priority = _Undefined,
    Object? expiresAt = _Undefined,
    Object? persistent = _Undefined,
    Object? externalId = _Undefined,
  }) {
    return CardPushRequest(
      source: source ?? this.source,
      title: title ?? this.title,
      body: body is String? ? body : this.body,
      dataJson: dataJson is String? ? dataJson : this.dataJson,
      actionsJson: actionsJson is String? ? actionsJson : this.actionsJson,
      layout: layout is String? ? layout : this.layout,
      priority: priority is String? ? priority : this.priority,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      persistent: persistent is bool? ? persistent : this.persistent,
      externalId: externalId is String? ? externalId : this.externalId,
    );
  }
}
