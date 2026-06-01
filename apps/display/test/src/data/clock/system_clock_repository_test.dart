import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:display/src/data/clock/system_clock_repository.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  // Tiny tick so the periodic stream emits quickly in tests.
  const fastTick = Duration(milliseconds: 10);

  group('SystemClockRepository', () {
    test('emits device-local time when no location is set', () async {
      final fixed = DateTime(2026, 6, 1, 9, 30, 0);
      final repo = SystemClockRepository(
        localNow: () => fixed,
        tick: fastTick,
      );

      final entity = await repo.clockStream().first;

      expect(entity.now, fixed);
    });

    test('emits time in the configured zone when aligned', () async {
      final chicago = tz.getLocation('America/Chicago');
      final repo = SystemClockRepository(location: chicago, tick: fastTick);

      final entity = await repo.clockStream().first;

      expect(entity.now, isA<tz.TZDateTime>());
      expect((entity.now as tz.TZDateTime).location.name, 'America/Chicago');
    });

    test('alignTo switches the zone for subsequent ticks', () async {
      final repo = SystemClockRepository(tick: fastTick);
      // Device-local before alignment.
      expect(await repo.clockStream().first, isNotNull);

      repo.alignTo(tz.getLocation('America/Chicago'));
      final entity = await repo.clockStream().first;

      expect((entity.now as tz.TZDateTime).location.name, 'America/Chicago');
    });

    test('alignTo(null) restores device-local time', () async {
      final repo = SystemClockRepository(
        location: tz.getLocation('America/Chicago'),
        tick: fastTick,
      );
      repo.alignTo(null);

      final entity = await repo.clockStream().first;

      expect(entity.now, isNot(isA<tz.TZDateTime>()));
    });
  });
}
