import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/app/landfall_root.dart';
import 'package:display/src/features/license/cubit/license_cubit.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/server/screens/change_server_screen.dart';
import 'package:display/src/features/settings/cubit/display_settings_cubit.dart';
import 'package:display/src/features/settings/screens/settings_screen.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';

class _MockDisplaySettingsCubit extends MockCubit<DisplaySettingsState>
    implements DisplaySettingsCubit {}

class _MockLicenseCubit extends MockCubit<LicenseState>
    implements LicenseCubit {}

class _MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

class _MockPhotoCubit extends MockCubit<PhotoState> implements PhotoCubit {}

class _MockDashboardProfileCubit extends MockCubit<DashboardProfileState>
    implements DashboardProfileCubit {}

class _FakeSettingsRepo implements DisplaySettingsRepository {
  DisplaySettings settings = const DisplaySettings(displayId: 'd1');
  @override
  Future<DisplaySettings> getSettings() async => settings;
  @override
  Future<void> saveSettings(DisplaySettings s) async => settings = s;
}

Widget _wrap() {
  final dsCubit = _MockDisplaySettingsCubit();
  final licCubit = _MockLicenseCubit();
  final themeCubit = _MockThemeCubit();
  final photoCubit = _MockPhotoCubit();
  final profileCubit = _MockDashboardProfileCubit();

  const loaded = DisplaySettingsLoaded(DisplaySettings(displayId: 'd1'));
  when(() => dsCubit.state).thenReturn(loaded);
  whenListen(dsCubit, Stream<DisplaySettingsState>.value(loaded));
  when(() => licCubit.state).thenReturn(const LicenseLoading());
  whenListen(licCubit, Stream<LicenseState>.value(const LicenseLoading()));
  when(() => licCubit.loadStatus()).thenAnswer((_) async {});
  when(() => themeCubit.state).thenReturn(const ThemeInitial());
  whenListen(themeCubit, Stream<ThemeState>.value(const ThemeInitial()));
  when(() => photoCubit.state).thenReturn(const PhotoLoading());
  whenListen(photoCubit, Stream<PhotoState>.value(const PhotoLoading()));
  when(() => profileCubit.state)
      .thenReturn(const DashboardProfileLoading());
  whenListen(profileCubit,
      Stream<DashboardProfileState>.value(const DashboardProfileLoading()));

  return AppRelauncher(
    relaunch: () {},
    child: RepositoryProvider<DisplaySettingsRepository>.value(
      value: _FakeSettingsRepo(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DisplaySettingsCubit>.value(value: dsCubit),
          BlocProvider<LicenseCubit>.value(value: licCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<PhotoCubit>.value(value: photoCubit),
          BlocProvider<DashboardProfileCubit>.value(value: profileCubit),
        ],
        child: MaterialApp(
          home: SettingsScreen(
            client: Client('http://localhost:9999'),
            serverUrl: 'http://localhost:8080/',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Display tab shows the current server address', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();

    expect(find.text('Server address'), findsOneWidget);
    expect(find.text('http://localhost:8080/'), findsOneWidget);
  });

  testWidgets('tapping the server tile opens the change-server screen',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();

    await tester.tap(find.text('Server address'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangeServerScreen), findsOneWidget);
  });
}
