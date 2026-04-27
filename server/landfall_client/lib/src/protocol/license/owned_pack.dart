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

/// A pack owned by a Serverpod auth user.
/// Created on Stripe webhook completion or via Founding Member auto-grant.
abstract class OwnedPack implements _i1.SerializableModel {
  OwnedPack._({
    this.id,
    required this.userId,
    required this.packId,
    required this.grantedAt,
    this.stripeSessionId,
  });

  factory OwnedPack({
    int? id,
    required String userId,
    required String packId,
    required DateTime grantedAt,
    String? stripeSessionId,
  }) = _OwnedPackImpl;

  factory OwnedPack.fromJson(Map<String, dynamic> jsonSerialization) {
    return OwnedPack(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      packId: jsonSerialization['packId'] as String,
      grantedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['grantedAt'],
      ),
      stripeSessionId: jsonSerialization['stripeSessionId'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Serverpod auth user identifier (UUID string).
  String userId;

  /// References IntegrationPack.packId.
  String packId;

  /// When this pack was granted.
  DateTime grantedAt;

  /// Stripe checkout session ID. Null for Founding Member auto-grants.
  String? stripeSessionId;

  /// Returns a shallow copy of this [OwnedPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OwnedPack copyWith({
    int? id,
    String? userId,
    String? packId,
    DateTime? grantedAt,
    String? stripeSessionId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OwnedPack',
      if (id != null) 'id': id,
      'userId': userId,
      'packId': packId,
      'grantedAt': grantedAt.toJson(),
      if (stripeSessionId != null) 'stripeSessionId': stripeSessionId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OwnedPackImpl extends OwnedPack {
  _OwnedPackImpl({
    int? id,
    required String userId,
    required String packId,
    required DateTime grantedAt,
    String? stripeSessionId,
  }) : super._(
         id: id,
         userId: userId,
         packId: packId,
         grantedAt: grantedAt,
         stripeSessionId: stripeSessionId,
       );

  /// Returns a shallow copy of this [OwnedPack]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OwnedPack copyWith({
    Object? id = _Undefined,
    String? userId,
    String? packId,
    DateTime? grantedAt,
    Object? stripeSessionId = _Undefined,
  }) {
    return OwnedPack(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      packId: packId ?? this.packId,
      grantedAt: grantedAt ?? this.grantedAt,
      stripeSessionId: stripeSessionId is String?
          ? stripeSessionId
          : this.stripeSessionId,
    );
  }
}
