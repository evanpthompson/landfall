import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/auth/data/device_auth_client.dart';

class _MockDeviceAuthClient extends Mock implements DeviceAuthClient {}

void main() {
  late _MockDeviceAuthClient deviceClient;

  setUp(() {
    deviceClient = _MockDeviceAuthClient();
  });

  group('startDeviceFlow', () {
    blocTest<AuthCubit, AuthState>(
      'emits AuthDevicePending with userCode and verificationUri',
      build: () => AuthCubit.withDeviceAuth(deviceAuthClient: deviceClient),
      setUp: () {
        when(() => deviceClient.startFlow()).thenAnswer(
          (_) async => const DeviceAuthStartResponse(
            userCode: 'AB12CD',
            deviceCode: 'device-code-abc',
            verificationUri: 'http://192.168.1.10:8080/device',
            expiresIn: 900,
            interval: 5,
          ),
        );
      },
      act: (c) => c.startDeviceFlow(),
      expect: () => [
        const AuthDevicePending(
          userCode: 'AB12CD',
          deviceCode: 'device-code-abc',
          verificationUri: 'http://192.168.1.10:8080/device',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError when startFlow throws',
      build: () => AuthCubit.withDeviceAuth(deviceAuthClient: deviceClient),
      setUp: () {
        when(() => deviceClient.startFlow())
            .thenThrow(Exception('network error'));
      },
      act: (c) => c.startDeviceFlow(),
      expect: () => [
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Could not start'),
        ),
      ],
    );
  });

  group('pollDeviceFlow', () {
    blocTest<AuthCubit, AuthState>(
      'stays in AuthDevicePending when status is authorization_pending',
      build: () => AuthCubit.withDeviceAuth(deviceAuthClient: deviceClient),
      seed: () => const AuthDevicePending(
        userCode: 'AB12CD',
        deviceCode: 'device-code-abc',
        verificationUri: 'http://x/device',
      ),
      setUp: () {
        when(() => deviceClient.poll('device-code-abc')).thenAnswer(
          (_) async => const DevicePollResponse(
            status: DevicePollStatus.authorizationPending,
          ),
        );
      },
      act: (c) => c.pollDeviceFlow('device-code-abc'),
      expect: () => [],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthAuthenticated when status is authorized',
      build: () => AuthCubit.withDeviceAuth(deviceAuthClient: deviceClient),
      seed: () => const AuthDevicePending(
        userCode: 'AB12CD',
        deviceCode: 'device-code-abc',
        verificationUri: 'http://x/device',
      ),
      setUp: () {
        when(() => deviceClient.poll('device-code-abc')).thenAnswer(
          (_) async => DevicePollResponse(
            status: DevicePollStatus.authorized,
            authSuccessJson: const {
              'authStrategy': 'otp',
              'token': 'jwt-token-xyz',
              'authUserId': '00000000-0000-0000-0000-000000000000',
              'scopeNames': ['user'],
            },
          ),
        );
      },
      act: (c) => c.pollDeviceFlow('device-code-abc'),
      expect: () => [
        const AuthAuthenticated(accessToken: 'jwt-token-xyz'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError when status is expired_token',
      build: () => AuthCubit.withDeviceAuth(deviceAuthClient: deviceClient),
      seed: () => const AuthDevicePending(
        userCode: 'AB12CD',
        deviceCode: 'device-code-abc',
        verificationUri: 'http://x/device',
      ),
      setUp: () {
        when(() => deviceClient.poll('device-code-abc')).thenAnswer(
          (_) async => const DevicePollResponse(
            status: DevicePollStatus.expiredToken,
          ),
        );
      },
      act: (c) => c.pollDeviceFlow('device-code-abc'),
      expect: () => [
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('expired'),
        ),
      ],
    );
  });
}

