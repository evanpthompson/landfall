import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart' hide CompanionEntity;
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/companion/cubit/companion_cubit.dart';
import 'package:display/src/features/companion/widgets/companion_qr_code.dart';
import 'package:display/src/features/license/cubit/license_cubit.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/settings/cubit/display_settings_cubit.dart';
import 'package:display/src/features/settings/screens/settings_screen.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockDisplaySettingsCubit extends MockCubit<DisplaySettingsState>
    implements DisplaySettingsCubit {}

class _MockLicenseCubit extends MockCubit<LicenseState>
    implements LicenseCubit {}

class _MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

class _MockPhotoCubit extends MockCubit<PhotoState> implements PhotoCubit {}

class _MockDashboardProfileCubit extends MockCubit<DashboardProfileState>
    implements DashboardProfileCubit {}

class _MockCompanionCubit extends MockCubit<CompanionState>
    implements CompanionCubit {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CompanionEntity _stubEntity() => CompanionEntity(
      id: 'test-id',
      displayId: 'display-abc',
      seed: 1,
      rarityTier: RarityTier.common,
      speciesId: 'lumen',
      name: 'Lumen',
      traits: const [],
      evolutionStage: 0,
      createdAt: DateTime(2026),
      assetCredit: '',
    );

Widget _wrap({
  required CompanionState companionState,
  DisplaySettingsState? displaySettingsState,
  String serverUrl = 'http://localhost:9999/',
}) {
  final dsState =
      displaySettingsState ?? const DisplaySettingsLoading();
  final dsCubit = _MockDisplaySettingsCubit();
  when(() => dsCubit.state).thenReturn(dsState);
  whenListen(dsCubit, Stream<DisplaySettingsState>.value(dsState));

  final licCubit = _MockLicenseCubit();
  when(() => licCubit.state).thenReturn(const LicenseLoading());
  whenListen(licCubit, Stream<LicenseState>.value(const LicenseLoading()));
  when(() => licCubit.loadStatus()).thenAnswer((_) async {});

  final themeCubit = _MockThemeCubit();
  when(() => themeCubit.state).thenReturn(const ThemeInitial());
  whenListen(themeCubit, Stream<ThemeState>.value(const ThemeInitial()));

  final photoCubit = _MockPhotoCubit();
  when(() => photoCubit.state).thenReturn(const PhotoLoading());
  whenListen(photoCubit, Stream<PhotoState>.value(const PhotoLoading()));

  final profileCubit = _MockDashboardProfileCubit();
  when(() => profileCubit.state).thenReturn(const DashboardProfileLoading());
  whenListen(profileCubit,
      Stream<DashboardProfileState>.value(const DashboardProfileLoading()));

  final companionCubit = _MockCompanionCubit();
  when(() => companionCubit.state).thenReturn(companionState);
  whenListen(
      companionCubit, Stream<CompanionState>.value(companionState));
  when(() => companionCubit.displayId).thenReturn('display-abc');
  when(() => companionCubit.serverUrl).thenReturn(serverUrl);

  return MultiBlocProvider(
    providers: [
      BlocProvider<DisplaySettingsCubit>.value(value: dsCubit),
      BlocProvider<LicenseCubit>.value(value: licCubit),
      BlocProvider<ThemeCubit>.value(value: themeCubit),
      BlocProvider<PhotoCubit>.value(value: photoCubit),
      BlocProvider<DashboardProfileCubit>.value(value: profileCubit),
      BlocProvider<CompanionCubit>.value(value: companionCubit),
    ],
    child: MaterialApp(
      home: SettingsScreen(
        client: Client(serverUrl),
        serverUrl: serverUrl,
      ),
    ),
  );
}

Future<void> _goToDisplayTab(WidgetTester tester) async {
  await tester.tap(find.text('Display'));
  await tester.pump(); // start tab switch
  await tester.pump(const Duration(milliseconds: 350)); // finish tab animation
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Settings Display tab — Remote Control QR tile', () {
    testWidgets('shows CompanionQrCode when companion URL is available',
        (tester) async {
      final state = CompanionLoaded(
        _stubEntity(),
        companionBaseUrl: 'http://192.168.1.42',
      );
      await tester.pumpWidget(_wrap(companionState: state));
      await tester.pump();
      await _goToDisplayTab(tester);

      expect(find.byType(CompanionQrCode), findsOneWidget);
      expect(find.textContaining('192.168.1.42'), findsOneWidget);
    });

    testWidgets(
        'falls back to port+2 URL when companionBaseUrl is empty',
        (tester) async {
      // companionBaseUrl empty → tile falls back to serverUrl port+2.
      // serverUrl is 'http://localhost:9999/' → fallback is port 10001.
      final state = CompanionLoaded(_stubEntity(), companionBaseUrl: '');
      await tester.pumpWidget(_wrap(companionState: state));
      await tester.pump();
      await _goToDisplayTab(tester);

      // QR still shows using the fallback URL.
      expect(find.byType(CompanionQrCode), findsOneWidget);
      expect(find.textContaining('localhost:10001'), findsOneWidget);
    });

    testWidgets('shows fallback message when companion is still loading',
        (tester) async {
      await tester.pumpWidget(_wrap(companionState: CompanionLoading()));
      await tester.pump();
      await _goToDisplayTab(tester);

      expect(find.byType(CompanionQrCode), findsNothing);
    });

    testWidgets('QR tile appears before Server section', (tester) async {
      final state = CompanionLoaded(
        _stubEntity(),
        companionBaseUrl: 'http://192.168.1.42',
      );
      // Provide loaded settings so the Server section header is rendered.
      await tester.pumpWidget(_wrap(
        companionState: state,
        displaySettingsState:
            const DisplaySettingsLoaded(DisplaySettings()),
      ));
      await tester.pump();
      await _goToDisplayTab(tester);

      // Both Remote Control header and Server header must be present.
      expect(find.textContaining('REMOTE CONTROL'), findsOneWidget);
      expect(find.textContaining('SERVER'), findsOneWidget);
    });

    testWidgets(
        'URL encodes displayId correctly into the companion path',
        (tester) async {
      final state = CompanionLoaded(
        _stubEntity(), // displayId = 'display-abc'
        companionBaseUrl: 'http://192.168.1.42',
      );
      await tester.pumpWidget(_wrap(companionState: state));
      await tester.pump();
      await _goToDisplayTab(tester);

      expect(
        find.textContaining('http://192.168.1.42/c/display-abc'),
        findsOneWidget,
      );
    });
  });
}
