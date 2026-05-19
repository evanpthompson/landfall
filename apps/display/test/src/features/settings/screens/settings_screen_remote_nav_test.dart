import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/license/cubit/license_cubit.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
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

Widget _wrap({
  _MockDisplaySettingsCubit? displaySettings,
  _MockLicenseCubit? license,
  _MockThemeCubit? theme,
  _MockPhotoCubit? photo,
  _MockDashboardProfileCubit? profile,
}) {
  final dsCubit = displaySettings ?? _MockDisplaySettingsCubit();
  final licCubit = license ?? _MockLicenseCubit();
  final themeCubit = theme ?? _MockThemeCubit();
  final photoCubit = photo ?? _MockPhotoCubit();
  final profileCubit = profile ?? _MockDashboardProfileCubit();

  when(() => dsCubit.state).thenReturn(const DisplaySettingsLoading());
  whenListen(dsCubit, Stream<DisplaySettingsState>.value(const DisplaySettingsLoading()));
  when(() => licCubit.state).thenReturn(const LicenseLoading());
  whenListen(licCubit, Stream<LicenseState>.value(const LicenseLoading()));
  when(() => licCubit.loadStatus()).thenAnswer((_) async {});
  when(() => themeCubit.state).thenReturn(const ThemeInitial());
  whenListen(themeCubit, Stream<ThemeState>.value(const ThemeInitial()));
  when(() => photoCubit.state).thenReturn(const PhotoLoading());
  whenListen(photoCubit, Stream<PhotoState>.value(const PhotoLoading()));
  when(() => profileCubit.state).thenReturn(const DashboardProfileLoading());
  whenListen(profileCubit, Stream<DashboardProfileState>.value(const DashboardProfileLoading()));

  return MultiBlocProvider(
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
        serverUrl: 'http://localhost:9999',
      ),
    ),
  );
}

void main() {
  group('SettingsScreen — remote nav (Phase 5)', () {
    group('PopScope', () {
      testWidgets('PopScope is present in the widget tree', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();

        expect(find.byType(PopScope), findsAtLeastNWidgets(1));
      });

      testWidgets('canPop is true — back gesture does not block navigation',
          (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();

        // The PopScope wrapping the screen must allow pops.
        final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
        expect(popScope.canPop, isTrue);
      });
    });

    group('FocusTraversalGroup', () {
      testWidgets('FocusTraversalGroup is present in the widget tree',
          (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();

        expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
      });

      testWidgets('arrowDown moves focus to next focusable item',
          (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();

        // Focus the first item via Tab.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final before = FocusManager.instance.primaryFocus;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        final after = FocusManager.instance.primaryFocus;
        // Focus should have moved.
        expect(after, isNot(same(before)));
      });

      testWidgets('arrowUp moves focus to previous focusable item',
          (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();

        // Tab twice to land on the second focusable item.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final before = FocusManager.instance.primaryFocus;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        final after = FocusManager.instance.primaryFocus;
        expect(after, isNot(same(before)));
      });
    });
  });
}

