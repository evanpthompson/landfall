import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Provider-agnostic interface for fetching upcoming calendar events.
///
/// Each calendar provider (Google, Microsoft, Apple/CalDAV) implements this
/// interface. The [CalendarRefreshCall] selects the right implementation at
/// runtime based on [LinkedCredential.provider].
abstract class CalendarService {
  /// Fetches upcoming events for all calendars accessible via [credential].
  ///
  /// Returns events starting from [from] up to [to], across all calendars
  /// visible to the credential. May update [credential] in the database if
  /// the access token is refreshed during the call.
  ///
  /// Throws on unrecoverable errors (e.g., revoked credentials).
  Future<List<CalendarEvent>> fetchUpcomingEvents(
    Session session,
    LinkedCredential credential, {
    required DateTime from,
    required DateTime to,
  });
}
