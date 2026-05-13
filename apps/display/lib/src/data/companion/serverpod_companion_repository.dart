import 'package:landfall_client/landfall_client.dart' as lf;
import 'package:landfall_shared/landfall_shared.dart';

import 'companion_repository.dart';

class ServerpodCompanionRepository implements CompanionRepository {
  ServerpodCompanionRepository(this._client);

  final lf.Client _client;

  @override
  Future<CompanionEntity> getOrCreateForDisplay(String displayId) async {
    final raw = await _client.companion.getOrCreateForDisplay(displayId);
    return _toShared(raw);
  }

  @override
  Future<String> getCompanionBaseUrl() =>
      _client.companion.getCompanionBaseUrl();

  static CompanionEntity _toShared(lf.CompanionEntity raw) {
    return CompanionEntity(
      id: raw.id?.toString() ?? raw.displayId,
      displayId: raw.displayId,
      seed: raw.seed,
      rarityTier: _parseRarity(raw.rarityTier),
      speciesId: raw.speciesId,
      name: raw.name,
      traits: _parseTraits(raw.traits),
      evolutionStage: raw.evolutionStage,
      createdAt: raw.createdAt,
      assetCredit: raw.assetCredit,
      lastEvolutionAt: raw.lastEvolutionAt,
    );
  }

  static RarityTier _parseRarity(String raw) {
    return switch (raw.toLowerCase()) {
      'common' => RarityTier.common,
      'uncommon' => RarityTier.uncommon,
      'rare' => RarityTier.rare,
      'epic' => RarityTier.epic,
      'legendary' => RarityTier.legendary,
      _ => RarityTier.common,
    };
  }

  static List<PersonalityTrait> _parseTraits(String raw) {
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .map((s) => switch (s) {
              'cheerful' => PersonalityTrait.cheerful,
              'anxious' => PersonalityTrait.anxious,
              'sleepy' => PersonalityTrait.sleepy,
              'curious' => PersonalityTrait.curious,
              'ferocious' => PersonalityTrait.ferocious,
              'gentle' => PersonalityTrait.gentle,
              _ => null,
            })
        .whereType<PersonalityTrait>()
        .toList();
  }
}
