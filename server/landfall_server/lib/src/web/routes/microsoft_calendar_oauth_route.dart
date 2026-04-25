import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../../generated/protocol.dart';

/// OAuth 2.0 routes for connecting a Microsoft Calendar account.
///
/// Flow:
///   1. GET /calendar/microsoft/oauth/start?authUserId=UUID  — redirects to
///      the Microsoft identity platform consent screen.
///   2. GET /calendar/microsoft/oauth/callback?code=...&state=... — exchanges
///      code for tokens, stores a [LinkedCredential], returns a confirmation page.
///
/// Configuration required in passwords.yaml:
///   microsoftClientId         — Azure app (client) ID
///   microsoftClientSecret     — Azure app client secret
///   microsoftOAuthRedirectUri — Full callback URL, e.g.
///                               https://yourdomain.com/calendar/microsoft/oauth/callback
///
/// State tokens are held in a short-lived in-process map. Safe for a
/// single-instance home server.

final _pendingStates = <String, _OAuthState>{};
const _stateTokenTtl = Duration(minutes: 10);

class _OAuthState {
  _OAuthState(this.authUserId, this.expiresAt);
  final String authUserId;
  final DateTime expiresAt;
}

/// GET /calendar/microsoft/oauth/start — redirects to the Microsoft consent screen.
class MicrosoftCalendarOAuthStartRoute extends Route {
  static const _authEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const _scopes = 'Calendars.Read offline_access';

  MicrosoftCalendarOAuthStartRoute() : super(methods: {Method.get});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final clientId = session.passwords['microsoftClientId'];
    final redirectUri = session.passwords['microsoftOAuthRedirectUri'];

    if (clientId == null || redirectUri == null) {
      return Response.internalServerError(
        body: Body.fromString(
          'microsoftClientId and microsoftOAuthRedirectUri must be set in passwords.yaml',
        ),
      );
    }

    final authUserId = request.url.queryParameters['authUserId'];
    if (authUserId == null || authUserId.isEmpty) {
      return Response.badRequest(
        body: Body.fromString('Missing authUserId query parameter'),
      );
    }

    final now = DateTime.now().toUtc();
    _pendingStates.removeWhere((_, v) => v.expiresAt.isBefore(now));

    final state = const Uuid().v4();
    _pendingStates[state] = _OAuthState(authUserId, now.add(_stateTokenTtl));

    final redirectUrl = Uri.parse(_authEndpoint).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes,
        'access_type': 'offline',
        'prompt': 'consent',
        'state': state,
      },
    );

    return Response.seeOther(redirectUrl);
  }
}

/// GET /calendar/microsoft/oauth/callback — exchanges code for tokens and
/// stores a [LinkedCredential].
class MicrosoftCalendarOAuthCallbackRoute extends Route {
  static const _tokenEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/token';
  static const _userInfoEndpoint =
      'https://graph.microsoft.com/v1.0/me';

  final http.Client _httpClient;

  MicrosoftCalendarOAuthCallbackRoute({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        super(methods: {Method.get});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final params = request.url.queryParameters;
    final code = params['code'];
    final state = params['state'];
    final error = params['error'];

    if (error != null) {
      return _htmlResponse(400, 'Microsoft authorization denied: $error');
    }

    if (code == null || state == null) {
      return _htmlResponse(400, 'Missing code or state parameter');
    }

    final pendingState = _pendingStates.remove(state);
    if (pendingState == null ||
        pendingState.expiresAt.isBefore(DateTime.now().toUtc())) {
      return _htmlResponse(
        400,
        'Invalid or expired state token. Please restart the connection flow.',
      );
    }

    final clientId = session.passwords['microsoftClientId'];
    final clientSecret = session.passwords['microsoftClientSecret'];
    final redirectUri = session.passwords['microsoftOAuthRedirectUri'];

    if (clientId == null || clientSecret == null || redirectUri == null) {
      return _htmlResponse(500, 'Server OAuth configuration is incomplete');
    }

    final tokenResponse = await _httpClient.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'scope': 'Calendars.Read offline_access',
      },
    );

    if (tokenResponse.statusCode != 200) {
      session.log(
        'Microsoft OAuth token exchange failed: '
        '${tokenResponse.statusCode} ${tokenResponse.body}',
        level: LogLevel.error,
      );
      return _htmlResponse(500, 'Token exchange failed. Please try again.');
    }

    final tokenJson = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final accessToken = tokenJson['access_token'] as String;
    final refreshToken = tokenJson['refresh_token'] as String?;
    final expiresIn = (tokenJson['expires_in'] as num).toInt();
    final scopes = tokenJson['scope'] as String?;
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(Duration(seconds: expiresIn));

    final userInfoResponse = await _httpClient.get(
      Uri.parse(_userInfoEndpoint),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (userInfoResponse.statusCode != 200) {
      return _htmlResponse(
        500,
        'Failed to fetch Microsoft account info. Please try again.',
      );
    }

    final userJson = jsonDecode(userInfoResponse.body) as Map<String, dynamic>;
    final providerEmail =
        (userJson['mail'] as String?) ??
        (userJson['userPrincipalName'] as String?) ??
        'unknown';

    final existing = await LinkedCredential.db.findFirstRow(
      session,
      where: (t) =>
          t.provider.equals('microsoft') &
          t.providerEmail.equals(providerEmail),
    );

    if (existing != null) {
      await LinkedCredential.db.updateRow(
        session,
        existing.copyWith(
          accessToken: accessToken,
          refreshToken: refreshToken ?? existing.refreshToken,
          tokenExpiresAt: expiresAt,
          scopes: scopes,
          isActive: true,
          updatedAt: now,
        ),
      );
    } else {
      await LinkedCredential.db.insertRow(
        session,
        LinkedCredential(
          authUserId: UuidValue.fromString(pendingState.authUserId),
          provider: 'microsoft',
          providerEmail: providerEmail,
          accessToken: accessToken,
          refreshToken: refreshToken,
          tokenExpiresAt: expiresAt,
          scopes: scopes,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return _htmlResponse(
      200,
      'Microsoft Calendar connected for $providerEmail. '
      'You can close this window.',
    );
  }

  Result _htmlResponse(int status, String message) {
    return Response(
      status,
      body: Body.fromString(
        '<!DOCTYPE html><html><body><p>$message</p></body></html>',
        mimeType: MimeType.html,
      ),
    );
  }
}
