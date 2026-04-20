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

/// Tracks the email → authUserId mapping for OTP-authenticated users.
/// Created on first successful OTP verification for an email address.
abstract class OtpAccount implements _i1.SerializableModel {
  OtpAccount._({
    this.id,
    required this.email,
    required this.authUserId,
  });

  factory OtpAccount({
    int? id,
    required String email,
    required _i1.UuidValue authUserId,
  }) = _OtpAccountImpl;

  factory OtpAccount.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtpAccount(
      id: jsonSerialization['id'] as int?,
      email: jsonSerialization['email'] as String,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The email address that was verified.
  String email;

  /// The Serverpod auth user ID linked to this email.
  _i1.UuidValue authUserId;

  /// Returns a shallow copy of this [OtpAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtpAccount copyWith({
    int? id,
    String? email,
    _i1.UuidValue? authUserId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OtpAccount',
      if (id != null) 'id': id,
      'email': email,
      'authUserId': authUserId.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtpAccountImpl extends OtpAccount {
  _OtpAccountImpl({
    int? id,
    required String email,
    required _i1.UuidValue authUserId,
  }) : super._(
         id: id,
         email: email,
         authUserId: authUserId,
       );

  /// Returns a shallow copy of this [OtpAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtpAccount copyWith({
    Object? id = _Undefined,
    String? email,
    _i1.UuidValue? authUserId,
  }) {
    return OtpAccount(
      id: id is int? ? id : this.id,
      email: email ?? this.email,
      authUserId: authUserId ?? this.authUserId,
    );
  }
}
