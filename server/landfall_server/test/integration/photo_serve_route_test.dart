import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';
import 'package:landfall_server/src/web/routes/photo_serve_route.dart';
import 'package:landfall_server/src/web/routes/photo_signing_service.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given PhotoServeRoute (SEC-04)',
    (sessionBuilder, endpoints) {
      // Read the test secret from a session so it matches what the route reads.
      String readSecret() {
        final s = sessionBuilder.build();
        final secret = s.passwords['photoSigningSecret']?.toString() ?? '';
        s.close();
        return secret;
      }

      group('unauthenticated access without token', () {
        test('returns 401', () async {
          final session = sessionBuilder.build();
          final request = RequestInternal.create(
            Method.get,
            Uri.parse('http://localhost/photos/1'),
            Object(),
          );
          final result = await PhotoServeRoute().handleCall(session, request);
          expect(
            (result as Response).statusCode,
            equals(401),
            reason: 'Unauthenticated request without token must return 401',
          );
          await session.close();
        });
      });

      group('authenticated access with bearer token', () {
        test('authenticated session bypasses token check and returns 404 for nonexistent photo', () async {
          // An authenticated session should pass the auth check and reach the
          // photo-lookup step. With no photo in the DB the route returns 404,
          // not 401 or 403 — confirming auth was accepted.
          final authed = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo('user-1', {}),
          );
          final session = authed.build();
          final request = RequestInternal.create(
            Method.get,
            Uri.parse('http://localhost/photos/999999'),
            Object(),
          );
          final result = await PhotoServeRoute().handleCall(session, request);
          expect(
            (result as Response).statusCode,
            equals(404),
            reason: 'Authenticated request for nonexistent photo must return 404',
          );
          await session.close();
        });
      });

      group('signed URL token validation', () {
        test('tampered token returns 403', () async {
          final session = sessionBuilder.build();
          final exp = DateTime.now()
                  .toUtc()
                  .add(const Duration(minutes: 5))
                  .millisecondsSinceEpoch ~/
              1000;
          final request = RequestInternal.create(
            Method.get,
            Uri.parse(
              'http://localhost/photos/1?token=invalid_tampered_token&exp=$exp',
            ),
            Object(),
          );
          final result = await PhotoServeRoute().handleCall(session, request);
          expect(
            (result as Response).statusCode,
            equals(403),
            reason: 'Tampered token must return 403',
          );
          await session.close();
        });

        test('expired token returns 403', () async {
          final session = sessionBuilder.build();
          final exp = DateTime.now()
                  .toUtc()
                  .subtract(const Duration(minutes: 1))
                  .millisecondsSinceEpoch ~/
              1000;
          final token = PhotoSigningService.signStatic(
            photoId: 1,
            expEpoch: exp,
            secret: readSecret(),
          );
          final request = RequestInternal.create(
            Method.get,
            Uri.parse('http://localhost/photos/1?token=$token&exp=$exp'),
            Object(),
          );
          final result = await PhotoServeRoute().handleCall(session, request);
          expect(
            (result as Response).statusCode,
            equals(403),
            reason: 'Expired token must return 403',
          );
          await session.close();
        });

        test('missing exp parameter returns 401', () async {
          final session = sessionBuilder.build();
          final request = RequestInternal.create(
            Method.get,
            Uri.parse('http://localhost/photos/1?token=sometoken'),
            Object(),
          );
          final result = await PhotoServeRoute().handleCall(session, request);
          expect((result as Response).statusCode, equals(401));
          await session.close();
        });

        test('valid signed URL token and nonexistent photo returns 404', () async {
          // A correctly-signed, unexpired token must pass the auth check.
          // With no matching photo in the DB the route returns 404 — confirming
          // the token was accepted (not 401/403).
          final session = sessionBuilder.build();
          const photoId = 888777;
          final exp = DateTime.now()
                  .toUtc()
                  .add(const Duration(minutes: 5))
                  .millisecondsSinceEpoch ~/
              1000;
          final token = PhotoSigningService.signStatic(
            photoId: photoId,
            expEpoch: exp,
            secret: readSecret(),
          );
          final request = RequestInternal.create(
            Method.get,
            Uri.parse('http://localhost/photos/$photoId?token=$token&exp=$exp'),
            Object(),
          );
          final result = await PhotoServeRoute().handleCall(session, request);
          expect(
            (result as Response).statusCode,
            equals(404),
            reason: 'Valid signed token with no matching photo must return 404',
          );
          await session.close();
        });

        test('valid signed URL token for existing photo with no active credential returns 500', () async {
          // Insert a photo row that references a non-existent credential.
          // The route should pass auth, find the photo, then fail on the missing
          // credential — returning 500 not 401/403.
          final session = sessionBuilder.build();
          final inserted = await Photo.db.insertRow(
            session,
            Photo(
              credentialId: 99999,
              providerFileId: 'drive_file_abc',
              filename: 'test.jpg',
              mimeType: 'image/jpeg',
              fetchedAt: DateTime.now().toUtc(),
            ),
          );
          final photoId = inserted.id!;
          final exp = DateTime.now()
                  .toUtc()
                  .add(const Duration(minutes: 5))
                  .millisecondsSinceEpoch ~/
              1000;
          final token = PhotoSigningService.signStatic(
            photoId: photoId,
            expEpoch: exp,
            secret: readSecret(),
          );
          final request = RequestInternal.create(
            Method.get,
            Uri.parse('http://localhost/photos/$photoId?token=$token&exp=$exp'),
            Object(),
          );
          final result = await PhotoServeRoute().handleCall(session, request);
          // Auth passed, photo found, but credential is missing → 500.
          expect(
            (result as Response).statusCode,
            equals(500),
            reason: 'Valid token with orphaned credential must return 500',
          );
          await session.close();
        });
      });

      group('nonexistent photo ID', () {
        test('authenticated request for nonexistent ID returns 404', () async {
          final authed = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo('user-1', {}),
          );
          final session = authed.build();
          final request = RequestInternal.create(
            Method.get,
            Uri.parse('http://localhost/photos/999999999'),
            Object(),
          );
          final result = await PhotoServeRoute().handleCall(session, request);
          expect(
            (result as Response).statusCode,
            equals(404),
          );
          await session.close();
        });

        test('invalid (non-numeric) photo ID returns 400', () async {
          final authed = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo('user-1', {}),
          );
          final session = authed.build();
          final request = RequestInternal.create(
            Method.get,
            Uri.parse('http://localhost/photos/not-a-number'),
            Object(),
          );
          final result = await PhotoServeRoute().handleCall(session, request);
          expect(
            (result as Response).statusCode,
            equals(400),
          );
          await session.close();
        });
      });
    },
  );
}
