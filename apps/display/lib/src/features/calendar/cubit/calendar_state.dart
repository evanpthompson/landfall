import 'package:landfall_shared/landfall_shared.dart';

sealed class CalendarState {
  const CalendarState();
}

final class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

final class CalendarLoaded extends CalendarState {
  const CalendarLoaded({
    required this.events,
    required this.fetchedAt,
    this.isStale = false,
  });

  final List<CalendarEventEntity> events;

  /// When these events were last fetched successfully.
  final DateTime fetchedAt;

  /// True when a later refresh failed and these events are being kept on
  /// screen anyway. A wall display that silently shows week-old events is
  /// indistinguishable from one that is up to date, which is how "the
  /// calendar froze" gets reported.
  final bool isStale;

  CalendarLoaded copyWith({bool? isStale}) => CalendarLoaded(
        events: events,
        fetchedAt: fetchedAt,
        isStale: isStale ?? this.isStale,
      );
}

final class CalendarEmpty extends CalendarState {
  const CalendarEmpty();
}

final class CalendarError extends CalendarState {
  const CalendarError(this.message);
  final String message;
}
