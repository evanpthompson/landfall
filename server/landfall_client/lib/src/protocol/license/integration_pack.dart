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

/// An integration pack in the Landfall marketplace catalog.
/// Seeded at deployment time; updated by re-running the seed migration.
abstract class IntegrationPack implements _i1.SerializableModel {
  IntegrationPack._({
    this.id,
    required this.packId,
    required this.name,
    required this.description,
    required this.version,
    required this.priceUsd,
    required this.authorName,
    this.iconUrl,
    this.stripePaymentLink,
    bool? isActive,
  }) : isActive = isActive ?? true;

  factory IntegrationPack({
    int? id,
    required String packId,
    required String name,
    required String description,
    required String version,
    required double priceUsd,
    required String authorName,
    String? iconUrl,
    String? stripePaymentLink,
    bool? isActive,
  }) = _IntegrationPackImpl;

  factory IntegrationPack.fromJson(Map<String, dynamic> jsonSerialization) {
    return IntegrationPack(
      id: jsonSerialization['id'] as int?,
      packId: jsonSerialization['packId'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      version: jsonSerialization['version'] as String,
      priceUsd: (jsonSerialization['priceUsd'] as num).toDouble(),
      authorName: jsonSerialization['authorName'] as String,
      iconUrl: jsonSerialization['iconUrl'] as String?,
      stripePaymentLink: jsonSerialization['stripePaymentLink'] as String?,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Stable slug used as the primary identifier (e.g. 'sports_scores').
  String packId;

  /// User-facing display name.
  String name;

  /// Short description shown in the pack browser.
  String description;

  /// Semantic version string.
  String version;

  /// Price in USD.
  double priceUsd;

  /// Pack author name.
  String authorName;

  /// Optional icon URL.
  String? iconUrl;

  /// Stripe payment link for purchasing this pack. Null = not yet set up.
  String? stripePaymentLink;

  /// Whether this pack is listed in the marketplace.
  bool isActive;

  /// Returns a shallow copy of this [IntegrationPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IntegrationPack copyWith({
    int? id,
    String? packId,
    String? name,
    String? description,
    String? version,
    double? priceUsd,
    String? authorName,
    String? iconUrl,
    String? stripePaymentLink,
    bool? isActive,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IntegrationPack',
      if (id != null) 'id': id,
      'packId': packId,
      'name': name,
      'description': description,
      'version': version,
      'priceUsd': priceUsd,
      'authorName': authorName,
      if (iconUrl != null) 'iconUrl': iconUrl,
      if (stripePaymentLink != null) 'stripePaymentLink': stripePaymentLink,
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IntegrationPackImpl extends IntegrationPack {
  _IntegrationPackImpl({
    int? id,
    required String packId,
    required String name,
    required String description,
    required String version,
    required double priceUsd,
    required String authorName,
    String? iconUrl,
    String? stripePaymentLink,
    bool? isActive,
  }) : super._(
         id: id,
         packId: packId,
         name: name,
         description: description,
         version: version,
         priceUsd: priceUsd,
         authorName: authorName,
         iconUrl: iconUrl,
         stripePaymentLink: stripePaymentLink,
         isActive: isActive,
       );

  /// Returns a shallow copy of this [IntegrationPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IntegrationPack copyWith({
    Object? id = _Undefined,
    String? packId,
    String? name,
    String? description,
    String? version,
    double? priceUsd,
    String? authorName,
    Object? iconUrl = _Undefined,
    Object? stripePaymentLink = _Undefined,
    bool? isActive,
  }) {
    return IntegrationPack(
      id: id is int? ? id : this.id,
      packId: packId ?? this.packId,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      priceUsd: priceUsd ?? this.priceUsd,
      authorName: authorName ?? this.authorName,
      iconUrl: iconUrl is String? ? iconUrl : this.iconUrl,
      stripePaymentLink: stripePaymentLink is String?
          ? stripePaymentLink
          : this.stripePaymentLink,
      isActive: isActive ?? this.isActive,
    );
  }
}
