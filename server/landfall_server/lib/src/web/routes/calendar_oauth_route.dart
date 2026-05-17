import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../../auth/auth_user_id.dart';
import '../../generated/protocol.dart';
import 'oauth_token_encryptor.dart';

/// OAuth 2.0 routes for connecting a Google Calendar account.
///
/// Flow:
///   1. GET /calendar/oauth/start  — requires an authenticated session;
///      derives authUserId from session.authenticated, then redirects to Google.
///   2. GET /calendar/oauth/callback?code=...&state=... — exchanges code for
///      tokens, encrypts them at rest, stores a [LinkedCredential], returns a
///      confirmation page.
///
/// Configuration required in passwords.yaml:
///   googleOAuthClientId       — OAuth client ID
///   googleOAuthClientSecret   — OAuth client secret
///   googleOAuthRedirectUri    — Full callback URL
///   oauthTokenEncryptionKey   — 64-char hex, AES-256 key for token encryption
///
/// The state token is held in a short-lived in-process map.

final _pendingStates = <String, _OAuthState>{};
const _stateTokenTtl = Duration(minutes: 10);

class _OAuthState {
  _OAuthState(this.authUserId, this.expiresAt);
  final String authUserId;
  final DateTime expiresAt;
}

// ignore: invalid_use_of_visible_for_testing_member — test hook only
void injectCalendarOAuthStateForTest(String state, String authUserId) {
  _pendingStates[state] = _OAuthState(
    authUserId,
    DateTime.now().toUtc().add(_stateTokenTtl),
  );
}

/// GET /calendar/oauth/start — requires authentication, then redirects to
/// Google's consent screen.
class CalendarOAuthStartRoute extends Route {
  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _scopes = [
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/drive.readonly',
    'email',
  ];

  CalendarOAuthStartRoute() : super(methods: {Method.get});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    // SEC-06: derive identity from the authenticated session, never from a
    // caller-supplied query parameter — unless the one-time setup token path
    // is used (see below).
    final String authUserId;

    if (session.authenticated != null) {
      authUserId =
          authUserIdFromIdentifier(session.authenticated!.userIdentifier);
    } else {
      // Setup token path: allows OAuth configuration from a phone browser
      // before a full session exists on the display.  Only accepted when
      // calendarOauthSetupToken is configured, the caller supplies the
      // matching token, and authUserId is a well-formed UUID.
      final setupToken = _password(session, 'calendarOauthSetupToken');
      final providedToken = request.url.queryParameters['setup_token'];
      final providedUserId = request.url.queryParameters['authUserId'];

      if (setupToken != null &&
          providedToken == setupToken &&
          providedUserId != null &&
          _isValidUuid(providedUserId)) {
        session.log(
          'Calendar OAuth start via setup token for user $providedUserId',
          level: LogLevel.warning,
        );
        authUserId = providedUserId;
      } else {
        return Response(
          401,
          body: Body.fromString(
            'Authentication required to connect a calendar.',
          ),
        );
      }
    }

    final clientId = _password(
      session,
      'googleOAuthClientId',
      legacyKey: 'googleClientId',
    );
    final redirectUri = _password(session, 'googleOAuthRedirectUri');

    if (clientId == null || redirectUri == null) {
      return Response.internalServerError(
        body: Body.fromString(
          'googleOAuthClientId and googleOAuthRedirectUri must be set in passwords.yaml',
        ),
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
        'scope': _scopes.join(' '),
        'access_type': 'offline',
        'prompt': 'consent',
        'state': state,
      },
    );

    return Response.seeOther(redirectUrl);
  }
}

/// GET /calendar/oauth/callback — exchanges code for tokens and stores
/// an encrypted [LinkedCredential].
class CalendarOAuthCallbackRoute extends Route {
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const _userInfoEndpoint =
      'https://www.googleapis.com/oauth2/v3/userinfo';

  final http.Client _httpClient;

  CalendarOAuthCallbackRoute({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client(),
      super(methods: {Method.get});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final params = request.url.queryParameters;
    final code = params['code'];
    final state = params['state'];
    final error = params['error'];

    if (error != null) {
      return _htmlResponse(400, 'Google authorization denied: $error');
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

    final clientId = _password(
      session,
      'googleOAuthClientId',
      legacyKey: 'googleClientId',
    );
    final clientSecret = _password(
      session,
      'googleOAuthClientSecret',
      legacyKey: 'googleClientSecret',
    );
    final redirectUri = _password(session, 'googleOAuthRedirectUri');

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
      },
    );

    if (tokenResponse.statusCode != 200) {
      session.log(
        'OAuth token exchange failed: '
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
        'Failed to fetch Google account info. Please try again.',
      );
    }

    final userJson = jsonDecode(userInfoResponse.body) as Map<String, dynamic>;
    final providerEmail = userJson['email'] as String;

    // SEC-07: encrypt tokens at rest.
    final encKey = session.passwords['oauthTokenEncryptionKey'];
    final storedAccess = OAuthTokenEncryptor.encryptIfKey(accessToken, encKey);
    final storedRefresh = refreshToken != null
        ? OAuthTokenEncryptor.encryptIfKey(refreshToken, encKey)
        : null;

    final existing = await LinkedCredential.db.findFirstRow(
      session,
      where: (t) =>
          t.provider.equals('google') & t.providerEmail.equals(providerEmail),
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
          provider: 'google',
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
      'Google Calendar connected for $providerEmail. '
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

String? _password(Session session, String key, {String? legacyKey}) {
  final value = session.passwords[key];
  if (value != null && value.isNotEmpty) return value;
  if (legacyKey == null) return null;
  final legacyValue = session.passwords[legacyKey];
  return legacyValue != null && legacyValue.isNotEmpty ? legacyValue : null;
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _isValidUuid(String s) => _uuidPattern.hasMatch(s);
