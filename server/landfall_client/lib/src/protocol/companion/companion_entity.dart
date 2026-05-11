/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// The companion creature assigned to a display.
/// One row per display, identified by displayId (the client-generated UUID).
/// Rarity, species, name, and traits are seeded once at creation and are fixed
/// forever. Evolution stage advances over time via the nightly evolution job.
abstract class CompanionEntity implements _i1.SerializableModel {
  CompanionEntity._({
    this.id,
    required this.displayId,
    required this.seed,
    required this.rarityTier,
    required this.speciesId,
    required this.name,
    required this.traits,
    int? evolutionStage,
    required this.createdAt,
    this.assetCredit,
    this.lastEvolutionAt,
  }) : evolutionStage = evolutionStage ?? 0;

  factory CompanionEntity({
    int? id,
    required String displayId,
    required int seed,
    required String rarityTier,
    required String speciesId,
    required String name,
    required String traits,
    int? evolutionStage,
    required DateTime createdAt,
    String? assetCredit,
    DateTime? lastEvolutionAt,
  }) = _CompanionEntityImpl;

  factory CompanionEntity.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanionEntity(
      id: jsonSerialization['id'] as int?,
      displayId: jsonSerialization['displayId'] as String,
      seed: jsonSerialization['seed'] as int,
      rarityTier: jsonSerialization['rarityTier'] as String,
      speciesId: jsonSerialization['speciesId'] as String,
      name: jsonSerialization['name'] as String,
      traits: jsonSerialization['traits'] as String,
      evolutionStage: jsonSerialization['evolutionStage'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      assetCredit: jsonSerialization['assetCredit'] as String?,
      lastEvolutionAt: jsonSerialization['lastEvolutionAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastEvolutionAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The display's stable UUID. One companion per display.
  String displayId;

  /// Deterministic seed derived from displayId — used by xrandom to pick
  /// species/rarity/name. Stored so future seeded draws stay reproducible.
  int seed;

  /// Rarity bucket: common | uncommon | rare | epic | legendary.
  String rarityTier;

  /// Identifies the creature template (e.g. "lumen", "axolotl").
  String speciesId;

  /// Display name — procedurally generated from seed, fixed forever.
  String name;

  /// Personality traits as a comma-separated list (e.g. "curious,gentle").
  /// Maps to PersonalityTrait enum in the client.
  String traits;

  /// 0 = Baby, 1 = Juvenile, 2 = Adult, 3 = Elder. Advances over time.
  int evolutionStage;

  /// When the companion was first created for this display.
  DateTime createdAt;

  /// Optional attribution string for the sprite artist.
  String? assetCredit;

  /// Last time the evolution stage changed. Null if never evolved.
  DateTime? lastEvolutionAt;

  /// Returns a shallow copy of this [CompanionEntity]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CompanionEntity copyWith({
    int? id,
    String? displayId,
    int? seed,
    String? rarityTier,
    String? speciesId,
    String? name,
    String? traits,
    int? evolutionStage,
    DateTime? createdAt,
    String? assetCredit,
    DateTime? lastEvolutionAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanionEntity',
      if (id != null) 'id': id,
      'displayId': displayId,
      'seed': seed,
      'rarityTier': rarityTier,
      'speciesId': speciesId,
      'name': name,
      'traits': traits,
      'evolutionStage': evolutionStage,
      'createdAt': createdAt.toJson(),
      if (assetCredit != null) 'assetCredit': assetCredit,
      if (lastEvolutionAt != null) 'lastEvolutionAt': lastEvolutionAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanionEntityImpl extends CompanionEntity {
  _CompanionEntityImpl({
    int? id,
    required String displayId,
    required int seed,
    required String rarityTier,
    required String speciesId,
    required String name,
    required String traits,
    int? evolutionStage,
    required DateTime createdAt,
    String? assetCredit,
    DateTime? lastEvolutionAt,
  }) : super._(
         id: id,
         displayId: displayId,
         seed: seed,
         rarityTier: rarityTier,
         speciesId: speciesId,
         name: name,
         traits: traits,
         evolutionStage: evolutionStage,
         createdAt: createdAt,
         assetCredit: assetCredit,
         lastEvolutionAt: lastEvolutionAt,
       );

  /// Returns a shallow copy of this [CompanionEntity]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CompanionEntity copyWith({
    Object? id = _Undefined,
    String? displayId,
    int? seed,
    String? rarityTier,
    String? speciesId,
    String? name,
    String? traits,
    int? evolutionStage,
    DateTime? createdAt,
    Object? assetCredit = _Undefined,
    Object? lastEvolutionAt = _Undefined,
  }) {
    return CompanionEntity(
      id: id is int? ? id : this.id,
      displayId: displayId ?? this.displayId,
      seed: seed ?? this.seed,
      rarityTier: rarityTier ?? this.rarityTier,
      speciesId: speciesId ?? this.speciesId,
      name: name ?? this.name,
      traits: traits ?? this.traits,
      evolutionStage: evolutionStage ?? this.evolutionStage,
      createdAt: createdAt ?? this.createdAt,
      assetCredit: assetCredit is String? ? assetCredit : this.assetCredit,
      lastEvolutionAt: lastEvolutionAt is DateTime?
          ? lastEvolutionAt
          : this.lastEvolutionAt,
    );
  }
}
