import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/providers/passkey.dart';
import 'package:test/test.dart';

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
      // The test Serverpod starts before this runs, so Serverpod.instance is
      // available. Initialize auth services so verifyCode can issue JWTs.
      AuthServices.set(
        tokenManagerBuilders: [JwtConfigFromPasswords()],
        identityProviderBuilders: [PasskeyIdpConfigFromPasswords()],
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
}
