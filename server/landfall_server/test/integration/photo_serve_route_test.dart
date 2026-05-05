import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/web/routes/photo_serve_route.dart';
import 'package:landfall_server/src/web/routes/photo_signing_service.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given PhotoServeRoute (SEC-04)',
    (sessionBuilder, endpoints) {
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

      group('signed URL token validation', () {
        // Read the test secret from a session so it matches what the route reads.
        String readSecret() {
          final s = sessionBuilder.build();
          final secret = s.passwords['photoSigningSecret']?.toString() ?? '';
          s.close();
          return secret;
        }

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
      });
    },
  );
}
