import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 4, 24, 9, 0);
  final later = DateTime.utc(2026, 4, 24, 10, 0);

  final event = CalendarEventEntity(
    id: 1,
    credentialId: 42,
    calendarId: 'primary',
    calendarName: 'Work',
    externalEventId: 'abc123',
    title: 'Standup',
    startTime: now,
    endTime: later,
    isAllDay: false,
  );

  group('CalendarEventEntity', () {
    test('equality uses key fields', () {
      final same = CalendarEventEntity(
        id: 1,
        credentialId: 42,
        calendarId: 'primary',
        calendarName: 'Work',
        externalEventId: 'abc123',
        title: 'Standup',
        startTime: now,
        endTime: later,
        isAllDay: false,
        location: 'Room 1',
      );
      // location is not part of equality
      expect(event, equals(same));
    });

    test('inequality on different externalEventId', () {
      final other = CalendarEventEntity(
        id: 2,
        credentialId: 42,
        calendarId: 'primary',
        calendarName: 'Work',
        externalEventId: 'xyz999',
        title: 'Standup',
        startTime: now,
        endTime: later,
        isAllDay: false,
      );
      expect(event, isNot(equals(other)));
    });

    test('toString includes calendar and title', () {
      expect(event.toString(), contains('Work'));
      expect(event.toString(), contains('Standup'));
    });
  });
}
