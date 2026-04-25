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
import '../photo/photo_endpoint.dart' as _i10;
import '../settings/settings_endpoint.dart' as _i11;
import '../weather/weather_endpoint.dart' as _i12;
import 'package:landfall_server/src/generated/cards/card_push_request.dart'
    as _i13;
import 'package:landfall_server/src/generated/protocol.dart' as _i14;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i15;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i16;
import 'package:landfall_server/src/generated/future_calls.dart' as _i17;
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
      'photo': _i10.PhotoEndpoint()
        ..initialize(
          server,
          'photo',
          null,
        ),
      'settings': _i11.SettingsEndpoint()
        ..initialize(
          server,
          'settings',
          null,
        ),
      'weather': _i12.WeatherEndpoint()
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
              type: _i1.getType<_i13.CardPushRequest>(),
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
              type: _i1.getType<_i13.CardPushRequest>(),
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
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['apiKey'] as _i3.ApiKeyEndpoint).generateKey(
                    session,
                    params['name'],
                  ),
        ),
        'listKeys': _i1.MethodConnector(
          name: 'listKeys',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['apiKey'] as _i3.ApiKeyEndpoint).listKeys(session),
        ),
        'revokeKey': _i1.MethodConnector(
          name: 'revokeKey',
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
              ) async => (endpoints['apiKey'] as _i3.ApiKeyEndpoint).revokeKey(
                session,
                params['id'],
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
                  .then((record) => _i14.Protocol().mapRecordToJson(record)),
        ),
        'register': _i1.MethodConnector(
          name: 'register',
          params: {
            'registrationRequest': _i1.ParameterDescription(
              name: 'registrationRequest',
              type: _i1.getType<_i15.PasskeyRegistrationRequest>(),
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
              type: _i1.getType<_i15.PasskeyLoginRequest>(),
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
        'pushCard': _i1.MethodConnector(
          name: 'pushCard',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i13.CardPushRequest>(),
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
                  (endpoints['photo'] as _i10.PhotoEndpoint).getPhotos(session),
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
              ) async => (endpoints['settings'] as _i11.SettingsEndpoint)
                  .getLinkedCredentials(session),
        ),
        'getMyAuthUserId': _i1.MethodConnector(
          name: 'getMyAuthUserId',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i11.SettingsEndpoint)
                  .getMyAuthUserId(session),
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
              ) async => (endpoints['weather'] as _i12.WeatherEndpoint)
                  .getCurrentWeather(session),
        ),
        'getForecast': _i1.MethodConnector(
          name: 'getForecast',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['weather'] as _i12.WeatherEndpoint)
                  .getForecast(session),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i15.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i16.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _i1.FutureCallDispatch? get futureCalls {
    return _i17.FutureCalls();
  }
}
