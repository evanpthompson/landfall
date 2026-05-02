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
import '../theme/landfall_theme.dart' as _i2;
import '../theme/theme_validation_error.dart' as _i3;
import 'package:landfall_client/src/protocol/protocol.dart' as _i4;

/// Result returned by ThemeEndpoint.uploadTheme and importTheme.
/// On success, theme is set and errors is empty.
/// On failure, theme is null and errors lists each problem found.
abstract class ThemeUploadResult implements _i1.SerializableModel {
  ThemeUploadResult._({
    this.theme,
    required this.errors,
  });

  factory ThemeUploadResult({
    _i2.LandfallTheme? theme,
    required List<_i3.ThemeValidationError> errors,
  }) = _ThemeUploadResultImpl;

  factory ThemeUploadResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThemeUploadResult(
      theme: jsonSerialization['theme'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.LandfallTheme>(
              jsonSerialization['theme'],
            ),
      errors: _i4.Protocol().deserialize<List<_i3.ThemeValidationError>>(
        jsonSerialization['errors'],
      ),
    );
  }

  /// The stored theme. Null when validation failed.
  _i2.LandfallTheme? theme;

  /// Validation errors. Empty on success.
  List<_i3.ThemeValidationError> errors;

  /// Returns a shallow copy of this [ThemeUploadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ThemeUploadResult copyWith({
    _i2.LandfallTheme? theme,
    List<_i3.ThemeValidationError>? errors,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemeUploadResult',
      if (theme != null) 'theme': theme?.toJson(),
      'errors': errors.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThemeUploadResultImpl extends ThemeUploadResult {
  _ThemeUploadResultImpl({
    _i2.LandfallTheme? theme,
    required List<_i3.ThemeValidationError> errors,
  }) : super._(
         theme: theme,
         errors: errors,
       );

  /// Returns a shallow copy of this [ThemeUploadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ThemeUploadResult copyWith({
    Object? theme = _Undefined,
    List<_i3.ThemeValidationError>? errors,
  }) {
    return ThemeUploadResult(
      theme: theme is _i2.LandfallTheme? ? theme : this.theme?.copyWith(),
      errors: errors ?? this.errors.map((e0) => e0.copyWith()).toList(),
    );
  }
}
