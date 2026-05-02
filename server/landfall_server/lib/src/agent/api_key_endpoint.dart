import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'api_key_service.dart';

/// API key management endpoint.
///
/// All methods require [setupToken] — the value of `apiKeyManagementToken`
/// in config/passwords.yaml. Set this before deploying to production.
class ApiKeyEndpoint extends Endpoint {
  final _keyService = ApiKeyService.instance;

  void _requireSetupToken(Session session, String setupToken) {
    final expected = session.passwords['apiKeyManagementToken'] ?? '';
    if (expected.isEmpty || setupToken != expected) {
      throw LandfallException(message: 'Unauthorized.');
    }
  }

  /// Generates a new API key with the given [name] label.
  ///
  /// The returned [ApiKeyCreateResponse.plainTextKey] is shown exactly once
  /// and cannot be recovered. The caller must store it securely.
  Future<ApiKeyCreateResponse> generateKey(
    Session session,
    String name,
    String setupToken,
  ) async {
    _requireSetupToken(session, setupToken);

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
  Future<List<ApiKey>> listKeys(Session session, String setupToken) async {
    _requireSetupToken(session, setupToken);

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
  Future<bool> revokeKey(Session session, int id, String setupToken) async {
    _requireSetupToken(session, setupToken);

    final key = await ApiKey.db.findById(session, id);
    if (key == null || key.revokedAt != null) return false;

    await ApiKey.db.updateRow(
      session,
      key.copyWith(revokedAt: DateTime.now().toUtc()),
    );
    return true;
  }
}
