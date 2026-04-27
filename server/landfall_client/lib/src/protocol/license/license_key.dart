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

/// A one-time license key for activating a Landfall Pro or Founding Member license.
/// Keys are generated after a Stripe purchase and emailed to the buyer.
/// Activation ties the key to a Serverpod auth user; one activation per key.
abstract class LicenseKey implements _i1.SerializableModel {
  LicenseKey._({
    this.id,
    required this.key,
    required this.tier,
    this.activatedByUserId,
    this.activatedAt,
    required this.purchasedAt,
    this.stripeSessionId,
    this.buyerEmail,
  });

  factory LicenseKey({
    int? id,
    required String key,
    required String tier,
    String? activatedByUserId,
    DateTime? activatedAt,
    required DateTime purchasedAt,
    String? stripeSessionId,
    String? buyerEmail,
  }) = _LicenseKeyImpl;

  factory LicenseKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return LicenseKey(
      id: jsonSerialization['id'] as int?,
      key: jsonSerialization['key'] as String,
      tier: jsonSerialization['tier'] as String,
      activatedByUserId: jsonSerialization['activatedByUserId'] as String?,
      activatedAt: jsonSerialization['activatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['activatedAt'],
            ),
      purchasedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['purchasedAt'],
      ),
      stripeSessionId: jsonSerialization['stripeSessionId'] as String?,
      buyerEmail: jsonSerialization['buyerEmail'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The license key as shown to the user (e.g. "LF-PRO-XXXX-XXXX").
  String key;

  /// License tier: 'pro' or 'founding_member'
  String tier;

  /// Serverpod auth user identifier (UUID string) that activated this key. Null = unactivated.
  String? activatedByUserId;

  /// When this key was activated.
  DateTime? activatedAt;

  /// When this key was created / purchased.
  DateTime purchasedAt;

  /// Stripe checkout session ID for audit trail. Null for manually issued keys.
  String? stripeSessionId;

  /// Buyer email captured by Stripe. Used for key delivery.
  String? buyerEmail;

  /// Returns a shallow copy of this [LicenseKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LicenseKey copyWith({
    int? id,
    String? key,
    String? tier,
    String? activatedByUserId,
    DateTime? activatedAt,
    DateTime? purchasedAt,
    String? stripeSessionId,
    String? buyerEmail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LicenseKey',
      if (id != null) 'id': id,
      'key': key,
      'tier': tier,
      if (activatedByUserId != null) 'activatedByUserId': activatedByUserId,
      if (activatedAt != null) 'activatedAt': activatedAt?.toJson(),
      'purchasedAt': purchasedAt.toJson(),
      if (stripeSessionId != null) 'stripeSessionId': stripeSessionId,
      if (buyerEmail != null) 'buyerEmail': buyerEmail,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LicenseKeyImpl extends LicenseKey {
  _LicenseKeyImpl({
    int? id,
    required String key,
    required String tier,
    String? activatedByUserId,
    DateTime? activatedAt,
    required DateTime purchasedAt,
    String? stripeSessionId,
    String? buyerEmail,
  }) : super._(
         id: id,
         key: key,
         tier: tier,
         activatedByUserId: activatedByUserId,
         activatedAt: activatedAt,
         purchasedAt: purchasedAt,
         stripeSessionId: stripeSessionId,
         buyerEmail: buyerEmail,
       );

  /// Returns a shallow copy of this [LicenseKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LicenseKey copyWith({
    Object? id = _Undefined,
    String? key,
    String? tier,
    Object? activatedByUserId = _Undefined,
    Object? activatedAt = _Undefined,
    DateTime? purchasedAt,
    Object? stripeSessionId = _Undefined,
    Object? buyerEmail = _Undefined,
  }) {
    return LicenseKey(
      id: id is int? ? id : this.id,
      key: key ?? this.key,
      tier: tier ?? this.tier,
      activatedByUserId: activatedByUserId is String?
          ? activatedByUserId
          : this.activatedByUserId,
      activatedAt: activatedAt is DateTime? ? activatedAt : this.activatedAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      stripeSessionId: stripeSessionId is String?
          ? stripeSessionId
          : this.stripeSessionId,
      buyerEmail: buyerEmail is String? ? buyerEmail : this.buyerEmail,
    );
  }
}
