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

void _setupMocks({
  required _MockDisplaySettingsCubit dsCubit,
  required _MockLicenseCubit licCubit,
  required _MockThemeCubit themeCubit,
  required _MockPhotoCubit photoCubit,
  required _MockDashboardProfileCubit profileCubit,
}) {
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
}

List<BlocProvider> _providers({
  required _MockDisplaySettingsCubit dsCubit,
  required _MockLicenseCubit licCubit,
  required _MockThemeCubit themeCubit,
  required _MockPhotoCubit photoCubit,
  required _MockDashboardProfileCubit profileCubit,
}) =>
    [
      BlocProvider<DisplaySettingsCubit>.value(value: dsCubit),
      BlocProvider<LicenseCubit>.value(value: licCubit),
      BlocProvider<ThemeCubit>.value(value: themeCubit),
      BlocProvider<PhotoCubit>.value(value: photoCubit),
      BlocProvider<DashboardProfileCubit>.value(value: profileCubit),
    ];

Widget _wrap({bool leanback = false}) {
  final dsCubit = _MockDisplaySettingsCubit();
  final licCubit = _MockLicenseCubit();
  final themeCubit = _MockThemeCubit();
  final photoCubit = _MockPhotoCubit();
  final profileCubit = _MockDashboardProfileCubit();
  _setupMocks(
    dsCubit: dsCubit,
    licCubit: licCubit,
    themeCubit: themeCubit,
    photoCubit: photoCubit,
    profileCubit: profileCubit,
  );

  return MultiBlocProvider(
    providers: _providers(
      dsCubit: dsCubit,
      licCubit: licCubit,
      themeCubit: themeCubit,
      photoCubit: photoCubit,
      profileCubit: profileCubit,
    ),
    child: MaterialApp(
      home: SettingsScreen(
        client: Client('http://localhost:9999'),
        serverUrl: 'http://localhost:9999',
        leanback: leanback,
      ),
    ),
  );
}

/// Builds a home scaffold with a button that pushes SettingsScreen on top.
Widget _wrapPushed({bool leanback = false}) {
  final dsCubit = _MockDisplaySettingsCubit();
  final licCubit = _MockLicenseCubit();
  final themeCubit = _MockThemeCubit();
  final photoCubit = _MockPhotoCubit();
  final profileCubit = _MockDashboardProfileCubit();
  _setupMocks(
    dsCubit: dsCubit,
    licCubit: licCubit,
    themeCubit: themeCubit,
    photoCubit: photoCubit,
    profileCubit: profileCubit,
  );

  return MultiBlocProvider(
    providers: _providers(
      dsCubit: dsCubit,
      licCubit: licCubit,
      themeCubit: themeCubit,
      photoCubit: photoCubit,
      profileCubit: profileCubit,
    ),
    child: MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: ElevatedButton(
            key: const Key('push_settings'),
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(
                  client: Client('http://localhost:9999'),
                  serverUrl: 'http://localhost:9999',
                  leanback: leanback,
                ),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ),
      ),
    ),
  );
}

/// Builds SettingsScreen wrapped in a MediaQuery that simulates an open IME
/// (non-zero bottom view inset).
Widget _wrapWithKeyboard({bool leanback = false}) {
  final dsCubit = _MockDisplaySettingsCubit();
  final licCubit = _MockLicenseCubit();
  final themeCubit = _MockThemeCubit();
  final photoCubit = _MockPhotoCubit();
  final profileCubit = _MockDashboardProfileCubit();
  _setupMocks(
    dsCubit: dsCubit,
    licCubit: licCubit,
    themeCubit: themeCubit,
    photoCubit: photoCubit,
    profileCubit: profileCubit,
  );

  return MultiBlocProvider(
    providers: _providers(
      dsCubit: dsCubit,
      licCubit: licCubit,
      themeCubit: themeCubit,
      photoCubit: photoCubit,
      profileCubit: profileCubit,
    ),
    child: MaterialApp(
      home: Builder(
        builder: (ctx) => MediaQuery(
          data: MediaQuery.of(ctx)
              .copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
          child: SettingsScreen(
            client: Client('http://localhost:9999'),
            serverUrl: 'http://localhost:9999',
            leanback: leanback,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SettingsScreen — remote nav', () {
    group('PopScope', () {
      testWidgets('PopScope is present in the widget tree', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();

        expect(
          find.byWidgetPredicate((w) => w is PopScope),
          findsAtLeastNWidgets(1),
        );
      });

      testWidgets(
          'canPop is false — Back is handled by onPopInvokedWithResult',
          (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();

        final popScope = tester.firstWidget<PopScope>(
          find.byWidgetPredicate((w) => w is PopScope),
        );
        expect(popScope.canPop, isFalse);
      });

      testWidgets(
          'Back with keyboard open (viewInsets > 0) dismisses focus without leaving the screen',
          (tester) async {
        await tester.pumpWidget(_wrapWithKeyboard());
        await tester.pump();

        // Focus an element so primaryFocus is non-null.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focused = FocusManager.instance.primaryFocus;
        expect(focused, isNotNull);

        // Simulate system Back.
        final navigator =
            tester.state<NavigatorState>(find.byType(Navigator));
        await navigator.maybePop();
        await tester.pump();

        // Keyboard-first: focus cleared, settings screen still visible.
        expect(focused!.hasFocus, isFalse);
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets(
          'Back with no keyboard open pops the settings screen',
          (tester) async {
        await tester.pumpWidget(_wrapPushed());
        await tester.pump();

        // Navigate to settings.
        await tester.tap(find.byKey(const Key('push_settings')));
        await tester.pump(); // start push animation
        await tester.pump(const Duration(milliseconds: 500)); // complete animation
        expect(find.byType(SettingsScreen), findsOneWidget);

        // No open keyboard — Back should pop.
        final navigator =
            tester.state<NavigatorState>(find.byType(Navigator));
        await navigator.maybePop();
        await tester.pump(); // start pop animation
        await tester.pump(const Duration(milliseconds: 500)); // complete animation

        expect(find.byType(SettingsScreen), findsNothing);
        expect(find.text('Open Settings'), findsOneWidget);
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

    group('Layout tab — leanback', () {
      testWidgets(
          'Layout tab does not show a placeholder — D-pad editor is used instead',
          (tester) async {
        await tester.pumpWidget(_wrap(leanback: true));
        await tester.pump();

        await tester.tap(find.text('Layout'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // No placeholder — leanback mode now shows the LayoutEditor directly.
        expect(
          find.byKey(const ValueKey('layout_leanback_placeholder')),
          findsNothing,
        );
      });
    });
  });
}
