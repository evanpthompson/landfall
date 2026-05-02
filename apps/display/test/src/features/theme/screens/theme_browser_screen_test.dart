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

class _MockCubit extends MockCubit<ThemeState> implements ThemeCubit {}

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
final _light = _theme(2, 'default-light', 'Default Light');
final _neon = _theme(3, 'neon-arcade', 'Neon Arcade');
final _allThemes = [_dark, _light, _neon];

Widget _wrap(_MockCubit cubit) => BlocProvider<ThemeCubit>.value(
      value: cubit,
      child: MaterialApp(
        theme: LandfallTheme.dark,
        home: const ThemeBrowserScreen(),
      ),
    );

void main() {
  late _MockCubit cubit;

  setUp(() => cubit = _MockCubit());

  group('ThemeBrowserScreen', () {
    testWidgets('shows loading indicator when ThemeLoading', (tester) async {
      when(() => cubit.state).thenReturn(const ThemeLoading());

      await tester.pumpWidget(_wrap(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when ThemeError', (tester) async {
      when(() => cubit.state)
          .thenReturn(const ThemeError('network error'));

      await tester.pumpWidget(_wrap(cubit));

      expect(find.textContaining('network error'), findsOneWidget);
    });

    testWidgets('renders a card for each theme when ThemeLoaded', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('Default Dark'), findsOneWidget);
      expect(find.text('Default Light'), findsOneWidget);
      expect(find.text('Neon Arcade'), findsOneWidget);
    });

    testWidgets('active theme card shows active indicator', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));

      await tester.pumpWidget(_wrap(cubit));

      // Only one check_circle — the active card
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('inactive cards show Apply button', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));

      await tester.pumpWidget(_wrap(cubit));

      // 2 inactive themes → 2 Apply buttons
      expect(find.text('Apply'), findsNWidgets(2));
    });

    testWidgets('tapping Apply calls cubit.applyTheme with the theme id',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: [_dark, _light]));
      when(() => cubit.applyTheme(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(cubit));

      // Only _dark (id=1) is active; _light (id=2) has an Apply button.
      await tester.tap(find.text('Apply'));
      await tester.pump();

      verify(() => cubit.applyTheme(2)).called(1);
    });

    testWidgets('renders screen title', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('Themes'), findsOneWidget);
    });
  });
}
