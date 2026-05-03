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
import 'package:serverpod/serverpod.dart' as _i1;
import '../agent/agent_endpoint.dart' as _i2;
import '../agent/api_key_endpoint.dart' as _i3;
import '../auth/jwt_refresh_endpoint.dart' as _i4;
import '../auth/otp_endpoint.dart' as _i5;
import '../auth/passkey_idp_endpoint.dart' as _i6;
import '../calendar/calendar_endpoint.dart' as _i7;
import '../cards/card_endpoint.dart' as _i8;
import '../greetings/greeting_endpoint.dart' as _i9;
import '../layout/layout_endpoint.dart' as _i10;
import '../license/license_endpoint.dart' as _i11;
import '../license/pack_endpoint.dart' as _i12;
import '../photo/photo_endpoint.dart' as _i13;
import '../profile/profile_endpoint.dart' as _i14;
import '../settings/settings_endpoint.dart' as _i15;
import '../theme/marketplace_endpoint.dart' as _i16;
import '../theme/theme_endpoint.dart' as _i17;
import '../weather/weather_endpoint.dart' as _i18;
import 'package:landfall_server/src/generated/cards/card_push_request.dart'
    as _i19;
import 'package:landfall_server/src/generated/protocol.dart' as _i20;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i21;
import 'package:landfall_server/src/generated/layout/layout_config.dart'
    as _i22;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i23;
import 'package:landfall_server/src/generated/future_calls.dart' as _i24;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'agent': _i2.AgentEndpoint()
        ..initialize(
          server,
          'agent',
          null,
        ),
      'apiKey': _i3.ApiKeyEndpoint()
        ..initialize(
          server,
          'apiKey',
          null,
        ),
      'jwtRefresh': _i4.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'otp': _i5.OtpEndpoint()
        ..initialize(
          server,
          'otp',
          null,
        ),
      'passkeyIdp': _i6.PasskeyIdpEndpoint()
        ..initialize(
          server,
          'passkeyIdp',
          null,
        ),
      'calendar': _i7.CalendarEndpoint()
        ..initialize(
          server,
          'calendar',
          null,
        ),
      'card': _i8.CardEndpoint()
        ..initialize(
          server,
          'card',
          null,
        ),
      'greeting': _i9.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
      'layout': _i10.LayoutEndpoint()
        ..initialize(
          server,
          'layout',
          null,
        ),
      'license': _i11.LicenseEndpoint()
        ..initialize(
          server,
          'license',
          null,
        ),
      'pack': _i12.PackEndpoint()
        ..initialize(
          server,
          'pack',
          null,
        ),
      'photo': _i13.PhotoEndpoint()
        ..initialize(
          server,
          'photo',
          null,
        ),
      'profile': _i14.ProfileEndpoint()
        ..initialize(
          server,
          'profile',
          null,
        ),
      'settings': _i15.SettingsEndpoint()
        ..initialize(
          server,
          'settings',
          null,
        ),
      'marketplace': _i16.MarketplaceEndpoint()
        ..initialize(
          server,
          'marketplace',
          null,
        ),
      'theme': _i17.ThemeEndpoint()
        ..initialize(
          server,
          'theme',
          null,
        ),
      'weather': _i18.WeatherEndpoint()
        ..initialize(
          server,
          'weather',
          null,
        ),
    };
    connectors['agent'] = _i1.EndpointConnector(
      name: 'agent',
      endpoint: endpoints['agent']!,
      methodConnectors: {
        'listCards': _i1.MethodConnector(
          name: 'listCards',
          params: {
            'apiKey': _i1.ParameterDescription(
              name: 'apiKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _i2.AgentEndpoint).listCards(
                session,
                params['apiKey'],
              ),
        ),
        'pushCard': _i1.MethodConnector(
          name: 'pushCard',
          params: {
            'apiKey': _i1.ParameterDescription(
              name: 'apiKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i19.CardPushRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _i2.AgentEndpoint).pushCard(
                session,
                params['apiKey'],
                params['request'],
              ),
        ),
        'updateCard': _i1.MethodConnector(
          name: 'updateCard',
          params: {
            'apiKey': _i1.ParameterDescription(
              name: 'apiKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'externalId': _i1.ParameterDescription(
              name: 'externalId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i19.CardPushRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _i2.AgentEndpoint).updateCard(
                session,
                params['apiKey'],
                params['externalId'],
                params['request'],
              ),
        ),
        'pushTicker': _i1.MethodConnector(
          name: 'pushTicker',
          params: {
            'apiKey': _i1.ParameterDescription(
              name: 'apiKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'source': _i1.ParameterDescription(
              name: 'source',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'expiresAt': _i1.ParameterDescription(
              name: 'expiresAt',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _i2.AgentEndpoint).pushTicker(
                session,
                params['apiKey'],
                params['source'],
                params['message'],
                expiresAt: params['expiresAt'],
              ),
        ),
        'dismissCard': _i1.MethodConnector(
          name: 'dismissCard',
          params: {
            'apiKey': _i1.ParameterDescription(
              name: 'apiKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'externalId': _i1.ParameterDescription(
              name: 'externalId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _i2.AgentEndpoint).dismissCard(
                session,
                params['apiKey'],
                params['externalId'],
              ),
        ),
      },
    );
    connectors['apiKey'] = _i1.EndpointConnector(
      name: 'apiKey',
      endpoint: endpoints['apiKey']!,
      methodConnectors: {
        'generateKey': _i1.MethodConnector(
          name: 'generateKey',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'setupToken': _i1.ParameterDescription(
              name: 'setupToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['apiKey'] as _i3.ApiKeyEndpoint).generateKey(
                    session,
                    params['name'],
                    params['setupToken'],
                  ),
        ),
        'listKeys': _i1.MethodConnector(
          name: 'listKeys',
          params: {
            'setupToken': _i1.ParameterDescription(
              name: 'setupToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['apiKey'] as _i3.ApiKeyEndpoint).listKeys(
                session,
                params['setupToken'],
              ),
        ),
        'revokeKey': _i1.MethodConnector(
          name: 'revokeKey',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setupToken': _i1.ParameterDescription(
              name: 'setupToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['apiKey'] as _i3.ApiKeyEndpoint).revokeKey(
                session,
                params['id'],
                params['setupToken'],
              ),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i4.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['otp'] = _i1.EndpointConnector(
      name: 'otp',
      endpoint: endpoints['otp']!,
      methodConnectors: {
        'sendCode': _i1.MethodConnector(
          name: 'sendCode',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['otp'] as _i5.OtpEndpoint).sendCode(
                session,
                params['email'],
              ),
        ),
        'verifyCode': _i1.MethodConnector(
          name: 'verifyCode',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'code': _i1.ParameterDescription(
              name: 'code',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['otp'] as _i5.OtpEndpoint).verifyCode(
                session,
                params['email'],
                params['code'],
              ),
        ),
      },
    );
    connectors['passkeyIdp'] = _i1.EndpointConnector(
      name: 'passkeyIdp',
      endpoint: endpoints['passkeyIdp']!,
      methodConnectors: {
        'createChallenge': _i1.MethodConnector(
          name: 'createChallenge',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['passkeyIdp'] as _i6.PasskeyIdpEndpoint)
                  .createChallenge(session)
                  .then((record) => _i20.Protocol().mapRecordToJson(record)),
        ),
        'register': _i1.MethodConnector(
          name: 'register',
          params: {
            'registrationRequest': _i1.ParameterDescription(
              name: 'registrationRequest',
              type: _i1.getType<_i21.PasskeyRegistrationRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['passkeyIdp'] as _i6.PasskeyIdpEndpoint).register(
                    session,
                    registrationRequest: params['registrationRequest'],
                  ),
        ),
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'loginRequest': _i1.ParameterDescription(
              name: 'loginRequest',
              type: _i1.getType<_i21.PasskeyLoginRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['passkeyIdp'] as _i6.PasskeyIdpEndpoint).login(
                    session,
                    loginRequest: params['loginRequest'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['passkeyIdp'] as _i6.PasskeyIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['calendar'] = _i1.EndpointConnector(
      name: 'calendar',
      endpoint: endpoints['calendar']!,
      methodConnectors: {
        'getUpcomingEvents': _i1.MethodConnector(
          name: 'getUpcomingEvents',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['calendar'] as _i7.CalendarEndpoint)
                  .getUpcomingEvents(session),
        ),
      },
    );
    connectors['card'] = _i1.EndpointConnector(
      name: 'card',
      endpoint: endpoints['card']!,
      methodConnectors: {
        'getCards': _i1.MethodConnector(
          name: 'getCards',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['card'] as _i8.CardEndpoint).getCards(session),
        ),
        'getTickerMessages': _i1.MethodConnector(
          name: 'getTickerMessages',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['card'] as _i8.CardEndpoint)
                  .getTickerMessages(session),
        ),
        'pushCard': _i1.MethodConnector(
          name: 'pushCard',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i19.CardPushRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['card'] as _i8.CardEndpoint).pushCard(
                session,
                params['request'],
              ),
        ),
        'dismissCard': _i1.MethodConnector(
          name: 'dismissCard',
          params: {
            'externalId': _i1.ParameterDescription(
              name: 'externalId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['card'] as _i8.CardEndpoint).dismissCard(
                session,
                params['externalId'],
              ),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i9.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    connectors['layout'] = _i1.EndpointConnector(
      name: 'layout',
      endpoint: endpoints['layout']!,
      methodConnectors: {
        'getLayouts': _i1.MethodConnector(
          name: 'getLayouts',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['layout'] as _i10.LayoutEndpoint)
                  .getLayouts(session),
        ),
        'saveLayout': _i1.MethodConnector(
          name: 'saveLayout',
          params: {
            'layout': _i1.ParameterDescription(
              name: 'layout',
              type: _i1.getType<_i22.LayoutConfig>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['layout'] as _i10.LayoutEndpoint).saveLayout(
                    session,
                    params['layout'],
                  ),
        ),
        'setActiveLayout': _i1.MethodConnector(
          name: 'setActiveLayout',
          params: {
            'layoutId': _i1.ParameterDescription(
              name: 'layoutId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['layout'] as _i10.LayoutEndpoint).setActiveLayout(
                    session,
                    params['layoutId'],
                  ),
        ),
        'deleteLayout': _i1.MethodConnector(
          name: 'deleteLayout',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['layout'] as _i10.LayoutEndpoint).deleteLayout(
                    session,
                    params['id'],
                  ),
        ),
      },
    );
    connectors['license'] = _i1.EndpointConnector(
      name: 'license',
      endpoint: endpoints['license']!,
      methodConnectors: {
        'getLicenseStatus': _i1.MethodConnector(
          name: 'getLicenseStatus',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['license'] as _i11.LicenseEndpoint)
                  .getLicenseStatus(session),
        ),
        'activateLicense': _i1.MethodConnector(
          name: 'activateLicense',
          params: {
            'key': _i1.ParameterDescription(
              name: 'key',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['license'] as _i11.LicenseEndpoint)
                  .activateLicense(
                    session,
                    params['key'],
                  ),
        ),
      },
    );
    connectors['pack'] = _i1.EndpointConnector(
      name: 'pack',
      endpoint: endpoints['pack']!,
      methodConnectors: {
        'listPacks': _i1.MethodConnector(
          name: 'listPacks',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['pack'] as _i12.PackEndpoint).listPacks(session),
        ),
        'getOwnedPacks': _i1.MethodConnector(
          name: 'getOwnedPacks',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['pack'] as _i12.PackEndpoint).getOwnedPacks(
                session,
              ),
        ),
      },
    );
    connectors['photo'] = _i1.EndpointConnector(
      name: 'photo',
      endpoint: endpoints['photo']!,
      methodConnectors: {
        'getPhotos': _i1.MethodConnector(
          name: 'getPhotos',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['photo'] as _i13.PhotoEndpoint).getPhotos(session),
        ),
      },
    );
    connectors['profile'] = _i1.EndpointConnector(
      name: 'profile',
      endpoint: endpoints['profile']!,
      methodConnectors: {
        'listProfiles': _i1.MethodConnector(
          name: 'listProfiles',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['profile'] as _i14.ProfileEndpoint)
                  .listProfiles(session),
        ),
        'createProfile': _i1.MethodConnector(
          name: 'createProfile',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'cardsJson': _i1.ParameterDescription(
              name: 'cardsJson',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i14.ProfileEndpoint).createProfile(
                    session,
                    params['name'],
                    cardsJson: params['cardsJson'],
                  ),
        ),
        'updateProfile': _i1.MethodConnector(
          name: 'updateProfile',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'themeId': _i1.ParameterDescription(
              name: 'themeId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'cardFilterJson': _i1.ParameterDescription(
              name: 'cardFilterJson',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'scheduleJson': _i1.ParameterDescription(
              name: 'scheduleJson',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'sortOrder': _i1.ParameterDescription(
              name: 'sortOrder',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'cardsJson': _i1.ParameterDescription(
              name: 'cardsJson',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i14.ProfileEndpoint).updateProfile(
                    session,
                    params['id'],
                    name: params['name'],
                    themeId: params['themeId'],
                    cardFilterJson: params['cardFilterJson'],
                    scheduleJson: params['scheduleJson'],
                    sortOrder: params['sortOrder'],
                    cardsJson: params['cardsJson'],
                  ),
        ),
        'deleteProfile': _i1.MethodConnector(
          name: 'deleteProfile',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i14.ProfileEndpoint).deleteProfile(
                    session,
                    params['id'],
                  ),
        ),
        'activateProfile': _i1.MethodConnector(
          name: 'activateProfile',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['profile'] as _i14.ProfileEndpoint)
                  .activateProfile(
                    session,
                    params['id'],
                  ),
        ),
        'duplicateProfile': _i1.MethodConnector(
          name: 'duplicateProfile',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'newName': _i1.ParameterDescription(
              name: 'newName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['profile'] as _i14.ProfileEndpoint)
                  .duplicateProfile(
                    session,
                    params['id'],
                    params['newName'],
                  ),
        ),
      },
    );
    connectors['settings'] = _i1.EndpointConnector(
      name: 'settings',
      endpoint: endpoints['settings']!,
      methodConnectors: {
        'getLinkedCredentials': _i1.MethodConnector(
          name: 'getLinkedCredentials',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i15.SettingsEndpoint)
                  .getLinkedCredentials(session),
        ),
        'getMyAuthUserId': _i1.MethodConnector(
          name: 'getMyAuthUserId',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i15.SettingsEndpoint)
                  .getMyAuthUserId(session),
        ),
      },
    );
    connectors['marketplace'] = _i1.EndpointConnector(
      name: 'marketplace',
      endpoint: endpoints['marketplace']!,
      methodConnectors: {
        'listMarketplaceThemes': _i1.MethodConnector(
          name: 'listMarketplaceThemes',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['marketplace'] as _i16.MarketplaceEndpoint)
                  .listMarketplaceThemes(session),
        ),
        'getMarketplaceTheme': _i1.MethodConnector(
          name: 'getMarketplaceTheme',
          params: {
            'themeId': _i1.ParameterDescription(
              name: 'themeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['marketplace'] as _i16.MarketplaceEndpoint)
                  .getMarketplaceTheme(
                    session,
                    params['themeId'],
                  ),
        ),
        'getOwnedThemes': _i1.MethodConnector(
          name: 'getOwnedThemes',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['marketplace'] as _i16.MarketplaceEndpoint)
                  .getOwnedThemes(session),
        ),
      },
    );
    connectors['theme'] = _i1.EndpointConnector(
      name: 'theme',
      endpoint: endpoints['theme']!,
      methodConnectors: {
        'listThemes': _i1.MethodConnector(
          name: 'listThemes',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['theme'] as _i17.ThemeEndpoint).listThemes(
                session,
              ),
        ),
        'uploadTheme': _i1.MethodConnector(
          name: 'uploadTheme',
          params: {
            'yaml': _i1.ParameterDescription(
              name: 'yaml',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['theme'] as _i17.ThemeEndpoint).uploadTheme(
                session,
                params['yaml'],
              ),
        ),
        'importTheme': _i1.MethodConnector(
          name: 'importTheme',
          params: {
            'url': _i1.ParameterDescription(
              name: 'url',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['theme'] as _i17.ThemeEndpoint).importTheme(
                session,
                params['url'],
              ),
        ),
        'deleteTheme': _i1.MethodConnector(
          name: 'deleteTheme',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['theme'] as _i17.ThemeEndpoint).deleteTheme(
                session,
                params['id'],
              ),
        ),
        'previewTheme': _i1.MethodConnector(
          name: 'previewTheme',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['theme'] as _i17.ThemeEndpoint).previewTheme(
                    session,
                    params['id'],
                  ),
        ),
        'applyTheme': _i1.MethodConnector(
          name: 'applyTheme',
          params: {
            'themeId': _i1.ParameterDescription(
              name: 'themeId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'profileId': _i1.ParameterDescription(
              name: 'profileId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['theme'] as _i17.ThemeEndpoint).applyTheme(
                session,
                params['themeId'],
                profileId: params['profileId'],
              ),
        ),
      },
    );
    connectors['weather'] = _i1.EndpointConnector(
      name: 'weather',
      endpoint: endpoints['weather']!,
      methodConnectors: {
        'getCurrentWeather': _i1.MethodConnector(
          name: 'getCurrentWeather',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['weather'] as _i18.WeatherEndpoint)
                  .getCurrentWeather(session),
        ),
        'getForecast': _i1.MethodConnector(
          name: 'getForecast',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['weather'] as _i18.WeatherEndpoint)
                  .getForecast(session),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i21.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i23.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _i1.FutureCallDispatch? get futureCalls {
    return _i24.FutureCalls();
  }
}
