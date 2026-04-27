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

/// A single pack entry returned from PackEndpoint.listPacks.
/// Merges catalog data with per-user ownership information.
abstract class PackInfoResponse implements _i1.SerializableModel {
  PackInfoResponse._({
    required this.packId,
    required this.name,
    required this.description,
    required this.version,
    required this.priceUsd,
    required this.authorName,
    this.iconUrl,
    this.stripePaymentLink,
    required this.isOwned,
  });

  factory PackInfoResponse({
    required String packId,
    required String name,
    required String description,
    required String version,
    required double priceUsd,
    required String authorName,
    String? iconUrl,
    String? stripePaymentLink,
    required bool isOwned,
  }) = _PackInfoResponseImpl;

  factory PackInfoResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return PackInfoResponse(
      packId: jsonSerialization['packId'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      version: jsonSerialization['version'] as String,
      priceUsd: (jsonSerialization['priceUsd'] as num).toDouble(),
      authorName: jsonSerialization['authorName'] as String,
      iconUrl: jsonSerialization['iconUrl'] as String?,
      stripePaymentLink: jsonSerialization['stripePaymentLink'] as String?,
      isOwned: _i1.BoolJsonExtension.fromJson(jsonSerialization['isOwned']),
    );
  }

  String packId;

  String name;

  String description;

  String version;

  double priceUsd;

  String authorName;

  String? iconUrl;

  String? stripePaymentLink;

  bool isOwned;

  /// Returns a shallow copy of this [PackInfoResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PackInfoResponse copyWith({
    String? packId,
    String? name,
    String? description,
    String? version,
    double? priceUsd,
    String? authorName,
    String? iconUrl,
    String? stripePaymentLink,
    bool? isOwned,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PackInfoResponse',
      'packId': packId,
      'name': name,
      'description': description,
      'version': version,
      'priceUsd': priceUsd,
      'authorName': authorName,
      if (iconUrl != null) 'iconUrl': iconUrl,
      if (stripePaymentLink != null) 'stripePaymentLink': stripePaymentLink,
      'isOwned': isOwned,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PackInfoResponseImpl extends PackInfoResponse {
  _PackInfoResponseImpl({
    required String packId,
    required String name,
    required String description,
    required String version,
    required double priceUsd,
    required String authorName,
    String? iconUrl,
    String? stripePaymentLink,
    required bool isOwned,
  }) : super._(
         packId: packId,
         name: name,
         description: description,
         version: version,
         priceUsd: priceUsd,
         authorName: authorName,
         iconUrl: iconUrl,
         stripePaymentLink: stripePaymentLink,
         isOwned: isOwned,
       );

  /// Returns a shallow copy of this [PackInfoResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PackInfoResponse copyWith({
    String? packId,
    String? name,
    String? description,
    String? version,
    double? priceUsd,
    String? authorName,
    Object? iconUrl = _Undefined,
    Object? stripePaymentLink = _Undefined,
    bool? isOwned,
  }) {
    return PackInfoResponse(
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
      isOwned: isOwned ?? this.isOwned,
    );
  }
}
