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

/// A single validation error returned when a theme fails to import.
/// tokenPath identifies the offending field (e.g. "color.accent").
abstract class ThemeValidationError
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ThemeValidationError._({
    required this.tokenPath,
    required this.message,
  });

  factory ThemeValidationError({
    required String tokenPath,
    required String message,
  }) = _ThemeValidationErrorImpl;

  factory ThemeValidationError.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ThemeValidationError(
      tokenPath: jsonSerialization['tokenPath'] as String,
      message: jsonSerialization['message'] as String,
    );
  }

  /// Dot-separated path to the invalid token (e.g. "color.accent").
  String tokenPath;

  /// Human-readable error message.
  String message;

  /// Returns a shallow copy of this [ThemeValidationError]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ThemeValidationError copyWith({
    String? tokenPath,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemeValidationError',
      'tokenPath': tokenPath,
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ThemeValidationError',
      'tokenPath': tokenPath,
      'message': message,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ThemeValidationErrorImpl extends ThemeValidationError {
  _ThemeValidationErrorImpl({
    required String tokenPath,
    required String message,
  }) : super._(
         tokenPath: tokenPath,
         message: message,
       );

  /// Returns a shallow copy of this [ThemeValidationError]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ThemeValidationError copyWith({
    String? tokenPath,
    String? message,
  }) {
    return ThemeValidationError(
      tokenPath: tokenPath ?? this.tokenPath,
      message: message ?? this.message,
    );
  }
}
