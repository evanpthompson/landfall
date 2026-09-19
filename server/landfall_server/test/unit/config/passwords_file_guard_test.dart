import 'package:test/test.dart';

import 'package:landfall_server/src/config/passwords_file_guard.dart';

void main() {
  group('resolveRunMode', () {
    test('reads --mode', () {
      expect(resolveRunMode(['--mode', 'production'], environment: {}),
          'production');
    });

    test('reads -m', () {
      expect(resolveRunMode(['-m', 'staging'], environment: {}), 'staging');
    });

    test('reads --mode=value', () {
      expect(resolveRunMode(['--mode=production'], environment: {}),
          'production');
    });

    test('falls back to SERVERPOD_RUN_MODE', () {
      expect(
        resolveRunMode([], environment: {'SERVERPOD_RUN_MODE': 'production'}),
        'production',
      );
    });

    test('command line wins over the environment', () {
      expect(
        resolveRunMode(
          ['-m', 'development'],
          environment: {'SERVERPOD_RUN_MODE': 'production'},
        ),
        'development',
      );
    });

    test('defaults to development', () {
      expect(resolveRunMode([], environment: {}), 'development');
    });
  });

  group('passwordsFileVerdict', () {
    // 0x4 is the world-read bit of the low octet.
    const worldReadable = 0x81A4; // 100644
    const ownerOnly = 0x8180; // 100600

    test('passes a 600 file in every mode', () {
      for (final mode in ['development', 'test', 'staging', 'production']) {
        expect(
          passwordsFileVerdict(mode: ownerOnly, runMode: mode),
          PasswordsFileVerdict.ok,
          reason: mode,
        );
      }
    });

    test('refuses to start in production when world-readable', () {
      expect(
        passwordsFileVerdict(mode: worldReadable, runMode: 'production'),
        PasswordsFileVerdict.refuse,
      );
    });

    test('refuses in staging too — it holds real secrets', () {
      expect(
        passwordsFileVerdict(mode: worldReadable, runMode: 'staging'),
        PasswordsFileVerdict.refuse,
      );
    });

    test('warns but continues in development, where recovery matters', () {
      expect(
        passwordsFileVerdict(mode: worldReadable, runMode: 'development'),
        PasswordsFileVerdict.warn,
      );
      expect(
        passwordsFileVerdict(mode: worldReadable, runMode: 'test'),
        PasswordsFileVerdict.warn,
      );
    });

    test('treats an unrecognised run mode as production', () {
      // Fail closed: an unknown mode is not a licence to keep going.
      expect(
        passwordsFileVerdict(mode: worldReadable, runMode: 'whatever'),
        PasswordsFileVerdict.refuse,
      );
    });
  });
}
