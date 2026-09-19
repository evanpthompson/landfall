import 'package:serverpod/serverpod.dart';

import '../auth/auth_user_id.dart';
import '../calendar/credential_integrity.dart';
import '../generated/protocol.dart';
import '../web/routes/calendar_link_ticket.dart';

/// Provides settings data to the display client.
///
/// All methods require an authenticated session.
class SettingsEndpoint extends Endpoint {
  /// Returns all linked credentials for the current user, token-free.
  Future<List<LinkedCredentialSummary>> getLinkedCredentials(
    Session session,
  ) async {
    if (session.authenticated == null) {
      throw LandfallException(message: 'Authentication required.');
    }
    // A row Dart cannot deserialize is skipped and logged rather than being
    // allowed to fail the whole call — one corrupt authUserId used to turn
    // this endpoint into a 500 for every user.
    final credentials = await findReadableCredentials(
      session,
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
    if (session.authenticated == null) {
      throw LandfallException(message: 'Authentication required.');
    }
    return authUserIdFromIdentifier(session.authenticated!.userIdentifier);
  }

  /// SEC-06: mints a short-lived, single-use ticket bound to the *caller's*
  /// authenticated identity, for use connecting a calendar account from a
  /// browser navigation that cannot present the JWT.
  ///
  /// The companion calls this over its authenticated RPC channel, then opens
  /// `/calendar/oauth/start?ticket=<ticket>`. The start route exchanges the
  /// ticket for the bound `authUserId` — it never trusts a caller-supplied
  /// identity. The ticket expires within minutes and cannot be replayed.
  Future<String> createCalendarLinkTicket(Session session) async {
    if (session.authenticated == null) {
      throw LandfallException(message: 'Authentication required.');
    }
    final authUserId =
        authUserIdFromIdentifier(session.authenticated!.userIdentifier);
    return calendarLinkTickets.issue(authUserId);
  }
}
