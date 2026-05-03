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

/// An API key for agent clients pushing cards to the display.
/// The plaintext key is never stored — only the HMAC-SHA-256 hash.
abstract class ApiKey implements _i1.SerializableModel {
  ApiKey._({
    this.id,
    required this.name,
    required this.keyHash,
    required this.prefix,
    required this.createdAt,
    this.lastUsedAt,
    this.lastUsedIp,
    this.revokedAt,
    int? dailyLimit,
    int? usageCount,
    required this.usageResetAt,
  }) : dailyLimit = dailyLimit ?? 500,
       usageCount = usageCount ?? 0;

  factory ApiKey({
    int? id,
    required String name,
    required String keyHash,
    required String prefix,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    String? lastUsedIp,
    DateTime? revokedAt,
    int? dailyLimit,
    int? usageCount,
    required DateTime usageResetAt,
  }) = _ApiKeyImpl;

  factory ApiKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiKey(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      keyHash: jsonSerialization['keyHash'] as String,
      prefix: jsonSerialization['prefix'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastUsedAt: jsonSerialization['lastUsedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsedAt']),
      lastUsedIp: jsonSerialization['lastUsedIp'] as String?,
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
      dailyLimit: jsonSerialization['dailyLimit'] as int?,
      usageCount: jsonSerialization['usageCount'] as int?,
      usageResetAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['usageResetAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Human-readable label for this key.
  String name;

  /// SHA-256 hex digest of the plaintext key. Never expose this to clients.
  String keyHash;

  /// First 8 characters of the plaintext key, for display/identification.
  String prefix;

  /// When this key was created.
  DateTime createdAt;

  /// When this key was last used to authenticate a request.
  DateTime? lastUsedAt;

  /// IP address of the most recent authenticated request. A07:2025.
  String? lastUsedIp;

  /// When this key was revoked. Non-null = key is inactive.
  DateTime? revokedAt;

  /// Maximum pushCard calls per day. Resets at UTC midnight.
  int dailyLimit;

  /// Number of pushCard calls made since usageResetAt.
  int usageCount;

  /// Next time usageCount resets to zero (UTC midnight).
  DateTime usageResetAt;

  /// Returns a shallow copy of this [ApiKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ApiKey copyWith({
    int? id,
    String? name,
    String? keyHash,
    String? prefix,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    String? lastUsedIp,
    DateTime? revokedAt,
    int? dailyLimit,
    int? usageCount,
    DateTime? usageResetAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiKey',
      if (id != null) 'id': id,
      'name': name,
      'keyHash': keyHash,
      'prefix': prefix,
      'createdAt': createdAt.toJson(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt?.toJson(),
      if (lastUsedIp != null) 'lastUsedIp': lastUsedIp,
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
      'dailyLimit': dailyLimit,
      'usageCount': usageCount,
      'usageResetAt': usageResetAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ApiKeyImpl extends ApiKey {
  _ApiKeyImpl({
    int? id,
    required String name,
    required String keyHash,
    required String prefix,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    String? lastUsedIp,
    DateTime? revokedAt,
    int? dailyLimit,
    int? usageCount,
    required DateTime usageResetAt,
  }) : super._(
         id: id,
         name: name,
         keyHash: keyHash,
         prefix: prefix,
         createdAt: createdAt,
         lastUsedAt: lastUsedAt,
         lastUsedIp: lastUsedIp,
         revokedAt: revokedAt,
         dailyLimit: dailyLimit,
         usageCount: usageCount,
         usageResetAt: usageResetAt,
       );

  /// Returns a shallow copy of this [ApiKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ApiKey copyWith({
    Object? id = _Undefined,
    String? name,
    String? keyHash,
    String? prefix,
    DateTime? createdAt,
    Object? lastUsedAt = _Undefined,
    Object? lastUsedIp = _Undefined,
    Object? revokedAt = _Undefined,
    int? dailyLimit,
    int? usageCount,
    DateTime? usageResetAt,
  }) {
    return ApiKey(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      keyHash: keyHash ?? this.keyHash,
      prefix: prefix ?? this.prefix,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt is DateTime? ? lastUsedAt : this.lastUsedAt,
      lastUsedIp: lastUsedIp is String? ? lastUsedIp : this.lastUsedIp,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      usageCount: usageCount ?? this.usageCount,
      usageResetAt: usageResetAt ?? this.usageResetAt,
    );
  }
}
