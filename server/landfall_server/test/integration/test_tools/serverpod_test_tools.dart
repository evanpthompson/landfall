/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: no_leading_underscores_for_local_identifiers

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_test/serverpod_test.dart' as _i1;
import 'package:serverpod/serverpod.dart' as _i2;
import 'dart:async' as _i3;
import 'package:landfall_server/src/generated/cards/card_row.dart' as _i4;
import 'package:landfall_server/src/generated/cards/card_push_request.dart'
    as _i5;
import 'package:landfall_server/src/generated/agent/api_key_create_response.dart'
    as _i6;
import 'package:landfall_server/src/generated/agent/api_key.dart' as _i7;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i8;
import 'dart:typed_data' as _i9;
import 'package:landfall_server/src/generated/protocol.dart' as _i10;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i11;
import 'package:landfall_server/src/generated/greetings/greeting.dart' as _i12;
import 'package:landfall_server/src/generated/weather/weather_current.dart'
    as _i13;
import 'package:landfall_server/src/generated/weather/weather_forecast.dart'
    as _i14;
import 'package:landfall_server/src/generated/protocol.dart';
import 'package:landfall_server/src/generated/endpoints.dart';
export 'package:serverpod_test/serverpod_test_public_exports.dart';

/// Creates a new test group that takes a callback that can be used to write tests.
/// The callback has two parameters: `sessionBuilder` and `endpoints`.
/// `sessionBuilder` is used to build a `Session` object that represents the server state during an endpoint call and is used to set up scenarios.
/// `endpoints` contains all your Serverpod endpoints and lets you call them:
/// ```dart
/// withServerpod('Given Example endpoint', (sessionBuilder, endpoints) {
///   test('when calling `hello` then should return greeting', () async {
///     final greeting = await endpoints.example.hello(sessionBuilder, 'Michael');
///     expect(greeting, 'Hello Michael');
///   });
/// });
/// ```
///
/// **Configuration options**
///
/// [applyMigrations] Whether pending migrations should be applied when starting Serverpod. Defaults to `true`
///
/// [enableSessionLogging] Whether session logging should be enabled. Defaults to `false`
///
/// [rollbackDatabase] Options for when to rollback the database during the test lifecycle.
/// By default `withServerpod` does all database operations inside a transaction that is rolled back after each `test` case.
/// Just like the following enum describes, the behavior of the automatic rollbacks can be configured:
/// ```dart
/// /// Options for when to rollback the database during the test lifecycle.
/// enum RollbackDatabase {
///   /// After each test. This is the default.
///   afterEach,
///
///   /// After all tests.
///   afterAll,
///
///   /// Disable rolling back the database.
///   disabled,
/// }
/// ```
///
/// [runMode] The run mode that Serverpod should be running in. Defaults to `test`.
///
/// [serverpodLoggingMode] The logging mode used when creating Serverpod. Defaults to `ServerpodLoggingMode.normal`
///
/// [serverpodStartTimeout] The timeout to use when starting Serverpod, which connects to the database among other things. Defaults to `Duration(seconds: 30)`.
///
/// [testServerOutputMode] Options for controlling test server output during test execution. Defaults to `TestServerOutputMode.normal`.
/// ```dart
/// /// Options for controlling test server output during test execution.
/// enum TestServerOutputMode {
///   /// Default mode - only stderr is printed (stdout suppressed).
///   /// This hides normal startup/shutdown logs while preserving error messages.
///   normal,
///
///   /// All logging - both stdout and stderr are printed.
///   /// Useful for debugging when you need to see all server output.
///   verbose,
///
///   /// No logging - both stdout and stderr are suppressed.
///   /// Completely silent mode, useful when you don't want any server output.
///   silent,
/// }
/// ```
///
/// [configOverride] A function to override the server configuration. This function is called with
/// the default server configuration after it is loaded from the config/ directory
/// and before it is used to start the server. Use this to override particular
/// settings in the server configuration.
///
/// [testGroupTagsOverride] By default Serverpod test tools tags the `withServerpod` test group with `"integration"`.
/// This is to provide a simple way to only run unit or integration tests.
/// This property allows this tag to be overridden to something else. Defaults to `['integration']`.
///
/// [experimentalFeatures] Optionally specify experimental features. See [Serverpod] for more information.
@_i1.isTestGroup
void withServerpod(
  String testGroupName,
  _i1.TestClosure<TestEndpoints> testClosure, {
  bool? applyMigrations,
  _i2.ServerpodConfig Function(_i2.ServerpodConfig)? configOverride,
  bool? enableSessionLogging,
  _i2.ExperimentalFeatures? experimentalFeatures,
  _i1.RollbackDatabase? rollbackDatabase,
  String? runMode,
  _i2.RuntimeParametersListBuilder? runtimeParametersBuilder,
  _i2.ServerpodLoggingMode? serverpodLoggingMode,
  Duration? serverpodStartTimeout,
  List<String>? testGroupTagsOverride,
  _i1.TestServerOutputMode? testServerOutputMode,
}) {
  _i1.buildWithServerpod<_InternalTestEndpoints>(
    testGroupName,
    _i1.TestServerpod(
      testEndpoints: _InternalTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      runMode: runMode,
      applyMigrations: applyMigrations,
      isDatabaseEnabled: true,
      serverpodLoggingMode: serverpodLoggingMode,
      testServerOutputMode: testServerOutputMode,
      experimentalFeatures: experimentalFeatures,
      runtimeParametersBuilder: runtimeParametersBuilder,
    ),
    maybeRollbackDatabase: rollbackDatabase,
    maybeEnableSessionLogging: enableSessionLogging,
    maybeTestGroupTagsOverride: testGroupTagsOverride,
    maybeServerpodStartTimeout: serverpodStartTimeout,
    maybeTestServerOutputMode: testServerOutputMode,
  )(testClosure);
}

class TestEndpoints {
  late final _AgentEndpoint agent;

  late final _ApiKeyEndpoint apiKey;

  late final _JwtRefreshEndpoint jwtRefresh;

  late final _OtpEndpoint otp;

  late final _PasskeyIdpEndpoint passkeyIdp;

  late final _CardEndpoint card;

  late final _GreetingEndpoint greeting;

  late final _WeatherEndpoint weather;
}

class _InternalTestEndpoints extends TestEndpoints
    implements _i1.InternalTestEndpoints {
  @override
  void initialize(
    _i2.SerializationManager serializationManager,
    _i2.EndpointDispatch endpoints,
  ) {
    agent = _AgentEndpoint(
      endpoints,
      serializationManager,
    );
    apiKey = _ApiKeyEndpoint(
      endpoints,
      serializationManager,
    );
    jwtRefresh = _JwtRefreshEndpoint(
      endpoints,
      serializationManager,
    );
    otp = _OtpEndpoint(
      endpoints,
      serializationManager,
    );
    passkeyIdp = _PasskeyIdpEndpoint(
      endpoints,
      serializationManager,
    );
    card = _CardEndpoint(
      endpoints,
      serializationManager,
    );
    greeting = _GreetingEndpoint(
      endpoints,
      serializationManager,
    );
    weather = _WeatherEndpoint(
      endpoints,
      serializationManager,
    );
  }
}

class _AgentEndpoint {
  _AgentEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i4.CardRow>> listCards(
    _i1.TestSessionBuilder sessionBuilder,
    String apiKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'agent',
            method: 'listCards',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'agent',
          methodName: 'listCards',
          parameters: _i1.testObjectToJson({'apiKey': apiKey}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i4.CardRow>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i4.CardRow> pushCard(
    _i1.TestSessionBuilder sessionBuilder,
    String apiKey,
    _i5.CardPushRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'agent',
            method: 'pushCard',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'agent',
          methodName: 'pushCard',
          parameters: _i1.testObjectToJson({
            'apiKey': apiKey,
            'request': request,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i4.CardRow>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i4.CardRow> updateCard(
    _i1.TestSessionBuilder sessionBuilder,
    String apiKey,
    String externalId,
    _i5.CardPushRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'agent',
            method: 'updateCard',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'agent',
          methodName: 'updateCard',
          parameters: _i1.testObjectToJson({
            'apiKey': apiKey,
            'externalId': externalId,
            'request': request,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i4.CardRow>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<bool> dismissCard(
    _i1.TestSessionBuilder sessionBuilder,
    String apiKey,
    String externalId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'agent',
            method: 'dismissCard',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'agent',
          methodName: 'dismissCard',
          parameters: _i1.testObjectToJson({
            'apiKey': apiKey,
            'externalId': externalId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ApiKeyEndpoint {
  _ApiKeyEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i6.ApiKeyCreateResponse> generateKey(
    _i1.TestSessionBuilder sessionBuilder,
    String name,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'apiKey',
            method: 'generateKey',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'apiKey',
          methodName: 'generateKey',
          parameters: _i1.testObjectToJson({'name': name}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i6.ApiKeyCreateResponse>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i7.ApiKey>> listKeys(
    _i1.TestSessionBuilder sessionBuilder,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'apiKey',
            method: 'listKeys',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'apiKey',
          methodName: 'listKeys',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i7.ApiKey>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<bool> revokeKey(
    _i1.TestSessionBuilder sessionBuilder,
    int id,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'apiKey',
            method: 'revokeKey',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'apiKey',
          methodName: 'revokeKey',
          parameters: _i1.testObjectToJson({'id': id}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _JwtRefreshEndpoint {
  _JwtRefreshEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i8.AuthSuccess> refreshAccessToken(
    _i1.TestSessionBuilder sessionBuilder, {
    required String refreshToken,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'jwtRefresh',
            method: 'refreshAccessToken',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'jwtRefresh',
          methodName: 'refreshAccessToken',
          parameters: _i1.testObjectToJson({'refreshToken': refreshToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i8.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _OtpEndpoint {
  _OtpEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<void> sendCode(
    _i1.TestSessionBuilder sessionBuilder,
    String email,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'otp',
            method: 'sendCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'otp',
          methodName: 'sendCode',
          parameters: _i1.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i8.AuthSuccess> verifyCode(
    _i1.TestSessionBuilder sessionBuilder,
    String email,
    String code,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'otp',
            method: 'verifyCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'otp',
          methodName: 'verifyCode',
          parameters: _i1.testObjectToJson({
            'email': email,
            'code': code,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i8.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _PasskeyIdpEndpoint {
  _PasskeyIdpEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<({_i9.ByteData challenge, _i2.UuidValue id})> createChallenge(
    _i1.TestSessionBuilder sessionBuilder,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'passkeyIdp',
            method: 'createChallenge',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'passkeyIdp',
          methodName: 'createChallenge',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await _localCallContext.method
            .call(
              _localUniqueSession,
              _localCallContext.arguments,
            )
            .then(
              (record) => _i10.Protocol()
                  .deserialize<({_i9.ByteData challenge, _i2.UuidValue id})>(
                    record,
                  ),
            );
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> register(
    _i1.TestSessionBuilder sessionBuilder, {
    required _i11.PasskeyRegistrationRequest registrationRequest,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'passkeyIdp',
            method: 'register',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'passkeyIdp',
          methodName: 'register',
          parameters: _i1.testObjectToJson({
            'registrationRequest': registrationRequest,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i8.AuthSuccess> login(
    _i1.TestSessionBuilder sessionBuilder, {
    required _i11.PasskeyLoginRequest loginRequest,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'passkeyIdp',
            method: 'login',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'passkeyIdp',
          methodName: 'login',
          parameters: _i1.testObjectToJson({'loginRequest': loginRequest}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i8.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<bool> hasAccount(_i1.TestSessionBuilder sessionBuilder) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'passkeyIdp',
            method: 'hasAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'passkeyIdp',
          methodName: 'hasAccount',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _CardEndpoint {
  _CardEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i4.CardRow>> getCards(
    _i1.TestSessionBuilder sessionBuilder,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'card',
            method: 'getCards',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'card',
          methodName: 'getCards',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i4.CardRow>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i4.CardRow> pushCard(
    _i1.TestSessionBuilder sessionBuilder,
    _i5.CardPushRequest request,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'card',
            method: 'pushCard',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'card',
          methodName: 'pushCard',
          parameters: _i1.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i4.CardRow>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<bool> dismissCard(
    _i1.TestSessionBuilder sessionBuilder,
    String externalId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'card',
            method: 'dismissCard',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'card',
          methodName: 'dismissCard',
          parameters: _i1.testObjectToJson({'externalId': externalId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _GreetingEndpoint {
  _GreetingEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i12.Greeting> hello(
    _i1.TestSessionBuilder sessionBuilder,
    String name,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'greeting',
            method: 'hello',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'greeting',
          methodName: 'hello',
          parameters: _i1.testObjectToJson({'name': name}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i12.Greeting>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _WeatherEndpoint {
  _WeatherEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i13.WeatherCurrent?> getCurrentWeather(
    _i1.TestSessionBuilder sessionBuilder,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'weather',
            method: 'getCurrentWeather',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'weather',
          methodName: 'getCurrentWeather',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i13.WeatherCurrent?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i14.WeatherForecast>> getForecast(
    _i1.TestSessionBuilder sessionBuilder,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'weather',
            method: 'getForecast',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'weather',
          methodName: 'getForecast',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i14.WeatherForecast>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}
