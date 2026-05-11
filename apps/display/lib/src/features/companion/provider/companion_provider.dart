import 'package:landfall_shared/landfall_shared.dart';

import 'sprite_frame_spec.dart';

abstract class SpriteSheetProvider {
  String get providerId;
  double get frameWidth;
  double get frameHeight;

  Set<CompanionAnimationState> get supportedStates;

  CompanionAnimationState get fallbackState => CompanionAnimationState.idle;

  bool supports(CompanionAnimationState state) =>
      supportedStates.contains(state);

  CompanionAnimationState resolve(CompanionAnimationState requested) =>
      supports(requested) ? requested : fallbackState;

  SpriteFrameSpec? specFor(CompanionAnimationState state);
}
