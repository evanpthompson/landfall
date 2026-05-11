import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/companion/companion_event_bus.dart';

void main() {
  group('CompanionEventBus', () {
    late CompanionEventBus bus;

    setUp(() => bus = CompanionEventBus());
    tearDown(() => bus.dispose());

    test('emitted trigger is received on stream', () async {
      final received = <CompanionTrigger>[];
      final sub = bus.events.listen(received.add);

      bus.emit(CompanionTrigger.cardUrgentArrived);
      bus.emit(CompanionTrigger.cardCelebratoryArrived);
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        CompanionTrigger.cardUrgentArrived,
        CompanionTrigger.cardCelebratoryArrived,
      ]);

      await sub.cancel();
    });

    test('multiple listeners each receive events independently', () async {
      final a = <CompanionTrigger>[];
      final b = <CompanionTrigger>[];
      final subA = bus.events.listen(a.add);
      final subB = bus.events.listen(b.add);

      bus.emit(CompanionTrigger.weatherChangedToRain);
      await Future<void>.delayed(Duration.zero);

      expect(a, [CompanionTrigger.weatherChangedToRain]);
      expect(b, [CompanionTrigger.weatherChangedToRain]);

      await subA.cancel();
      await subB.cancel();
    });

    test('triggerToState maps cardUrgentArrived → reactUrgent', () {
      expect(
        CompanionEventBus.triggerToState(CompanionTrigger.cardUrgentArrived),
        CompanionAnimationState.reactUrgent,
      );
    });

    test('triggerToState maps cardCelebratoryArrived → reactCelebratory', () {
      expect(
        CompanionEventBus.triggerToState(
          CompanionTrigger.cardCelebratoryArrived,
        ),
        CompanionAnimationState.reactCelebratory,
      );
    });

    test('triggerToState maps weatherChangedToRain → reactWeatherRain', () {
      expect(
        CompanionEventBus.triggerToState(
          CompanionTrigger.weatherChangedToRain,
        ),
        CompanionAnimationState.reactWeatherRain,
      );
    });

    test('triggerToState maps weatherChangedToSun → reactWeatherSun', () {
      expect(
        CompanionEventBus.triggerToState(CompanionTrigger.weatherChangedToSun),
        CompanionAnimationState.reactWeatherSun,
      );
    });

    test('triggerToState maps nightProfileActivated → reactNight', () {
      expect(
        CompanionEventBus.triggerToState(CompanionTrigger.nightProfileActivated),
        CompanionAnimationState.reactNight,
      );
    });

    test('triggerToState maps dayProfileActivated → idle', () {
      expect(
        CompanionEventBus.triggerToState(CompanionTrigger.dayProfileActivated),
        CompanionAnimationState.idle,
      );
    });

    test('triggerToState maps evolutionMilestoneReached → evolve', () {
      expect(
        CompanionEventBus.triggerToState(
          CompanionTrigger.evolutionMilestoneReached,
        ),
        CompanionAnimationState.evolve,
      );
    });
  });
}
