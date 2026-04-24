import 'package:landfall_shared/src/models/calendar/calendar_event_entity.dart';

abstract class CalendarRepository {
  /// Returns upcoming events from all active calendar feeds, sorted by [startTime].
  Future<List<CalendarEventEntity>> getUpcomingEvents();
}
