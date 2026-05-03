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
import 'package:serverpod/serverpod.dart' as _i1;

/// A marketplace theme entry returned from MarketplaceEndpoint.
/// Merges LandfallTheme data with per-user ownership information.
abstract class MarketplaceThemeInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MarketplaceThemeInfo._({
    required this.id,
    required this.slug,
    required this.name,
    required this.schemaVersion,
    this.author,
    this.description,
    this.previewUrl,
    required this.tagsJson,
    required this.resolvedJson,
    this.priceUsd,
    this.stripeProductId,
    required this.isBuiltIn,
    required this.createdAt,
    required this.isOwned,
  });

  factory MarketplaceThemeInfo({
    required int id,
    required String slug,
    required String name,
    required String schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    required String tagsJson,
    required String resolvedJson,
    int? priceUsd,
    String? stripeProductId,
    required bool isBuiltIn,
    required DateTime createdAt,
    required bool isOwned,
  }) = _MarketplaceThemeInfoImpl;

  factory MarketplaceThemeInfo.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MarketplaceThemeInfo(
      id: jsonSerialization['id'] as int,
      slug: jsonSerialization['slug'] as String,
      name: jsonSerialization['name'] as String,
      schemaVersion: jsonSerialization['schemaVersion'] as String,
      author: jsonSerialization['author'] as String?,
      description: jsonSerialization['description'] as String?,
      previewUrl: jsonSerialization['previewUrl'] as String?,
      tagsJson: jsonSerialization['tagsJson'] as String,
      resolvedJson: jsonSerialization['resolvedJson'] as String,
      priceUsd: jsonSerialization['priceUsd'] as int?,
      stripeProductId: jsonSerialization['stripeProductId'] as String?,
      isBuiltIn: _i1.BoolJsonExtension.fromJson(jsonSerialization['isBuiltIn']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      isOwned: _i1.BoolJsonExtension.fromJson(jsonSerialization['isOwned']),
    );
  }

  int id;

  String slug;

  String name;

  String schemaVersion;

  String? author;

  String? description;

  String? previewUrl;

  String tagsJson;

  String resolvedJson;

  int? priceUsd;

  String? stripeProductId;

  bool isBuiltIn;

  DateTime createdAt;

  bool isOwned;

  /// Returns a shallow copy of this [MarketplaceThemeInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MarketplaceThemeInfo copyWith({
    int? id,
    String? slug,
    String? name,
    String? schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    String? tagsJson,
    String? resolvedJson,
    int? priceUsd,
    String? stripeProductId,
    bool? isBuiltIn,
    DateTime? createdAt,
    bool? isOwned,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketplaceThemeInfo',
      'id': id,
      'slug': slug,
      'name': name,
      'schemaVersion': schemaVersion,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (previewUrl != null) 'previewUrl': previewUrl,
      'tagsJson': tagsJson,
      'resolvedJson': resolvedJson,
      if (priceUsd != null) 'priceUsd': priceUsd,
      if (stripeProductId != null) 'stripeProductId': stripeProductId,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toJson(),
      'isOwned': isOwned,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketplaceThemeInfo',
      'id': id,
      'slug': slug,
      'name': name,
      'schemaVersion': schemaVersion,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (previewUrl != null) 'previewUrl': previewUrl,
      'tagsJson': tagsJson,
      'resolvedJson': resolvedJson,
      if (priceUsd != null) 'priceUsd': priceUsd,
      if (stripeProductId != null) 'stripeProductId': stripeProductId,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toJson(),
      'isOwned': isOwned,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketplaceThemeInfoImpl extends MarketplaceThemeInfo {
  _MarketplaceThemeInfoImpl({
    required int id,
    required String slug,
    required String name,
    required String schemaVersion,
    String? author,
    String? description,
    String? previewUrl,
    required String tagsJson,
    required String resolvedJson,
    int? priceUsd,
    String? stripeProductId,
    required bool isBuiltIn,
    required DateTime createdAt,
    required bool isOwned,
  }) : super._(
         id: id,
         slug: slug,
         name: name,
         schemaVersion: schemaVersion,
         author: author,
         description: description,
         previewUrl: previewUrl,
         tagsJson: tagsJson,
         resolvedJson: resolvedJson,
         priceUsd: priceUsd,
         stripeProductId: stripeProductId,
         isBuiltIn: isBuiltIn,
         createdAt: createdAt,
         isOwned: isOwned,
       );

  /// Returns a shallow copy of this [MarketplaceThemeInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MarketplaceThemeInfo copyWith({
    int? id,
    String? slug,
    String? name,
    String? schemaVersion,
    Object? author = _Undefined,
    Object? description = _Undefined,
    Object? previewUrl = _Undefined,
    String? tagsJson,
    String? resolvedJson,
    Object? priceUsd = _Undefined,
    Object? stripeProductId = _Undefined,
    bool? isBuiltIn,
    DateTime? createdAt,
    bool? isOwned,
  }) {
    return MarketplaceThemeInfo(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      author: author is String? ? author : this.author,
      description: description is String? ? description : this.description,
      previewUrl: previewUrl is String? ? previewUrl : this.previewUrl,
      tagsJson: tagsJson ?? this.tagsJson,
      resolvedJson: resolvedJson ?? this.resolvedJson,
      priceUsd: priceUsd is int? ? priceUsd : this.priceUsd,
      stripeProductId: stripeProductId is String?
          ? stripeProductId
          : this.stripeProductId,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      isOwned: isOwned ?? this.isOwned,
    );
  }
}
