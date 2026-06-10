import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart' hide Card;
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';
import 'package:display/src/features/theme/screens/theme_browser_screen.dart';
import 'package:display/src/features/settings/widgets/themes_tab_view.dart';

class _MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

// ── fixtures ──────────────────────────────────────────────────────────────────

LandfallThemeTokens _tokens() => const LandfallThemeTokens(
      backgroundType: 'solid',
      backgroundValue: '#0d0d0d',
      cardFill: '#1a1a1a',
      cardBorderColor: '#333333',
      cardBorderWidth: 1.0,
      cardBorderStyle: 'solid',
      cardRadius: 8,
      cardBlur: 0,
      cardShadow: 'none',
      fontFamily: 'Inter',
      typographyScale: 'default',
      headingWeight: 600,
      bodyWeight: 400,
      letterSpacing: 'normal',
      timeDisplayFontFamily: 'Inter',
      timeDisplayWeight: 700,
      colorAccent: '#7C3AED',
      colorAccentMuted: '#5b21b6',
      colorTextPrimary: '#ffffff',
      colorTextSecondary: '#aaaaaa',
      colorTextTertiary: '#888888',
      colorDivider: '#333333',
      colorAgentBorder: '#444444',
      colorSuccess: '#00ff00',
      colorWarning: '#ffff00',
      colorAlert: '#ff0000',
      animationTransition: 'fade',
      animationSpeed: 'normal',
      animationCardEntry: 'slide',
      animationTickerScroll: 'smooth',
      moodUrgentBorderColor: '#ff0000',
      moodUrgentFillColor: '#330000',
      moodUrgentPulse: true,
      moodUrgentScale: 1.02,
      moodUrgentAnimation: 'pulse',
      moodCelebratoryBorderColor: '#ffcc00',
      moodCelebratoryFillColor: '#332200',
      moodCelebratoryPulse: false,
      moodCelebratoryScale: 1.0,
      moodCelebratoryAnimation: 'confetti',
      moodSuccessBorderColor: '#00ff00',
      moodSuccessFillColor: '#003300',
      moodSuccessPulse: false,
      moodSuccessScale: 1.0,
      moodSuccessAnimation: 'none',
      moodMutedBorderColor: '#555555',
      moodMutedFillColor: '#1a1a1a',
      moodMutedPulse: false,
      moodMutedScale: 1.0,
      moodMutedAnimation: 'none',
      moodMutedOpacity: 0.5,
      photoTransition: 'drift',
    );

ThemeInfo _theme(int id, String slug, String name) => ThemeInfo(
      id: id,
      slug: slug,
      name: name,
      schemaVersion: '1.0',
      isBuiltIn: true,
      tokens: _tokens(),
    );

final _dark = _theme(1, 'default-dark', 'Default Dark');

Widget _wrap(
  _MockThemeCubit themeCubit, {
  Future<void> Function()? onAfterThemeApplied,
}) {
  return BlocProvider<ThemeCubit>.value(
    value: themeCubit,
    child: MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(
        body: ThemesTabView(onAfterThemeApplied: onAfterThemeApplied),
      ),
    ),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ThemesTabView', () {
    testWidgets('shows spinner when state is ThemeInitial', (tester) async {
      final cubit = _MockThemeCubit();
      when(() => cubit.state).thenReturn(const ThemeInitial());
      whenListen(cubit, Stream<ThemeState>.value(const ThemeInitial()));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows spinner when state is ThemeLoading', (tester) async {
      final cubit = _MockThemeCubit();
      when(() => cubit.state).thenReturn(const ThemeLoading());
      whenListen(cubit, Stream<ThemeState>.value(const ThemeLoading()));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows active theme name when ThemeLoaded', (tester) async {
      final cubit = _MockThemeCubit();
      final state = ThemeLoaded(_dark);
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<ThemeState>.value(state));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.text('Default Dark'), findsOneWidget);
    });

    testWidgets('shows ACTIVE THEME section header when ThemeLoaded',
        (tester) async {
      final cubit = _MockThemeCubit();
      final state = ThemeLoaded(_dark);
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<ThemeState>.value(state));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.text('ACTIVE THEME'), findsOneWidget);
    });

    testWidgets('shows Browse Themes button when ThemeLoaded', (tester) async {
      final cubit = _MockThemeCubit();
      final state = ThemeLoaded(_dark);
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<ThemeState>.value(state));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.text('Browse Themes'), findsOneWidget);
    });

    testWidgets('Browse Themes navigates to ThemeBrowserScreen',
        (tester) async {
      final cubit = _MockThemeCubit();
      final state = ThemeLoaded(_dark);
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<ThemeState>.value(state));

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      await tester.tap(find.text('Browse Themes'));
      await tester.pumpAndSettle();

      expect(find.byType(ThemeBrowserScreen), findsOneWidget);
    });

    testWidgets('onAfterThemeApplied called when Browse Themes screen pops',
        (tester) async {
      final cubit = _MockThemeCubit();
      final state = ThemeLoaded(_dark);
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, Stream<ThemeState>.value(state));

      var called = false;
      await tester.pumpWidget(
        _wrap(cubit, onAfterThemeApplied: () async {
          called = true;
        }),
      );
      await tester.pump();

      await tester.tap(find.text('Browse Themes'));
      await tester.pumpAndSettle();

      expect(find.byType(ThemeBrowserScreen), findsOneWidget);

      // Pop back to ThemesTabView.
      final NavigatorState nav = tester.state(find.byType(Navigator).first);
      nav.pop();
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });
}
