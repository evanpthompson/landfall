import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/widgets/auth_gate.dart';
import 'package:display/src/features/auth/screens/web_login_screen.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

Widget _wrap(AuthState state, _MockAuthCubit cubit, {Widget? child}) {
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<AuthState>.value(state));
  return BlocProvider<AuthCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: AuthGate(
        child: child ?? const Text('settings content'),
      ),
    ),
  );
}

void main() {
  group('AuthGate', () {
    testWidgets('shows child when authenticated', (tester) async {
      final cubit = _MockAuthCubit();
      await tester.pumpWidget(
        _wrap(
          const AuthAuthenticated(accessToken: 'tok'),
          cubit,
          child: const Text('settings content'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('settings content'), findsOneWidget);
      expect(find.byType(WebLoginScreen), findsNothing);
    });

    testWidgets('shows WebLoginScreen when unauthenticated', (tester) async {
      final cubit = _MockAuthCubit();
      await tester.pumpWidget(_wrap(const AuthUnauthenticated(), cubit));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(WebLoginScreen), findsOneWidget);
      expect(find.text('settings content'), findsNothing);
    });

    testWidgets('shows WebLoginScreen while sending code', (tester) async {
      final cubit = _MockAuthCubit();
      await tester.pumpWidget(_wrap(const AuthSendingCode(), cubit));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(WebLoginScreen), findsOneWidget);
    });

    testWidgets('shows WebLoginScreen while verifying', (tester) async {
      final cubit = _MockAuthCubit();
      await tester.pumpWidget(
        _wrap(const AuthVerifying(email: 'a@b.com'), cubit),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(WebLoginScreen), findsOneWidget);
    });

    testWidgets(
        'transitions from login to child when state changes to authenticated',
        (tester) async {
      final cubit = _MockAuthCubit();
      when(() => cubit.state).thenReturn(const AuthUnauthenticated());
      final controller = StreamController<AuthState>.broadcast();
      whenListen(cubit, controller.stream);

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: LandfallTheme.dark,
            home: const AuthGate(child: Text('settings content')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(WebLoginScreen), findsOneWidget);

      controller.add(const AuthAuthenticated(accessToken: 'tok'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('settings content'), findsOneWidget);
      expect(find.byType(WebLoginScreen), findsNothing);

      await controller.close();
    });

    testWidgets('returns to login screen after sign out', (tester) async {
      final cubit = _MockAuthCubit();
      when(() => cubit.state)
          .thenReturn(const AuthAuthenticated(accessToken: 'tok'));
      final controller = StreamController<AuthState>.broadcast();
      whenListen(cubit, controller.stream);

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: LandfallTheme.dark,
            home: const AuthGate(child: Text('settings content')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('settings content'), findsOneWidget);

      controller.add(const AuthUnauthenticated());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(WebLoginScreen), findsOneWidget);
      expect(find.text('settings content'), findsNothing);

      await controller.close();
    });
  });
}
