import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/data/device_auth_client.dart';

class _MockClient extends Mock implements Client {}

class _MockSessionManager extends Mock implements ClientAuthSessionManager {}

class _MockDeviceAuthClient extends Mock implements DeviceAuthClient {}

AuthSuccess _authSuccess(String token) => AuthSuccess(
      authStrategy: 'jwt',
      token: token,
      authUserId: UuidValue.fromString(
        '00000000-0000-0000-0000-000000000000',
      ),
      scopeNames: const {},
    );

void main() {
  late _MockClient client;
  late _MockSessionManager sessionManager;
  late _MockDeviceAuthClient deviceClient;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(_authSuccess('fallback'));
  });

  setUp(() {
    client = _MockClient();
    sessionManager = _MockSessionManager();
    deviceClient = _MockDeviceAuthClient();
    when(() => sessionManager.restore()).thenAnswer((_) async {});
    when(() => sessionManager.initialize(
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async => true);
  });

  AuthCubit build() => AuthCubit(
        client: client,
        sessionManager: sessionManager,
        deviceAuthClient: deviceClient,
      );

  group('startup session restore', () {
    test('validates the restored session against the server', () async {
      when(() => sessionManager.authInfo).thenReturn(_authSuccess('live'));
      when(() => sessionManager.isAuthenticated).thenReturn(true);

      final cubit = build();
      await pumpEventQueue();

      verify(() => sessionManager.initialize(timeout: any(named: 'timeout')))
          .called(1);
      expect(cubit.state, const AuthAuthenticated(accessToken: 'live'));
    });

    test('stays unauthenticated when the server rejects the stored session',
        () async {
      // initialize() signs the device out when the refresh token is dead, so
      // authInfo is null by the time it returns.
      when(() => sessionManager.initialize(
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => false);
      when(() => sessionManager.authInfo).thenReturn(null);
      when(() => sessionManager.isAuthenticated).thenReturn(false);

      final cubit = build();
      await pumpEventQueue();

      expect(cubit.state, isA<AuthUnauthenticated>());
    });

    test('keeps the stored session when the server is unreachable', () async {
      // Offline: validation throws, but the restored token is still the best
      // credential available — the display should not be bounced to login.
      when(() => sessionManager.initialize(
            timeout: any(named: 'timeout'),
          )).thenThrow(Exception('connection refused'));
      when(() => sessionManager.authInfo).thenReturn(_authSuccess('cached'));
      when(() => sessionManager.isAuthenticated).thenReturn(true);

      final cubit = build();
      await pumpEventQueue();

      expect(cubit.state, const AuthAuthenticated(accessToken: 'cached'));
    });
  });

  group('sessionExpired', () {
    test('clears stored credentials and returns to unauthenticated', () async {
      when(() => sessionManager.authInfo).thenReturn(_authSuccess('live'));
      when(() => sessionManager.isAuthenticated).thenReturn(true);
      when(() => sessionManager.signOutDevice()).thenAnswer((_) async => true);

      final cubit = build();
      await pumpEventQueue();
      expect(cubit.state, isA<AuthAuthenticated>());

      await cubit.sessionExpired();

      verify(() => sessionManager.signOutDevice()).called(1);
      expect(cubit.state, isA<AuthUnauthenticated>());
    });

    test('clears storage even when the sign-out call fails', () async {
      when(() => sessionManager.authInfo).thenReturn(_authSuccess('live'));
      when(() => sessionManager.isAuthenticated).thenReturn(true);
      when(() => sessionManager.signOutDevice())
          .thenThrow(Exception('server unreachable'));
      when(() => sessionManager.updateSignedInUser(null))
          .thenAnswer((_) async {});

      final cubit = build();
      await pumpEventQueue();

      await cubit.sessionExpired();

      verify(() => sessionManager.updateSignedInUser(null)).called(1);
      expect(cubit.state, isA<AuthUnauthenticated>());
    });
  });

  group('device flow', () {
    test('does not report success when the session cannot be persisted',
        () async {
      when(() => sessionManager.authInfo).thenReturn(null);
      when(() => sessionManager.isAuthenticated).thenReturn(false);
      when(() => sessionManager.updateSignedInUser(any()))
          .thenThrow(Exception('disk full'));
      when(() => deviceClient.poll('device-code-abc')).thenAnswer(
        (_) async => const DevicePollResponse(
          status: DevicePollStatus.authorized,
          authSuccessJson: {
            'authStrategy': 'jwt',
            'token': 'jwt-token-xyz',
            'authUserId': '00000000-0000-0000-0000-000000000000',
            'scopeNames': <String>[],
          },
        ),
      );

      final cubit = build();
      await pumpEventQueue();

      await cubit.pollDeviceFlow('device-code-abc');

      expect(cubit.state, isA<AuthError>());
    });
  });
}
