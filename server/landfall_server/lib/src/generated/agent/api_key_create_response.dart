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
import '../agent/api_key.dart' as _i2;
import 'package:landfall_server/src/generated/protocol.dart' as _i3;

/// Returned once when an API key is generated.
/// The plainTextKey is never stored and cannot be recovered — the client
/// must save it immediately.
abstract class ApiKeyCreateResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ApiKeyCreateResponse._({
    required this.key,
    required this.plainTextKey,
  });

  factory ApiKeyCreateResponse({
    required _i2.ApiKey key,
    required String plainTextKey,
  }) = _ApiKeyCreateResponseImpl;

  factory ApiKeyCreateResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ApiKeyCreateResponse(
      key: _i3.Protocol().deserialize<_i2.ApiKey>(jsonSerialization['key']),
      plainTextKey: jsonSerialization['plainTextKey'] as String,
    );
  }

  /// The created key record (without the plaintext).
  _i2.ApiKey key;

  /// The full plaintext key. Shown once; treat like a password.
  String plainTextKey;

  /// Returns a shallow copy of this [ApiKeyCreateResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ApiKeyCreateResponse copyWith({
    _i2.ApiKey? key,
    String? plainTextKey,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiKeyCreateResponse',
      'key': key.toJson(),
      'plainTextKey': plainTextKey,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ApiKeyCreateResponse',
      'key': key.toJsonForProtocol(),
      'plainTextKey': plainTextKey,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ApiKeyCreateResponseImpl extends ApiKeyCreateResponse {
  _ApiKeyCreateResponseImpl({
    required _i2.ApiKey key,
    required String plainTextKey,
  }) : super._(
         key: key,
         plainTextKey: plainTextKey,
       );

  /// Returns a shallow copy of this [ApiKeyCreateResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ApiKeyCreateResponse copyWith({
    _i2.ApiKey? key,
    String? plainTextKey,
  }) {
    return ApiKeyCreateResponse(
      key: key ?? this.key.copyWith(),
      plainTextKey: plainTextKey ?? this.plainTextKey,
    );
  }
}
