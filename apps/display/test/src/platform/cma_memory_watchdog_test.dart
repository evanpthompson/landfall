import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/platform/cma_memory_watchdog.dart';

const _sampleMeminfo = '''
MemTotal:        3885396 kB
MemFree:          120044 kB
Buffers:           45000 kB
CmaTotal:         524288 kB
CmaFree:            1820 kB
''';

void main() {
  group('CmaStatus.parseMeminfo', () {
    test('parses CmaTotal and CmaFree from /proc/meminfo text', () {
      final status = CmaStatus.parseMeminfo(_sampleMeminfo);
      expect(status, isNotNull);
      expect(status!.totalKb, 524288);
      expect(status.freeKb, 1820);
    });

    test('returns null when CMA lines are absent (no-CMA kernel)', () {
      const meminfo = 'MemTotal: 100 kB\nMemFree: 50 kB\n';
      expect(CmaStatus.parseMeminfo(meminfo), isNull);
    });

    test('freeFraction is free / total', () {
      const status = CmaStatus(totalKb: 1000, freeKb: 250);
      expect(status.freeFraction, closeTo(0.25, 1e-9));
    });

    test('freeFraction treats a zero-sized pool as "not under pressure"', () {
      const status = CmaStatus(totalKb: 0, freeKb: 0);
      expect(status.freeFraction, 1.0);
    });
  });

  group('CmaMemoryWatchdog.tick', () {
    test('fires the reclaimer when free is below the threshold', () {
      var reclaimed = 0;
      final watchdog = CmaMemoryWatchdog(
        pressureThreshold: 0.15,
        read: () => const CmaStatus(totalKb: 1000, freeKb: 50), // 5% free
        reclaim: () => reclaimed++,
      );
      expect(watchdog.tick(), isTrue);
      expect(reclaimed, 1);
    });

    test('does not fire when free is above the threshold', () {
      var reclaimed = 0;
      final watchdog = CmaMemoryWatchdog(
        pressureThreshold: 0.15,
        read: () => const CmaStatus(totalKb: 1000, freeKb: 500), // 50% free
        reclaim: () => reclaimed++,
      );
      expect(watchdog.tick(), isFalse);
      expect(reclaimed, 0);
    });

    test('fires at the threshold boundary (at-or-below pressure)', () {
      var reclaimed = 0;
      final watchdog = CmaMemoryWatchdog(
        pressureThreshold: 0.15,
        read: () => const CmaStatus(totalKb: 1000, freeKb: 150), // exactly 15%
        reclaim: () => reclaimed++,
      );
      expect(watchdog.tick(), isTrue);
      expect(reclaimed, 1);
    });

    test('no-ops when CMA is unreadable (null reader, e.g. non-Linux host)', () {
      var reclaimed = 0;
      final watchdog = CmaMemoryWatchdog(
        read: () => null,
        reclaim: () => reclaimed++,
      );
      expect(watchdog.tick(), isFalse);
      expect(reclaimed, 0);
    });
  });

  group('CmaMemoryWatchdog.start/stop', () {
    test('polls on the configured interval and stops cleanly', () {
      fakeAsync((async) {
        var reclaimed = 0;
        final watchdog = CmaMemoryWatchdog(
          pressureThreshold: 0.15,
          read: () => const CmaStatus(totalKb: 1000, freeKb: 10),
          reclaim: () => reclaimed++,
        );
        watchdog.start(interval: const Duration(seconds: 15));
        async.elapse(const Duration(seconds: 46)); // 3 ticks
        expect(reclaimed, 3);
        watchdog.stop();
        async.elapse(const Duration(minutes: 5));
        expect(reclaimed, 3, reason: 'stop() must cancel the timer');
      });
    });
  });
}
