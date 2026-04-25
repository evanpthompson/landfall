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

/// A safe, token-free summary of a LinkedCredential for display in the
/// settings screen. Never exposes access/refresh tokens.
abstract class LinkedCredentialSummary implements _i1.SerializableModel {
  LinkedCredentialSummary._({
    required this.id,
    required this.provider,
    required this.providerEmail,
    required this.isActive,
    required this.createdAt,
  });

  factory LinkedCredentialSummary({
    required int id,
    required String provider,
    required String providerEmail,
    required bool isActive,
    required DateTime createdAt,
  }) = _LinkedCredentialSummaryImpl;

  factory LinkedCredentialSummary.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LinkedCredentialSummary(
      id: jsonSerialization['id'] as int,
      provider: jsonSerialization['provider'] as String,
      providerEmail: jsonSerialization['providerEmail'] as String,
      isActive: _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// DB primary key of the source LinkedCredential.
  int id;

  /// Provider identifier, e.g. "google" or "microsoft".
  String provider;

  /// The account email address for this credential.
  String providerEmail;

  /// Whether this credential is currently active.
  bool isActive;

  /// When this credential was first connected.
  DateTime createdAt;

  /// Returns a shallow copy of this [LinkedCredentialSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LinkedCredentialSummary copyWith({
    int? id,
    String? provider,
    String? providerEmail,
    bool? isActive,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LinkedCredentialSummary',
      'id': id,
      'provider': provider,
      'providerEmail': providerEmail,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _LinkedCredentialSummaryImpl extends LinkedCredentialSummary {
  _LinkedCredentialSummaryImpl({
    required int id,
    required String provider,
    required String providerEmail,
    required bool isActive,
    required DateTime createdAt,
  }) : super._(
         id: id,
         provider: provider,
         providerEmail: providerEmail,
         isActive: isActive,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LinkedCredentialSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LinkedCredentialSummary copyWith({
    int? id,
    String? provider,
    String? providerEmail,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return LinkedCredentialSummary(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      providerEmail: providerEmail ?? this.providerEmail,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
