import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/cards/cubit/card_cubit.dart';
import 'package:display/src/features/companion/companion_event_bus.dart';

class MockCardRepository extends Mock implements CardRepository {}

Card _card({
  String id = 'c-1',
  CardPriority priority = CardPriority.normal,
  bool persistent = false,
}) =>
    Card(
      id: id,
      source: 'agent.test',
      title: 'Test',
      layout: CardLayout.medium,
      priority: priority,
      persistent: persistent,
      createdAt: DateTime(2026, 5, 1),
    );

void main() {
  late MockCardRepository repository;
  late CompanionEventBus bus;
  late List<CompanionTrigger> captured;

  setUp(() {
    repository = MockCardRepository();
    bus = CompanionEventBus();
    captured = [];
    bus.events.listen(captured.add);
  });

  tearDown(() => bus.dispose());

  test('ephemeral card emits cardUrgentArrived', () async {
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => [_card(priority: CardPriority.ephemeral)]);

    final cubit = CardCubit(repository, bus: bus);
    await cubit.fetchCards();

    expect(captured, contains(CompanionTrigger.cardUrgentArrived));
    await cubit.close();
  });

  test('persistent card emits cardCelebratoryArrived', () async {
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => [_card(persistent: true)]);

    final cubit = CardCubit(repository, bus: bus);
    await cubit.fetchCards();

    expect(captured, contains(CompanionTrigger.cardCelebratoryArrived));
    await cubit.close();
  });

  test('normal card emits no bus trigger', () async {
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => [_card(priority: CardPriority.normal)]);

    final cubit = CardCubit(repository, bus: bus);
    await cubit.fetchCards();

    expect(captured, isEmpty);
    await cubit.close();
  });

  test('second fetch only emits for genuinely new cards', () async {
    final existing = _card(id: 'old', priority: CardPriority.ephemeral);
    final newCard = _card(id: 'new', priority: CardPriority.ephemeral);

    when(() => repository.getActiveCards())
        .thenAnswer((_) async => [existing]);
    final cubit = CardCubit(repository, bus: bus);
    await cubit.fetchCards();
    captured.clear();

    when(() => repository.getActiveCards())
        .thenAnswer((_) async => [existing, newCard]);
    await cubit.fetchCards();

    expect(captured.length, 1);
    expect(captured.first, CompanionTrigger.cardUrgentArrived);
    await cubit.close();
  });

  test('no bus — fetchCards completes without error', () async {
    when(() => repository.getActiveCards())
        .thenAnswer((_) async => [_card(priority: CardPriority.ephemeral)]);

    final cubit = CardCubit(repository);
    await expectLater(cubit.fetchCards(), completes);
    await cubit.close();
  });
}
