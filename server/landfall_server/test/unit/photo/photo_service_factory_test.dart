import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';
import 'package:landfall_server/src/photo/google_drive_photo_service.dart';
import 'package:landfall_server/src/photo/photo_service_factory.dart';

LinkedCredential _credential(String provider) => LinkedCredential(
      authUserId: UuidValue.fromString('00000000-0000-4000-8000-000000000001'),
      provider: provider,
      providerEmail: 'x@y.z',
      accessToken: '',
      isActive: true,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  group('photoServiceFor', () {
    test('returns OAuth service for provider="google"', () {
      final service = photoServiceFor(
        credential: _credential('google'),
        passwords: const {},
      );
      expect(service, isA<GoogleDrivePhotoService>());
    });

    test('throws clear error for unknown provider', () {
      expect(
        () => photoServiceFor(
          credential: _credential('apple'),
          passwords: const {},
        ),
        throwsA(isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          contains('apple'),
        )),
      );
    });

    test(
      'throws when provider="google-sa" but no service account credentials '
      'are configured',
      () {
        expect(
          () => photoServiceFor(
            credential: _credential('google-sa'),
            passwords: const {},
          ),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('googleServiceAccountEmail'),
              contains('googleServiceAccountPrivateKey'),
            ),
          )),
        );
      },
    );

    test(
      'throws when provider="google-sa" but private key is malformed',
      () {
        // Malformed PEM fails at GoogleServiceAccountAuth construction.
        expect(
          () => photoServiceFor(
            credential: _credential('google-sa'),
            passwords: const {
              'googleServiceAccountEmail': 'svc@x.iam.gserviceaccount.com',
              'googleServiceAccountPrivateKey': 'not a pem',
            },
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
