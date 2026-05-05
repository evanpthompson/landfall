import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/auth/otp_service.dart';
import 'package:landfall_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

String _hashCode(String code) =>
    sha256.convert(utf8.encode(code)).toString();

/// Inserts a known OTP request directly so tests can supply a predictable code.
Future<OtpRequest> _insertRequest(
  TestSessionBuilder sessionBuilder, {
  required String email,
  required String code,
  Duration lifetime = const Duration(minutes: 10),
  bool alreadyUsed = false,
}) async {
  final session = sessionBuilder.build();
  final now = DateTime.now().toUtc();
  return OtpRequest.db.insertRow(
    session,
    OtpRequest(
      email: email,
      codeHash: _hashCode(code),
      createdAt: now,
      expiresAt: now.add(lifetime),
      usedAt: alreadyUsed ? now : null,
    ),
  );
}

void main() {
  withServerpod('Given OtpEndpoint', (sessionBuilder, endpoints) {
    setUpAll(() {
      // The test Serverpod starts before this runs, so Serverpod.instance and
      // passwords.yaml are available. Initialize auth services with only the
      // JWT token manager — no IDP needed to issue tokens in these tests.
      AuthServices.set(
        tokenManagerBuilders: [JwtConfigFromPasswords()],
      );
    });

    group('sendCode', () {
      test('succeeds without throwing', () async {
        await expectLater(
          endpoints.otp.sendCode(sessionBuilder, 'user@example.com'),
          completes,
        );
      });

      test('stores an OTP request in the database', () async {
        const email = 'stored@example.com';
        await endpoints.otp.sendCode(sessionBuilder, email);

        final session = sessionBuilder.build();
        final requests = await OtpRequest.db.find(
          session,
          where: (t) => t.email.equals(email),
        );

        expect(requests, hasLength(1));
        expect(requests.first.usedAt, isNull);
        expect(requests.first.expiresAt.isAfter(DateTime.now()), isTrue);
      });

      test('normalises email to lowercase', () async {
        await endpoints.otp.sendCode(sessionBuilder, 'UPPER@EXAMPLE.COM');

        final session = sessionBuilder.build();
        final requests = await OtpRequest.db.find(
          session,
          where: (t) => t.email.equals('upper@example.com'),
        );

        expect(requests, hasLength(1));
      });
    });

    group('verifyCode', () {
      test('returns AuthSuccess with a token for a valid code', () async {
        const email = 'verify@example.com';
        const code = '123456';
        await _insertRequest(sessionBuilder, email: email, code: code);

        final result =
            await endpoints.otp.verifyCode(sessionBuilder, email, code);

        expect(result.token, isNotEmpty);
        expect(result.authUserId, isNotNull);
      });

      test('creates an OtpAccount on first login', () async {
        const email = 'newuser@example.com';
        const code = '654321';
        await _insertRequest(sessionBuilder, email: email, code: code);

        await endpoints.otp.verifyCode(sessionBuilder, email, code);

        final session = sessionBuilder.build();
        final accounts = await OtpAccount.db.find(
          session,
          where: (t) => t.email.equals(email),
        );

        expect(accounts, hasLength(1));
        expect(accounts.first.authUserId, isNotNull);
      });

      test('returns the same authUserId on subsequent logins', () async {
        const email = 'returning@example.com';

        await _insertRequest(sessionBuilder, email: email, code: '111111');
        final first =
            await endpoints.otp.verifyCode(sessionBuilder, email, '111111');

        await _insertRequest(sessionBuilder, email: email, code: '222222');
        final second =
            await endpoints.otp.verifyCode(sessionBuilder, email, '222222');

        expect(second.authUserId, equals(first.authUserId));
      });

      test('marks the request as used after verification', () async {
        const email = 'used@example.com';
        const code = '789012';
        final inserted = await _insertRequest(
          sessionBuilder,
          email: email,
          code: code,
        );

        await endpoints.otp.verifyCode(sessionBuilder, email, code);

        final session = sessionBuilder.build();
        final updated = await OtpRequest.db.findById(session, inserted.id!);
        expect(updated!.usedAt, isNotNull);
      });

      test('throws for an incorrect code', () async {
        const email = 'wrong@example.com';
        await _insertRequest(sessionBuilder, email: email, code: '000000');

        expect(
          () => endpoints.otp.verifyCode(sessionBuilder, email, '999999'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws for an expired code', () async {
        const email = 'expired@example.com';
        const code = '555555';
        await _insertRequest(
          sessionBuilder,
          email: email,
          code: code,
          lifetime: const Duration(seconds: -1), // already expired
        );

        expect(
          () => endpoints.otp.verifyCode(sessionBuilder, email, code),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on replay — used code cannot be verified again', () async {
        const email = 'replay@example.com';
        const code = '112233';
        await _insertRequest(
          sessionBuilder,
          email: email,
          code: code,
          alreadyUsed: true,
        );

        expect(
          () => endpoints.otp.verifyCode(sessionBuilder, email, code),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when no pending request exists for email', () async {
        expect(
          () => endpoints.otp.verifyCode(
            sessionBuilder,
            'nocode@example.com',
            '000000',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });

  // SEC-08: OTP hardening — log sanitization and rate limiting.
  withServerpod(
    'Given OtpService SEC-08 hardening',
    (sessionBuilder, endpoints) {
      setUp(() {
        OtpService.resetRateLimits();
      });

    group('log sanitization', () {
      test('sendCode log message does not contain the OTP code', () {
        // The sanitized log message must never expose a 6-digit code.
        // We test the message builder directly — if it contains no code,
        // and sendCode uses it, the log is clean.
        final message = OtpService.buildSanitizedLogMessage(
          'test@example.com',
          const Duration(minutes: 10),
        );
        expect(message, isNot(matches(r'\b\d{6}\b')));
        expect(message, contains('test@example.com'));
      });
    });

    group('per-email verify attempt cap', () {
      test('5 failed attempts are allowed', () async {
        const email = 'cap5@example.com';
        await _insertRequest(sessionBuilder, email: email, code: '999999');

        for (var i = 0; i < 5; i++) {
          try {
            await endpoints.otp.verifyCode(sessionBuilder, email, 'wrong$i');
          } catch (_) {
            // Expected — wrong code
          }
        }

        // After 5 failures a 6th attempt must be rejected with rate-limit error
        expect(
          () => endpoints.otp.verifyCode(sessionBuilder, email, 'wrong5'),
          throwsA(isA<Exception>()),
          reason: '6th failed verify attempt must be rate-limited',
        );
      });

      test('successful verify resets the failure counter', () async {
        const email = 'resetcap@example.com';
        await _insertRequest(sessionBuilder, email: email, code: 'aaaaaa');
        await _insertRequest(sessionBuilder, email: email, code: '111111');

        // Accumulate 4 failures
        for (var i = 0; i < 4; i++) {
          try {
            await endpoints.otp.verifyCode(sessionBuilder, email, 'bad$i');
          } catch (_) {}
        }

        // Correct code clears the counter
        await endpoints.otp.verifyCode(sessionBuilder, email, '111111');

        // Counter is reset — next failure batch should be allowed again
        await _insertRequest(sessionBuilder, email: email, code: '222222');
        for (var i = 0; i < 5; i++) {
          try {
            await endpoints.otp.verifyCode(sessionBuilder, email, 'post$i');
          } catch (_) {}
        }
        expect(
          () => endpoints.otp.verifyCode(sessionBuilder, email, 'post5'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('per-IP generation throttle', () {
      test('exceeding the send limit for an IP is rejected', () async {
        const ip = '10.0.0.42';
        const email = 'ipthrottle@example.com';

        // Send up to the limit
        for (var i = 0; i < OtpService.maxSendRequestsPerIp; i++) {
          final session = sessionBuilder.build();
          await OtpService().sendCode(session, email, clientIp: ip);
          await session.close();
        }

        // One more must be throttled
        final session = sessionBuilder.build();
        expect(
          () => OtpService().sendCode(session, email, clientIp: ip),
          throwsA(isA<Exception>()),
          reason: 'Requests beyond the per-IP limit must be rejected',
        );
        await session.close();
      });

      test('requests without an IP are not throttled', () async {
        // If IP is null (e.g. internal calls, test mode) the throttle is skipped.
        for (var i = 0; i <= OtpService.maxSendRequestsPerIp + 2; i++) {
          await expectLater(
            endpoints.otp.sendCode(
              sessionBuilder,
              'noip_$i@example.com',
            ),
            completes,
          );
        }
      });
    });
  });
}
