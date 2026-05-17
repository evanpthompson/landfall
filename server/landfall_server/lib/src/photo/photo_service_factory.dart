import 'package:http/http.dart' as http;

import '../generated/protocol.dart';
import 'google_drive_photo_service.dart';
import 'google_drive_service_account_photo_service.dart';
import 'google_service_account_auth.dart';
import 'photo_service.dart';

/// Single source of truth for picking the right [PhotoService] given a
/// [LinkedCredential]. Used by both [PhotoRefreshCall] and [PhotoServeRoute]
/// so they can never drift on which provider strings are supported.
///
/// Provider routing:
/// * `"google"`     → [GoogleDrivePhotoService] (user OAuth credentials)
/// * `"google-sa"`  → [GoogleDriveServiceAccountPhotoService] (service
///                    account self-signed JWT). The service account email
///                    and private key are read from [passwords].
///
/// [passwords] must be `session.passwords` at the production call site.
/// Passed in directly (rather than reading off a Session) so the factory is
/// trivially unit-testable without spinning up a Serverpod test session.
///
/// [httpClient] is forwarded to the constructed service for test injection.
PhotoService photoServiceFor({
  required LinkedCredential credential,
  required Map<String, String> passwords,
  http.Client? httpClient,
}) {
  switch (credential.provider) {
    case 'google':
      return GoogleDrivePhotoService(httpClient: httpClient);
    case 'google-sa':
      final email = passwords['googleServiceAccountEmail'];
      final key = passwords['googleServiceAccountPrivateKey'];
      if (email == null || email.isEmpty || key == null || key.isEmpty) {
        throw StateError(
          'LinkedCredential.provider="google-sa" but '
          'googleServiceAccountEmail and googleServiceAccountPrivateKey '
          'are not configured in passwords.yaml. The service account row '
          'cannot be used without them.',
        );
      }
      return GoogleDriveServiceAccountPhotoService(
        auth: GoogleServiceAccountAuth(
          clientEmail: email,
          privateKeyPem: key,
          scopes: const ['https://www.googleapis.com/auth/drive.readonly'],
          httpClient: httpClient,
        ),
        httpClient: httpClient,
      );
    default:
      throw UnimplementedError(
        'Photo provider "${credential.provider}" is not yet supported.',
      );
  }
}
