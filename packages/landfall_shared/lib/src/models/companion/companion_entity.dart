enum RarityTier { common, uncommon, rare, epic, legendary }

enum PersonalityTrait { cheerful, anxious, sleepy, curious, ferocious, gentle }

class CompanionEntity {
  const CompanionEntity({
    required this.id,
    required this.displayId,
    required this.seed,
    required this.rarityTier,
    required this.speciesId,
    required this.name,
    required this.traits,
    required this.evolutionStage,
    required this.createdAt,
    this.customName,
    this.assetCredit,
    this.lastEvolutionAt,
  });

  final String id;
  final String displayId;
  final int seed;
  final RarityTier rarityTier;
  final String speciesId;
  final String name;
  final List<PersonalityTrait> traits;
  final int evolutionStage;
  final DateTime createdAt;
  final String? customName;
  final String? assetCredit;
  final DateTime? lastEvolutionAt;
}
