import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_state.dart';

class _MockRepo extends Mock implements DashboardProfileRepository {}

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  blocTest<DashboardProfileCubit, DashboardProfileState>(
    'emits SessionExpired — not a layout error — when the server rejects the '
    'display credentials',
    build: () => DashboardProfileCubit(repo),
    setUp: () {
      when(() => repo.listProfiles())
          .thenThrow(const SessionExpiredException());
    },
    act: (c) => c.loadProfiles(),
    expect: () => [
      const DashboardProfileLoading(),
      const DashboardProfileSessionExpired(),
    ],
  );

  blocTest<DashboardProfileCubit, DashboardProfileState>(
    'still reports ordinary failures as an error',
    build: () => DashboardProfileCubit(repo),
    setUp: () {
      when(() => repo.listProfiles()).thenThrow(StateError('socket closed'));
    },
    act: (c) => c.loadProfiles(),
    expect: () => [
      const DashboardProfileLoading(),
      isA<DashboardProfileError>(),
    ],
  );
}
