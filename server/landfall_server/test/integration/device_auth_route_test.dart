import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/auth/device_auth_service.dart';
import 'package:landfall_server/src/web/routes/device_auth_route.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given DeviceAuthRoutes', (sessionBuilder, endpoints) {
    setUpAll(() {
      AuthServices.set(
        tokenManagerBuilders: [JwtConfigFromPasswords()],
      );
    });

    setUp(DeviceAuthService.resetForTest);

    Future<Response> postStart(Session session) async {
      final req = RequestInternal.create(
        Method.post,
        Uri.parse('http://localhost:8080/auth/device/start'),
        Object(),
      );
      return (await DeviceAuthStartRoute().handleCall(session, req)) as Response;
    }

    // Variant that pins the LAN-base resolution: the verification URL shown to
    // the phone must come from [resolveBaseUrl], NOT the request host (which is
    // loopback when the TV hits the local server on the Pi).
    Future<Response> postStartWithBase(
      Session session,
      Future<String> Function() resolveBaseUrl,
    ) async {
      final req = RequestInternal.create(
        Method.post,
        // Loopback request host — what the TV actually sends on the Pi.
        Uri.parse('http://127.0.0.1:8082/auth/device/start'),
        Object(),
      );
      return (await DeviceAuthStartRoute(resolveBaseUrl: resolveBaseUrl)
          .handleCall(session, req)) as Response;
    }

    Future<Response> postPoll(Session session, String deviceCode) async {
      final req = RequestInternal.create(
        Method.post,
        Uri.parse('http://localhost:8080/auth/device/poll'),
        Object(),
        body: Body.fromString(
          jsonEncode({'deviceCode': deviceCode}),
          mimeType: MimeType.json,
        ),
      );
      return (await DeviceAuthPollRoute().handleCall(session, req)) as Response;
    }

    Future<Response> getDevice(Session session) async {
      final req = RequestInternal.create(
        Method.get,
        Uri.parse('http://localhost:8080/device'),
        Object(),
      );
      return (await DevicePageRoute().handleCall(session, req)) as Response;
    }

    Future<Response> postDevice(
      Session session, {
      required String userCode,
      required String email,
      required String code,
    }) async {
      final encoded = Uri(
        queryParameters: {
          'userCode': userCode,
          'email': email,
          'code': code,
        },
      ).query;
      final req = RequestInternal.create(
        Method.post,
        Uri.parse('http://localhost:8080/device'),
        Object(),
        body: Body.fromString(
          encoded,
          mimeType: MimeType.urlEncoded,
        ),
      );
      return (await DevicePageRoute().handleCall(session, req)) as Response;
    }

    // ── POST /auth/device/start ────────────────────────────────────────────────

    group('POST /auth/device/start', () {
      test('returns 200 with required fields', () async {
        final session = sessionBuilder.build();
        final res = await postStart(session);
        await session.close();

        expect(res.statusCode, equals(200));
        final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
        expect(body['userCode'], isA<String>());
        expect(body['deviceCode'], isA<String>());
        expect(body['verificationUri'], isA<String>());
        expect(body['expiresIn'], isA<int>());
        expect(body['interval'], isA<int>());
      });

      test('userCode is 6 uppercase alphanumeric characters', () async {
        final session = sessionBuilder.build();
        final res = await postStart(session);
        await session.close();

        final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
        expect(
          body['userCode'] as String,
          matches(r'^[A-Z0-9]{6}$'),
        );
      });

      test('verificationUri contains /device path', () async {
        final session = sessionBuilder.build();
        final res = await postStart(session);
        await session.close();

        final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
        expect(body['verificationUri'] as String, contains('/device'));
      });

      test('verificationUri uses the resolved LAN base, not the request host',
          () async {
        final session = sessionBuilder.build();
        final res = await postStartWithBase(
          session,
          () async => 'https://kitchen-pi.local',
        );
        await session.close();

        final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
        final uri = body['verificationUri'] as String;
        // Must be the LAN-reachable host, never the loopback the TV connected on.
        expect(uri, 'https://kitchen-pi.local/device');
        expect(uri, isNot(contains('127.0.0.1')));
      });

      test('verificationUri falls back to request origin when no LAN base',
          () async {
        final session = sessionBuilder.build();
        // Empty base => isolated host with no domain and no RFC1918 address.
        final res = await postStartWithBase(session, () async => '');
        await session.close();

        final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
        expect(body['verificationUri'] as String, 'http://127.0.0.1:8082/device');
      });
    });

    // ── POST /auth/device/poll ─────────────────────────────────────────────────

    group('POST /auth/device/poll', () {
      test('returns authorization_pending for an unpaired device code',
          () async {
        final s1 = sessionBuilder.build();
        final startRes = await postStart(s1);
        await s1.close();
        final startBody =
            jsonDecode(await startRes.readAsString()) as Map<String, dynamic>;

        final s2 = sessionBuilder.build();
        final pollRes =
            await postPoll(s2, startBody['deviceCode'] as String);
        await s2.close();

        expect(pollRes.statusCode, equals(200));
        final body =
            jsonDecode(await pollRes.readAsString()) as Map<String, dynamic>;
        expect(body['status'], equals('authorization_pending'));
        expect(body.containsKey('authSuccess'), isFalse);
      });

      test('returns expired_token for an unknown device code', () async {
        final session = sessionBuilder.build();
        final res = await postPoll(session, 'no-such-device-code');
        await session.close();

        final body =
            jsonDecode(await res.readAsString()) as Map<String, dynamic>;
        expect(body['status'], equals('expired_token'));
      });

      test('returns authorized + authSuccess after completeFlow', () async {
        final s1 = sessionBuilder.build();
        final startRes = await postStart(s1);
        await s1.close();
        final startBody =
            jsonDecode(await startRes.readAsString()) as Map<String, dynamic>;

        DeviceAuthService.pairForTest(
          startBody['userCode'] as String,
          'test-jwt-token',
        );

        final s2 = sessionBuilder.build();
        final pollRes =
            await postPoll(s2, startBody['deviceCode'] as String);
        await s2.close();

        final body =
            jsonDecode(await pollRes.readAsString()) as Map<String, dynamic>;
        expect(body['status'], equals('authorized'));
        final authSuccess = body['authSuccess'] as Map<String, dynamic>;
        expect(authSuccess['token'], equals('test-jwt-token'));
      });
    });

    // ── GET /device ───────────────────────────────────────────────────────────

    group('GET /device', () {
      test('returns 200 HTML page with form', () async {
        final session = sessionBuilder.build();
        final res = await getDevice(session);
        await session.close();

        expect(res.statusCode, equals(200));
        final body = await res.readAsString();
        expect(body, contains('<!DOCTYPE html>'));
        expect(body, contains('<form'));
        expect(body, contains('userCode'));
        expect(body, contains('email'));
      });
    });

    // ── POST /device ──────────────────────────────────────────────────────────

    group('POST /device', () {
      test('returns error page for an unknown or expired user code', () async {
        final session = sessionBuilder.build();
        final res = await postDevice(
          session,
          userCode: 'ZZZZZZ',
          email: 'user@example.com',
          code: '000000',
        );
        await session.close();

        final body = await res.readAsString();
        expect(body.toLowerCase(), contains('invalid'));
      });
    });
  });
}
