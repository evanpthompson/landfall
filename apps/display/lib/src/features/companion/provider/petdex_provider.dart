import 'package:landfall_shared/landfall_shared.dart';

import 'companion_provider.dart';
import 'sprite_frame_spec.dart';

// Row mapping derived from petdex pet-states.ts (not the README — the README is wrong).
class PetdexProvider extends SpriteSheetProvider {
  static const _map = <CompanionAnimationState, SpriteFrameSpec>{
    CompanionAnimationState.idle: SpriteFrameSpec(row: 0, frameCount: 6, fps: 6),
    CompanionAnimationState.play: SpriteFrameSpec(row: 1, frameCount: 8, fps: 12),
    CompanionAnimationState.playLeft: SpriteFrameSpec(row: 2, frameCount: 8, fps: 12),
    CompanionAnimationState.pet: SpriteFrameSpec(row: 3, frameCount: 4, fps: 8, loops: false),
    CompanionAnimationState.reactCelebratory: SpriteFrameSpec(row: 4, frameCount: 5, fps: 12, loops: false),
    CompanionAnimationState.reactUrgent: SpriteFrameSpec(row: 5, frameCount: 8, fps: 12, loops: false),
    CompanionAnimationState.idleCalm: SpriteFrameSpec(row: 6, frameCount: 6, fps: 8),
    CompanionAnimationState.playSprint: SpriteFrameSpec(row: 7, frameCount: 8, fps: 12),
    CompanionAnimationState.lookAtViewer: SpriteFrameSpec(row: 8, frameCount: 6, fps: 8, loops: false),
  };

  @override
  String get providerId => 'petdex';

  @override
  double get frameWidth => 192;

  @override
  double get frameHeight => 208;

  @override
  Set<CompanionAnimationState> get supportedStates => _map.keys.toSet();

  @override
  SpriteFrameSpec? specFor(CompanionAnimationState state) => _map[state];
}
