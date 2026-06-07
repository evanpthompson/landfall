import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/widgets/auth_gate.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';
import 'package:display/src/features/settings/screens/web_settings_screen.dart';
import 'package:display/src/features/settings/widgets/layout_tab_view.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockDashboardProfileCubit extends MockCubit<DashboardProfileState>
    implements DashboardProfileCubit {}

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

  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<DashboardProfileCubit>.value(value: pCubit),
    ],
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: AuthGate(
        child: WebSettingsScreen(
          onPush: onPush ?? (_) async {},
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

    testWidgets('non-Layout tabs show placeholder panes', (tester) async {
      await tester.pumpWidget(_wrapAuthenticated());
      await tester.pump();

      await tester.tap(find.text('Themes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('coming soon'), findsOneWidget);
    });

    testWidgets('unauthenticated state shows login wall, not settings',
        (tester) async {
      final authCubit = _MockAuthCubit();
      final pCubit = _MockDashboardProfileCubit();
      when(() => authCubit.state).thenReturn(const AuthUnauthenticated());
      whenListen(
        authCubit,
        Stream<AuthState>.value(const AuthUnauthenticated()),
      );
      when(() => pCubit.state).thenReturn(const DashboardProfileLoading());
      whenListen(
        pCubit,
        Stream<DashboardProfileState>.value(const DashboardProfileLoading()),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<DashboardProfileCubit>.value(value: pCubit),
          ],
          child: MaterialApp(
            theme: LandfallTheme.dark,
            home: AuthGate(
              child: WebSettingsScreen(onPush: (_) async {}),
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
