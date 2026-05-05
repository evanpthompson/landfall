import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

CalendarEvent _event({
  int credentialId = 1,
  String calendarId = 'primary',
  String calendarName = 'My Calendar',
  String? externalEventId,
  String title = 'Team Standup',
  required DateTime startTime,
  Duration duration = const Duration(hours: 1),
  bool isAllDay = false,
  String? location,
}) {
  final now = DateTime.now().toUtc();
  return CalendarEvent(
    credentialId: credentialId,
    calendarId: calendarId,
    calendarName: calendarName,
    externalEventId: externalEventId ?? 'evt_${startTime.millisecondsSinceEpoch}',
    title: title,
    startTime: startTime,
    endTime: startTime.add(duration),
    isAllDay: isAllDay,
    location: location,
    fetchedAt: now,
  );
}

void main() {
  withServerpod('Given CalendarEndpoint', (sessionBuilder, endpoints) {
    late TestSessionBuilder authed;

    setUp(() async {
      authed = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo('user-1', {}),
      );
      final session = sessionBuilder.build();
      await CalendarEvent.db.deleteWhere(
        session,
        where: (t) => t.id > 0,
      );
      await session.close();
    });

    group('getUpcomingEvents', () {
      test('returns empty list when no events exist', () async {
        final result = await endpoints.calendar.getUpcomingEvents(authed);
        expect(result, isEmpty);
      });

      test('returns future events', () async {
        final session = sessionBuilder.build();
        final tomorrow = DateTime.now().toUtc().add(const Duration(days: 1));
        await CalendarEvent.db.insertRow(
          session,
          _event(title: 'Future Event', startTime: tomorrow),
        );
        await session.close();

        final result =
            await endpoints.calendar.getUpcomingEvents(authed);

        expect(result, hasLength(1));
        expect(result.first.title, equals('Future Event'));
      });

      test('excludes past events', () async {
        final session = sessionBuilder.build();
        final yesterday =
            DateTime.now().toUtc().subtract(const Duration(days: 1));
        await CalendarEvent.db.insertRow(
          session,
          _event(title: 'Past Event', startTime: yesterday),
        );
        await session.close();

        final result =
            await endpoints.calendar.getUpcomingEvents(authed);

        expect(result, isEmpty);
      });

      test('returns events ordered by start time ascending', () async {
        final session = sessionBuilder.build();
        final base = DateTime.now().toUtc().add(const Duration(hours: 1));

        await CalendarEvent.db.insert(session, [
          _event(title: 'Third', startTime: base.add(const Duration(hours: 2))),
          _event(title: 'First', startTime: base),
          _event(title: 'Second', startTime: base.add(const Duration(hours: 1))),
        ]);
        await session.close();

        final result =
            await endpoints.calendar.getUpcomingEvents(authed);

        expect(result.length, equals(3));
        expect(result[0].title, equals('First'));
        expect(result[1].title, equals('Second'));
        expect(result[2].title, equals('Third'));
      });

      test('caps results at 20 events', () async {
        final session = sessionBuilder.build();
        final base = DateTime.now().toUtc().add(const Duration(hours: 1));

        final events = List.generate(
          25,
          (i) => _event(
            title: 'Event $i',
            startTime: base.add(Duration(hours: i)),
            externalEventId: 'evt_$i',
          ),
        );
        await CalendarEvent.db.insert(session, events);
        await session.close();

        final result =
            await endpoints.calendar.getUpcomingEvents(authed);

        expect(result, hasLength(20));
      });

      test('cap returns the soonest 20 when over limit', () async {
        final session = sessionBuilder.build();
        final base = DateTime.now().toUtc().add(const Duration(hours: 1));

        final events = List.generate(
          25,
          (i) => _event(
            title: 'Event $i',
            startTime: base.add(Duration(hours: i)),
            externalEventId: 'evt_$i',
          ),
        );
        await CalendarEvent.db.insert(session, events);
        await session.close();

        final result =
            await endpoints.calendar.getUpcomingEvents(authed);

        expect(result.first.title, equals('Event 0'));
        expect(result.last.title, equals('Event 19'));
      });

      test('returns all event fields correctly', () async {
        final session = sessionBuilder.build();
        final start =
            DateTime.now().toUtc().add(const Duration(hours: 3));
        await CalendarEvent.db.insertRow(
          session,
          _event(
            title: 'Board Meeting',
            startTime: start,
            calendarName: 'Work',
            location: 'Conference Room A',
            isAllDay: false,
          ),
        );
        await session.close();

        final result =
            await endpoints.calendar.getUpcomingEvents(authed);

        expect(result.first.title, equals('Board Meeting'));
        expect(result.first.calendarName, equals('Work'));
        expect(result.first.location, equals('Conference Room A'));
        expect(result.first.isAllDay, isFalse);
      });

      test('handles events from multiple calendar feeds', () async {
        final session = sessionBuilder.build();
        final base = DateTime.now().toUtc().add(const Duration(hours: 1));

        await CalendarEvent.db.insert(session, [
          _event(
            credentialId: 1,
            calendarName: 'Google Work',
            title: 'Standup',
            startTime: base,
            externalEventId: 'g1',
          ),
          _event(
            credentialId: 2,
            calendarName: 'Microsoft Personal',
            title: 'Dentist',
            startTime: base.add(const Duration(hours: 2)),
            externalEventId: 'ms1',
          ),
        ]);
        await session.close();

        final result =
            await endpoints.calendar.getUpcomingEvents(authed);

        expect(result, hasLength(2));
        expect(
          result.map((e) => e.calendarName).toSet(),
          containsAll(['Google Work', 'Microsoft Personal']),
        );
      });
    });
  });

  // SEC-04: CalendarEndpoint auth guards.
  withServerpod(
    'Given CalendarEndpoint auth guards (SEC-04)',
    (sessionBuilder, endpoints) {
      test('getUpcomingEvents rejects unauthenticated caller', () async {
        expect(
          () => endpoints.calendar.getUpcomingEvents(sessionBuilder),
          throwsA(isA<Exception>()),
        );
      });

      test('authenticated caller can fetch events', () async {
        final authed = sessionBuilder.copyWith(
          authentication:
              AuthenticationOverride.authenticationInfo('user-1', {}),
        );
        final result = await endpoints.calendar.getUpcomingEvents(authed);
        expect(result, isA<List>());
      });
    },
  );
}
