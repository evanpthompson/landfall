import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/app/landfall_root.dart';
import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/screens/login_screen.dart';
import 'package:display/src/features/server/screens/change_server_screen.dart';
import 'package:landfall_shared/landfall_shared.dart';

class _MockCubit extends MockCubit<AuthState> implements AuthCubit {}

class _FakeSettingsRepo implements DisplaySettingsRepository {
  DisplaySettings settings = const DisplaySettings(displayId: 'd1');
  @override
  Future<DisplaySettings> getSettings() async => settings;
  @override
  Future<void> saveSettings(DisplaySettings s) async => settings = s;
}

Widget _wrap(AuthState state, _MockCubit cubit, {bool leanback = false}) {
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<AuthState>.value(state));
  return AppRelauncher(
    relaunch: () {},
    child: RepositoryProvider<DisplaySettingsRepository>.value(
      value: _FakeSettingsRepo(),
      child: BlocProvider<AuthCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: LandfallTheme.dark,
          home: LoginScreen(
            leanback: leanback,
            serverUrl: 'https://old.example.com/',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('leanback: tapping "Change server address" opens the screen',
      (tester) async {
    final cubit = _MockCubit();
    when(() => cubit.startDeviceFlow()).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(const AuthUnauthenticated(), cubit,
        leanback: true));
    await tester.pump();

    expect(find.text('Change server address'), findsOneWidget);

    await tester.tap(find.text('Change server address'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangeServerScreen), findsOneWidget);
    expect(find.text('Current: https://old.example.com/'), findsOneWidget);
  });

  testWidgets('email step: "Change server address" link opens the screen',
      (tester) async {
    final cubit = _MockCubit();

    await tester.pumpWidget(_wrap(const AuthUnauthenticated(), cubit));
    await tester.pump();

    await tester.tap(find.text('Change server address'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangeServerScreen), findsOneWidget);
  });

  testWidgets('device-pending step exposes "Change server address"',
      (tester) async {
    final cubit = _MockCubit();
    await tester.pumpWidget(_wrap(
      const AuthDevicePending(
        userCode: 'ABCD-1234',
        deviceCode: 'dev',
        verificationUri: 'https://old.example.com/device',
      ),
      cubit,
      leanback: true,
    ));
    await tester.pump();

    expect(find.text('Change server address'), findsOneWidget);
  });
}
