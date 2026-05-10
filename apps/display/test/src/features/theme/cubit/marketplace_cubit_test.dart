import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/theme/cubit/marketplace_cubit.dart';
import 'package:display/src/features/theme/cubit/marketplace_state.dart';

class _MockRepo extends Mock implements MarketplaceRepository {}

// ── fixtures ──────────────────────────────────────────────────────────────────

LandfallThemeTokens _tokens() => const LandfallThemeTokens(
      backgroundType: 'solid',
      backgroundValue: '#000000',
      cardFill: '#111111',
      cardBorderColor: '#222222',
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
      colorAccent: '#00ffcc',
      colorAccentMuted: '#00ccaa',
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

ThemeInfo _theme(int id, String slug) => ThemeInfo(
      id: id,
      slug: slug,
      name: slug,
      schemaVersion: '1.0',
      isBuiltIn: false,
      tokens: _tokens(),
    );

MarketplaceThemeInfo _mktTheme(int id, String slug,
        {int priceUsd = 499, bool isOwned = false}) =>
    MarketplaceThemeInfo(
      theme: _theme(id, slug),
      priceUsd: priceUsd,
      isOwned: isOwned,
    );

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  MarketplaceCubit build() => MarketplaceCubit(repo);

  // ── loadMarketplace ──────────────────────────────────────────────────────────

  group('loadMarketplace', () {
    blocTest<MarketplaceCubit, MarketplaceState>(
      'emits Loading then Loaded when themes exist',
      build: build,
      setUp: () {
        when(() => repo.listMarketplaceThemes()).thenAnswer((_) async => [
              _mktTheme(1, 'neon-arcade'),
              _mktTheme(2, 'deep-blue', priceUsd: 0),
            ]);
      },
      act: (c) => c.loadMarketplace(),
      expect: () => [
        const MarketplaceLoading(),
        predicate<MarketplaceState>((s) =>
            s is MarketplaceLoaded && s.themes.length == 2),
      ],
    );

    blocTest<MarketplaceCubit, MarketplaceState>(
      'emits Loading then Loaded with empty list when no marketplace themes',
      build: build,
      setUp: () {
        when(() => repo.listMarketplaceThemes()).thenAnswer((_) async => []);
      },
      act: (c) => c.loadMarketplace(),
      expect: () => [
        const MarketplaceLoading(),
        const MarketplaceLoaded(themes: []),
      ],
    );

    blocTest<MarketplaceCubit, MarketplaceState>(
      'emits Loading then Error when repository throws',
      build: build,
      setUp: () {
        when(() => repo.listMarketplaceThemes())
            .thenThrow(Exception('network error'));
      },
      act: (c) => c.loadMarketplace(),
      expect: () => [
        const MarketplaceLoading(),
        isA<MarketplaceError>(),
      ],
    );

    blocTest<MarketplaceCubit, MarketplaceState>(
      'loaded themes carry isOwned flag from repository',
      build: build,
      setUp: () {
        when(() => repo.listMarketplaceThemes()).thenAnswer((_) async => [
              _mktTheme(1, 'owned-theme', isOwned: true),
              _mktTheme(2, 'unowned-theme'),
            ]);
      },
      act: (c) => c.loadMarketplace(),
      expect: () => [
        const MarketplaceLoading(),
        predicate<MarketplaceState>((s) {
          if (s is! MarketplaceLoaded) return false;
          final owned = s.themes.firstWhere((t) => t.theme.slug == 'owned-theme');
          final unowned =
              s.themes.firstWhere((t) => t.theme.slug == 'unowned-theme');
          return owned.isOwned && !unowned.isOwned;
        }),
      ],
    );
  });

  // ── refreshOwnedThemes ──────────────────────────────────────────────────────

  group('refreshOwnedThemes', () {
    blocTest<MarketplaceCubit, MarketplaceState>(
      'updates isOwned on existing themes after purchase',
      build: build,
      setUp: () {
        when(() => repo.listMarketplaceThemes()).thenAnswer((_) async => [
              _mktTheme(1, 'neon-arcade'),
              _mktTheme(2, 'deep-blue'),
            ]);
        when(() => repo.getOwnedThemes()).thenAnswer((_) async => [
              _mktTheme(1, 'neon-arcade', isOwned: true),
            ]);
      },
      seed: () => MarketplaceLoaded(themes: [
        _mktTheme(1, 'neon-arcade'),
        _mktTheme(2, 'deep-blue'),
      ]),
      act: (c) => c.refreshOwnedThemes(),
      expect: () => [
        predicate<MarketplaceState>((s) {
          if (s is! MarketplaceLoaded) return false;
          final neon = s.themes.firstWhere((t) => t.theme.slug == 'neon-arcade');
          final deep = s.themes.firstWhere((t) => t.theme.slug == 'deep-blue');
          return neon.isOwned && !deep.isOwned;
        }),
      ],
    );

    blocTest<MarketplaceCubit, MarketplaceState>(
      'does nothing when state is not Loaded',
      build: build,
      seed: () => const MarketplaceLoading(),
      act: (c) => c.refreshOwnedThemes(),
      expect: () => [],
    );
  });

  // ── state equality ──────────────────────────────────────────────────────────

  group('MarketplaceLoaded equality', () {
    test('equal when theme lists match', () {
      final themes = [_mktTheme(1, 'neon')];
      expect(
        MarketplaceLoaded(themes: themes),
        equals(MarketplaceLoaded(themes: themes)),
      );
    });

    test('not equal when theme lists differ in length', () {
      expect(
        MarketplaceLoaded(themes: [_mktTheme(1, 'neon')]),
        isNot(equals(const MarketplaceLoaded(themes: []))),
      );
    });
  });

  group('MarketplaceError equality', () {
    test('equal when messages match', () {
      expect(
        const MarketplaceError('oops'),
        equals(const MarketplaceError('oops')),
      );
    });
    test('not equal when messages differ', () {
      expect(
        const MarketplaceError('a'),
        isNot(equals(const MarketplaceError('b'))),
      );
    });
  });
}
