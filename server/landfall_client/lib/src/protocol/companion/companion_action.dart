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

/// A companion interaction triggered by the phone web page.
/// Wire-only — not persisted. Pushed from CompanionEndpoint.pushAction and
/// delivered via CompanionEndpoint.pollForEvents long-polling.
abstract class CompanionAction implements _i1.SerializableModel {
  CompanionAction._({
    required this.kind,
    required this.timestamp,
  });

  factory CompanionAction({
    required String kind,
    required DateTime timestamp,
  }) = _CompanionActionImpl;

  factory CompanionAction.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanionAction(
      kind: jsonSerialization['kind'] as String,
      timestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  /// The interaction type: "pet" | "play" | "feed".
  /// Maps to CompanionAnimationState on the client.
  String kind;

  /// When the action was emitted, server-side. Used by clients to ignore
  /// actions older than their last seen timestamp (de-dupe on reconnect).
  DateTime timestamp;

  /// Returns a shallow copy of this [CompanionAction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CompanionAction copyWith({
    String? kind,
    DateTime? timestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanionAction',
      'kind': kind,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CompanionActionImpl extends CompanionAction {
  _CompanionActionImpl({
    required String kind,
    required DateTime timestamp,
  }) : super._(
         kind: kind,
         timestamp: timestamp,
       );

  /// Returns a shallow copy of this [CompanionAction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CompanionAction copyWith({
    String? kind,
    DateTime? timestamp,
  }) {
    return CompanionAction(
      kind: kind ?? this.kind,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
