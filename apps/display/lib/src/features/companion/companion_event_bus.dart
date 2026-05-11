import 'dart:async';

import 'package:landfall_shared/landfall_shared.dart';

class CompanionEventBus {
  final _controller = StreamController<CompanionTrigger>.broadcast(sync: true);

  Stream<CompanionTrigger> get events => _controller.stream;

  void emit(CompanionTrigger trigger) => _controller.add(trigger);

  void dispose() => _controller.close();

  static CompanionAnimationState triggerToState(CompanionTrigger trigger) {
    return switch (trigger) {
      CompanionTrigger.cardUrgentArrived => CompanionAnimationState.reactUrgent,
      CompanionTrigger.cardCelebratoryArrived => CompanionAnimationState.reactCelebratory,
      CompanionTrigger.weatherChangedToRain => CompanionAnimationState.reactWeatherRain,
      CompanionTrigger.weatherChangedToSun => CompanionAnimationState.reactWeatherSun,
      CompanionTrigger.nightProfileActivated => CompanionAnimationState.reactNight,
      CompanionTrigger.dayProfileActivated => CompanionAnimationState.idle,
      CompanionTrigger.evolutionMilestoneReached => CompanionAnimationState.evolve,
    };
  }
}
