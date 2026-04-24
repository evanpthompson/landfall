import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'calendar_state.dart';

/// Fetches upcoming calendar events from [CalendarRepository].
///
/// Call [loadEvents] once on startup and periodically (every 15 min) to keep
/// data fresh. The server refreshes its cache on the same cadence, so polling
/// any more frequently would return the same data.
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(this._repository) : super(const CalendarLoading());

  final CalendarRepository _repository;

  Future<void> loadEvents() async {
    emit(const CalendarLoading());
    try {
      final events = await _repository.getUpcomingEvents();
      if (events.isEmpty) {
        emit(const CalendarEmpty());
      } else {
        emit(CalendarLoaded(events: events));
      }
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }
}
