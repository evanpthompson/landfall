import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Provides settings data to the display client.
///
/// All methods require an authenticated session.
class SettingsEndpoint extends Endpoint {
  /// Returns all linked credentials for the current user, token-free.
  Future<List<LinkedCredentialSummary>> getLinkedCredentials(
    Session session,
  ) async {
    final credentials = await LinkedCredential.db.find(
      session,
      where: (t) => t.isActive.equals(true),
      orderBy: (t) => t.createdAt,
    );

    return credentials
        .map(
          (c) => LinkedCredentialSummary(
            id: c.id!,
            provider: c.provider,
            providerEmail: c.providerEmail,
            isActive: c.isActive,
            createdAt: c.createdAt,
          ),
        )
        .toList();
  }

  /// Returns a stable, deterministic auth user ID string suitable for use in
  /// OAuth link URLs (e.g. /calendar/oauth/start?authUserId=...).
  ///
  /// The ID is derived from the authenticated Serverpod user's identifier and
  /// formatted as a valid UUID so it can be stored in LinkedCredential.authUserId.
  Future<String> getMyAuthUserId(Session session) async {
    final userIdentifier = session.authenticated?.userIdentifier ?? '0';
    // Stable UUID format: 00000000-0000-0000-0000-<userId padded to 12 digits>
    final padded = userIdentifier.padLeft(12, '0');
    return '00000000-0000-0000-0000-$padded';
  }
}
