import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:display/src/domain/use_cases/get_current_time_use_case.dart';
import 'package:display/src/features/clock/cubit/clock_cubit.dart';
import 'package:display/src/features/clock/cubit/clock_state.dart';

class MockClockRepository extends Mock implements ClockRepository {}

/// Builds a real [GetCurrentTimeUseCase] backed by the mock repository.
/// This tests the full chain: cubit → use case → repository.
GetCurrentTimeUseCase makeUseCase(ClockRepository repo) =>
    GetCurrentTimeUseCase(repo);

void main() {
  late MockClockRepository repository;

  setUp(() {
    repository = MockClockRepository();
  });

  group('ClockCubit', () {
    test('initial state is ClockInitial', () {
      when(() => repository.clockStream())
          .thenAnswer((_) => const Stream.empty());
      final cubit = ClockCubit(makeUseCase(repository));
      expect(cubit.state, isA<ClockInitial>());
    });

    group('startTicking', () {
      final t0 = DateTime(2026, 4, 17, 9, 30, 0);
      final t1 = DateTime(2026, 4, 17, 9, 30, 1);

      blocTest<ClockCubit, ClockState>(
        'emits ClockTicking for each entity the stream emits',
        build: () {
          when(() => repository.clockStream()).thenAnswer(
            (_) => Stream.fromIterable([ClockEntity(t0), ClockEntity(t1)]),
          );
          return ClockCubit(makeUseCase(repository));
        },
        act: (cubit) => cubit.startTicking(),
        expect: () => [
          ClockTicking(ClockEntity(t0)),
          ClockTicking(ClockEntity(t1)),
        ],
      );

      blocTest<ClockCubit, ClockState>(
        'does not emit ClockInitial after ticking starts',
        build: () {
          when(() => repository.clockStream()).thenAnswer(
            (_) => Stream.fromIterable([ClockEntity(t0)]),
          );
          return ClockCubit(makeUseCase(repository));
        },
        act: (cubit) => cubit.startTicking(),
        expect: () => [isA<ClockTicking>()],
      );

      blocTest<ClockCubit, ClockState>(
        'subscribes to the repository stream exactly once per startTicking call',
        build: () {
          when(() => repository.clockStream())
              .thenAnswer((_) => Stream.fromIterable([ClockEntity(t0)]));
          return ClockCubit(makeUseCase(repository));
        },
        act: (cubit) => cubit.startTicking(),
        verify: (_) {
          verify(() => repository.clockStream()).called(1);
        },
      );

      blocTest<ClockCubit, ClockState>(
        're-subscribes when startTicking is called again',
        build: () {
          when(() => repository.clockStream()).thenAnswer(
            (_) => Stream.fromIterable([ClockEntity(t0)]),
          );
          return ClockCubit(makeUseCase(repository));
        },
        act: (cubit) async {
          await cubit.startTicking();
          await cubit.startTicking();
        },
        verify: (_) {
          verify(() => repository.clockStream()).called(2);
        },
      );
    });
  });
}
