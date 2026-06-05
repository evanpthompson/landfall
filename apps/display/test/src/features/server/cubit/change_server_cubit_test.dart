import 'package:bloc_test/bloc_test.dart';
import 'package:display/src/data/server/server_health_checker.dart';
import 'package:display/src/features/server/cubit/change_server_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

class _MockHealthChecker extends Mock implements ServerHealthChecker {}

class _MockSettingsRepo extends Mock implements DisplaySettingsRepository {}

void main() {
  late _MockHealthChecker health;
  late _MockSettingsRepo settings;

  setUpAll(() => registerFallbackValue(const DisplaySettings()));

  setUp(() {
    health = _MockHealthChecker();
    settings = _MockSettingsRepo();
    when(() => settings.getSettings())
        .thenAnswer((_) async => const DisplaySettings(displayId: 'd1'));
    when(() => settings.saveSettings(any())).thenAnswer((_) async {});
    when(() => health.isReachable(any())).thenAnswer((_) async => true);
    when(() => health.servesWebRoutes(any())).thenAnswer((_) async => true);
  });

  ChangeServerCubit build() =>
      ChangeServerCubit(healthChecker: health, settingsRepository: settings);

  test('initial state is editing with no error', () {
    expect(build().state, const ChangeServerEditing());
  });

  blocTest<ChangeServerCubit, ChangeServerState>(
    'validates, persists the URL + wizardComplete, then emits saved',
    build: build,
    act: (c) => c.submit('https://app.example.com'),
    expect: () => [
      const ChangeServerValidating(),
      const ChangeServerSaved('https://app.example.com/'),
    ],
    verify: (_) {
      verify(
        () => settings.saveSettings(
          any(
            that: isA<DisplaySettings>()
                .having((s) => s.serverUrl, 'serverUrl',
                    'https://app.example.com/')
                .having((s) => s.wizardComplete, 'wizardComplete', true)
                .having((s) => s.displayId, 'displayId', 'd1'),
          ),
        ),
      ).called(1);
    },
  );

  blocTest<ChangeServerCubit, ChangeServerState>(
    'emits editing with an error when the server is unreachable',
    build: build,
    setUp: () => when(() => health.isReachable(any()))
        .thenAnswer((_) async => false),
    act: (c) => c.submit('https://nope.example.com'),
    expect: () => [
      const ChangeServerValidating(),
      isA<ChangeServerEditing>()
          .having((s) => s.error, 'error', contains('Could not reach')),
    ],
    verify: (_) => verifyNever(() => settings.saveSettings(any())),
  );

  blocTest<ChangeServerCubit, ChangeServerState>(
    'rejects the bare API port with the wrong-origin message',
    build: build,
    setUp: () => when(() => health.servesWebRoutes(any()))
        .thenAnswer((_) async => false),
    act: (c) => c.submit('http://192.168.1.10:8080'),
    expect: () => [
      const ChangeServerValidating(),
      isA<ChangeServerEditing>()
          .having((s) => s.error, 'error', contains('API port')),
    ],
    verify: (_) => verifyNever(() => settings.saveSettings(any())),
  );
}
