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

  group('CmaMemoryWatchdog cooldown', () {
    test('does not reclaim again on the next tick under sustained pressure',
        () {
      // The Pi sits below the threshold more or less permanently — its own
      // framebuffer is CMA. Reclaiming on every tick meant purging and
      // re-uploading every texture every 15 seconds, which is the stall the
      // watchdog was supposed to prevent.
      var reclaimed = 0;
      var now = DateTime(2026, 9, 19, 12);
      final watchdog = CmaMemoryWatchdog(
        pressureThreshold: 0.15,
        reclaimCooldown: const Duration(minutes: 5),
        read: () => const CmaStatus(totalKb: 1000, freeKb: 4),
        reclaim: () => reclaimed++,
        now: () => now,
      );

      expect(watchdog.tick(), isTrue);
      now = now.add(const Duration(seconds: 15));
      expect(watchdog.tick(), isFalse);
      now = now.add(const Duration(seconds: 15));
      expect(watchdog.tick(), isFalse);
      expect(reclaimed, 1);
    });

    test('reclaims again once the cooldown has elapsed', () {
      var reclaimed = 0;
      var now = DateTime(2026, 9, 19, 12);
      final watchdog = CmaMemoryWatchdog(
        pressureThreshold: 0.15,
        reclaimCooldown: const Duration(minutes: 5),
        read: () => const CmaStatus(totalKb: 1000, freeKb: 4),
        reclaim: () => reclaimed++,
        now: () => now,
      );

      expect(watchdog.tick(), isTrue);
      now = now.add(const Duration(minutes: 5));
      expect(watchdog.tick(), isTrue);
      expect(reclaimed, 2);
    });

    test('re-arms immediately when free memory recovers', () {
      var reclaimed = 0;
      var freeKb = 40; // 4% — under pressure
      var now = DateTime(2026, 9, 19, 12);
      final watchdog = CmaMemoryWatchdog(
        pressureThreshold: 0.15,
        recoveryThreshold: 0.25,
        reclaimCooldown: const Duration(minutes: 5),
        read: () => CmaStatus(totalKb: 1000, freeKb: freeKb),
        reclaim: () => reclaimed++,
        now: () => now,
      );

      expect(watchdog.tick(), isTrue);
      freeKb = 300; // 30% — recovered past the upper threshold
      now = now.add(const Duration(seconds: 15));
      expect(watchdog.tick(), isFalse);
      freeKb = 40; // pressure returns
      now = now.add(const Duration(seconds: 15));
      expect(
        watchdog.tick(),
        isTrue,
        reason: 'a genuine new pressure episode should not wait out the '
            'cooldown',
      );
      expect(reclaimed, 2);
    });

    test('does not re-arm inside the hysteresis band', () {
      var reclaimed = 0;
      var freeKb = 40;
      var now = DateTime(2026, 9, 19, 12);
      final watchdog = CmaMemoryWatchdog(
        pressureThreshold: 0.15,
        recoveryThreshold: 0.25,
        reclaimCooldown: const Duration(minutes: 5),
        read: () => CmaStatus(totalKb: 1000, freeKb: freeKb),
        reclaim: () => reclaimed++,
        now: () => now,
      );

      expect(watchdog.tick(), isTrue);
      freeKb = 200; // 20% — above pressure, below recovery
      now = now.add(const Duration(seconds: 15));
      expect(watchdog.tick(), isFalse);
      freeKb = 40;
      now = now.add(const Duration(seconds: 15));
      expect(
        watchdog.tick(),
        isFalse,
        reason: 'hovering around the threshold is the same episode, not a '
            'new one',
      );
      expect(reclaimed, 1);
    });
  });

  group('CmaMemoryWatchdog.start/stop', () {
    test('keeps polling but rate-limits reclaims under sustained pressure', () {
      fakeAsync((async) {
        var reclaimed = 0;
        var reads = 0;
        final watchdog = CmaMemoryWatchdog(
          pressureThreshold: 0.15,
          reclaimCooldown: const Duration(minutes: 5),
          read: () {
            reads++;
            return const CmaStatus(totalKb: 1000, freeKb: 10);
          },
          reclaim: () => reclaimed++,
        );
        watchdog.start(interval: const Duration(seconds: 15));
        async.elapse(const Duration(seconds: 46)); // 3 ticks
        expect(reads, 3, reason: 'the watchdog must keep watching');
        expect(reclaimed, 1, reason: 'but reclaim at most once per cooldown');
        watchdog.stop();
        async.elapse(const Duration(minutes: 10));
        expect(reads, 3, reason: 'stop() must cancel the timer');
      });
    });
  });
}
