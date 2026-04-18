import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'api_key_service.dart';

/// API key management endpoint.
///
/// Phase 2: Unauthenticated — open for local dev, matching Phase 0 CardEndpoint.
/// Phase 5: Will require display-owner authentication before any mutation.
class ApiKeyEndpoint extends Endpoint {
  final _keyService = ApiKeyService.instance;

  /// Generates a new API key with the given [name] label.
  ///
  /// The returned [ApiKeyCreateResponse.plainTextKey] is shown exactly once
  /// and cannot be recovered. The caller must store it securely.
  Future<ApiKeyCreateResponse> generateKey(
    Session session,
    String name,
  ) async {
    if (name.trim().isEmpty) {
      throw LandfallException(message: 'Key name must not be empty.');
    }
    if (name.length > 80) {
      throw LandfallException(
        message: 'Key name must be at most 80 characters.',
      );
    }

    final (:key, :plainTextKey) = await _keyService.createKey(session, name);
    return ApiKeyCreateResponse(key: key, plainTextKey: plainTextKey);
  }

  /// Returns all non-revoked API keys.
  ///
  /// Only metadata is returned — hashes and plaintext keys are never exposed.
  Future<List<ApiKey>> listKeys(Session session) async {
    return ApiKey.db.find(
      session,
      where: (t) => t.revokedAt.equals(null),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }

  /// Revokes an API key by its database [id].
  ///
  /// The key is soft-deleted: its [ApiKey.revokedAt] is set to now.
  /// Revoked keys are rejected by [AgentEndpoint] immediately.
  ///
  /// Returns true if the key existed and was revoked, false if not found
  /// or already revoked.
  Future<bool> revokeKey(Session session, int id) async {
    final key = await ApiKey.db.findById(session, id);
    if (key == null || key.revokedAt != null) return false;

    await ApiKey.db.updateRow(
      session,
      key.copyWith(revokedAt: DateTime.now().toUtc()),
    );
    return true;
  }
}
