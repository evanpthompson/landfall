import 'package:display/src/app/startup_decision.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

void main() {
  group('resolveStartupDecision', () {
    test('uses integration test server URL first', () {
      final decision = resolveStartupDecision(
        settings: const DisplaySettings(
          serverUrl: 'http://stored:8080/',
          wizardComplete: true,
        ),
        integrationTestServerUrl: 'http://integration:8080/',
        integrationTestWizardMode: false,
        defaultServerUrl: 'http://127.0.0.1:8080/',
      );

      expect(decision.target, StartupTarget.display);
      expect(decision.serverUrl, 'http://integration:8080/');
      expect(decision.persistDefaultSettings, isFalse);
    });

    test('wizard mode forces setup wizard', () {
      final decision = resolveStartupDecision(
        settings: const DisplaySettings(
          serverUrl: 'http://stored:8080/',
          wizardComplete: true,
        ),
        integrationTestServerUrl: '',
        integrationTestWizardMode: true,
        defaultServerUrl: 'http://127.0.0.1:8080/',
      );

      expect(decision.target, StartupTarget.setupWizard);
    });

    test('stored settings used when they match the production default', () {
      final decision = resolveStartupDecision(
        settings: const DisplaySettings(
          serverUrl: 'http://127.0.0.1:8080/',
          wizardComplete: true,
        ),
        integrationTestServerUrl: '',
        integrationTestWizardMode: false,
        defaultServerUrl: 'http://127.0.0.1:8080/',
      );

      expect(decision.target, StartupTarget.display);
      expect(decision.serverUrl, 'http://127.0.0.1:8080/');
      expect(decision.persistDefaultSettings, isFalse);
    });

    test(
      'production default overrides stored URL when they differ and persists',
      () {
        // Guards against the stale-dev-URL trap: a Mac dev DB pinned an old
        // DHCP IP, and the dart-define swap could not take effect because
        // the stored URL won unconditionally. Now a non-empty, differing
        // default wins and overwrites the stored value.
        final decision = resolveStartupDecision(
          settings: const DisplaySettings(
            serverUrl: 'http://192.168.1.118:8080/',
            wizardComplete: true,
          ),
          integrationTestServerUrl: '',
          integrationTestWizardMode: false,
          defaultServerUrl: 'http://MacBookPro-3.lan:8080/',
        );

        expect(decision.target, StartupTarget.display);
        expect(decision.serverUrl, 'http://MacBookPro-3.lan:8080/');
        expect(decision.persistDefaultSettings, isTrue);
      },
    );

    test('stored settings used when no default is baked in', () {
      final decision = resolveStartupDecision(
        settings: const DisplaySettings(
          serverUrl: 'http://stored:8080/',
          wizardComplete: true,
        ),
        integrationTestServerUrl: '',
        integrationTestWizardMode: false,
        defaultServerUrl: '',
      );

      expect(decision.target, StartupTarget.display);
      expect(decision.serverUrl, 'http://stored:8080/');
      expect(decision.persistDefaultSettings, isFalse);
    });

    test('uses and persists production default when setup is incomplete', () {
      final decision = resolveStartupDecision(
        settings: const DisplaySettings(),
        integrationTestServerUrl: '',
        integrationTestWizardMode: false,
        defaultServerUrl: 'http://127.0.0.1:8080/',
      );

      expect(decision.target, StartupTarget.display);
      expect(decision.serverUrl, 'http://127.0.0.1:8080/');
      expect(decision.persistDefaultSettings, isTrue);
    });

    test('shows setup wizard when no stored settings or default exist', () {
      final decision = resolveStartupDecision(
        settings: const DisplaySettings(),
        integrationTestServerUrl: '',
        integrationTestWizardMode: false,
        defaultServerUrl: '',
      );

      expect(decision.target, StartupTarget.setupWizard);
    });
  });
}
