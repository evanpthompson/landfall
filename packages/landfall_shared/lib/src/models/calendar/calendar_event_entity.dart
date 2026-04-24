/// A calendar event from any provider, mapped to a provider-agnostic domain model.
class CalendarEventEntity {
  const CalendarEventEntity({
    required this.id,
    required this.credentialId,
    required this.calendarId,
    required this.calendarName,
    required this.externalEventId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    this.location,
    this.description,
  });

  final int id;

  /// Server-side FK to the LinkedCredential that provided this event.
  final int credentialId;

  /// Provider-assigned calendar ID, e.g. "primary" or a Google calendar ID.
  final String calendarId;

  /// Human-readable calendar name, e.g. "Work", "Family".
  final String calendarName;

  /// Provider-assigned event ID, stable across refreshes.
  final String externalEventId;

  final String title;

  /// UTC start time. For all-day events, midnight UTC of the event date.
  final DateTime startTime;

  /// UTC end time. For all-day events, midnight UTC of the day after the event.
  final DateTime endTime;

  final bool isAllDay;

  final String? location;

  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventEntity &&
          id == other.id &&
          credentialId == other.credentialId &&
          calendarId == other.calendarId &&
          externalEventId == other.externalEventId &&
          title == other.title &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          isAllDay == other.isAllDay;

  @override
  int get hashCode => Object.hash(
        id,
        credentialId,
        calendarId,
        externalEventId,
        title,
        startTime,
        endTime,
        isAllDay,
      );

  @override
  String toString() =>
      'CalendarEventEntity($calendarName: $title, start: $startTime, allDay: $isAllDay)';
}
