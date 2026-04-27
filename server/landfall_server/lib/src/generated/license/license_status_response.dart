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

/// Response from LicenseEndpoint.getLicenseStatus and activateLicense.
/// Carries tier and display metadata; never exposes the raw key hash.
abstract class LicenseStatusResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  LicenseStatusResponse._({
    required this.tier,
    this.activatedAt,
    this.maskedKey,
  });

  factory LicenseStatusResponse({
    required String tier,
    DateTime? activatedAt,
    String? maskedKey,
  }) = _LicenseStatusResponseImpl;

  factory LicenseStatusResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LicenseStatusResponse(
      tier: jsonSerialization['tier'] as String,
      activatedAt: jsonSerialization['activatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['activatedAt'],
            ),
      maskedKey: jsonSerialization['maskedKey'] as String?,
    );
  }

  /// License tier: 'free' | 'pro' | 'founding_member'
  String tier;

  /// When the license was activated. Null for free tier.
  DateTime? activatedAt;

  /// Partially masked license key for UI display (e.g. "LF-PRO-****-1234").
  String? maskedKey;

  /// Returns a shallow copy of this [LicenseStatusResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LicenseStatusResponse copyWith({
    String? tier,
    DateTime? activatedAt,
    String? maskedKey,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LicenseStatusResponse',
      'tier': tier,
      if (activatedAt != null) 'activatedAt': activatedAt?.toJson(),
      if (maskedKey != null) 'maskedKey': maskedKey,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LicenseStatusResponse',
      'tier': tier,
      if (activatedAt != null) 'activatedAt': activatedAt?.toJson(),
      if (maskedKey != null) 'maskedKey': maskedKey,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LicenseStatusResponseImpl extends LicenseStatusResponse {
  _LicenseStatusResponseImpl({
    required String tier,
    DateTime? activatedAt,
    String? maskedKey,
  }) : super._(
         tier: tier,
         activatedAt: activatedAt,
         maskedKey: maskedKey,
       );

  /// Returns a shallow copy of this [LicenseStatusResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LicenseStatusResponse copyWith({
    String? tier,
    Object? activatedAt = _Undefined,
    Object? maskedKey = _Undefined,
  }) {
    return LicenseStatusResponse(
      tier: tier ?? this.tier,
      activatedAt: activatedAt is DateTime? ? activatedAt : this.activatedAt,
      maskedKey: maskedKey is String? ? maskedKey : this.maskedKey,
    );
  }
}
