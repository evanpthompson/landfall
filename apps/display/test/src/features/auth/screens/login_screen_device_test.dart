import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/screens/login_screen.dart';

class _MockCubit extends MockCubit<AuthState> implements AuthCubit {}

Widget _wrapLeanback(AuthState state, _MockCubit cubit) {
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<AuthState>.value(state));
  return BlocProvider<AuthCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: const LoginScreen(leanback: true),
    ),
  );
}

Widget _wrapNormal(AuthState state, _MockCubit cubit) {
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<AuthState>.value(state));
  return BlocProvider<AuthCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: const LoginScreen(leanback: false),
    ),
  );
}

void main() {
  group('LoginScreen — device auth step (leanback)', () {
    testWidgets('shows device code and verification URL in leanback mode',
        (tester) async {
      final cubit = _MockCubit();
      await tester.pumpWidget(
        _wrapLeanback(
          const AuthDevicePending(
            userCode: 'AB12CD',
            deviceCode: 'device-code-abc',
            verificationUri: 'http://192.168.1.10:8080/device',
          ),
          cubit,
        ),
      );
      await tester.pump();

      expect(find.text('AB12CD'), findsOneWidget);
      expect(find.text('http://192.168.1.10:8080/device'), findsOneWidget);
    });

    testWidgets('shows "Sign in from your phone" heading in device pending state',
        (tester) async {
      final cubit = _MockCubit();
      await tester.pumpWidget(
        _wrapLeanback(
          const AuthDevicePending(
            userCode: 'XY34ZW',
            deviceCode: 'dc-xyz',
            verificationUri: 'http://x/device',
          ),
          cubit,
        ),
      );
      await tester.pump();

      expect(find.text('Sign in from your phone'), findsOneWidget);
    });

    testWidgets(
        'shows device auth option (not just email step) on first open in leanback mode',
        (tester) async {
      final cubit = _MockCubit();
      await tester.pumpWidget(
        _wrapLeanback(const AuthUnauthenticated(), cubit),
      );
      await tester.pump();

      // In leanback mode the primary CTA should be the device flow.
      expect(find.textContaining('TV code'), findsOneWidget);
    });

    testWidgets('does NOT show device auth option in non-leanback mode',
        (tester) async {
      final cubit = _MockCubit();
      await tester.pumpWidget(
        _wrapNormal(const AuthUnauthenticated(), cubit),
      );
      await tester.pump();

      expect(find.textContaining('TV code'), findsNothing);
    });

    testWidgets(
        'tapping device-flow CTA calls startDeviceFlow on cubit',
        (tester) async {
      final cubit = _MockCubit();
      when(() => cubit.startDeviceFlow()).thenAnswer((_) async {});

      await tester.pumpWidget(
        _wrapLeanback(const AuthUnauthenticated(), cubit),
      );
      await tester.pump();

      await tester.tap(find.textContaining('TV code'));
      await tester.pump();

      verify(() => cubit.startDeviceFlow()).called(1);
    });
  });
}
