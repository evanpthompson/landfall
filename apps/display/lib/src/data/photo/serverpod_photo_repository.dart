import 'dart:developer' as dev;

import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// Fetches photo metadata from the Serverpod server.
///
/// No local cache — the server is the cache (refreshed every 30 minutes).
/// Constructs [PhotoEntity.imageUrl] from [serverUrl] so the widget can load
/// images via [Image.network] without any knowledge of provider details.
class ServerpodPhotoRepository implements PhotoRepository {
  ServerpodPhotoRepository(this._client, this._serverUrl);

  final Client _client;

  /// Base server URL, e.g. `'http://localhost:8080/'`.
  final String _serverUrl;

  @override
  Future<List<PhotoEntity>> getPhotos() async {
    try {
      final rows = await _client.photo.getPhotos();
      final photos = <PhotoEntity>[];
      for (final row in rows) {
        photos.add(await _toEntity(row));
      }
      return photos;
    } catch (e, stackTrace) {
      dev.log(
        'getPhotos failed (serverUrl: $_serverUrl)',
        name: 'landfall.photo',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<PhotoEntity> _toEntity(Photo row) async {
    final base = _serverUrl.endsWith('/') ? _serverUrl : '$_serverUrl/';
    final signedPath = await _client.photo.getSignedPhotoUrl(row.id!);
    final imageUrl = signedPath.startsWith('http')
        ? signedPath
        : '$base${signedPath.startsWith('/') ? signedPath.substring(1) : signedPath}';
    return PhotoEntity(
      id: row.id!,
      filename: row.filename,
      mimeType: row.mimeType,
      fetchedAt: row.fetchedAt,
      imageUrl: imageUrl,
    );
  }
}
