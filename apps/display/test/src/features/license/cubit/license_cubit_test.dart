import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/license/cubit/license_cubit.dart';

class _MockRepo extends Mock implements LicenseRepository {}

const _freeTier = LicenseStatus(tier: LicenseTier.free);
final _proTier = LicenseStatus(
  tier: LicenseTier.pro,
  activatedAt: DateTime.utc(2026, 4, 26),
  maskedKey: 'LF-PRO-****-1234',
);

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  LicenseCubit build() => LicenseCubit(repo);

  group('loadStatus', () {
    blocTest<LicenseCubit, LicenseState>(
      'emits [loading, loaded(free)] when no license activated',
      build: build,
      setUp: () {
        when(() => repo.getLicenseStatus())
            .thenAnswer((_) async => _freeTier);
      },
      act: (c) => c.loadStatus(),
      expect: () => [
        const LicenseLoading(),
        LicenseLoaded(_freeTier),
      ],
    );

    blocTest<LicenseCubit, LicenseState>(
      'emits [loading, loaded(pro)] when pro license active',
      build: build,
      setUp: () {
        when(() => repo.getLicenseStatus()).thenAnswer((_) async => _proTier);
      },
      act: (c) => c.loadStatus(),
      expect: () => [
        const LicenseLoading(),
        LicenseLoaded(_proTier),
      ],
    );

    blocTest<LicenseCubit, LicenseState>(
      'emits [loading, error] when repository throws',
      build: build,
      setUp: () {
        when(() => repo.getLicenseStatus())
            .thenThrow(Exception('server error'));
      },
      act: (c) => c.loadStatus(),
      expect: () => [
        const LicenseLoading(),
        isA<LicenseError>(),
      ],
    );
  });

  group('activateLicense', () {
    blocTest<LicenseCubit, LicenseState>(
      'emits [activating, loaded(pro)] on success',
      build: build,
      setUp: () {
        when(() => repo.activateLicense('LF-PRO-TEST-0001'))
            .thenAnswer((_) async => _proTier);
      },
      act: (c) => c.activateLicense('LF-PRO-TEST-0001'),
      expect: () => [
        const LicenseActivating(),
        LicenseLoaded(_proTier),
      ],
    );

    blocTest<LicenseCubit, LicenseState>(
      'emits [activating, error] when key is invalid',
      build: build,
      setUp: () {
        when(() => repo.activateLicense('BAD-KEY'))
            .thenThrow(Exception('key not found'));
      },
      act: (c) => c.activateLicense('BAD-KEY'),
      expect: () => [
        const LicenseActivating(),
        isA<LicenseError>(),
      ],
    );
  });
}
