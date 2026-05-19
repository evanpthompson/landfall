import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/platform/leanback.dart';

void main() {
  group('Leanback', () {
    test('explicit override true wins over platform check', () async {
      final l = Leanback.test(isAndroid: false, override: true);
      expect(await l.isLeanback(), isTrue);
    });

    test('explicit override false wins over Android UI mode', () async {
      // Force-disable on a real Android TV is useful when stress-testing the
      // touch UX on a Fire TV during development.
      final l = Leanback.test(
        isAndroid: true,
        override: false,
        probe: () async => true,
      );
      expect(await l.isLeanback(), isFalse);
    });

    test('non-Android platforms short-circuit and never probe', () async {
      var probeCalled = false;
      final l = Leanback.test(
        isAndroid: false,
        probe: () async {
          probeCalled = true;
          return true;
        },
      );
      expect(await l.isLeanback(), isFalse);
      expect(probeCalled, isFalse);
    });

    test('Android + UI_MODE_TYPE_TELEVISION returns true', () async {
      final l = Leanback.test(isAndroid: true, probe: () async => true);
      expect(await l.isLeanback(), isTrue);
    });

    test('Android + non-television UI mode returns false', () async {
      final l = Leanback.test(isAndroid: true, probe: () async => false);
      expect(await l.isLeanback(), isFalse);
    });

    test('Android + probe throwing PlatformException defaults to false', () async {
      // Defensive: if the native side isn't wired (e.g. an older APK with no
      // MethodChannel handler), assume touch UX rather than crashing.
      final l = Leanback.test(
        isAndroid: true,
        probe: () async => throw Exception('no handler'),
      );
      expect(await l.isLeanback(), isFalse);
    });

    test('Android + probe returning null defaults to false', () async {
      final l = Leanback.test(isAndroid: true, probe: () async => null);
      expect(await l.isLeanback(), isFalse);
    });
  });
}
