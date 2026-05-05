import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../web/routes/photo_signing_service.dart';

class PhotoEndpoint extends Endpoint {
  Future<List<Photo>> getPhotos(Session session) async {
    _requireAuth(session);
    return Photo.db.find(
      session,
      orderBy: (t) => t.filename,
      orderDescending: false,
    );
  }

  /// Returns a short-lived signed URL for [photoId].
  ///
  /// The URL can be used by the display client to fetch photo bytes from
  /// [PhotoServeRoute] without embedding a session token in the HTTP request.
  /// Tokens expire after [PhotoSigningService.tokenLifetime].
  Future<String> getSignedPhotoUrl(Session session, int photoId) async {
    _requireAuth(session);

    final secret = session.passwords['photoSigningSecret']?.toString() ?? '';
    if (secret.isEmpty) {
      throw LandfallException(message: 'Photo signing not configured.');
    }

    final photo = await Photo.db.findById(session, photoId);
    if (photo == null) {
      throw LandfallException(message: 'Photo not found.');
    }

    final signer = PhotoSigningService(secret);
    final (:token, :exp) = signer.sign(photoId);

    // Return a relative URL — the client prepends its configured server base URL.
    return '/photos/$photoId?token=$token&exp=$exp';
  }

  void _requireAuth(Session session) {
    if (session.authenticated == null) {
      throw LandfallException(message: 'Authentication required.');
    }
  }
}
