import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:display/src/domain/use_cases/get_current_time_use_case.dart';

class MockClockRepository extends Mock implements ClockRepository {}

void main() {
  late MockClockRepository repository;
  late GetCurrentTimeUseCase useCase;

  setUp(() {
    repository = MockClockRepository();
    useCase = GetCurrentTimeUseCase(repository);
  });

  group('GetCurrentTimeUseCase', () {
    test('call() returns the repository stream', () {
      final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 0));
      final stream = Stream.fromIterable([entity]);
      when(() => repository.clockStream()).thenAnswer((_) => stream);

      final result = useCase();

      expect(result, isA<Stream<ClockEntity>>());
      verify(() => repository.clockStream()).called(1);
    });

    test('call() delegates to repository on each invocation', () {
      final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 0));
      when(() => repository.clockStream())
          .thenAnswer((_) => Stream.fromIterable([entity]));

      useCase();
      useCase();

      verify(() => repository.clockStream()).called(2);
    });
  });
}
