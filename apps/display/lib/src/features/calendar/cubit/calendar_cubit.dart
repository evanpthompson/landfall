import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'calendar_state.dart';

/// Fetches upcoming calendar events from [CalendarRepository].
///
/// Call [loadEvents] once on startup and periodically (every 15 min) to keep
/// data fresh. The server refreshes its cache on the same cadence, so polling
/// any more frequently would return the same data.
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(this._repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(const CalendarLoading());

  final CalendarRepository _repository;
  final DateTime Function() _now;

  Future<void> loadEvents() async {
    final previous = state;
    // Only show the spinner when there is nothing to show. Emitting it on
    // every 15-minute refresh made the card blink through a loading state
    // four times an hour for no reason.
    if (previous is! CalendarLoaded) {
      emit(const CalendarLoading());
    }
    try {
      final events = await _repository.getUpcomingEvents();
      if (events.isEmpty) {
        emit(const CalendarEmpty());
      } else {
        emit(CalendarLoaded(events: events, fetchedAt: _now()));
      }
    } catch (e) {
      // Keep showing the last events rather than blanking the card, but mark
      // them stale so the display is not claiming they are current.
      if (previous is CalendarLoaded) {
        emit(previous.copyWith(isStale: true));
        return;
      }
      emit(CalendarError(e.toString()));
    }
  }
}
