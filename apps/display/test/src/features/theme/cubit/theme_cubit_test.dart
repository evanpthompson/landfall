import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';

class _MockRepo extends Mock implements ThemeRepository {}

class _MockProfileRepo extends Mock implements DashboardProfileRepository {}

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
  colorAccent: '#ffffff',
  colorAccentMuted: '#cccccc',
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

ThemeInfo _theme(int id, String slug, {String name = ''}) => ThemeInfo(
  id: id,
  slug: slug,
  name: name.isEmpty ? slug : name,
  schemaVersion: '1.0',
  isBuiltIn: true,
  tokens: _tokens(),
);

final _defaultDark = _theme(1, 'default-dark', name: 'Default Dark');
final _defaultLight = _theme(2, 'default-light', name: 'Default Light');
final _neon = _theme(3, 'neon-arcade', name: 'Neon Arcade');
final _allThemes = [_defaultDark, _defaultLight, _neon];

ProfileInfo _profile({String? themeSlug}) => ProfileInfo(
  id: 7,
  name: 'Weekday',
  slug: 'weekday',
  isActive: true,
  layout: DashboardLayout.weekdayLayout(),
  sortOrder: 0,
  companionThemeSlug: themeSlug,
);

void main() {
  late _MockRepo repo;
  late _MockProfileRepo profileRepo;

  setUp(() {
    repo = _MockRepo();
    profileRepo = _MockProfileRepo();
  });

  ThemeCubit build() => ThemeCubit(repo);

  // ── loadThemes ────────────────────────────────────────────────────────────

  group('loadThemes', () {
    blocTest<ThemeCubit, ThemeState>(
      'emits Loading then Loaded when themes exist',
      build: build,
      setUp: () {
        when(() => repo.listThemes()).thenAnswer((_) async => _allThemes);
      },
      act: (c) => c.loadThemes(),
      expect: () => [
        const ThemeLoading(),
        ThemeLoaded(_defaultDark, themes: _allThemes),
      ],
    );

    blocTest<ThemeCubit, ThemeState>(
      'selects default-dark as active when present',
      build: build,
      setUp: () {
        when(
          () => repo.listThemes(),
        ).thenAnswer((_) async => [_neon, _defaultDark, _defaultLight]);
      },
      act: (c) => c.loadThemes(),
      expect: () => [
        const ThemeLoading(),
        predicate<ThemeState>(
          (s) => s is ThemeLoaded && s.active.slug == 'default-dark',
        ),
      ],
    );

    blocTest<ThemeCubit, ThemeState>(
      'falls back to first theme when default-dark is absent',
      build: build,
      setUp: () {
        when(
          () => repo.listThemes(),
        ).thenAnswer((_) async => [_neon, _defaultLight]);
      },
      act: (c) => c.loadThemes(),
      expect: () => [
        const ThemeLoading(),
        predicate<ThemeState>(
          (s) => s is ThemeLoaded && s.active.slug == 'neon-arcade',
        ),
      ],
    );

    blocTest<ThemeCubit, ThemeState>(
      'restores the active profile theme on startup',
      build: () => ThemeCubit(repo, profileRepository: profileRepo),
      setUp: () {
        when(() => repo.listThemes()).thenAnswer((_) async => _allThemes);
        when(
          () => profileRepo.getActiveProfile(),
        ).thenAnswer((_) async => _profile(themeSlug: 'neon-arcade'));
      },
      act: (c) => c.loadThemes(),
      expect: () => [
        const ThemeLoading(),
        predicate<ThemeState>(
          (s) => s is ThemeLoaded && s.active.slug == 'neon-arcade',
        ),
      ],
    );

    blocTest<ThemeCubit, ThemeState>(
      'emits Loading then Error when repository throws',
      build: build,
      setUp: () {
        when(() => repo.listThemes()).thenThrow(Exception('network error'));
      },
      act: (c) => c.loadThemes(),
      expect: () => [const ThemeLoading(), isA<ThemeError>()],
    );
  });

  // ── applyTheme ────────────────────────────────────────────────────────────

  group('applyTheme', () {
    blocTest<ThemeCubit, ThemeState>(
      'calls repo.applyTheme and emits Loaded with new active',
      build: build,
      setUp: () {
        when(
          () => repo.applyTheme(2, profileId: any(named: 'profileId')),
        ).thenAnswer((_) async {});
        when(() => repo.listThemes()).thenAnswer((_) async => _allThemes);
      },
      seed: () => ThemeLoaded(_defaultDark, themes: _allThemes),
      act: (c) => c.applyTheme(2),
      expect: () => [
        predicate<ThemeState>(
          (s) => s is ThemeLoaded && s.active.slug == 'default-light',
        ),
      ],
      verify: (_) {
        verify(() => repo.applyTheme(2, profileId: null)).called(1);
      },
    );

    blocTest<ThemeCubit, ThemeState>(
      'passes profileId to repo when provided',
      build: build,
      setUp: () {
        when(
          () => repo.applyTheme(any(), profileId: any(named: 'profileId')),
        ).thenAnswer((_) async {});
        when(() => repo.listThemes()).thenAnswer((_) async => _allThemes);
      },
      seed: () => ThemeLoaded(_defaultDark, themes: _allThemes),
      act: (c) => c.applyTheme(3, profileId: 7),
      verify: (_) {
        verify(() => repo.applyTheme(3, profileId: 7)).called(1);
      },
    );

    blocTest<ThemeCubit, ThemeState>(
      'applies to the active profile when profileId is omitted',
      build: () => ThemeCubit(repo, profileRepository: profileRepo),
      setUp: () {
        when(
          () => profileRepo.getActiveProfile(),
        ).thenAnswer((_) async => _profile());
        when(
          () => repo.applyTheme(any(), profileId: any(named: 'profileId')),
        ).thenAnswer((_) async {});
        when(() => repo.listThemes()).thenAnswer((_) async => _allThemes);
      },
      seed: () => ThemeLoaded(_defaultDark, themes: _allThemes),
      act: (c) => c.applyTheme(3),
      verify: (_) {
        verify(() => repo.applyTheme(3, profileId: 7)).called(1);
      },
    );

    blocTest<ThemeCubit, ThemeState>(
      'emits Error when applyTheme throws',
      build: build,
      setUp: () {
        when(
          () => repo.applyTheme(any(), profileId: any(named: 'profileId')),
        ).thenThrow(Exception('not found'));
      },
      seed: () => ThemeLoaded(_defaultDark, themes: _allThemes),
      act: (c) => c.applyTheme(99),
      expect: () => [isA<ThemeError>()],
    );

    blocTest<ThemeCubit, ThemeState>(
      'does nothing when state is not Loaded',
      build: build,
      seed: () => const ThemeLoading(),
      act: (c) => c.applyTheme(2),
      expect: () => [],
    );
  });

  // ── state equality ────────────────────────────────────────────────────────

  group('ThemeLoaded equality', () {
    test('equal when active and theme list match', () {
      final a = ThemeLoaded(_defaultDark, themes: _allThemes);
      final b = ThemeLoaded(_defaultDark, themes: _allThemes);
      expect(a, equals(b));
    });

    test('not equal when active differs', () {
      final a = ThemeLoaded(_defaultDark, themes: _allThemes);
      final b = ThemeLoaded(_defaultLight, themes: _allThemes);
      expect(a, isNot(equals(b)));
    });
  });

  group('ThemeError equality', () {
    test('equal when messages match', () {
      expect(const ThemeError('oops'), equals(const ThemeError('oops')));
    });

    test('not equal when messages differ', () {
      expect(const ThemeError('a'), isNot(equals(const ThemeError('b'))));
    });
  });
}
