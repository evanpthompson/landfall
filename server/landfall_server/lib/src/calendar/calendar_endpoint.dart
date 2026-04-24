import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Serves cached calendar events to the Flutter display client.
///
/// Events are populated by [CalendarRefreshCall] on a 15-minute schedule.
/// Returns an empty list gracefully if no credentials have been connected yet.
class CalendarEndpoint extends Endpoint {
  /// Returns the next 20 upcoming events across all active calendar feeds,
  /// sorted by start time.
  Future<List<CalendarEvent>> getUpcomingEvents(Session session) async {
    const clampedLimit = 20;
    final now = DateTime.now().toUtc();

    return CalendarEvent.db.find(
      session,
      where: (t) => t.startTime > now,
      orderBy: (t) => t.startTime,
      orderDescending: false,
      limit: clampedLimit,
    );
  }
}
