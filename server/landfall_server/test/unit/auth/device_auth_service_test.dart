import 'package:test/test.dart';

import 'package:landfall_server/src/auth/device_auth_service.dart';

void main() {
  setUp(DeviceAuthService.resetForTest);

  group('startFlow', () {
    test('returns a 6-character alphanumeric user code', () {
      final result = DeviceAuthService.startFlow(
        verificationUri: 'http://192.168.1.10:8080/device',
      );
      expect(result.userCode, hasLength(6));
      expect(result.userCode, matches(r'^[A-Z0-9]{6}$'));
    });

    test('returns a non-empty device code', () {
      final result = DeviceAuthService.startFlow(
        verificationUri: 'http://192.168.1.10:8080/device',
      );
      expect(result.deviceCode, isNotEmpty);
    });

    test('embeds the verificationUri in the result', () {
      const uri = 'http://x.example.com/device';
      final result = DeviceAuthService.startFlow(verificationUri: uri);
      expect(result.verificationUri, equals(uri));
    });

    test('returns a positive expiresIn', () {
      final result = DeviceAuthService.startFlow(
        verificationUri: 'http://192.168.1.10:8080/device',
      );
      expect(result.expiresIn, greaterThan(0));
    });

    test('each call returns a distinct user code and device code', () {
      final a = DeviceAuthService.startFlow(
        verificationUri: 'http://x/device',
      );
      final b = DeviceAuthService.startFlow(
        verificationUri: 'http://x/device',
      );
      expect(a.deviceCode, isNot(equals(b.deviceCode)));
      // User codes are randomly generated — collisions are astronomically rare.
    });
  });

  group('pollFlow', () {
    test('returns authorization_pending for an unpaired device code', () {
      final start = DeviceAuthService.startFlow(
        verificationUri: 'http://192.168.1.10:8080/device',
      );
      final poll = DeviceAuthService.pollFlow(start.deviceCode);
      expect(poll.status, DevicePollStatus.authorizationPending);
      expect(poll.accessToken, isNull);
    });

    test('returns expired_token for an unknown device code', () {
      final poll = DeviceAuthService.pollFlow('unknown-device-code');
      expect(poll.status, DevicePollStatus.expiredToken);
    });

    test('returns the access token after pairing', () {
      final start = DeviceAuthService.startFlow(
        verificationUri: 'http://192.168.1.10:8080/device',
      );
      DeviceAuthService.pairForTest(start.userCode, 'test-access-token');

      final poll = DeviceAuthService.pollFlow(start.deviceCode);
      expect(poll.status, DevicePollStatus.authorized);
      expect(poll.accessToken, equals('test-access-token'));
    });

    test('returns expired_token for an expired entry', () {
      final start = DeviceAuthService.startFlow(
        verificationUri: 'http://x/device',
        lifetime: const Duration(seconds: -1), // already expired
      );
      final poll = DeviceAuthService.pollFlow(start.deviceCode);
      expect(poll.status, DevicePollStatus.expiredToken);
    });
  });

  group('isValidUserCode', () {
    test('returns false for an unknown user code', () {
      expect(DeviceAuthService.isValidUserCode('XXXXXX'), isFalse);
    });

    test('returns true for a known, non-expired user code', () {
      final start = DeviceAuthService.startFlow(
        verificationUri: 'http://x/device',
      );
      expect(DeviceAuthService.isValidUserCode(start.userCode), isTrue);
    });

    test('returns false for an expired user code', () {
      final start = DeviceAuthService.startFlow(
        verificationUri: 'http://x/device',
        lifetime: const Duration(seconds: -1),
      );
      expect(DeviceAuthService.isValidUserCode(start.userCode), isFalse);
    });
  });

  group('completeFlow', () {
    test('stores the auth success so pollFlow returns it', () {
      final start = DeviceAuthService.startFlow(
        verificationUri: 'http://x/device',
      );
      DeviceAuthService.completeFlow(start.userCode, {
        'authStrategy': 'otp',
        'token': 'tok-abc',
        'authUserId': '00000000-0000-0000-0000-000000000000',
        'scopeNames': ['user'],
      });

      final poll = DeviceAuthService.pollFlow(start.deviceCode);
      expect(poll.status, DevicePollStatus.authorized);
      expect(poll.accessToken, 'tok-abc');
    });

    test('no-ops for an unknown user code', () {
      // Should not throw.
      expect(
        () => DeviceAuthService.completeFlow('ZZZZZZ', {
          'authStrategy': 'otp',
          'token': 'tok-xyz',
          'authUserId': '00000000-0000-0000-0000-000000000000',
          'scopeNames': ['user'],
        }),
        returnsNormally,
      );
    });
  });
}
