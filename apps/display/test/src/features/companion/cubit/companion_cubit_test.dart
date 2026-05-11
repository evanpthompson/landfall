import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/data/companion/companion_repository.dart';
import 'package:display/src/features/companion/cubit/companion_cubit.dart';

class MockCompanionRepository extends Mock implements CompanionRepository {}

CompanionEntity _testEntity({String displayId = 'test-display'}) =>
    CompanionEntity(
      id: '42',
      displayId: displayId,
      seed: 12345,
      rarityTier: RarityTier.rare,
      speciesId: 'lumen',
      name: 'Sparkle',
      traits: [PersonalityTrait.curious],
      evolutionStage: 1,
      createdAt: DateTime(2026, 5, 1),
    );

void main() {
  late MockCompanionRepository repository;

  setUp(() => repository = MockCompanionRepository());

  test('initial state is CompanionLoading', () {
    final cubit = CompanionCubit(
      displayId: 'test',
      serverUrl: 'http://localhost:8080/',
      repository: repository,
    );
    expect(cubit.state, isA<CompanionLoading>());
    cubit.close();
  });

  test('exposes displayId and serverUrl as fields', () {
    final cubit = CompanionCubit(
      displayId: 'my-display',
      serverUrl: 'http://localhost:8080/',
      repository: repository,
    );
    expect(cubit.displayId, 'my-display');
    expect(cubit.serverUrl, 'http://localhost:8080/');
    cubit.close();
  });

  group('load', () {
    blocTest<CompanionCubit, CompanionState>(
      'emits [CompanionLoading, CompanionLoaded] when repository succeeds',
      build: () {
        when(() => repository.getOrCreateForDisplay('test-display'))
            .thenAnswer((_) async => _testEntity());
        return CompanionCubit(
          displayId: 'test-display',
          serverUrl: 'http://localhost:8080/',
          repository: repository,
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<CompanionLoading>(),
        isA<CompanionLoaded>()
            .having((s) => s.entity.name, 'name', 'Sparkle')
            .having((s) => s.entity.rarityTier, 'rarity', RarityTier.rare)
            .having((s) => s.entity.evolutionStage, 'stage', 1),
      ],
    );

    blocTest<CompanionCubit, CompanionState>(
      'falls back to Lumen when repository throws',
      build: () {
        when(() => repository.getOrCreateForDisplay(any()))
            .thenThrow(Exception('network error'));
        return CompanionCubit(
          displayId: 'test-display',
          serverUrl: 'http://localhost:8080/',
          repository: repository,
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<CompanionLoading>(),
        isA<CompanionLoaded>()
            .having((s) => s.entity.speciesId, 'speciesId', 'lumen')
            .having((s) => s.entity.name, 'name', 'Lumen'),
      ],
    );

    blocTest<CompanionCubit, CompanionState>(
      'loaded entity displayId matches cubit displayId',
      build: () {
        when(() => repository.getOrCreateForDisplay('d-99'))
            .thenAnswer((_) async => _testEntity(displayId: 'd-99'));
        return CompanionCubit(
          displayId: 'd-99',
          serverUrl: 'http://localhost:8080/',
          repository: repository,
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<CompanionLoading>(),
        isA<CompanionLoaded>()
            .having((s) => s.entity.displayId, 'displayId', 'd-99'),
      ],
    );
  });
}
