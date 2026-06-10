import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart' as lf hide LandfallTheme;
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/widgets/auth_gate.dart';
import 'package:display/src/features/license/cubit/license_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/settings/screens/web_settings_screen.dart';
import 'package:display/src/features/settings/widgets/layout_tab_view.dart';
import 'package:display/src/features/settings/widgets/web_display_tab.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockDashboardProfileCubit extends MockCubit<DashboardProfileState>
    implements DashboardProfileCubit {}

class _MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

class _MockLicenseCubit extends MockCubit<LicenseState>
    implements LicenseCubit {}

class _MockClient extends Mock implements lf.Client {}

class _MockDisplaySettingsEndpoint extends Mock
    implements lf.EndpointDisplaySettings {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProfileInfo _profile() => ProfileInfo(
      id: 1,
      name: 'Default',
      slug: 'default',
      isActive: true,
      layout: DashboardLayout.defaultLayout(),
      sortOrder: 0,
    );

AuthState _authenticated() =>
    const AuthAuthenticated(accessToken: 'test-token');

Widget _wrapAuthenticated({
  _MockDashboardProfileCubit? profileCubit,
  _MockThemeCubit? themeCubit,
  _MockLicenseCubit? licenseCubit,
  lf.Client? client,
  Future<void> Function(String kind)? onPush,
}) {
  final authCubit = _MockAuthCubit();
  when(() => authCubit.state).thenReturn(_authenticated());
  whenListen(authCubit, Stream<AuthState>.value(_authenticated()));

  final pCubit = profileCubit ?? _MockDashboardProfileCubit();
  if (profileCubit == null) {
    when(() => pCubit.state).thenReturn(const DashboardProfileLoading());
    whenListen(
      pCubit,
      Stream<DashboardProfileState>.value(const DashboardProfileLoading()),
    );
  }

  final tCubit = themeCubit ?? _MockThemeCubit();
  if (themeCubit == null) {
    when(() => tCubit.state).thenReturn(const ThemeInitial());
    whenListen(tCubit, Stream<ThemeState>.value(const ThemeInitial()));
  }

  final lCubit = licenseCubit ?? _MockLicenseCubit();
  if (licenseCubit == null) {
    when(() => lCubit.state).thenReturn(const LicenseLoading());
    whenListen(lCubit, Stream<LicenseState>.value(const LicenseLoading()));
  }

  final mockClient = client ?? _MockClient();
  final mockDsEndpoint = _MockDisplaySettingsEndpoint();
  when(() => mockDsEndpoint.get(any())).thenAnswer((_) async => null);
  when(() => mockClient.displaySettings).thenReturn(mockDsEndpoint);

  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<DashboardProfileCubit>.value(value: pCubit),
      BlocProvider<ThemeCubit>.value(value: tCubit),
      BlocProvider<LicenseCubit>.value(value: lCubit),
    ],
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: AuthGate(
        child: WebSettingsScreen(
          onPush: onPush ?? (_) async {},
          client: mockClient,
          serverUrl: 'http://localhost:8080/',
          displayId: 'display-test',
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(DashboardLayout.defaultLayout());
    registerFallbackValue('');
  });

  group('WebSettingsScreen', () {
    testWidgets('renders a TabBar with 5 expected tabs', (tester) async {
      await tester.pumpWidget(_wrapAuthenticated());
      await tester.pump();

      for (final label in [
        'Layout',
        'Themes',
        'Accounts',
        'Display',
        'License',
      ]) {
        expect(find.text(label), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Layout tab is active by default and shows LayoutTabView',
        (tester) async {
      await tester.pumpWidget(_wrapAuthenticated());
      await tester.pump();

      expect(find.byType(LayoutTabView), findsOneWidget);
    });

    testWidgets('Display tab renders WebDisplayTab', (tester) async {
      await tester.pumpWidget(_wrapAuthenticated());
      await tester.pump();

      await tester.tap(find.text('Display'));
      await tester.pumpAndSettle();

      // Placeholder is gone; real tab renders (loading → form).
      expect(find.textContaining('coming soon'), findsNothing);
      expect(find.byType(WebDisplayTab), findsOneWidget);
    });

    testWidgets('unauthenticated state shows login wall, not settings',
        (tester) async {
      final authCubit = _MockAuthCubit();
      final pCubit = _MockDashboardProfileCubit();
      final tCubit = _MockThemeCubit();
      final lCubit = _MockLicenseCubit();

      when(() => authCubit.state).thenReturn(const AuthUnauthenticated());
      whenListen(authCubit, Stream<AuthState>.value(const AuthUnauthenticated()));
      when(() => pCubit.state).thenReturn(const DashboardProfileLoading());
      whenListen(pCubit, Stream<DashboardProfileState>.value(const DashboardProfileLoading()));
      when(() => tCubit.state).thenReturn(const ThemeInitial());
      whenListen(tCubit, Stream<ThemeState>.value(const ThemeInitial()));
      when(() => lCubit.state).thenReturn(const LicenseLoading());
      whenListen(lCubit, Stream<LicenseState>.value(const LicenseLoading()));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<DashboardProfileCubit>.value(value: pCubit),
            BlocProvider<ThemeCubit>.value(value: tCubit),
            BlocProvider<LicenseCubit>.value(value: lCubit),
          ],
          child: MaterialApp(
            theme: LandfallTheme.dark,
            home: AuthGate(
              child: WebSettingsScreen(
                onPush: (_) async {},
                client: _MockClient(),
                serverUrl: 'http://localhost:8080/',
                displayId: 'display-test',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(WebSettingsScreen), findsNothing);
    });

    testWidgets(
        'onPush called with layout.changed after onLayoutSaved fires',
        (tester) async {
      final pCubit = _MockDashboardProfileCubit();
      final loaded = DashboardProfileLoaded(_profile());
      when(() => pCubit.state).thenReturn(loaded);
      whenListen(pCubit, Stream<DashboardProfileState>.value(loaded));
      when(() => pCubit.saveActiveLayout(any())).thenAnswer((_) async {});

      final pushed = <String>[];

      await tester.pumpWidget(
        _wrapAuthenticated(
          profileCubit: pCubit,
          onPush: (kind) async => pushed.add(kind),
        ),
      );
      await tester.pump();

      // Access the screen state to exercise the save path directly.
      final state = tester.state<WebSettingsScreenState>(
        find.byType(WebSettingsScreen),
      );
      await state.onLayoutSaved(DashboardLayout.defaultLayout());
      await tester.pump();

      verify(() => pCubit.saveActiveLayout(any())).called(1);
      expect(pushed, contains('layout.changed'));
    });

    testWidgets(
        'onPush is NOT called if saveActiveLayout throws',
        (tester) async {
      final pCubit = _MockDashboardProfileCubit();
      final loaded = DashboardProfileLoaded(_profile());
      when(() => pCubit.state).thenReturn(loaded);
      whenListen(pCubit, Stream<DashboardProfileState>.value(loaded));
      when(() => pCubit.saveActiveLayout(any())).thenThrow(Exception('save failed'));

      final pushed = <String>[];

      await tester.pumpWidget(
        _wrapAuthenticated(
          profileCubit: pCubit,
          onPush: (kind) async => pushed.add(kind),
        ),
      );
      await tester.pump();

      final state = tester.state<WebSettingsScreenState>(
        find.byType(WebSettingsScreen),
      );
      // The save throws; push must NOT fire.
      await state.onLayoutSaved(DashboardLayout.defaultLayout());
      await tester.pump();

      expect(pushed, isEmpty);
    });
  });
}
