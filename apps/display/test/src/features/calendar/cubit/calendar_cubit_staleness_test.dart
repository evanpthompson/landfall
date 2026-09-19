import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/calendar/cubit/calendar_cubit.dart';
import 'package:display/src/features/calendar/cubit/calendar_state.dart';

class _MockCalendarRepository extends Mock implements CalendarRepository {}

final _event = CalendarEventEntity(
  id: 1,
  credentialId: 1,
  calendarId: 'primary',
  calendarName: 'Work',
  externalEventId: 'evt-1',
  title: 'Sprint planning',
  startTime: DateTime.utc(2026, 9, 19, 14),
  endTime: DateTime.utc(2026, 9, 19, 15),
  isAllDay: false,
);

void main() {
  late _MockCalendarRepository repository;
  final fixedNow = DateTime.utc(2026, 9, 19, 12);

  setUp(() => repository = _MockCalendarRepository());

  CalendarCubit build() => CalendarCubit(repository, now: () => fixedNow);

  blocTest<CalendarCubit, CalendarState>(
    'does not blink through loading on a refresh that already has events',
    build: build,
    setUp: () {
      when(() => repository.getUpcomingEvents())
          .thenAnswer((_) async => [_event]);
    },
    act: (c) async {
      await c.loadEvents();
      await c.loadEvents();
    },
    expect: () => [
      isA<CalendarLoading>(),
      isA<CalendarLoaded>(),
      // The 15-minute refresh replaces the data in place. Emitting
      // CalendarLoading again made the card flash a spinner four times an hour.
      isA<CalendarLoaded>(),
    ],
  );

  blocTest<CalendarCubit, CalendarState>(
    'keeps the last events and marks them stale when a refresh fails',
    build: build,
    setUp: () {
      when(() => repository.getUpcomingEvents())
          .thenAnswer((_) async => [_event]);
    },
    act: (c) async {
      await c.loadEvents();
      when(() => repository.getUpcomingEvents())
          .thenThrow(Exception('server unreachable'));
      await c.loadEvents();
    },
    expect: () => [
      isA<CalendarLoading>(),
      isA<CalendarLoaded>().having((s) => s.isStale, 'isStale', isFalse),
      isA<CalendarLoaded>()
          .having((s) => s.isStale, 'isStale', isTrue)
          .having((s) => s.events, 'events', [_event])
          .having((s) => s.fetchedAt, 'fetchedAt', fixedNow),
    ],
  );

  blocTest<CalendarCubit, CalendarState>(
    'still reports an error when the very first load fails',
    build: build,
    setUp: () {
      when(() => repository.getUpcomingEvents())
          .thenThrow(Exception('server unreachable'));
    },
    act: (c) => c.loadEvents(),
    expect: () => [
      isA<CalendarLoading>(),
      isA<CalendarError>(),
    ],
  );

  blocTest<CalendarCubit, CalendarState>(
    'records when the events were fetched',
    build: build,
    setUp: () {
      when(() => repository.getUpcomingEvents())
          .thenAnswer((_) async => [_event]);
    },
    act: (c) => c.loadEvents(),
    expect: () => [
      isA<CalendarLoading>(),
      isA<CalendarLoaded>().having((s) => s.fetchedAt, 'fetchedAt', fixedNow),
    ],
  );
}
