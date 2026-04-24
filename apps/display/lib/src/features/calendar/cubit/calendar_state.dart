import 'package:landfall_shared/landfall_shared.dart';

sealed class CalendarState {
  const CalendarState();
}

final class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

final class CalendarLoaded extends CalendarState {
  const CalendarLoaded({required this.events});
  final List<CalendarEventEntity> events;
}

final class CalendarEmpty extends CalendarState {
  const CalendarEmpty();
}

final class CalendarError extends CalendarState {
  const CalendarError(this.message);
  final String message;
}
