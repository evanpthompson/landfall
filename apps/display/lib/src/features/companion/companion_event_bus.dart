import 'dart:async';

import 'package:landfall_shared/landfall_shared.dart';

class CompanionEventBus {
  final _controller = StreamController<CompanionTrigger>.broadcast(sync: true);
  final _kindController = StreamController<String>.broadcast(sync: true);

  Stream<CompanionTrigger> get events => _controller.stream;

  /// Web companion action kinds (pet / play / feed) routed from the server
  /// long-poll. CompanionCard subscribes and triggers the matching animation.
  Stream<String> get companionKinds => _kindController.stream;

  void emit(CompanionTrigger trigger) => _controller.add(trigger);

  void emitCompanionKind(String kind) => _kindController.add(kind);

  void dispose() {
    _controller.close();
    _kindController.close();
  }

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
