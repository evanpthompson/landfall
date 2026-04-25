import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Provider-agnostic interface for listing and fetching photos.
///
/// Each photo provider (Google Drive, etc.) implements this interface.
/// [PhotoRefreshCall] uses [listPhotos] to sync metadata. [PhotoServeRoute]
/// uses [fetchPhotoBytes] to proxy image bytes on demand.
abstract class PhotoService {
  /// Lists all photos accessible in [folderId] via [credential].
  ///
  /// Returns [Photo] objects without DB ids set — the caller is responsible
  /// for persisting them. Only image MIME types are returned.
  Future<List<Photo>> listPhotos(
    Session session,
    LinkedCredential credential,
    String folderId,
  );

  /// Fetches the raw image bytes for a single photo identified by
  /// [providerFileId] using [credential].
  ///
  /// May refresh [credential]'s access token transparently if it is close
  /// to expiry.
  Future<Uint8List> fetchPhotoBytes(
    Session session,
    LinkedCredential credential,
    String providerFileId,
  );
}
