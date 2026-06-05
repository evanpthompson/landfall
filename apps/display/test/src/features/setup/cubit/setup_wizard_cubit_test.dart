import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/data/server/server_health_checker.dart';
import 'package:display/src/features/setup/cubit/setup_wizard_cubit.dart';

class _MockSettingsRepo extends Mock implements DisplaySettingsRepository {}

class _MockHealthChecker extends Mock implements ServerHealthChecker {}

void main() {
  setUpAll(() {
    registerFallbackValue(const DisplaySettings());
  });

  late _MockSettingsRepo settings;
  late _MockHealthChecker health;

  const defaultSettings = DisplaySettings();

  setUp(() {
    settings = _MockSettingsRepo();
    health = _MockHealthChecker();

    when(() => settings.getSettings()).thenAnswer((_) async => defaultSettings);
    when(() => settings.saveSettings(any())).thenAnswer((_) async {});
    // Default to a healthy, web-capable server; failure cases override below.
    when(() => health.isReachable(any())).thenAnswer((_) async => true);
    when(() => health.servesWebRoutes(any())).thenAnswer((_) async => true);
  });

  SetupWizardCubit build() => SetupWizardCubit(
        settingsRepository: settings,
        healthChecker: health,
      );

  group('init', () {
    blocTest<SetupWizardCubit, SetupWizardState>(
      'starts at serverUrl step when no URL stored',
      build: build,
      act: (c) => c.init(),
      expect: () => [const SetupWizardAt(SetupWizardStep.serverUrl)],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'resumes at location step when URL stored but location empty',
      build: build,
      setUp: () {
        when(() => settings.getSettings()).thenAnswer(
          (_) async =>
              const DisplaySettings(serverUrl: 'https://x.com/'),
        );
      },
      act: (c) => c.init(),
      expect: () => [
        const SetupWizardAt(
          SetupWizardStep.location,
          serverUrl: 'https://x.com/',
        ),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'resumes at linkAccount step when URL and location are stored',
      build: build,
      setUp: () {
        when(() => settings.getSettings()).thenAnswer(
          (_) async => const DisplaySettings(
            serverUrl: 'https://x.com/',
            locationName: 'Seattle',
          ),
        );
      },
      act: (c) => c.init(),
      expect: () => [
        const SetupWizardAt(
          SetupWizardStep.linkAccount,
          serverUrl: 'https://x.com/',
        ),
      ],
    );
  });

  group('submitServerUrl', () {
    blocTest<SetupWizardCubit, SetupWizardState>(
      'emits validating then location step on reachable URL',
      build: build,
      act: (c) => c.submitServerUrl('https://api.example.com'),
      expect: () => [
        const SetupWizardValidating(),
        const SetupWizardAt(
          SetupWizardStep.location,
          serverUrl: 'https://api.example.com/',
        ),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'normalises URL — appends trailing slash',
      build: build,
      act: (c) => c.submitServerUrl('  https://no-slash.dev  '),
      verify: (_) {
        verify(() => health.isReachable('https://no-slash.dev/')).called(1);
      },
      expect: () => [
        const SetupWizardValidating(),
        const SetupWizardAt(
          SetupWizardStep.location,
          serverUrl: 'https://no-slash.dev/',
        ),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'emits validating then error on unreachable URL',
      build: build,
      setUp: () {
        when(() => health.isReachable(any())).thenAnswer((_) async => false);
      },
      act: (c) => c.submitServerUrl('https://unreachable.example.com'),
      expect: () => [
        const SetupWizardValidating(),
        const SetupWizardStepError(
          'Could not reach the server. Check the URL and try again.',
          SetupWizardStep.serverUrl,
        ),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'emits validating then wrong-origin error when /config is absent',
      build: build,
      setUp: () {
        when(() => health.servesWebRoutes(any())).thenAnswer((_) async => false);
      },
      act: (c) => c.submitServerUrl('http://192.168.1.10:8080'),
      expect: () => [
        const SetupWizardValidating(),
        isA<SetupWizardStepError>()
            .having((s) => s.message, 'message', contains('API port'))
            .having((s) => s.step, 'step', SetupWizardStep.serverUrl),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'persists serverUrl to settings on success',
      build: build,
      act: (c) => c.submitServerUrl('https://api.example.com/'),
      verify: (_) {
        verify(
          () => settings.saveSettings(
            any(
              that: isA<DisplaySettings>().having(
                (s) => s.serverUrl,
                'serverUrl',
                'https://api.example.com/',
              ),
            ),
          ),
        ).called(1);
      },
    );
  });

  group('submitLocation', () {
    blocTest<SetupWizardCubit, SetupWizardState>(
      'advances to linkAccount after saving location',
      build: build,
      act: (c) async {
        // seed serverUrl so it carries forward
        await c.submitServerUrl('https://api.example.com/');
        await c.submitLocation('Seattle, WA');
      },
      skip: 2, // skip the serverUrl transitions
      expect: () => [
        const SetupWizardAt(
          SetupWizardStep.linkAccount,
          serverUrl: 'https://api.example.com/',
        ),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'trims whitespace before saving',
      build: build,
      act: (c) async {
        await c.submitServerUrl('https://api.example.com/');
        await c.submitLocation('  Portland  ');
      },
      verify: (_) {
        verify(
          () => settings.saveSettings(
            any(
              that: isA<DisplaySettings>().having(
                (s) => s.locationName,
                'locationName',
                'Portland',
              ),
            ),
          ),
        ).called(greaterThanOrEqualTo(1));
      },
    );
  });

  group('advanceToDone', () {
    blocTest<SetupWizardCubit, SetupWizardState>(
      'advances to done step',
      build: build,
      setUp: () {
        when(() => settings.getSettings()).thenAnswer(
          (_) async =>
              const DisplaySettings(serverUrl: 'https://x.com/', locationName: 'Denver'),
        );
      },
      act: (c) async {
        await c.submitServerUrl('https://x.com/');
        c.advanceToDone();
      },
      skip: 2,
      expect: () => [
        const SetupWizardAt(SetupWizardStep.done, serverUrl: 'https://x.com/'),
      ],
    );
  });

  group('complete', () {
    blocTest<SetupWizardCubit, SetupWizardState>(
      'emits SetupWizardComplete and persists wizardComplete flag',
      build: build,
      act: (c) async {
        await c.submitServerUrl('https://api.example.com/');
        await c.complete();
      },
      skip: 2,
      expect: () => [
        const SetupWizardComplete(serverUrl: 'https://api.example.com/'),
      ],
      verify: (_) {
        verify(
          () => settings.saveSettings(
            any(
              that: isA<DisplaySettings>().having(
                (s) => s.wizardComplete,
                'wizardComplete',
                isTrue,
              ),
            ),
          ),
        ).called(greaterThanOrEqualTo(1));
      },
    );
  });

  group('previousStep', () {
    blocTest<SetupWizardCubit, SetupWizardState>(
      'serverUrl step — previousStep is a no-op (first step)',
      build: build,
      act: (c) => c.previousStep(),
      expect: () => [],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'location → serverUrl',
      build: build,
      act: (c) async {
        await c.submitServerUrl('https://x.com/');
        c.previousStep();
      },
      skip: 2,
      expect: () => [const SetupWizardAt(SetupWizardStep.serverUrl)],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'linkAccount → location',
      build: build,
      act: (c) async {
        await c.submitServerUrl('https://x.com/');
        await c.submitLocation('Seattle');
        c.previousStep();
      },
      skip: 3,
      expect: () => [
        const SetupWizardAt(
          SetupWizardStep.location,
          serverUrl: 'https://x.com/',
        ),
      ],
    );

  });
}
