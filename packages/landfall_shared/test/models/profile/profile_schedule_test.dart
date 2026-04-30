import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  // Helper: build a DateTime for a given weekday and time.
  // weekday: 1=Mon … 7=Sun
  DateTime at(int weekday, int hour, int minute) {
    // Find next occurrence of the given weekday from a fixed Monday base.
    // 2026-04-27 is a Monday (weekday 1).
    final base = DateTime(2026, 4, 27);
    final dayOffset = (weekday - 1) % 7;
    return base.add(Duration(days: dayOffset, hours: hour, minutes: minute));
  }

  group('ProfileSchedule.isActiveAt', () {
    group('always', () {
      const schedule = ProfileSchedule(type: ProfileScheduleType.always);

      test('active on weekday', () {
        expect(schedule.isActiveAt(at(1, 9, 0)), isTrue);
      });

      test('active on weekend', () {
        expect(schedule.isActiveAt(at(6, 14, 0)), isTrue);
      });

      test('active at midnight', () {
        expect(schedule.isActiveAt(at(3, 0, 0)), isTrue);
      });
    });

    group('weekday', () {
      const schedule = ProfileSchedule(type: ProfileScheduleType.weekday);

      test('active Monday', () => expect(schedule.isActiveAt(at(1, 10, 0)), isTrue));
      test('active Friday', () => expect(schedule.isActiveAt(at(5, 10, 0)), isTrue));
      test('inactive Saturday', () => expect(schedule.isActiveAt(at(6, 10, 0)), isFalse));
      test('inactive Sunday', () => expect(schedule.isActiveAt(at(7, 10, 0)), isFalse));
    });

    group('weekend', () {
      const schedule = ProfileSchedule(type: ProfileScheduleType.weekend);

      test('inactive Monday', () => expect(schedule.isActiveAt(at(1, 10, 0)), isFalse));
      test('inactive Friday', () => expect(schedule.isActiveAt(at(5, 10, 0)), isFalse));
      test('active Saturday', () => expect(schedule.isActiveAt(at(6, 10, 0)), isTrue));
      test('active Sunday', () => expect(schedule.isActiveAt(at(7, 10, 0)), isTrue));
    });

    group('daily with time window', () {
      const schedule = ProfileSchedule(
        type: ProfileScheduleType.daily,
        startHour: 9,
        endHour: 17,
      );

      test('active at 09:00', () => expect(schedule.isActiveAt(at(1, 9, 0)), isTrue));
      test('active at 16:59', () => expect(schedule.isActiveAt(at(1, 16, 59)), isTrue));
      test('inactive at 17:00', () => expect(schedule.isActiveAt(at(1, 17, 0)), isFalse));
      test('inactive at 08:59', () => expect(schedule.isActiveAt(at(1, 8, 59)), isFalse));
      test('active on weekend too', () => expect(schedule.isActiveAt(at(6, 12, 0)), isTrue));
    });

    group('overnight time window', () {
      const schedule = ProfileSchedule(
        type: ProfileScheduleType.daily,
        startHour: 22,
        endHour: 6,
      );

      test('active at 22:00', () => expect(schedule.isActiveAt(at(1, 22, 0)), isTrue));
      test('active at 23:59', () => expect(schedule.isActiveAt(at(1, 23, 59)), isTrue));
      test('active at 00:00', () => expect(schedule.isActiveAt(at(1, 0, 0)), isTrue));
      test('active at 05:59', () => expect(schedule.isActiveAt(at(1, 5, 59)), isTrue));
      test('inactive at 06:00', () => expect(schedule.isActiveAt(at(1, 6, 0)), isFalse));
      test('inactive at 12:00', () => expect(schedule.isActiveAt(at(1, 12, 0)), isFalse));
    });

    group('custom with specific days', () {
      const schedule = ProfileSchedule(
        type: ProfileScheduleType.custom,
        daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
        startHour: 8,
        endHour: 18,
      );

      test('active Monday 10:00', () => expect(schedule.isActiveAt(at(1, 10, 0)), isTrue));
      test('active Wednesday 10:00', () => expect(schedule.isActiveAt(at(3, 10, 0)), isTrue));
      test('inactive Tuesday 10:00', () => expect(schedule.isActiveAt(at(2, 10, 0)), isFalse));
      test('inactive Monday 07:59', () => expect(schedule.isActiveAt(at(1, 7, 59)), isFalse));
      test('inactive Monday 18:00', () => expect(schedule.isActiveAt(at(1, 18, 0)), isFalse));
    });

    group('custom with null daysOfWeek (all days)', () {
      const schedule = ProfileSchedule(
        type: ProfileScheduleType.custom,
        startHour: 20,
        endHour: 22,
      );

      test('active any day in window', () {
        for (var day = 1; day <= 7; day++) {
          expect(schedule.isActiveAt(at(day, 21, 0)), isTrue,
              reason: 'day $day should be active');
        }
      });
    });
  });

  group('ProfileSchedule JSON round-trip', () {
    test('always type survives round-trip', () {
      const s = ProfileSchedule(type: ProfileScheduleType.always);
      expect(ProfileSchedule.fromJson(s.toJson()), equals(s));
    });

    test('fully specified schedule survives round-trip', () {
      const s = ProfileSchedule(
        type: ProfileScheduleType.custom,
        startHour: 9,
        startMinute: 30,
        endHour: 17,
        endMinute: 45,
        daysOfWeek: [1, 2, 3, 4, 5],
      );
      expect(ProfileSchedule.fromJson(s.toJson()), equals(s));
    });

    test('null optional fields omitted from JSON', () {
      const s = ProfileSchedule(type: ProfileScheduleType.weekday);
      final json = s.toJson();
      expect(json.containsKey('startHour'), isFalse);
      expect(json.containsKey('daysOfWeek'), isFalse);
    });
  });
}
