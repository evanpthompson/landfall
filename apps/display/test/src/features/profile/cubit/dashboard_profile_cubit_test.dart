import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';

class _MockRepo extends Mock implements DashboardProfileRepository {}

// ── fixtures ──────────────────────────────────────────────────────────────────

ProfileInfo _profile(int id, String name, {bool active = false}) => ProfileInfo(
      id: id,
      name: name,
      slug: name.toLowerCase(),
      isActive: active,
      layout: DashboardLayout.weekdayLayout(),
      sortOrder: id,
    );

final _weekday = _profile(1, 'Weekday', active: true);
final _weekend = _profile(2, 'Weekend');
final _night = _profile(3, 'Night');
final _all = [_weekday, _weekend, _night];

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(DashboardLayout.weekdayLayout());
  });

  DashboardProfileCubit build() => DashboardProfileCubit(repo);

  // ── loadProfiles ────────────────────────────────────────────────────────────

  group('loadProfiles', () {
    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'emits Loading then Loaded when profiles exist',
      build: build,
      setUp: () {
        when(() => repo.listProfiles()).thenAnswer((_) async => _all);
      },
      act: (c) => c.loadProfiles(),
      expect: () => [
        const DashboardProfileLoading(),
        DashboardProfileLoaded(_weekday, profiles: _all),
      ],
    );

    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'seeds defaults and emits Loaded when server has no profiles',
      build: build,
      setUp: () {
        var listCallCount = 0;
        when(() => repo.listProfiles()).thenAnswer((_) async {
          listCallCount++;
          return listCallCount == 1 ? [] : _all;
        });
        when(() => repo.createProfile(any(), layout: any(named: 'layout')))
            .thenAnswer((_) async => _weekday);
        when(() => repo.activateProfile(any()))
            .thenAnswer((_) async => _weekday);
      },
      act: (c) => c.loadProfiles(),
      expect: () => [
        const DashboardProfileLoading(),
        DashboardProfileLoaded(_weekday, profiles: _all),
      ],
    );

    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'emits Loading then Error when repository throws',
      build: build,
      setUp: () {
        when(() => repo.listProfiles()).thenThrow(Exception('network error'));
      },
      act: (c) => c.loadProfiles(),
      expect: () => [
        const DashboardProfileLoading(),
        isA<DashboardProfileError>(),
      ],
    );

    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'selects first profile as active when none is marked active',
      build: build,
      setUp: () {
        final noActive = [
          _profile(1, 'Weekday'),
          _profile(2, 'Weekend'),
        ];
        when(() => repo.listProfiles()).thenAnswer((_) async => noActive);
      },
      act: (c) => c.loadProfiles(),
      expect: () => [
        const DashboardProfileLoading(),
        predicate<DashboardProfileState>((s) =>
            s is DashboardProfileLoaded && s.active.name == 'Weekday'),
      ],
    );
  });

  // ── activateProfile ─────────────────────────────────────────────────────────

  group('activateProfile', () {
    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'calls activateProfile on repo then refreshes state',
      build: build,
      setUp: () {
        when(() => repo.activateProfile(2))
            .thenAnswer((_) async => _weekend.copyWith(isActive: true));
        when(() => repo.listProfiles()).thenAnswer((_) async => [
              _weekday.copyWith(isActive: false),
              _weekend.copyWith(isActive: true),
              _night,
            ]);
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.activateProfile(2),
      expect: () => [
        predicate<DashboardProfileState>((s) =>
            s is DashboardProfileLoaded && s.active.name == 'Weekend'),
      ],
    );

    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'emits Error when activateProfile throws',
      build: build,
      setUp: () {
        when(() => repo.activateProfile(any()))
            .thenThrow(Exception('server error'));
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.activateProfile(2),
      expect: () => [isA<DashboardProfileError>()],
    );
  });

  // ── saveActiveLayout ─────────────────────────────────────────────────────────

  group('saveActiveLayout', () {
    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'calls updateProfile with new layout then refreshes',
      build: build,
      setUp: () {
        when(() => repo.updateProfile(any(), layout: any(named: 'layout')))
            .thenAnswer((_) async => _weekday);
        when(() => repo.listProfiles()).thenAnswer((_) async => _all);
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.saveActiveLayout(DashboardLayout.nightLayout()),
      verify: (_) {
        verify(() => repo.updateProfile(
              _weekday.id,
              layout: any(named: 'layout'),
            )).called(1);
      },
    );

    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'does nothing when state is not Loaded',
      build: build,
      seed: () => const DashboardProfileLoading(),
      act: (c) => c.saveActiveLayout(DashboardLayout.nightLayout()),
      expect: () => [],
    );
  });

  // ── createProfile ────────────────────────────────────────────────────────────

  group('createProfile', () {
    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'calls createProfile on repo then refreshes',
      build: build,
      setUp: () {
        final newProfile = _profile(4, 'Party');
        when(() => repo.createProfile('Party', layout: any(named: 'layout')))
            .thenAnswer((_) async => newProfile);
        when(() => repo.listProfiles())
            .thenAnswer((_) async => [..._all, newProfile]);
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.createProfile('Party'),
      expect: () => [
        predicate<DashboardProfileState>((s) =>
            s is DashboardProfileLoaded && s.profiles.length == 4),
      ],
    );

    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'emits Error when createProfile throws',
      build: build,
      setUp: () {
        when(() => repo.createProfile(any(), layout: any(named: 'layout')))
            .thenThrow(Exception('server error'));
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.createProfile('Party'),
      expect: () => [isA<DashboardProfileError>()],
    );
  });

  // ── renameProfile ─────────────────────────────────────────────────────────────

  group('renameProfile', () {
    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'calls updateProfile with new name then refreshes',
      build: build,
      setUp: () {
        when(() => repo.updateProfile(1, name: 'Morning'))
            .thenAnswer((_) async => _weekday.copyWith(name: 'Morning'));
        when(() => repo.listProfiles()).thenAnswer((_) async => [
              _weekday.copyWith(name: 'Morning'),
              _weekend,
              _night,
            ]);
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.renameProfile(1, 'Morning'),
      expect: () => [
        predicate<DashboardProfileState>((s) =>
            s is DashboardProfileLoaded && s.active.name == 'Morning'),
      ],
    );
  });

  // ── duplicateProfile ──────────────────────────────────────────────────────────

  group('duplicateProfile', () {
    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'calls duplicateProfile on repo then refreshes',
      build: build,
      setUp: () {
        final copy = _profile(4, 'Weekday Copy');
        when(() => repo.duplicateProfile(1, 'Weekday Copy'))
            .thenAnswer((_) async => copy);
        when(() => repo.listProfiles())
            .thenAnswer((_) async => [..._all, copy]);
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.duplicateProfile(1, 'Weekday Copy'),
      expect: () => [
        predicate<DashboardProfileState>((s) =>
            s is DashboardProfileLoaded && s.profiles.length == 4),
      ],
    );
  });

  // ── deleteProfile ─────────────────────────────────────────────────────────────

  group('deleteProfile', () {
    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'calls deleteProfile on repo then refreshes',
      build: build,
      setUp: () {
        when(() => repo.deleteProfile(3)).thenAnswer((_) async {});
        when(() => repo.listProfiles())
            .thenAnswer((_) async => [_weekday, _weekend]);
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.deleteProfile(3),
      expect: () => [
        predicate<DashboardProfileState>((s) =>
            s is DashboardProfileLoaded && s.profiles.length == 2),
      ],
    );

    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'emits Error when deleteProfile throws',
      build: build,
      setUp: () {
        when(() => repo.deleteProfile(any()))
            .thenThrow(Exception('cannot delete active profile'));
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.deleteProfile(1),
      expect: () => [isA<DashboardProfileError>()],
    );
  });

  // ── state equality ────────────────────────────────────────────────────────────

  group('DashboardProfileLoaded equality', () {
    test('equal when active and profiles match', () {
      final a = DashboardProfileLoaded(_weekday, profiles: _all);
      final b = DashboardProfileLoaded(_weekday, profiles: _all);
      expect(a, equals(b));
    });

    test('not equal when active differs', () {
      final a = DashboardProfileLoaded(_weekday, profiles: _all);
      final b = DashboardProfileLoaded(_weekend, profiles: _all);
      expect(a, isNot(equals(b)));
    });
  });

  group('DashboardProfileError equality', () {
    test('equal when messages match', () {
      expect(
        const DashboardProfileError('oops'),
        equals(const DashboardProfileError('oops')),
      );
    });

    test('not equal when messages differ', () {
      expect(
        const DashboardProfileError('a'),
        isNot(equals(const DashboardProfileError('b'))),
      );
    });
  });

  // ── resetActiveLayout ────────────────────────────────────────────────────────

  group('resetActiveLayout', () {
    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'saves the active profile default layout then refreshes',
      build: build,
      setUp: () {
        when(() => repo.updateProfile(any(), layout: any(named: 'layout')))
            .thenAnswer((_) async => _weekday);
        when(() => repo.listProfiles()).thenAnswer((_) async => _all);
      },
      seed: () => DashboardProfileLoaded(_weekday, profiles: _all),
      act: (c) => c.resetActiveLayout(),
      verify: (_) {
        verify(() => repo.updateProfile(
              _weekday.id,
              layout: any(named: 'layout'),
            )).called(1);
      },
    );

    blocTest<DashboardProfileCubit, DashboardProfileState>(
      'does nothing when state is not Loaded',
      build: build,
      seed: () => const DashboardProfileLoading(),
      act: (c) => c.resetActiveLayout(),
      expect: () => [],
    );
  });
}
