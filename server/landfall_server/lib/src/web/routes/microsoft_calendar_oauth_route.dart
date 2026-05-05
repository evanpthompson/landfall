import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../../generated/protocol.dart';
import 'oauth_token_encryptor.dart';

/// OAuth 2.0 routes for connecting a Microsoft Calendar account.
///
/// Flow:
///   1. GET /calendar/microsoft/oauth/start  — requires an authenticated
///      session; derives authUserId from session.authenticated, then redirects
///      to the Microsoft identity platform consent screen.
///   2. GET /calendar/microsoft/oauth/callback?code=...&state=... — exchanges
///      code for tokens, encrypts them at rest, stores a [LinkedCredential],
///      returns a confirmation page.
///
/// Configuration required in passwords.yaml:
///   microsoftClientId         — Azure app (client) ID
///   microsoftClientSecret     — Azure app client secret
///   microsoftOAuthRedirectUri — Full callback URL
///   oauthTokenEncryptionKey   — 64-char hex, AES-256 key for token encryption

final _pendingStates = <String, _OAuthState>{};
const _stateTokenTtl = Duration(minutes: 10);

class _OAuthState {
  _OAuthState(this.authUserId, this.expiresAt);
  final String authUserId;
  final DateTime expiresAt;
}

// ignore: invalid_use_of_visible_for_testing_member — test hook only
void injectMicrosoftOAuthStateForTest(String state, String authUserId) {
  _pendingStates[state] = _OAuthState(
    authUserId,
    DateTime.now().toUtc().add(_stateTokenTtl),
  );
}

String _userIdentifierToUuid(String userIdentifier) {
  final padded = userIdentifier.padLeft(12, '0');
  // RFC4122 v4 layout: version nibble = 4, variant nibble = 8.
  return '00000000-0000-4000-8000-$padded';
}

/// GET /calendar/microsoft/oauth/start — requires authentication, then
/// redirects to the Microsoft consent screen.
class MicrosoftCalendarOAuthStartRoute extends Route {
  static const _authEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const _scopes = 'Calendars.Read offline_access';

  MicrosoftCalendarOAuthStartRoute() : super(methods: {Method.get});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    // SEC-06: derive identity from session, not from caller-supplied query param.
    if (session.authenticated == null) {
      return Response(
        401,
        body: Body.fromString(
          'Authentication required to connect a calendar.',
        ),
      );
    }

    final clientId = session.passwords['microsoftClientId'];
    final redirectUri = session.passwords['microsoftOAuthRedirectUri'];

    if (clientId == null || clientId.isEmpty || redirectUri == null) {
      return Response.internalServerError(
        body: Body.fromString(
          'microsoftClientId and microsoftOAuthRedirectUri must be set in passwords.yaml',
        ),
      );
    }

    final authUserId =
        _userIdentifierToUuid(session.authenticated!.userIdentifier);

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
/// stores an encrypted [LinkedCredential].
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

    // SEC-07: encrypt tokens at rest.
    final encKey = session.passwords['oauthTokenEncryptionKey'];
    final storedAccess = OAuthTokenEncryptor.encryptIfKey(accessToken, encKey);
    final storedRefresh = refreshToken != null
        ? OAuthTokenEncryptor.encryptIfKey(refreshToken, encKey)
        : null;

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
          accessToken: storedAccess,
          refreshToken: storedRefresh ?? existing.refreshToken,
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
          accessToken: storedAccess,
          refreshToken: storedRefresh,
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
