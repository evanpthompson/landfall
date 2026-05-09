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

    test('stored completed settings override production default', () {
      final decision = resolveStartupDecision(
        settings: const DisplaySettings(
          serverUrl: 'http://stored:8080/',
          wizardComplete: true,
        ),
        integrationTestServerUrl: '',
        integrationTestWizardMode: false,
        defaultServerUrl: 'http://127.0.0.1:8080/',
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
