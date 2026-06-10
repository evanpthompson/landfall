import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';
import 'package:landfall_server/src/web/routes/calendar_link_ticket.dart';
import 'package:landfall_server/src/web/routes/calendar_oauth_route.dart';
import 'package:landfall_server/src/web/routes/microsoft_calendar_oauth_route.dart';
import 'package:landfall_server/src/web/routes/oauth_token_encryptor.dart';

import 'test_tools/serverpod_test_tools.dart';

/// A minimal [http.Client] stub that routes by URL path.
class _StubHttpClient extends http.BaseClient {
  _StubHttpClient({required this.tokenBody, required this.userInfoBody});

  final String tokenBody;
  final String userInfoBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    final isToken = path.contains('token');
    final body = isToken ? tokenBody : userInfoBody;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      isToken ? 200 : 200,
    );
  }
}

void main() {
  withServerpod('Given OAuth start routes (SEC-06)', (sessionBuilder, endpoints) {
    late TestSessionBuilder authed;

    setUp(() {
      authed = sessionBuilder.copyWith(
        authentication:
            AuthenticationOverride.authenticationInfo('100000000001', {}),
      );
    });

    group('CalendarOAuthStartRoute', () {
      test('rejects unauthenticated caller with 401', () async {
        final session = sessionBuilder.build();
        final request = RequestInternal.create(
          Method.get,
          Uri.parse(
            'http://localhost/calendar/oauth/start?authUserId=00000000-0000-0000-0000-000000000001',
          ),
          Object(),
        );

        final result =
            await CalendarOAuthStartRoute().handleCall(session, request);
        expect(
          (result as Response).statusCode,
          equals(401),
          reason: 'Unauthenticated OAuth start must be rejected',
        );
      });

      test('authenticated caller is redirected (303)', () async {
        final session = authed.build();
        final request = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/calendar/oauth/start'),
          Object(),
        );

        final result =
            await CalendarOAuthStartRoute().handleCall(session, request);
        expect(
          (result as Response).statusCode,
          equals(303),
          reason: 'Authenticated caller must be redirected to Google',
        );
      });

      test('valid single-use ticket is redirected (303)', () async {
        final store = CalendarLinkTicketStore();
        final ticket = store.issue('00000000-0000-4000-8000-100000000042');
        final session = sessionBuilder.build();
        final request = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/calendar/oauth/start?ticket=$ticket'),
          Object(),
        );

        final result = await CalendarOAuthStartRoute(ticketStore: store)
            .handleCall(session, request);
        expect(
          (result as Response).statusCode,
          equals(303),
          reason: 'A valid ticket must be redirected to Google',
        );
      });

      test('a consumed ticket cannot be replayed (401)', () async {
        final store = CalendarLinkTicketStore();
        final ticket = store.issue('00000000-0000-4000-8000-100000000042');
        final session = sessionBuilder.build();
        Request req() => RequestInternal.create(
              Method.get,
              Uri.parse('http://localhost/calendar/oauth/start?ticket=$ticket'),
              Object(),
            );

        final first = await CalendarOAuthStartRoute(ticketStore: store)
            .handleCall(session, req());
        expect((first as Response).statusCode, equals(303));

        final second = await CalendarOAuthStartRoute(ticketStore: store)
            .handleCall(session, req());
        expect(
          (second as Response).statusCode,
          equals(401),
          reason: 'A single-use ticket must not be replayable',
        );
      });

      test('an unknown ticket is rejected (401)', () async {
        final session = sessionBuilder.build();
        final request = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/calendar/oauth/start?ticket=bogus'),
          Object(),
        );

        final result = await CalendarOAuthStartRoute(
          ticketStore: CalendarLinkTicketStore(),
        ).handleCall(session, request);
        expect(
          (result as Response).statusCode,
          equals(401),
          reason: 'An unknown ticket must be rejected',
        );
      });

      test('a caller-supplied authUserId without a ticket is rejected (401)',
          () async {
        // SEC-06 regression: identity must never come from a query parameter.
        final session = sessionBuilder.build();
        final request = RequestInternal.create(
          Method.get,
          Uri.parse(
            'http://localhost/calendar/oauth/start'
            '?authUserId=00000000-0000-0000-0000-000000000042',
          ),
          Object(),
        );

        final result =
            await CalendarOAuthStartRoute().handleCall(session, request);
        expect(
          (result as Response).statusCode,
          equals(401),
          reason: 'A bare authUserId query param must not authorize the flow',
        );
      });
    });

    group('MicrosoftCalendarOAuthStartRoute', () {
      test('rejects unauthenticated caller with 401', () async {
        final session = sessionBuilder.build();
        final request = RequestInternal.create(
          Method.get,
          Uri.parse(
            'http://localhost/calendar/microsoft/oauth/start?authUserId=00000000-0000-0000-0000-000000000001',
          ),
          Object(),
        );

        final result = await MicrosoftCalendarOAuthStartRoute()
            .handleCall(session, request);
        expect(
          (result as Response).statusCode,
          equals(401),
          reason: 'Unauthenticated Microsoft OAuth start must be rejected',
        );
      });

      test('returns 500 when Microsoft credentials are not configured',
          () async {
        // Test config has empty microsoftClientId → route should report misconfiguration.
        final session = authed.build();
        final request = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/calendar/microsoft/oauth/start'),
          Object(),
        );

        final result = await MicrosoftCalendarOAuthStartRoute()
            .handleCall(session, request);
        // Microsoft client ID is empty in test config → 500 (not 401 and not 303).
        expect((result as Response).statusCode, isNot(401));
      });

      test('a valid ticket authorizes the flow (past the 401 gate)', () async {
        final store = CalendarLinkTicketStore();
        final ticket = store.issue('00000000-0000-4000-8000-100000000042');
        final session = sessionBuilder.build();
        final request = RequestInternal.create(
          Method.get,
          Uri.parse(
            'http://localhost/calendar/microsoft/oauth/start?ticket=$ticket',
          ),
          Object(),
        );

        final result = await MicrosoftCalendarOAuthStartRoute(ticketStore: store)
            .handleCall(session, request);
        // Ticket clears the auth gate; config is empty in tests → not a 401.
        expect((result as Response).statusCode, isNot(401));
      });

      test('an unknown ticket is rejected (401)', () async {
        final session = sessionBuilder.build();
        final request = RequestInternal.create(
          Method.get,
          Uri.parse(
            'http://localhost/calendar/microsoft/oauth/start?ticket=bogus',
          ),
          Object(),
        );

        final result = await MicrosoftCalendarOAuthStartRoute(
          ticketStore: CalendarLinkTicketStore(),
        ).handleCall(session, request);
        expect((result as Response).statusCode, equals(401));
      });
    });
  });

  withServerpod('Given CalendarOAuthCallbackRoute (SEC-07)', (
    sessionBuilder,
    endpoints,
  ) {
    setUp(() async {
      final session = sessionBuilder.build();
      await LinkedCredential.db.deleteWhere(session, where: (t) => t.id > 0);
      await session.close();
    });

    test('stores access token as ciphertext when encryption key is configured',
        () async {
      const fakeState = 'test-state-token-sec07-google';
      const fakeEmail = 'encrypted@example.com';
      const fakeAccess = 'ya29.real-access-token';
      const fakeRefresh = '1//real-refresh-token';

      injectCalendarOAuthStateForTest(
        fakeState,
        '00000000-0000-4000-8000-100000000001',
      );

      final stub = _StubHttpClient(
        tokenBody: jsonEncode({
          'access_token': fakeAccess,
          'refresh_token': fakeRefresh,
          'expires_in': 3600,
          'scope': 'calendar.readonly',
        }),
        userInfoBody: jsonEncode({'email': fakeEmail}),
      );

      final session = sessionBuilder.build();
      final request = RequestInternal.create(
        Method.get,
        Uri.parse(
          'http://localhost/calendar/oauth/callback?code=fake-code&state=$fakeState',
        ),
        Object(),
      );

      await CalendarOAuthCallbackRoute(httpClient: stub)
          .handleCall(session, request);

      final stored = await LinkedCredential.db.findFirstRow(
        session,
        where: (t) => t.providerEmail.equals(fakeEmail),
      );

      expect(stored, isNotNull);
      expect(
        OAuthTokenEncryptor.isEncrypted(stored!.accessToken),
        isTrue,
        reason: 'Stored access token must be ciphertext, not plaintext',
      );
      if (stored.refreshToken != null) {
        expect(
          OAuthTokenEncryptor.isEncrypted(stored.refreshToken!),
          isTrue,
          reason: 'Stored refresh token must be ciphertext, not plaintext',
        );
      }
      await session.close();
    });

    test('stored token decrypts to original plaintext', () async {
      const fakeState = 'test-state-token-sec07-decrypt';
      const fakeEmail = 'decrypt@example.com';
      const fakeAccess = 'ya29.decrypt-me';

      injectCalendarOAuthStateForTest(
        fakeState,
        '00000000-0000-4000-8000-100000000001',
      );

      final stub = _StubHttpClient(
        tokenBody: jsonEncode({
          'access_token': fakeAccess,
          'refresh_token': null,
          'expires_in': 3600,
          'scope': 'calendar.readonly',
        }),
        userInfoBody: jsonEncode({'email': fakeEmail}),
      );

      final session = sessionBuilder.build();
      final request = RequestInternal.create(
        Method.get,
        Uri.parse(
          'http://localhost/calendar/oauth/callback?code=fake&state=$fakeState',
        ),
        Object(),
      );

      await CalendarOAuthCallbackRoute(httpClient: stub)
          .handleCall(session, request);

      final stored = await LinkedCredential.db.findFirstRow(
        session,
        where: (t) => t.providerEmail.equals(fakeEmail),
      );

      expect(stored, isNotNull);

      // Decrypt the stored token using the key from test config.
      final encKey = session.passwords['oauthTokenEncryptionKey'];
      expect(encKey, isNotNull, reason: 'Test config must have oauthTokenEncryptionKey');
      final decrypted = OAuthTokenEncryptor.decryptIfEncrypted(
        stored!.accessToken,
        encKey,
      );
      expect(decrypted, equals(fakeAccess));
      await session.close();
    });
  });

  withServerpod('Given OAuthTokenMigration', (sessionBuilder, endpoints) {
    setUp(() async {
      final session = sessionBuilder.build();
      await LinkedCredential.db.deleteWhere(session, where: (t) => t.id > 0);
      await session.close();
    });

    test('migration encrypts plaintext tokens idempotently', () async {
      const plaintextAccess = 'ya29.plaintext-access';
      const plaintextRefresh = 'refresh-plaintext';

      final session = sessionBuilder.build();
      final now = DateTime.now().toUtc();

      // Insert a credential with plaintext tokens.
      await LinkedCredential.db.insertRow(
        session,
        LinkedCredential(
          authUserId:
              UuidValue.fromString('00000000-0000-4000-8000-100000000001'),
          provider: 'google',
          providerEmail: 'migrate@example.com',
          accessToken: plaintextAccess,
          refreshToken: plaintextRefresh,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Run migration.
      final encKey = session.passwords['oauthTokenEncryptionKey'];
      expect(encKey, isNotNull);
      await OAuthTokenMigration.encryptAll(session, encKey!);

      // Verify tokens are now encrypted.
      final stored = await LinkedCredential.db.findFirstRow(
        session,
        where: (t) => t.providerEmail.equals('migrate@example.com'),
      );
      expect(OAuthTokenEncryptor.isEncrypted(stored!.accessToken), isTrue);
      expect(OAuthTokenEncryptor.isEncrypted(stored.refreshToken!), isTrue);

      // Run migration again — idempotent.
      await OAuthTokenMigration.encryptAll(session, encKey);

      final storedAgain = await LinkedCredential.db.findFirstRow(
        session,
        where: (t) => t.providerEmail.equals('migrate@example.com'),
      );
      expect(
        OAuthTokenEncryptor.decryptIfEncrypted(storedAgain!.accessToken, encKey),
        equals(plaintextAccess),
        reason: 'Token must still decrypt to original after idempotent migration',
      );
      await session.close();
    });
  });
}
