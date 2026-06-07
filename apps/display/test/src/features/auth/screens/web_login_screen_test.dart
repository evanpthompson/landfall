import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/screens/web_login_screen.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

Widget _wrap(AuthState state, _MockAuthCubit cubit) {
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<AuthState>.value(state));
  return BlocProvider<AuthCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: const WebLoginScreen(),
    ),
  );
}

void main() {
  group('WebLoginScreen', () {
    group('email step', () {
      testWidgets('shows email field and send-code button when unauthenticated',
          (tester) async {
        final cubit = _MockAuthCubit();
        await tester.pumpWidget(_wrap(const AuthUnauthenticated(), cubit));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Send code'), findsOneWidget);
      });

      testWidgets('calls sendCode with trimmed email on button tap',
          (tester) async {
        final cubit = _MockAuthCubit();
        when(() => cubit.sendCode(any())).thenAnswer((_) async {});
        await tester.pumpWidget(_wrap(const AuthUnauthenticated(), cubit));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(find.byType(TextField), '  user@test.com  ');
        await tester.tap(find.text('Send code'));
        verify(() => cubit.sendCode('user@test.com')).called(1);
      });

      testWidgets('shows loading spinner while sending code', (tester) async {
        final cubit = _MockAuthCubit();
        await tester.pumpWidget(_wrap(const AuthSendingCode(), cubit));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows error message when state is AuthError with unauthenticated previous',
          (tester) async {
        final cubit = _MockAuthCubit();
        await tester.pumpWidget(
          _wrap(
            const AuthError(
              message: 'Could not send code.',
              previous: AuthUnauthenticated(),
            ),
            cubit,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Could not send code.'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      });
    });

    group('code step', () {
      testWidgets('shows Pinput and resend button when code was sent',
          (tester) async {
        final cubit = _MockAuthCubit();
        await tester.pumpWidget(
          _wrap(const AuthCodeSent(email: 'user@test.com'), cubit),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Code sent to user@test.com'), findsOneWidget);
        expect(find.text('Resend code'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('shows loading spinner while verifying', (tester) async {
        final cubit = _MockAuthCubit();
        await tester.pumpWidget(
          _wrap(const AuthVerifying(email: 'user@test.com'), cubit),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows error message when code is wrong', (tester) async {
        final cubit = _MockAuthCubit();
        await tester.pumpWidget(
          _wrap(
            const AuthError(
              message: 'Invalid or expired code.',
              previous: AuthCodeSent(email: 'user@test.com'),
            ),
            cubit,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Invalid or expired code.'), findsOneWidget);
        expect(find.text('Resend code'), findsOneWidget);
      });

      testWidgets('resend button calls sendCode with original email',
          (tester) async {
        final cubit = _MockAuthCubit();
        when(() => cubit.sendCode(any())).thenAnswer((_) async {});
        await tester.pumpWidget(
          _wrap(const AuthCodeSent(email: 'a@b.com'), cubit),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Resend code'));
        verify(() => cubit.sendCode('a@b.com')).called(1);
      });
    });
  });
}
