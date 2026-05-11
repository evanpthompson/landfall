import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/companion/companion_repository.dart';
import 'companion_state.dart';

export 'companion_state.dart';

class CompanionCubit extends Cubit<CompanionState> {
  CompanionCubit({
    required this.displayId,
    required this.serverUrl,
    required this.repository,
  }) : super(CompanionLoading());

  final String displayId;
  final String serverUrl;
  final CompanionRepository repository;

  Future<void> load() async {
    emit(CompanionLoading());
    try {
      final entity = await repository.getOrCreateForDisplay(displayId);
      emit(CompanionLoaded(entity));
    } catch (_) {
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

  /// Directly injects a loaded entity — for use in widget tests only.
  void loadEntity(CompanionEntity entity) => emit(CompanionLoaded(entity));
}
