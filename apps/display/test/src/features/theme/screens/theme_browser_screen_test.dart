import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart' hide Card;
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/theme/cubit/marketplace_cubit.dart';
import 'package:display/src/features/theme/cubit/marketplace_state.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';
import 'package:display/src/features/theme/screens/theme_browser_screen.dart';

class _MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

class _MockMarketplaceCubit extends MockCubit<MarketplaceState>
    implements MarketplaceCubit {}

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

MarketplaceThemeInfo _mktTheme(int id, String name,
        {int priceUsd = 499, bool isOwned = false}) =>
    MarketplaceThemeInfo(
      theme: _theme(id, name.toLowerCase().replaceAll(' ', '-'), name),
      priceUsd: priceUsd,
      isOwned: isOwned,
    );

final _dark = _theme(1, 'default-dark', 'Default Dark');
final _light = _theme(2, 'default-light', 'Default Light');
final _neon = _theme(3, 'neon-arcade', 'Neon Arcade');
final _allThemes = [_dark, _light, _neon];

Widget _wrap(_MockThemeCubit themeCubit, _MockMarketplaceCubit mktCubit) =>
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<MarketplaceCubit>.value(value: mktCubit),
      ],
      child: MaterialApp(
        theme: LandfallTheme.dark,
        home: const ThemeBrowserScreen(),
      ),
    );

void main() {
  late _MockThemeCubit cubit;
  late _MockMarketplaceCubit mktCubit;

  setUp(() {
    cubit = _MockThemeCubit();
    mktCubit = _MockMarketplaceCubit();
    // Marketplace tab defaults to empty loaded state unless overridden.
    when(() => mktCubit.state)
        .thenReturn(const MarketplaceLoaded(themes: []));
  });

  // ── Installed tab ──────────────────────────────────────────────────────────

  group('ThemeBrowserScreen — Installed tab', () {
    testWidgets('shows loading indicator when ThemeLoading', (tester) async {
      when(() => cubit.state).thenReturn(const ThemeLoading());

      await tester.pumpWidget(_wrap(cubit, mktCubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when ThemeError', (tester) async {
      when(() => cubit.state).thenReturn(const ThemeError('network error'));

      await tester.pumpWidget(_wrap(cubit, mktCubit));

      expect(find.textContaining('network error'), findsOneWidget);
    });

    testWidgets('renders a card for each theme when ThemeLoaded', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));

      await tester.pumpWidget(_wrap(cubit, mktCubit));

      expect(find.text('Default Dark'), findsOneWidget);
      expect(find.text('Default Light'), findsOneWidget);
      expect(find.text('Neon Arcade'), findsOneWidget);
    });

    testWidgets('active theme card shows active indicator', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));

      await tester.pumpWidget(_wrap(cubit, mktCubit));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('inactive cards show Apply button', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));

      await tester.pumpWidget(_wrap(cubit, mktCubit));

      expect(find.text('Apply'), findsNWidgets(2));
    });

    testWidgets('tapping Apply calls cubit.applyTheme with the theme id',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: [_dark, _light]));
      when(() => cubit.applyTheme(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(cubit, mktCubit));

      await tester.tap(find.text('Apply'));
      await tester.pump();

      verify(() => cubit.applyTheme(2)).called(1);
    });

    testWidgets('renders screen title', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));

      await tester.pumpWidget(_wrap(cubit, mktCubit));

      expect(find.text('Themes'), findsOneWidget);
    });
  });

  // ── Marketplace tab ────────────────────────────────────────────────────────

  group('ThemeBrowserScreen — Marketplace tab', () {
    Future<void> switchToMarketplaceTab(WidgetTester tester) async {
      await tester.tap(find.text('Marketplace'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('has a Marketplace tab', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));

      await tester.pumpWidget(_wrap(cubit, mktCubit));

      expect(find.text('Marketplace'), findsOneWidget);
    });

    testWidgets('marketplace tab shows marketplace themes', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));
      when(() => mktCubit.state).thenReturn(MarketplaceLoaded(themes: [
        _mktTheme(10, 'Synthwave 84'),
        _mktTheme(11, 'System Grey', priceUsd: 0),
      ]));

      await tester.pumpWidget(_wrap(cubit, mktCubit));
      await switchToMarketplaceTab(tester);

      expect(find.text('Synthwave 84'), findsOneWidget);
      expect(find.text('System Grey'), findsOneWidget);
    });

    testWidgets('marketplace tab shows price labels', (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: []));
      when(() => mktCubit.state).thenReturn(MarketplaceLoaded(themes: [
        _mktTheme(10, 'Paid Theme', priceUsd: 499),
        _mktTheme(11, 'Free Theme', priceUsd: 0),
      ]));

      await tester.pumpWidget(_wrap(cubit, mktCubit));
      await switchToMarketplaceTab(tester);

      expect(find.text('\$4.99'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('marketplace tab shows Owned badge for purchased themes',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: []));
      when(() => mktCubit.state).thenReturn(MarketplaceLoaded(themes: [
        _mktTheme(10, 'Owned Theme', isOwned: true),
        _mktTheme(11, 'Unowned Theme'),
      ]));

      await tester.pumpWidget(_wrap(cubit, mktCubit));
      await switchToMarketplaceTab(tester);

      expect(find.text('Owned'), findsOneWidget);
    });

    testWidgets('marketplace tab shows loading indicator when MarketplaceLoading',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(ThemeLoaded(_dark, themes: _allThemes));
      when(() => mktCubit.state).thenReturn(const MarketplaceLoading());

      await tester.pumpWidget(_wrap(cubit, mktCubit));
      await switchToMarketplaceTab(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('marketplace tab shows empty message when no themes',
        (tester) async {
      when(() => cubit.state).thenReturn(ThemeLoaded(_dark, themes: []));
      when(() => mktCubit.state)
          .thenReturn(const MarketplaceLoaded(themes: []));

      await tester.pumpWidget(_wrap(cubit, mktCubit));
      await switchToMarketplaceTab(tester);

      expect(find.textContaining('No marketplace themes'), findsOneWidget);
    });
  });
}
