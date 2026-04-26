import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  group('DisplaySettings', () {
    test('defaults', () {
      const s = DisplaySettings();
      expect(s.dimEnabled, isTrue);
      expect(s.dimStartHour, 22);
      expect(s.dimEndHour, 7);
      expect(s.dimLevel, 0.85);
      expect(s.locationName, '');
      expect(s.serverUrl, '');
      expect(s.wizardComplete, isFalse);
    });

    test('copyWith overrides only specified fields', () {
      const original = DisplaySettings(
        locationName: 'Seattle',
        serverUrl: 'https://api.example.com/',
        wizardComplete: true,
      );

      final updated = original.copyWith(locationName: 'Portland');

      expect(updated.locationName, 'Portland');
      expect(updated.serverUrl, 'https://api.example.com/');
      expect(updated.wizardComplete, isTrue);
      expect(updated.dimEnabled, original.dimEnabled);
    });

    test('copyWith serverUrl and wizardComplete', () {
      const s = DisplaySettings();
      final updated = s.copyWith(
        serverUrl: 'https://my.landfall.dev/',
        wizardComplete: true,
      );
      expect(updated.serverUrl, 'https://my.landfall.dev/');
      expect(updated.wizardComplete, isTrue);
      expect(updated.locationName, '');
    });

    test('equality — identical instances are equal', () {
      const a = DisplaySettings(serverUrl: 'https://x.com/', wizardComplete: true);
      const b = DisplaySettings(serverUrl: 'https://x.com/', wizardComplete: true);
      expect(a, equals(b));
    });

    test('equality — differs when serverUrl differs', () {
      const a = DisplaySettings(serverUrl: 'https://a.com/');
      const b = DisplaySettings(serverUrl: 'https://b.com/');
      expect(a, isNot(equals(b)));
    });

    test('equality — differs when wizardComplete differs', () {
      const a = DisplaySettings(wizardComplete: false);
      const b = DisplaySettings(wizardComplete: true);
      expect(a, isNot(equals(b)));
    });

    test('hashCode matches for equal instances', () {
      const a = DisplaySettings(serverUrl: 'https://x.com/', wizardComplete: true);
      const b = DisplaySettings(serverUrl: 'https://x.com/', wizardComplete: true);
      expect(a.hashCode, b.hashCode);
    });
  });
}
