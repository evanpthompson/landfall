import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/setup/cubit/setup_wizard_cubit.dart';
import 'package:display/src/features/setup/screens/setup_wizard_screen.dart';

class _MockCubit extends MockCubit<SetupWizardState>
    implements SetupWizardCubit {}

Widget _wrap(
  SetupWizardState state, {
  ValueChanged<String>? onComplete,
  bool leanback = false,
}) {
  final cubit = _MockCubit();
  when(() => cubit.state).thenReturn(state);
  whenListen(cubit, Stream<SetupWizardState>.value(state));

  return BlocProvider<SetupWizardCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: SetupWizardScreen(
        onComplete: onComplete ?? (_) {},
        leanback: leanback,
      ),
    ),
  );
}

void main() {
  group('SetupWizardScreen', () {
    testWidgets('shows server URL input on serverUrl step', (tester) async {
      await tester
          .pumpWidget(_wrap(const SetupWizardAt(SetupWizardStep.serverUrl)));
      await tester.pump();

      expect(find.text('Connect to your server'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('shows spinner when validating', (tester) async {
      await tester.pumpWidget(_wrap(const SetupWizardValidating()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text on serverUrl error', (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardStepError(
          'Could not reach the server.',
          SetupWizardStep.serverUrl,
        ),
      ));
      await tester.pump();

      expect(find.text('Could not reach the server.'), findsOneWidget);
    });

    testWidgets('shows location input on location step', (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(
          SetupWizardStep.location,
          serverUrl: 'https://x.com/',
        ),
      ));
      await tester.pump();

      expect(find.text('Where are you?'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('shows account info tiles on linkAccount step', (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(
          SetupWizardStep.linkAccount,
          serverUrl: 'https://x.com/',
        ),
      ));
      await tester.pump();

      expect(find.text('Connect accounts'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Agent API keys'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('shows launch button and server URL on done step',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(
          SetupWizardStep.done,
          serverUrl: 'https://api.example.com/',
        ),
      ));
      await tester.pump();

      expect(find.text("You're all set"), findsOneWidget);
      expect(find.text('Connected to https://api.example.com/'), findsOneWidget);
      expect(find.text('Launch Landfall'), findsOneWidget);
    });

    testWidgets('step indicator renders 4 dots (serverUrl, location, linkAccount, done)',
        (tester) async {
      await tester
          .pumpWidget(_wrap(const SetupWizardAt(SetupWizardStep.serverUrl)));
      await tester.pump();

      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('calls onComplete when SetupWizardComplete is emitted',
        (tester) async {
      String? received;
      final cubit = _MockCubit();
      const completeState =
          SetupWizardComplete(serverUrl: 'https://done.example.com/');

      when(() => cubit.state)
          .thenReturn(const SetupWizardAt(SetupWizardStep.done));
      whenListen(
        cubit,
        Stream<SetupWizardState>.fromIterable([
          const SetupWizardAt(SetupWizardStep.done),
          completeState,
        ]),
      );

      await tester.pumpWidget(
        BlocProvider<SetupWizardCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: LandfallTheme.dark,
            home: SetupWizardScreen(onComplete: (url) => received = url),
          ),
        ),
      );
      await tester.pump();

      expect(received, 'https://done.example.com/');
    });

    testWidgets('location step does not auto-pop the keyboard', (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(
          SetupWizardStep.location,
          serverUrl: 'https://x.com/',
        ),
      ));
      await tester.pump();

      // The location field is not autofocused on entry, so the IME is not
      // force-shown over the "Where are you?" page.
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isFalse);
    });

    testWidgets('location step lands focus on a button so the TV OK key '
        'activates it without navigating first', (tester) async {
      final cubit = _MockCubit();
      const state = SetupWizardAt(
          SetupWizardStep.location, serverUrl: 'https://x.com/');
      when(() => cubit.state).thenReturn(state);
      // Single, stable state (as on a real device) — a re-emit of the same
      // state would rebuild and steal the autofocus, which never happens live.
      whenListen(
        cubit,
        const Stream<SetupWizardState>.empty(),
        initialState: state,
      );
      when(() => cubit.submitLocation(any())).thenAnswer((_) async {});

      await tester.pumpWidget(BlocProvider<SetupWizardCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: LandfallTheme.dark,
          home: SetupWizardScreen(onComplete: (_) {}, leanback: false),
        ),
      ));
      await tester.pumpAndSettle();

      // No focus traversal first — OK (Fire TV center) hits the focused button.
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();

      verify(() => cubit.submitLocation(any())).called(1);
    });

    // ── Remote nav — PopScope ────────────────────────────────────────────────

    testWidgets('Back (maybePop) on non-first step calls previousStep',
        (tester) async {
      final cubit = _MockCubit();
      const state = SetupWizardAt(
          SetupWizardStep.location, serverUrl: 'https://x.com/');
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<SetupWizardState>.value(state));
      when(() => cubit.previousStep()).thenReturn(null);

      await tester.pumpWidget(BlocProvider<SetupWizardCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: LandfallTheme.dark,
          home: SetupWizardScreen(onComplete: (_) {}),
        ),
      ));
      await tester.pump();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();

      verify(() => cubit.previousStep()).called(1);
    });

    testWidgets('Back with the keyboard open dismisses it, no step change',
        (tester) async {
      final cubit = _MockCubit();
      const state = SetupWizardAt(
          SetupWizardStep.location, serverUrl: 'https://x.com/');
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<SetupWizardState>.value(state));
      when(() => cubit.previousStep()).thenReturn(null);

      await tester.pumpWidget(BlocProvider<SetupWizardCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: LandfallTheme.dark,
          // Simulate an open soft keyboard via non-zero bottom view insets.
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
              child: SetupWizardScreen(onComplete: (_) {}),
            ),
          ),
        ),
      ));
      await tester.pump();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();

      // Keyboard-first: Back closes the IME instead of navigating a step.
      verifyNever(() => cubit.previousStep());
    });

    testWidgets('Back (maybePop) on the first (serverUrl) step does NOT call '
        'previousStep', (tester) async {
      final cubit = _MockCubit();
      const state = SetupWizardAt(SetupWizardStep.serverUrl);
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<SetupWizardState>.value(state));
      when(() => cubit.previousStep()).thenReturn(null);

      await tester.pumpWidget(BlocProvider<SetupWizardCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: LandfallTheme.dark,
          home: SetupWizardScreen(onComplete: (_) {}),
        ),
      ));
      await tester.pump();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();

      verifyNever(() => cubit.previousStep());
    });

    // ── Remote nav — quick-fill chips (leanback only) ───────────────────────

    testWidgets('serverUrl step — quick-fill chips visible when leanback=true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(SetupWizardStep.serverUrl),
        leanback: true,
      ));
      await tester.pump();

      expect(find.text('http://'), findsOneWidget);
      expect(find.text('https://'), findsOneWidget);
      expect(find.text(':8080/'), findsOneWidget);
    });

    testWidgets('serverUrl step — quick-fill chips hidden when leanback=false',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(SetupWizardStep.serverUrl),
      ));
      await tester.pump();

      expect(find.text('http://'), findsNothing);
      expect(find.text('https://'), findsNothing);
      expect(find.text(':8080/'), findsNothing);
    });

    // ── Remote nav — arrow-key focus traversal ───────────────────────────────

    testWidgets('arrowDown moves focus to next interactive element', (tester) async {
      await tester.pumpWidget(_wrap(
        const SetupWizardAt(SetupWizardStep.serverUrl),
      ));
      await tester.pump();

      // Tab to establish initial focus order, then test arrowDown.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final before = FocusManager.instance.primaryFocus?.context?.widget;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      final after = FocusManager.instance.primaryFocus?.context?.widget;
      // Focus should have moved (different widget focused).
      expect(after, isNot(same(before)));
    });
  });
}
