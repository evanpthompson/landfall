import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../../photo/google_drive_photo_service.dart';
import '../../photo/photo_service.dart';

/// Serves photo image bytes, proxied on demand from the upstream provider.
///
/// Route: GET /photos/**
///
/// The URL uses Landfall's internal photo ID (the DB primary key), not any
/// provider-specific identifier. The serve route looks up the Photo row,
/// loads the associated LinkedCredential, selects the right [PhotoService]
/// implementation, and streams back the image bytes with the correct
/// Content-Type.
///
/// This abstraction keeps all provider concepts server-side. The display
/// client constructs URLs as http://{host}/photos/{photo.id} and has no
/// knowledge of Drive file IDs or any other provider detail.
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
}
