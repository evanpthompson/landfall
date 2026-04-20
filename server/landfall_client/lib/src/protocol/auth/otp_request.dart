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

/// A pending OTP challenge sent to an email address.
/// Records are kept after use for audit purposes; expired/used rows are
/// excluded from verification by the service layer.
abstract class OtpRequest implements _i1.SerializableModel {
  OtpRequest._({
    this.id,
    required this.email,
    required this.codeHash,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
  });

  factory OtpRequest({
    int? id,
    required String email,
    required String codeHash,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
  }) = _OtpRequestImpl;

  factory OtpRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtpRequest(
      id: jsonSerialization['id'] as int?,
      email: jsonSerialization['email'] as String,
      codeHash: jsonSerialization['codeHash'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The email address the code was sent to.
  String email;

  /// SHA-256 hex digest of the plaintext code.
  String codeHash;

  /// When this request was created.
  DateTime createdAt;

  /// When this code expires.
  DateTime expiresAt;

  /// Set when the code was successfully verified (fail-closed: can only be used once).
  DateTime? usedAt;

  /// Returns a shallow copy of this [OtpRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtpRequest copyWith({
    int? id,
    String? email,
    String? codeHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OtpRequest',
      if (id != null) 'id': id,
      'email': email,
      'codeHash': codeHash,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtpRequestImpl extends OtpRequest {
  _OtpRequestImpl({
    int? id,
    required String email,
    required String codeHash,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
  }) : super._(
         id: id,
         email: email,
         codeHash: codeHash,
         createdAt: createdAt,
         expiresAt: expiresAt,
         usedAt: usedAt,
       );

  /// Returns a shallow copy of this [OtpRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtpRequest copyWith({
    Object? id = _Undefined,
    String? email,
    String? codeHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? usedAt = _Undefined,
  }) {
    return OtpRequest(
      id: id is int? ? id : this.id,
      email: email ?? this.email,
      codeHash: codeHash ?? this.codeHash,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt is DateTime? ? usedAt : this.usedAt,
    );
  }
}
