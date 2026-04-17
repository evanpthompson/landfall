import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'package:display/src/features/cards/cubit/card_state.dart';

class MockCardRepository extends Mock implements CardRepository {}

// Minimal Card factory for tests.
Card makeCard({
  String id = 'card-1',
  String source = 'agent.claude',
  String title = 'Test Card',
  CardPriority priority = CardPriority.normal,
  bool persistent = false,
}) {
  return Card(
    id: id,
    source: source,
    title: title,
    layout: CardLayout.medium,
    priority: priority,
    persistent: persistent,
    createdAt: DateTime(2026, 4, 14, 12, 0, 0),
  );
}

void main() {
  late MockCardRepository repository;

  setUp(() {
    repository = MockCardRepository();
  });

  group('CardCubit', () {
    test('initial state is CardLoading', () {
      final cubit = CardCubit(repository);
      expect(cubit.state, isA<CardLoading>());
    });

    group('fetchCards', () {
      blocTest<CardCubit, CardState>(
        'emits [CardLoading, CardLoaded] when fetch succeeds',
        build: () {
          when(() => repository.getActiveCards()).thenAnswer(
            (_) async => [makeCard()],
          );
          return CardCubit(repository);
        },
        act: (cubit) => cubit.fetchCards(),
        expect: () => [
          isA<CardLoading>(),
          isA<CardLoaded>()
              .having((s) => s.cards.length, 'cards.length', 1),
        ],
      );

      blocTest<CardCubit, CardState>(
        'emits [CardLoading, CardLoaded] with empty list when no active cards',
        build: () {
          when(() => repository.getActiveCards()).thenAnswer(
            (_) async => [],
          );
          return CardCubit(repository);
        },
        act: (cubit) => cubit.fetchCards(),
        expect: () => [
          isA<CardLoading>(),
          isA<CardLoaded>()
              .having((s) => s.cards, 'cards', isEmpty),
        ],
      );

      blocTest<CardCubit, CardState>(
        'emits [CardLoading, CardError] when fetch throws',
        build: () {
          when(() => repository.getActiveCards()).thenThrow(
            Exception('Network error'),
          );
          return CardCubit(repository);
        },
        act: (cubit) => cubit.fetchCards(),
        expect: () => [
          isA<CardLoading>(),
          isA<CardError>(),
        ],
      );

      blocTest<CardCubit, CardState>(
        'always emits CardLoading before CardLoaded on re-fetch',
        build: () {
          when(() => repository.getActiveCards()).thenAnswer(
            (_) async => [makeCard()],
          );
          return CardCubit(repository);
        },
        act: (cubit) async {
          await cubit.fetchCards();
          await cubit.fetchCards();
        },
        expect: () => [
          isA<CardLoading>(),
          isA<CardLoaded>(),
          isA<CardLoading>(),
          isA<CardLoaded>(),
        ],
      );
    });

    group('dismissCard', () {
      blocTest<CardCubit, CardState>(
        'optimistically removes card from CardLoaded state',
        build: () {
          when(() => repository.getActiveCards()).thenAnswer(
            (_) async => [makeCard(id: 'card-1'), makeCard(id: 'card-2')],
          );
          when(() => repository.dismissCard(any())).thenAnswer(
            (_) async => true,
          );
          return CardCubit(repository);
        },
        act: (cubit) async {
          await cubit.fetchCards();
          await cubit.dismissCard('card-1');
        },
        expect: () => [
          isA<CardLoading>(),
          isA<CardLoaded>()
              .having((s) => s.cards.length, 'cards.length', 2),
          isA<CardLoaded>()
              .having((s) => s.cards.length, 'cards.length', 1)
              .having((s) => s.cards.first.id, 'remaining card id', 'card-2'),
        ],
      );

      blocTest<CardCubit, CardState>(
        'does nothing to state if current state is not CardLoaded',
        build: () {
          when(() => repository.dismissCard(any())).thenAnswer(
            (_) async => false,
          );
          return CardCubit(repository);
        },
        // Initial state is CardLoading — dismissCard should be a no-op
        act: (cubit) => cubit.dismissCard('card-1'),
        expect: () => <CardState>[],
      );

      blocTest<CardCubit, CardState>(
        're-fetches from server if dismissCard throws',
        build: () {
          when(() => repository.getActiveCards()).thenAnswer(
            (_) async => [makeCard(id: 'card-1'), makeCard(id: 'card-2')],
          );
          when(() => repository.dismissCard(any())).thenThrow(
            Exception('Server error'),
          );
          return CardCubit(repository);
        },
        act: (cubit) async {
          await cubit.fetchCards();
          await cubit.dismissCard('card-1');
        },
        expect: () => [
          isA<CardLoading>(),
          // Loaded with 2 cards
          isA<CardLoaded>()
              .having((s) => s.cards.length, 'cards.length', 2),
          // Optimistic remove (1 card)
          isA<CardLoaded>()
              .having((s) => s.cards.length, 'cards.length', 1),
          // Re-fetch after failure: loading then back to 2 cards
          isA<CardLoading>(),
          isA<CardLoaded>()
              .having((s) => s.cards.length, 'cards.length', 2),
        ],
      );
    });
  });
}
