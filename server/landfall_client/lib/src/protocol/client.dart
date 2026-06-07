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
import 'package:landfall_client/src/protocol/companion/companion_entity.dart'
    as _i11;
import 'package:landfall_client/src/protocol/companion/companion_action.dart'
    as _i12;
import 'package:landfall_client/src/protocol/greetings/greeting.dart' as _i13;
import 'package:landfall_client/src/protocol/layout/layout_config.dart' as _i14;
import 'package:landfall_client/src/protocol/license/license_status_response.dart'
    as _i15;
import 'package:landfall_client/src/protocol/license/pack_info_response.dart'
    as _i16;
import 'package:landfall_client/src/protocol/photo/photo.dart' as _i17;
import 'package:landfall_client/src/protocol/profile/dashboard_profile.dart'
    as _i18;
import 'package:landfall_client/src/protocol/settings/remote_display_settings.dart'
    as _i19;
import 'package:landfall_client/src/protocol/settings/linked_credential_summary.dart'
    as _i20;
import 'package:landfall_client/src/protocol/theme/marketplace_theme_info.dart'
    as _i21;
import 'package:landfall_client/src/protocol/theme/landfall_theme.dart' as _i22;
import 'package:landfall_client/src/protocol/theme/theme_upload_result.dart'
    as _i23;
import 'package:landfall_client/src/protocol/weather/weather_current.dart'
    as _i24;
import 'package:landfall_client/src/protocol/weather/weather_forecast.dart'
    as _i25;
import 'protocol.dart' as _i26;

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

  /// Returns all active (non-dismissed, non-expired) grid cards.
  ///
  /// Ticker-layout cards are excluded — they are presence signals, not content.
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

  /// Pushes a ticker heartbeat message to the ghost ticker strip.
  ///
  /// Convenience wrapper for [pushCard] with [layout: 'ticker'] and a
  /// default TTL of 30 seconds. [message] maps to the card title.
  /// [expiresAt] overrides the default TTL.
  _i2.Future<_i3.CardRow> pushTicker(
    String apiKey,
    String source,
    String message, {
    DateTime? expiresAt,
  }) => caller.callServerEndpoint<_i3.CardRow>(
    'agent',
    'pushTicker',
    {
      'apiKey': apiKey,
      'source': source,
      'message': message,
      'expiresAt': expiresAt,
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
/// All methods require [setupToken] — the value of `apiKeyManagementToken`
/// in config/passwords.yaml. Set this before deploying to production.
/// {@category Endpoint}
class EndpointApiKey extends _i1.EndpointRef {
  EndpointApiKey(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'apiKey';

  /// Generates a new API key with the given [name] label.
  ///
  /// The returned [ApiKeyCreateResponse.plainTextKey] is shown exactly once
  /// and cannot be recovered. The caller must store it securely.
  _i2.Future<_i5.ApiKeyCreateResponse> generateKey(
    String name,
    String setupToken,
  ) => caller.callServerEndpoint<_i5.ApiKeyCreateResponse>(
    'apiKey',
    'generateKey',
    {
      'name': name,
      'setupToken': setupToken,
    },
  );

  /// Returns all non-revoked API keys.
  ///
  /// Only metadata is returned — hashes and plaintext keys are never exposed.
  _i2.Future<List<_i6.ApiKey>> listKeys(String setupToken) =>
      caller.callServerEndpoint<List<_i6.ApiKey>>(
        'apiKey',
        'listKeys',
        {'setupToken': setupToken},
      );

  /// Revokes an API key by its database [id].
  ///
  /// The key is soft-deleted: its [ApiKey.revokedAt] is set to now.
  /// Revoked keys are rejected by [AgentEndpoint] immediately.
  ///
  /// Returns true if the key existed and was revoked, false if not found
  /// or already revoked.
  _i2.Future<bool> revokeKey(
    int id,
    String setupToken,
  ) => caller.callServerEndpoint<bool>(
    'apiKey',
    'revokeKey',
    {
      'id': id,
      'setupToken': setupToken,
    },
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

/// {@category Endpoint}
class EndpointCalendar extends _i1.EndpointRef {
  EndpointCalendar(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'calendar';

  _i2.Future<List<_i10.CalendarEvent>> getUpcomingEvents() =>
      caller.callServerEndpoint<List<_i10.CalendarEvent>>(
        'calendar',
        'getUpcomingEvents',
        {},
      );
}

/// Endpoint for card management.
///
/// [getCards] and [getTickerMessages] are read-only and may be called by the
/// local display without a session. [pushCard] and [dismissCard] mutate state
/// and require an authenticated session (SEC-01).
/// {@category Endpoint}
class EndpointCard extends _i1.EndpointRef {
  EndpointCard(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'card';

  /// Returns all active grid cards for the display.
  ///
  /// Active = not dismissed AND (persistent OR not yet expired).
  /// Ticker-layout cards are excluded — use [getTickerMessages] for those.
  /// Cards are returned newest-first.
  _i2.Future<List<_i3.CardRow>> getCards() =>
      caller.callServerEndpoint<List<_i3.CardRow>>(
        'card',
        'getCards',
        {},
      );

  /// Returns the current ticker buffer: non-expired ticker-layout cards,
  /// newest first, capped at 10 entries.
  _i2.Future<List<_i3.CardRow>> getTickerMessages() =>
      caller.callServerEndpoint<List<_i3.CardRow>>(
        'card',
        'getTickerMessages',
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

/// Companion server endpoint.
///
/// Owns the per-display companion entity (one row per display, seeded once)
/// and the phone→TV event delivery channel via long-polling.
///
/// Delivery model:
/// - TV calls [pollForEvents] which blocks until either an action arrives
///   or the timeout elapses (returns null on timeout).
/// - Phone calls [pushAction] which completes any pending poll for that
///   display, or enqueues the action if no TV is currently polling.
/// - State is in-memory: server restart drops pending actions and forces
///   TVs to reconnect their poll. Acceptable for alpha — actions are
///   ephemeral by design.
/// {@category Endpoint}
class EndpointCompanion extends _i1.EndpointRef {
  EndpointCompanion(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'companion';

  /// Returns the companion entity for [displayId], creating it on first
  /// access. MVP seeds every display with Lumen — Phase 22+ will use the
  /// displayId hash to seed an xrandom draw across the full creature pool.
  _i2.Future<_i11.CompanionEntity> getOrCreateForDisplay(String displayId) =>
      caller.callServerEndpoint<_i11.CompanionEntity>(
        'companion',
        'getOrCreateForDisplay',
        {'displayId': displayId},
      );

  /// Long-polls for the next companion action targeted at [displayId].
  ///
  /// Returns the action as soon as one is pushed via [pushAction], or null
  /// if [timeoutSeconds] elapses with no action. Clients should immediately
  /// reissue the poll on either outcome.
  ///
  /// If actions are already queued for this display (pushed while no poll
  /// was active), the oldest is returned immediately.
  _i2.Future<_i12.CompanionAction?> pollForEvents(
    String displayId, {
    required int timeoutSeconds,
  }) => caller.callServerEndpoint<_i12.CompanionAction?>(
    'companion',
    'pollForEvents',
    {
      'displayId': displayId,
      'timeoutSeconds': timeoutSeconds,
    },
  );

  /// Pushes a [kind] action for [displayId], typically called from the
  /// phone web page tap handler.
  ///
  /// If a TV is currently long-polling for this display, the action is
  /// delivered to it immediately. Otherwise the action is queued
  /// (capped at [_maxQueuePerDisplay] — oldest dropped on overflow).
  _i2.Future<void> pushAction(
    String displayId,
    String kind,
  ) => caller.callServerEndpoint<void>(
    'companion',
    'pushAction',
    {
      'displayId': displayId,
      'kind': kind,
    },
  );

  /// Returns the base URL a phone should hit to load `/c/{displayId}`.
  ///
  /// Delegates to [resolveLanBaseUrl] so the companion page and the
  /// device-auth `/device` page can never drift on how the LAN-reachable
  /// host is resolved. The phone scanning the QR must be on the same LAN as
  /// the host; the URL is not designed to be internet-reachable.
  _i2.Future<String> getCompanionBaseUrl() => caller.callServerEndpoint<String>(
    'companion',
    'getCompanionBaseUrl',
    {},
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
  _i2.Future<_i13.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i13.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// Manages saved display layout configurations.
///
/// Layouts are stored in [layout_configs]. Each row is a named layout with a
/// preset category (weekday | weekend | night | custom). One row has
/// [LayoutConfig.isActive] = true — that is the layout currently shown on the
/// display.
/// {@category Endpoint}
class EndpointLayout extends _i1.EndpointRef {
  EndpointLayout(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'layout';

  /// Returns all saved layouts, ordered by preset type then name.
  ///
  /// Returns an empty list if no layouts have been saved yet.
  _i2.Future<List<_i14.LayoutConfig>> getLayouts() =>
      caller.callServerEndpoint<List<_i14.LayoutConfig>>(
        'layout',
        'getLayouts',
        {},
      );

  /// Saves [layout], inserting a new row or updating an existing one by id.
  ///
  /// If [layout.id] is null a new row is created. Returns the saved row.
  _i2.Future<_i14.LayoutConfig> saveLayout(_i14.LayoutConfig layout) =>
      caller.callServerEndpoint<_i14.LayoutConfig>(
        'layout',
        'saveLayout',
        {'layout': layout},
      );

  /// Marks [layoutId] as active and clears the active flag on all others.
  ///
  /// Returns the newly activated [LayoutConfig].
  _i2.Future<_i14.LayoutConfig> setActiveLayout(int layoutId) =>
      caller.callServerEndpoint<_i14.LayoutConfig>(
        'layout',
        'setActiveLayout',
        {'layoutId': layoutId},
      );

  /// Deletes the layout with the given [id].
  ///
  /// The active layout cannot be deleted — an exception is thrown instead.
  _i2.Future<void> deleteLayout(int id) => caller.callServerEndpoint<void>(
    'layout',
    'deleteLayout',
    {'id': id},
  );
}

/// Manages license key activation and status queries.
///
/// One license key can be activated per Serverpod auth user. The key is tied
/// to the account permanently — it survives app reinstalls because auth is
/// server-side.
/// {@category Endpoint}
class EndpointLicense extends _i1.EndpointRef {
  EndpointLicense(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'license';

  /// Returns the current license status for the authenticated user.
  ///
  /// Returns free tier when the user has no activated license or is not signed in.
  _i2.Future<_i15.LicenseStatusResponse> getLicenseStatus() =>
      caller.callServerEndpoint<_i15.LicenseStatusResponse>(
        'license',
        'getLicenseStatus',
        {},
      );

  /// Activates [key] for the authenticated user.
  ///
  /// Throws [LicenseException] if the key is not found or already activated
  /// by a different user.
  _i2.Future<_i15.LicenseStatusResponse> activateLicense(String key) =>
      caller.callServerEndpoint<_i15.LicenseStatusResponse>(
        'license',
        'activateLicense',
        {'key': key},
      );
}

/// Manages the integration pack marketplace catalog and per-user ownership.
/// {@category Endpoint}
class EndpointPack extends _i1.EndpointRef {
  EndpointPack(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'pack';

  /// Returns all active packs in the catalog, with ownership flags for the
  /// authenticated user. Anonymous sessions see all packs as unowned.
  _i2.Future<List<_i16.PackInfoResponse>> listPacks() =>
      caller.callServerEndpoint<List<_i16.PackInfoResponse>>(
        'pack',
        'listPacks',
        {},
      );

  /// Returns packs owned by the authenticated user.
  ///
  /// Returns an empty list for anonymous sessions.
  _i2.Future<List<_i16.PackInfoResponse>> getOwnedPacks() =>
      caller.callServerEndpoint<List<_i16.PackInfoResponse>>(
        'pack',
        'getOwnedPacks',
        {},
      );
}

/// {@category Endpoint}
class EndpointPhoto extends _i1.EndpointRef {
  EndpointPhoto(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'photo';

  _i2.Future<List<_i17.Photo>> getPhotos() =>
      caller.callServerEndpoint<List<_i17.Photo>>(
        'photo',
        'getPhotos',
        {},
      );

  /// Returns a short-lived signed URL for [photoId].
  ///
  /// The URL can be used by the display client to fetch photo bytes from
  /// [PhotoServeRoute] without embedding a session token in the HTTP request.
  /// Tokens expire after [PhotoSigningService.tokenLifetime].
  _i2.Future<String> getSignedPhotoUrl(int photoId) =>
      caller.callServerEndpoint<String>(
        'photo',
        'getSignedPhotoUrl',
        {'photoId': photoId},
      );
}

/// Manages named dashboard profiles.
///
/// Each profile stores a complete layout (cardsJson + grid dimensions), an
/// agent card filter, an optional theme, and an optional schedule. Exactly one
/// profile has [DashboardProfile.isActive] = true at any time.
/// {@category Endpoint}
class EndpointProfile extends _i1.EndpointRef {
  EndpointProfile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'profile';

  /// Returns all profiles ordered by [DashboardProfile.sortOrder] ascending.
  _i2.Future<List<_i18.DashboardProfile>> listProfiles() =>
      caller.callServerEndpoint<List<_i18.DashboardProfile>>(
        'profile',
        'listProfiles',
        {},
      );

  /// Creates a new profile with the given [name].
  ///
  /// [cardsJson] sets the initial card layout. When omitted the layout is an
  /// empty array — callers should pass in the current active layout's cardsJson
  /// to duplicate it as a starting point.
  ///
  /// Returns the created [DashboardProfile] with its assigned id.
  _i2.Future<_i18.DashboardProfile> createProfile(
    String name, {
    String? cardsJson,
  }) => caller.callServerEndpoint<_i18.DashboardProfile>(
    'profile',
    'createProfile',
    {
      'name': name,
      'cardsJson': cardsJson,
    },
  );

  /// Updates the mutable fields of an existing profile.
  ///
  /// Only non-null arguments are applied — pass null to leave a field unchanged.
  _i2.Future<_i18.DashboardProfile> updateProfile(
    int id, {
    String? name,
    String? themeId,
    String? cardFilterJson,
    String? scheduleJson,
    int? sortOrder,
    String? cardsJson,
  }) => caller.callServerEndpoint<_i18.DashboardProfile>(
    'profile',
    'updateProfile',
    {
      'id': id,
      'name': name,
      'themeId': themeId,
      'cardFilterJson': cardFilterJson,
      'scheduleJson': scheduleJson,
      'sortOrder': sortOrder,
      'cardsJson': cardsJson,
    },
  );

  /// Deletes the profile with the given [id].
  ///
  /// Throws [InvalidRequestException] if the profile is currently active or if
  /// it is the last remaining profile.
  _i2.Future<void> deleteProfile(int id) => caller.callServerEndpoint<void>(
    'profile',
    'deleteProfile',
    {'id': id},
  );

  /// Switches the active profile to [id].
  ///
  /// Clears [isActive] on all other profiles atomically. Returns the newly
  /// activated profile.
  _i2.Future<_i18.DashboardProfile> activateProfile(int id) =>
      caller.callServerEndpoint<_i18.DashboardProfile>(
        'profile',
        'activateProfile',
        {'id': id},
      );

  /// Creates a copy of the profile identified by [id] with the given [newName].
  ///
  /// The duplicate is inactive and placed at the end of the sort order.
  /// Returns the newly created profile.
  _i2.Future<_i18.DashboardProfile> duplicateProfile(
    int id,
    String newName,
  ) => caller.callServerEndpoint<_i18.DashboardProfile>(
    'profile',
    'duplicateProfile',
    {
      'id': id,
      'newName': newName,
    },
  );
}

/// Provides remote read/write access to a display's user-configurable settings.
///
/// All methods require an authenticated session.
/// One row per displayId — last-write-wins by updatedAt.
/// {@category Endpoint}
class EndpointDisplaySettings extends _i1.EndpointRef {
  EndpointDisplaySettings(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'displaySettings';

  /// Returns the remote settings record for [displayId], or null when no
  /// record exists yet (display has not yet seeded its settings to the server).
  _i2.Future<_i19.RemoteDisplaySettings?> get(String displayId) =>
      caller.callServerEndpoint<_i19.RemoteDisplaySettings?>(
        'displaySettings',
        'get',
        {'displayId': displayId},
      );

  /// Upserts the settings record for the given [settings.displayId].
  ///
  /// Bumps [RemoteDisplaySettings.updatedAt] to now() server-side so that
  /// last-write-wins resolution always uses a monotonically-increasing server
  /// clock rather than a client clock.
  _i2.Future<void> save(_i19.RemoteDisplaySettings settings) =>
      caller.callServerEndpoint<void>(
        'displaySettings',
        'save',
        {'settings': settings},
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
  _i2.Future<List<_i20.LinkedCredentialSummary>> getLinkedCredentials() =>
      caller.callServerEndpoint<List<_i20.LinkedCredentialSummary>>(
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

/// Marketplace-specific theme queries.
///
/// Complements [ThemeEndpoint] with purchase-awareness. All read methods work
/// unauthenticated; ownership flags are silently false when the caller is not
/// authenticated.
/// {@category Endpoint}
class EndpointMarketplace extends _i1.EndpointRef {
  EndpointMarketplace(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'marketplace';

  /// Returns all themes where [LandfallTheme.isMarketplace] is true, ordered
  /// by name. Each entry carries an [MarketplaceThemeInfo.isOwned] flag based
  /// on the authenticated caller's purchase history.
  _i2.Future<List<_i21.MarketplaceThemeInfo>> listMarketplaceThemes() =>
      caller.callServerEndpoint<List<_i21.MarketplaceThemeInfo>>(
        'marketplace',
        'listMarketplaceThemes',
        {},
      );

  /// Returns the marketplace entry for [themeId].
  ///
  /// Throws [NotFoundException] when [themeId] is unknown or is not a
  /// marketplace theme.
  _i2.Future<_i21.MarketplaceThemeInfo> getMarketplaceTheme(int themeId) =>
      caller.callServerEndpoint<_i21.MarketplaceThemeInfo>(
        'marketplace',
        'getMarketplaceTheme',
        {'themeId': themeId},
      );

  /// Returns all marketplace themes owned (purchased) by the authenticated
  /// caller. Returns an empty list for unauthenticated sessions.
  _i2.Future<List<_i21.MarketplaceThemeInfo>> getOwnedThemes() =>
      caller.callServerEndpoint<List<_i21.MarketplaceThemeInfo>>(
        'marketplace',
        'getOwnedThemes',
        {},
      );
}

/// Manages themes: built-in, user-imported, and marketplace.
/// {@category Endpoint}
class EndpointTheme extends _i1.EndpointRef {
  EndpointTheme(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'theme';

  /// Returns all themes available on this display (built-in + imported).
  ///
  /// Built-ins are seeded if the themes table is empty.
  _i2.Future<List<_i22.LandfallTheme>> listThemes() =>
      caller.callServerEndpoint<List<_i22.LandfallTheme>>(
        'theme',
        'listThemes',
        {},
      );

  /// Validates and stores a theme from a raw YAML or JSON [yaml] string.
  ///
  /// On success [ThemeUploadResult.theme] is set and [errors] is empty.
  /// On failure [theme] is null and [errors] lists each validation problem.
  ///
  /// If a theme with the same slug already exists it is replaced.
  _i2.Future<_i23.ThemeUploadResult> uploadTheme(String yaml) =>
      caller.callServerEndpoint<_i23.ThemeUploadResult>(
        'theme',
        'uploadTheme',
        {'yaml': yaml},
      );

  /// Fetches a theme YAML/JSON from the given HTTPS [url], validates, and
  /// stores it.
  ///
  /// Returns the same [ThemeUploadResult] shape as [uploadTheme].
  /// Rejects non-HTTPS URLs, private IP ranges, and loopback addresses to
  /// prevent SSRF. Enforces a 10-second fetch timeout. OWASP A06:2025.
  _i2.Future<_i23.ThemeUploadResult> importTheme(String url) =>
      caller.callServerEndpoint<_i23.ThemeUploadResult>(
        'theme',
        'importTheme',
        {'url': url},
      );

  /// Deletes the theme with the given [id].
  ///
  /// Throws [InvalidRequestException] when attempting to delete a built-in
  /// theme. Is a no-op when [id] does not exist.
  _i2.Future<void> deleteTheme(int id) => caller.callServerEndpoint<void>(
    'theme',
    'deleteTheme',
    {'id': id},
  );

  /// Returns the fully resolved token JSON string for the theme identified by
  /// [id].
  ///
  /// Throws [NotFoundException] when [id] does not exist.
  _i2.Future<String> previewTheme(int id) => caller.callServerEndpoint<String>(
    'theme',
    'previewTheme',
    {'id': id},
  );

  /// Links the theme identified by [themeId] to a profile or to the global
  /// display setting.
  ///
  /// When [profileId] is provided, updates [DashboardProfile.themeId] for that
  /// profile. When null, is a no-op at the profile level (placeholder for a
  /// future global theme setting).
  ///
  /// Throws [NotFoundException] when [themeId] does not exist.
  _i2.Future<void> applyTheme(
    int themeId, {
    int? profileId,
  }) => caller.callServerEndpoint<void>(
    'theme',
    'applyTheme',
    {
      'themeId': themeId,
      'profileId': profileId,
    },
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
  _i2.Future<_i24.WeatherCurrent?> getCurrentWeather() =>
      caller.callServerEndpoint<_i24.WeatherCurrent?>(
        'weather',
        'getCurrentWeather',
        {},
      );

  /// Returns the cached 5-day forecast, oldest day first.
  ///
  /// Returns an empty list if no forecast data has been cached yet.
  _i2.Future<List<_i25.WeatherForecast>> getForecast() =>
      caller.callServerEndpoint<List<_i25.WeatherForecast>>(
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
         _i26.Protocol(),
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
    companion = EndpointCompanion(this);
    greeting = EndpointGreeting(this);
    layout = EndpointLayout(this);
    license = EndpointLicense(this);
    pack = EndpointPack(this);
    photo = EndpointPhoto(this);
    profile = EndpointProfile(this);
    displaySettings = EndpointDisplaySettings(this);
    settings = EndpointSettings(this);
    marketplace = EndpointMarketplace(this);
    theme = EndpointTheme(this);
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

  late final EndpointCompanion companion;

  late final EndpointGreeting greeting;

  late final EndpointLayout layout;

  late final EndpointLicense license;

  late final EndpointPack pack;

  late final EndpointPhoto photo;

  late final EndpointProfile profile;

  late final EndpointDisplaySettings displaySettings;

  late final EndpointSettings settings;

  late final EndpointMarketplace marketplace;

  late final EndpointTheme theme;

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
    'companion': companion,
    'greeting': greeting,
    'layout': layout,
    'license': license,
    'pack': pack,
    'photo': photo,
    'profile': profile,
    'displaySettings': displaySettings,
    'settings': settings,
    'marketplace': marketplace,
    'theme': theme,
    'weather': weather,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
