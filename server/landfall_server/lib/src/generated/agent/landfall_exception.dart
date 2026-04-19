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

/// A domain exception surfaced to agent API callers.
/// Used for authentication failures, validation errors, and rate limiting.
abstract class LandfallException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  LandfallException._({required this.message});

  factory LandfallException({required String message}) = _LandfallExceptionImpl;

  factory LandfallException.fromJson(Map<String, dynamic> jsonSerialization) {
    return LandfallException(message: jsonSerialization['message'] as String);
  }

  String message;

  /// Returns a shallow copy of this [LandfallException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LandfallException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LandfallException',
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LandfallException',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'LandfallException(message: $message)';
  }
}

class _LandfallExceptionImpl extends LandfallException {
  _LandfallExceptionImpl({required String message}) : super._(message: message);

  /// Returns a shallow copy of this [LandfallException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LandfallException copyWith({String? message}) {
    return LandfallException(message: message ?? this.message);
  }
}
