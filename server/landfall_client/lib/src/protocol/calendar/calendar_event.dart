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

/// A calendar event cached from an external provider.
///
/// Events are scoped to a LinkedCredential + calendarId pair.
/// On each refresh, all events for a given credential are replaced.
/// All-day events have startTime and endTime set to midnight UTC of the event date.
abstract class CalendarEvent implements _i1.SerializableModel {
  CalendarEvent._({
    this.id,
    required this.credentialId,
    required this.calendarId,
    required this.calendarName,
    required this.externalEventId,
    required this.title,
    required this.startTime,
    required this.endTime,
    bool? isAllDay,
    this.location,
    this.description,
    required this.fetchedAt,
  }) : isAllDay = isAllDay ?? false;

  factory CalendarEvent({
    int? id,
    required int credentialId,
    required String calendarId,
    required String calendarName,
    required String externalEventId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    bool? isAllDay,
    String? location,
    String? description,
    required DateTime fetchedAt,
  }) = _CalendarEventImpl;

  factory CalendarEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return CalendarEvent(
      id: jsonSerialization['id'] as int?,
      credentialId: jsonSerialization['credentialId'] as int,
      calendarId: jsonSerialization['calendarId'] as String,
      calendarName: jsonSerialization['calendarName'] as String,
      externalEventId: jsonSerialization['externalEventId'] as String,
      title: jsonSerialization['title'] as String,
      startTime: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['startTime'],
      ),
      endTime: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endTime']),
      isAllDay: jsonSerialization['isAllDay'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isAllDay']),
      location: jsonSerialization['location'] as String?,
      description: jsonSerialization['description'] as String?,
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The LinkedCredential this event was fetched from.
  int credentialId;

  /// Provider-assigned calendar ID within the account.
  /// e.g. "primary", "user@example.com", or a long opaque Google calendar ID.
  String calendarId;

  /// Human-readable calendar name, e.g. "Work", "Family", "Shared".
  String calendarName;

  /// Provider-assigned event ID. Stable across refreshes for the same event.
  String externalEventId;

  /// Event title / summary.
  String title;

  /// Start time in UTC. For all-day events, midnight UTC of the event date.
  DateTime startTime;

  /// End time in UTC. For all-day events, midnight UTC of the day after the event.
  DateTime endTime;

  /// True for all-day events (no specific time).
  bool isAllDay;

  /// Optional location string.
  String? location;

  /// Optional event description / notes.
  String? description;

  /// When this event was last fetched from the upstream provider.
  DateTime fetchedAt;

  /// Returns a shallow copy of this [CalendarEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CalendarEvent copyWith({
    int? id,
    int? credentialId,
    String? calendarId,
    String? calendarName,
    String? externalEventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? location,
    String? description,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CalendarEvent',
      if (id != null) 'id': id,
      'credentialId': credentialId,
      'calendarId': calendarId,
      'calendarName': calendarName,
      'externalEventId': externalEventId,
      'title': title,
      'startTime': startTime.toJson(),
      'endTime': endTime.toJson(),
      'isAllDay': isAllDay,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CalendarEventImpl extends CalendarEvent {
  _CalendarEventImpl({
    int? id,
    required int credentialId,
    required String calendarId,
    required String calendarName,
    required String externalEventId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    bool? isAllDay,
    String? location,
    String? description,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         credentialId: credentialId,
         calendarId: calendarId,
         calendarName: calendarName,
         externalEventId: externalEventId,
         title: title,
         startTime: startTime,
         endTime: endTime,
         isAllDay: isAllDay,
         location: location,
         description: description,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [CalendarEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CalendarEvent copyWith({
    Object? id = _Undefined,
    int? credentialId,
    String? calendarId,
    String? calendarName,
    String? externalEventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    Object? location = _Undefined,
    Object? description = _Undefined,
    DateTime? fetchedAt,
  }) {
    return CalendarEvent(
      id: id is int? ? id : this.id,
      credentialId: credentialId ?? this.credentialId,
      calendarId: calendarId ?? this.calendarId,
      calendarName: calendarName ?? this.calendarName,
      externalEventId: externalEventId ?? this.externalEventId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location is String? ? location : this.location,
      description: description is String? ? description : this.description,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
