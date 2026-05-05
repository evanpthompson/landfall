import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../../photo/google_drive_photo_service.dart';
import '../../photo/photo_service.dart';
import 'photo_signing_service.dart';

class PhotoServeRoute extends Route {
  PhotoServeRoute() : super(methods: {Method.get});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    // Path is /photos/{id} — extract the last segment as the photo ID.
    final segments = request.url.pathSegments;
    final idStr = segments.isNotEmpty ? segments.last : null;
    final photoId = int.tryParse(idStr ?? '');

    if (photoId == null) {
      return Response.badRequest(
        body: Body.fromString('Invalid or missing photo ID in path'),
      );
    }

    // Require either an authenticated session or a valid signed URL token.
    final authResult = _checkAuth(session, request, photoId);
    if (authResult != null) return authResult;

    final photo = await Photo.db.findById(session, photoId);
    if (photo == null) {
      return Response.notFound();
    }

    final credential = await LinkedCredential.db.findById(
      session,
      photo.credentialId,
    );
    if (credential == null || !credential.isActive) {
      return Response.internalServerError(
        body: Body.fromString('No active credential for photo $photoId'),
      );
    }

    try {
      final service = _serviceFor(credential);
      final bytes = await service.fetchPhotoBytes(
        session,
        credential,
        photo.providerFileId,
      );

      final mimeParts = photo.mimeType.split('/');
      final mimeType = mimeParts.length == 2
          ? MimeType(mimeParts[0], mimeParts[1])
          : MimeType.octetStream;

      return Response(
        200,
        body: Body.fromData(bytes, mimeType: mimeType),
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to fetch photo $photoId from provider: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return Response.internalServerError(
        body: Body.fromString('Failed to fetch photo'),
      );
    }
  }

  PhotoService _serviceFor(LinkedCredential credential) {
    return switch (credential.provider) {
      'google' => GoogleDrivePhotoService(),
      _ => throw UnimplementedError(
          'Photo provider "${credential.provider}" is not yet supported.',
        ),
    };
  }

  /// Returns a non-null [Response] error if the caller is not authorised.
  /// Returns null when the request should proceed.
  Result? _checkAuth(Session session, Request request, int photoId) {
    if (session.authenticated != null) return null;

    final params = request.url.queryParameters;
    final tokenStr = params['token'];
    final expStr = params['exp'];
    final exp = int.tryParse(expStr ?? '');

    if (tokenStr == null || exp == null) {
      return Response(
        401,
        body: Body.fromString('Authentication required'),
      );
    }

    final secret = session.passwords['photoSigningSecret']?.toString() ?? '';
    if (secret.isEmpty) {
      return Response(401, body: Body.fromString('Authentication required'));
    }

    if (!PhotoSigningService(secret).verify(photoId, tokenStr, exp)) {
      return Response(403, body: Body.fromString('Invalid or expired token'));
    }

    return null;
  }
}
