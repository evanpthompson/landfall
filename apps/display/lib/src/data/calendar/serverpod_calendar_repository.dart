import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// Fetches upcoming calendar events from the Serverpod server.
///
/// No local cache — the server is the cache (refreshed every 15 minutes).
/// Returns an empty list gracefully if no credentials have been connected yet
/// or the server is unreachable.
class ServerpodCalendarRepository implements CalendarRepository {
  ServerpodCalendarRepository(this._client);

  final Client _client;

  @override
  Future<List<CalendarEventEntity>> getUpcomingEvents() async {
    try {
      final rows = await _client.calendar.getUpcomingEvents();
      return rows.map(_toEntity).toList();
    } catch (_) {
      return [];
    }
  }

  CalendarEventEntity _toEntity(CalendarEvent row) => CalendarEventEntity(
        id: row.id!,
        credentialId: row.credentialId,
        calendarId: row.calendarId,
        calendarName: row.calendarName,
        externalEventId: row.externalEventId,
        title: row.title,
        startTime: row.startTime,
        endTime: row.endTime,
        isAllDay: row.isAllDay,
        location: row.location,
        description: row.description,
      );
}
