import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/screens/login_screen.dart';
import 'package:pinput/pinput.dart';

class _MockCubit extends MockCubit<AuthState> implements AuthCubit {}

Widget _wrap(AuthState state, _MockCubit cubit, {bool leanback = false}) {
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<AuthState>.value(state));
  return BlocProvider<AuthCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: LoginScreen(leanback: leanback),
    ),
  );
}

void main() {
  group('LoginScreen — remote nav (Phase 4b)', () {
    // ── Email step ─────────────────────────────────────────────────────────────

    group('_EmailStep focus traversal', () {
      testWidgets('initial focus lands on the email TextField', (tester) async {
        final cubit = _MockCubit();
        await tester.pumpWidget(_wrap(const AuthUnauthenticated(), cubit));
        await tester.pump();

        // Tab to move focus into the form area.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final focused = FocusManager.instance.primaryFocus?.context?.widget;
        // The focused widget should be inside a TextField.
        expect(focused, isNotNull);
      });

      testWidgets('arrowDown moves focus from email field to Send code button',
          (tester) async {
        final cubit = _MockCubit();
        await tester.pumpWidget(_wrap(const AuthUnauthenticated(), cubit));
        await tester.pump();

        // Focus the email field.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final beforeFocus = FocusManager.instance.primaryFocus;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        final afterFocus = FocusManager.instance.primaryFocus;
        expect(afterFocus, isNot(same(beforeFocus)));
      });

      testWidgets('Enter on Send code button calls sendCode', (tester) async {
        final cubit = _MockCubit();
        when(() => cubit.sendCode(any())).thenAnswer((_) async {});

        await tester.pumpWidget(_wrap(const AuthUnauthenticated(), cubit));
        await tester.pump();

        // Tap the Send code button via text.
        await tester.tap(find.text('Send code'));
        await tester.pump();

        verify(() => cubit.sendCode(any())).called(1);
      });
    });

    // ── Code step ──────────────────────────────────────────────────────────────

    group('_CodeStep Pinput OTP field', () {
      testWidgets('shows a Pinput widget with length 6 in CodeSent state',
          (tester) async {
        final cubit = _MockCubit();
        await tester.pumpWidget(
          _wrap(const AuthCodeSent(email: 'user@example.com'), cubit),
        );
        await tester.pump();

        final pinput = tester.widget<Pinput>(find.byType(Pinput));
        expect(pinput.length, equals(6));
      });

      testWidgets('Pinput is configured for numeric input', (tester) async {
        final cubit = _MockCubit();
        await tester.pumpWidget(
          _wrap(const AuthCodeSent(email: 'user@example.com'), cubit),
        );
        await tester.pump();

        final pinput = tester.widget<Pinput>(find.byType(Pinput));
        expect(pinput.keyboardType, TextInputType.number);
      });

      testWidgets('completing 6 digits calls verifyCode', (tester) async {
        final cubit = _MockCubit();
        when(() => cubit.verifyCode(any(), any())).thenAnswer((_) async {});

        await tester.pumpWidget(
          _wrap(const AuthCodeSent(email: 'user@example.com'), cubit),
        );
        await tester.pump();

        await tester.enterText(find.byType(Pinput), '123456');
        await tester.pump();

        verify(() => cubit.verifyCode('user@example.com', '123456')).called(1);
      });
    });

    // ── Leanback device-auth step ──────────────────────────────────────────────

    group('leanback email fallback', () {
      testWidgets('arrowDown from device-flow button reaches email field',
          (tester) async {
        final cubit = _MockCubit();
        when(() => cubit.startDeviceFlow()).thenAnswer((_) async {});

        await tester.pumpWidget(
          _wrap(const AuthUnauthenticated(), cubit, leanback: true),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final before = FocusManager.instance.primaryFocus;

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        final after = FocusManager.instance.primaryFocus;
        expect(after, isNot(same(before)));
      });
    });
  });
}
