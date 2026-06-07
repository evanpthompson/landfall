import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/settings/cubit/display_settings_cubit.dart';

class _MockRepo extends Mock implements DisplaySettingsRepository {}

const _settings = DisplaySettings(
  dimEnabled: true,
  dimStartHour: 22,
  dimEndHour: 7,
  dimLevel: 0.85,
  locationName: 'Test City',
  displayId: 'display-abc',
);

void main() {
  setUpAll(() => registerFallbackValue(const DisplaySettings()));

  group('DisplaySettingsCubit', () {
    late _MockRepo repo;

    setUp(() {
      repo = _MockRepo();
      when(() => repo.getSettings()).thenAnswer((_) async => _settings);
      when(() => repo.saveSettings(any())).thenAnswer((_) async {});
    });

    blocTest<DisplaySettingsCubit, DisplaySettingsState>(
      'loadSettings emits DisplaySettingsLoaded',
      build: () => DisplaySettingsCubit(repo),
      act: (c) => c.loadSettings(),
      expect: () => [DisplaySettingsLoaded(_settings)],
    );

    blocTest<DisplaySettingsCubit, DisplaySettingsState>(
      'updateSettings saves and emits DisplaySettingsLoaded',
      build: () => DisplaySettingsCubit(repo),
      act: (c) => c.updateSettings(_settings),
      expect: () => [DisplaySettingsLoaded(_settings)],
      verify: (_) => verify(() => repo.saveSettings(_settings)).called(1),
    );

    test('updateSettings calls onAfterSave when provided', () async {
      final pushed = <DisplaySettings>[];
      final cubit = DisplaySettingsCubit(
        repo,
        onAfterSave: pushed.add,
      );

      await cubit.updateSettings(_settings);

      expect(pushed, [_settings]);
    });

    test('updateSettings does not throw when onAfterSave is null', () async {
      final cubit = DisplaySettingsCubit(repo);
      await expectLater(cubit.updateSettings(_settings), completes);
    });
  });
}
