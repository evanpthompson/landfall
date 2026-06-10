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

Widget _wrapLoaded() {
  final authCubit = _MockAuthCubit();
  when(() => authCubit.state)
      .thenReturn(const AuthAuthenticated(accessToken: 'tok'));
  whenListen(
    authCubit,
    Stream<AuthState>.value(const AuthAuthenticated(accessToken: 'tok')),
  );

  final pCubit = _MockDashboardProfileCubit();
  final loaded = DashboardProfileLoaded(_profile());
  when(() => pCubit.state).thenReturn(loaded);
  whenListen(pCubit, Stream<DashboardProfileState>.value(loaded));
  when(() => pCubit.saveActiveLayout(any())).thenAnswer((_) async {});

  final tCubit = _MockThemeCubit();
  when(() => tCubit.state).thenReturn(const ThemeInitial());
  whenListen(tCubit, Stream<ThemeState>.value(const ThemeInitial()));

  final lCubit = _MockLicenseCubit();
  when(() => lCubit.state).thenReturn(const LicenseLoading());
  whenListen(lCubit, Stream<LicenseState>.value(const LicenseLoading()));

  final mockClient = _MockClient();
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
          onPush: (_) async {},
          client: mockClient,
          serverUrl: 'http://localhost:8080/',
          displayId: 'display-test',
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Goldens
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(DashboardLayout.defaultLayout());
    registerFallbackValue('');
  });

  group('WebSettingsScreen goldens', () {
    // Viewport note: 600 px is the minimum width where both the LayoutEditor
    // and WebDisplayTab hour-picker rows render without overflow assertions.
    // 390 px (iPhone 14 Pro) causes RenderFlex overflows in both widgets —
    // tracked as a separate responsive-layout fix.
    testWidgets('Layout tab — 600×900 (portrait, no overflow)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapLoaded());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(WebSettingsScreen),
        matchesGoldenFile('goldens/web_settings_layout_600x900.png'),
      );
    });

    testWidgets('Layout tab — 1024×600 (landscape)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapLoaded());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(WebSettingsScreen),
        matchesGoldenFile('goldens/web_settings_layout_landscape_1024x600.png'),
      );
    });

    testWidgets('Display tab — 600×900 (portrait, no overflow)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapLoaded());
      await tester.pump();

      await tester.tap(find.text('Display'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await expectLater(
        find.byType(WebSettingsScreen),
        matchesGoldenFile('goldens/web_settings_display_600x900.png'),
      );

      // Let async loads resolve cleanly so dispose doesn't throw.
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
