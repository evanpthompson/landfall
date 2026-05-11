import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'companion_state.dart';

export 'companion_state.dart';

/// Manages the companion's persistent identity — which creature lives on this
/// display, its rarity, traits, and evolution stage.
///
/// MVP: seeds from [displayId] and uses a fixed Lumen entity. Future phases
/// will load from the server and evaluate evolution signals nightly.
class CompanionCubit extends Cubit<CompanionState> {
  CompanionCubit({required this.displayId}) : super(CompanionLoading()) {
    _load();
  }

  final String displayId;

  void _load() {
    // MVP: Lumen is the demo creature for this display.
    // Phase 22+ will seed from displayId using xrandom to pick from the full pool.
    emit(
      CompanionLoaded(
        CompanionEntity(
          id: 'companion_${displayId}_lumen',
          displayId: displayId,
          seed: displayId.hashCode,
          rarityTier: RarityTier.uncommon,
          speciesId: 'lumen',
          name: 'Lumen',
          traits: [PersonalityTrait.curious, PersonalityTrait.gentle],
          evolutionStage: 0,
          createdAt: DateTime(2026, 5, 10),
          assetCredit: '@changhaoliao via petdex (crafter.run)',
        ),
      ),
    );
  }
}
