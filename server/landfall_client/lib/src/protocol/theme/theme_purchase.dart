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

/// Records a theme purchase by a Serverpod auth user.
/// Created on Stripe checkout.session.completed with purchase_type=theme.
abstract class ThemePurchase implements _i1.SerializableModel {
  ThemePurchase._({
    this.id,
    required this.userId,
    required this.themeId,
    required this.purchasedAt,
    this.stripePaymentIntentId,
  });

  factory ThemePurchase({
    int? id,
    required String userId,
    required int themeId,
    required DateTime purchasedAt,
    String? stripePaymentIntentId,
  }) = _ThemePurchaseImpl;

  factory ThemePurchase.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThemePurchase(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      themeId: jsonSerialization['themeId'] as int,
      purchasedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['purchasedAt'],
      ),
      stripePaymentIntentId:
          jsonSerialization['stripePaymentIntentId'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Serverpod auth user identifier (UUID string).
  String userId;

  /// References LandfallTheme.id.
  int themeId;

  /// When this theme was purchased.
  DateTime purchasedAt;

  /// Stripe checkout session ID. Used for idempotency on webhook replay.
  String? stripePaymentIntentId;

  /// Returns a shallow copy of this [ThemePurchase]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ThemePurchase copyWith({
    int? id,
    String? userId,
    int? themeId,
    DateTime? purchasedAt,
    String? stripePaymentIntentId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemePurchase',
      if (id != null) 'id': id,
      'userId': userId,
      'themeId': themeId,
      'purchasedAt': purchasedAt.toJson(),
      if (stripePaymentIntentId != null)
        'stripePaymentIntentId': stripePaymentIntentId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThemePurchaseImpl extends ThemePurchase {
  _ThemePurchaseImpl({
    int? id,
    required String userId,
    required int themeId,
    required DateTime purchasedAt,
    String? stripePaymentIntentId,
  }) : super._(
         id: id,
         userId: userId,
         themeId: themeId,
         purchasedAt: purchasedAt,
         stripePaymentIntentId: stripePaymentIntentId,
       );

  /// Returns a shallow copy of this [ThemePurchase]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ThemePurchase copyWith({
    Object? id = _Undefined,
    String? userId,
    int? themeId,
    DateTime? purchasedAt,
    Object? stripePaymentIntentId = _Undefined,
  }) {
    return ThemePurchase(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      themeId: themeId ?? this.themeId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      stripePaymentIntentId: stripePaymentIntentId is String?
          ? stripePaymentIntentId
          : this.stripePaymentIntentId,
    );
  }
}
