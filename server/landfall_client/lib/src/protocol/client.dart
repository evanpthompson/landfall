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
import 'dart:async' as _i2;
import 'package:landfall_client/src/protocol/cards/card_row.dart' as _i3;
import 'package:landfall_client/src/protocol/cards/card_push_request.dart'
    as _i4;
import 'package:landfall_client/src/protocol/agent/api_key_create_response.dart'
    as _i5;
import 'package:landfall_client/src/protocol/agent/api_key.dart' as _i6;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i7;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i8;
import 'dart:typed_data' as _i9;
import 'package:landfall_client/src/protocol/calendar/calendar_event.dart'
    as _i10;
import 'package:landfall_client/src/protocol/greetings/greeting.dart' as _i11;
import 'package:landfall_client/src/protocol/photo/photo.dart' as _i12;
import 'package:landfall_client/src/protocol/settings/linked_credential_summary.dart'
    as _i13;
import 'package:landfall_client/src/protocol/weather/weather_current.dart'
    as _i14;
import 'package:landfall_client/src/protocol/weather/weather_forecast.dart'
    as _i15;
import 'protocol.dart' as _i16;

/// The authenticated agent push API.
///
/// All methods require [apiKey] — a valid plaintext API key generated via
/// [ApiKeyEndpoint.generateKey]. Rate limit: 500 pushCard calls per day
/// per key (configurable per key).
/// {@category Endpoint}
class EndpointAgent extends _i1.EndpointRef {
  EndpointAgent(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'agent';

  /// Returns all active (non-dismissed, non-expired) cards for this display.
  ///
  /// Cards are returned newest-first.
  _i2.Future<List<_i3.CardRow>> listCards(String apiKey) =>
      caller.callServerEndpoint<List<_i3.CardRow>>(
        'agent',
        'listCards',
        {'apiKey': apiKey},
      );

  /// Pushes a card to the display.
  ///
  /// If [CardPushRequest.externalId] is provided and a card with that ID
  /// already exists, the existing card is updated in-place. Otherwise a
  /// new card is created with a generated UUID.
  ///
  /// Returns the created or updated [CardRow].
  _i2.Future<_i3.CardRow> pushCard(
    String apiKey,
    _i4.CardPushRequest request,
  ) => caller.callServerEndpoint<_i3.CardRow>(
    'agent',
    'pushCard',
    {
      'apiKey': apiKey,
      'request': request,
    },
  );

  /// Updates an existing card by [externalId].
  ///
  /// Title and source in [request] replace the existing values.
  /// Returns the updated [CardRow], or throws if no card with that
  /// [externalId] exists.
  _i2.Future<_i3.CardRow> updateCard(
    String apiKey,
    String externalId,
    _i4.CardPushRequest request,
  ) => caller.callServerEndpoint<_i3.CardRow>(
    'agent',
    'updateCard',
    {
      'apiKey': apiKey,
      'externalId': externalId,
      'request': request,
    },
  );

  /// Dismisses a card by its [externalId].
  ///
  /// Sets [CardRow.dismissedAt] to now. The card is retained in the database
  /// for history queries. Returns true if a card was found and dismissed,
  /// false if no card with that externalId exists.
  _i2.Future<bool> dismissCard(
    String apiKey,
    String externalId,
  ) => caller.callServerEndpoint<bool>(
    'agent',
    'dismissCard',
    {
      'apiKey': apiKey,
      'externalId': externalId,
    },
  );
}

/// API key management endpoint.
///
/// Phase 2: Unauthenticated — open for local dev, matching Phase 0 CardEndpoint.
/// Phase 5: Will require display-owner authentication before any mutation.
/// {@category Endpoint}
class EndpointApiKey extends _i1.EndpointRef {
  EndpointApiKey(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'apiKey';

  /// Generates a new API key with the given [name] label.
  ///
  /// The returned [ApiKeyCreateResponse.plainTextKey] is shown exactly once
  /// and cannot be recovered. The caller must store it securely.
  _i2.Future<_i5.ApiKeyCreateResponse> generateKey(String name) =>
      caller.callServerEndpoint<_i5.ApiKeyCreateResponse>(
        'apiKey',
        'generateKey',
        {'name': name},
      );

  /// Returns all non-revoked API keys.
  ///
  /// Only metadata is returned — hashes and plaintext keys are never exposed.
  _i2.Future<List<_i6.ApiKey>> listKeys() =>
      caller.callServerEndpoint<List<_i6.ApiKey>>(
        'apiKey',
        'listKeys',
        {},
      );

  /// Revokes an API key by its database [id].
  ///
  /// The key is soft-deleted: its [ApiKey.revokedAt] is set to now.
  /// Revoked keys are rejected by [AgentEndpoint] immediately.
  ///
  /// Returns true if the key existed and was revoked, false if not found
  /// or already revoked.
  _i2.Future<bool> revokeKey(int id) => caller.callServerEndpoint<bool>(
    'apiKey',
    'revokeKey',
    {'id': id},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i7.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i2.Future<_i7.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i7.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// OTP email authentication endpoint.
///
/// Provides a passwordless login flow:
///   1. Client calls [sendCode] with the user's email address.
///   2. The server generates a 6-digit code, stores a SHA-256 hash, and logs
///      (or emails) the plaintext code.
///   3. Client calls [verifyCode] with the email and the code the user entered.
///   4. On success, the server returns an [AuthSuccess] containing a JWT.
///
/// Fail-closed: wrong code, expired code, or replay all throw [ServerpodUnauthenticatedException].
/// {@category Endpoint}
class EndpointOtp extends _i1.EndpointRef {
  EndpointOtp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'otp';

  /// Sends a one-time code to [email].
  ///
  /// Always returns void — do not reveal whether the email is registered.
  _i2.Future<void> sendCode(String email) => caller.callServerEndpoint<void>(
    'otp',
    'sendCode',
    {'email': email},
  );

  /// Verifies [code] for [email] and returns an [AuthSuccess] with a JWT.
  ///
  /// Throws [ServerpodUnauthenticatedException] on any failure.
  _i2.Future<_i7.AuthSuccess> verifyCode(
    String email,
    String code,
  ) => caller.callServerEndpoint<_i7.AuthSuccess>(
    'otp',
    'verifyCode',
    {
      'email': email,
      'code': code,
    },
  );
}

/// Exposes the Passkey authentication endpoints.
///
/// The passkey IDP handles WebAuthn challenge creation, passkey registration,
/// and passkey-based login. See [PasskeyIdpBaseEndpoint] for the full API.
/// {@category Endpoint}
class EndpointPasskeyIdp extends _i8.EndpointPasskeyIdpBase {
  EndpointPasskeyIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'passkeyIdp';

  /// Returns a new challenge to be used for a login or registration request.
  @override
  _i2.Future<({_i9.ByteData challenge, _i1.UuidValue id})> createChallenge() =>
      caller.callServerEndpoint<({_i9.ByteData challenge, _i1.UuidValue id})>(
        'passkeyIdp',
        'createChallenge',
        {},
      );

  /// Registers a Passkey for the [session]'s current user.
  ///
  /// Throws if the user is not authenticated.
  @override
  _i2.Future<void> register({
    required _i8.PasskeyRegistrationRequest registrationRequest,
  }) => caller.callServerEndpoint<void>(
    'passkeyIdp',
    'register',
    {'registrationRequest': registrationRequest},
  );

  /// Authenticates the user related to the given Passkey.
  @override
  _i2.Future<_i7.AuthSuccess> login({
    required _i8.PasskeyLoginRequest loginRequest,
  }) => caller.callServerEndpoint<_i7.AuthSuccess>(
    'passkeyIdp',
    'login',
    {'loginRequest': loginRequest},
  );

  @override
  _i2.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'passkeyIdp',
    'hasAccount',
    {},
  );
}

/// Serves cached calendar events to the Flutter display client.
///
/// Events are populated by [CalendarRefreshCall] on a 15-minute schedule.
/// Returns an empty list gracefully if no credentials have been connected yet.
/// {@category Endpoint}
class EndpointCalendar extends _i1.EndpointRef {
  EndpointCalendar(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'calendar';

  /// Returns the next 20 upcoming events across all active calendar feeds,
  /// sorted by start time.
  _i2.Future<List<_i10.CalendarEvent>> getUpcomingEvents() =>
      caller.callServerEndpoint<List<_i10.CalendarEvent>>(
        'calendar',
        'getUpcomingEvents',
        {},
      );
}

/// Endpoint for card management.
///
/// Phase 0: No authentication required — open for local development.
/// Phase 2: API key authentication will be added to [pushCard] and [dismissCard].
/// {@category Endpoint}
class EndpointCard extends _i1.EndpointRef {
  EndpointCard(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'card';

  /// Returns all active cards for the display.
  ///
  /// Active = not dismissed AND (persistent OR not yet expired).
  /// Cards are returned newest-first.
  _i2.Future<List<_i3.CardRow>> getCards() =>
      caller.callServerEndpoint<List<_i3.CardRow>>(
        'card',
        'getCards',
        {},
      );

  /// Pushes a card to the display.
  ///
  /// If [CardPushRequest.externalId] is provided and a card with that ID
  /// already exists, the existing card is updated in-place. Otherwise a
  /// new card is created with a generated UUID.
  ///
  /// Returns the created or updated [CardRow].
  _i2.Future<_i3.CardRow> pushCard(_i4.CardPushRequest request) =>
      caller.callServerEndpoint<_i3.CardRow>(
        'card',
        'pushCard',
        {'request': request},
      );

  /// Dismisses a card by its [externalId].
  ///
  /// Sets [CardRow.dismissedAt] to now. The card is retained in the database
  /// for history queries. Returns true if a card was found and dismissed,
  /// false if no card with that externalId exists.
  _i2.Future<bool> dismissCard(String externalId) =>
      caller.callServerEndpoint<bool>(
        'card',
        'dismissCard',
        {'externalId': externalId},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i11.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i11.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// Serves cached photo metadata to the Flutter display client.
///
/// Photo entries are populated by [PhotoRefreshCall] on a 30-minute schedule.
/// Returns an empty list gracefully if no photos have been synced yet.
///
/// Image bytes are NOT served through this endpoint. The display client
/// fetches images via the [PhotoServeRoute] web route at /photos/{id}.
/// {@category Endpoint}
class EndpointPhoto extends _i1.EndpointRef {
  EndpointPhoto(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'photo';

  /// Returns all available photos ordered by filename.
  _i2.Future<List<_i12.Photo>> getPhotos() =>
      caller.callServerEndpoint<List<_i12.Photo>>(
        'photo',
        'getPhotos',
        {},
      );
}

/// Provides settings data to the display client.
///
/// All methods require an authenticated session.
/// {@category Endpoint}
class EndpointSettings extends _i1.EndpointRef {
  EndpointSettings(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'settings';

  /// Returns all linked credentials for the current user, token-free.
  _i2.Future<List<_i13.LinkedCredentialSummary>> getLinkedCredentials() =>
      caller.callServerEndpoint<List<_i13.LinkedCredentialSummary>>(
        'settings',
        'getLinkedCredentials',
        {},
      );

  /// Returns a stable, deterministic auth user ID string suitable for use in
  /// OAuth link URLs (e.g. /calendar/oauth/start?authUserId=...).
  ///
  /// The ID is derived from the authenticated Serverpod user's identifier and
  /// formatted as a valid UUID so it can be stored in LinkedCredential.authUserId.
  _i2.Future<String> getMyAuthUserId() => caller.callServerEndpoint<String>(
    'settings',
    'getMyAuthUserId',
    {},
  );
}

/// Serves cached weather data to the Flutter display client.
///
/// Data is populated by [WeatherRefreshCall] on a 10-minute schedule.
/// Endpoints return null / empty list gracefully if no data has been
/// cached yet (e.g., on a fresh server start before the first refresh).
/// {@category Endpoint}
class EndpointWeather extends _i1.EndpointRef {
  EndpointWeather(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'weather';

  /// Returns the most recently cached current conditions, or null if none.
  _i2.Future<_i14.WeatherCurrent?> getCurrentWeather() =>
      caller.callServerEndpoint<_i14.WeatherCurrent?>(
        'weather',
        'getCurrentWeather',
        {},
      );

  /// Returns the cached 5-day forecast, oldest day first.
  ///
  /// Returns an empty list if no forecast data has been cached yet.
  _i2.Future<List<_i15.WeatherForecast>> getForecast() =>
      caller.callServerEndpoint<List<_i15.WeatherForecast>>(
        'weather',
        'getForecast',
        {},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i8.Caller(client);
    serverpod_auth_core = _i7.Caller(client);
  }

  late final _i8.Caller serverpod_auth_idp;

  late final _i7.Caller serverpod_auth_core;
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i16.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    agent = EndpointAgent(this);
    apiKey = EndpointApiKey(this);
    jwtRefresh = EndpointJwtRefresh(this);
    otp = EndpointOtp(this);
    passkeyIdp = EndpointPasskeyIdp(this);
    calendar = EndpointCalendar(this);
    card = EndpointCard(this);
    greeting = EndpointGreeting(this);
    photo = EndpointPhoto(this);
    settings = EndpointSettings(this);
    weather = EndpointWeather(this);
    modules = Modules(this);
  }

  late final EndpointAgent agent;

  late final EndpointApiKey apiKey;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointOtp otp;

  late final EndpointPasskeyIdp passkeyIdp;

  late final EndpointCalendar calendar;

  late final EndpointCard card;

  late final EndpointGreeting greeting;

  late final EndpointPhoto photo;

  late final EndpointSettings settings;

  late final EndpointWeather weather;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'agent': agent,
    'apiKey': apiKey,
    'jwtRefresh': jwtRefresh,
    'otp': otp,
    'passkeyIdp': passkeyIdp,
    'calendar': calendar,
    'card': card,
    'greeting': greeting,
    'photo': photo,
    'settings': settings,
    'weather': weather,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
