import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Serves cached photo metadata to the Flutter display client.
///
/// Photo entries are populated by [PhotoRefreshCall] on a 30-minute schedule.
/// Returns an empty list gracefully if no photos have been synced yet.
///
/// Image bytes are NOT served through this endpoint. The display client
/// fetches images via the [PhotoServeRoute] web route at /photos/{id}.
class PhotoEndpoint extends Endpoint {
  /// Returns all available photos ordered by filename.
  Future<List<Photo>> getPhotos(Session session) async {
    return Photo.db.find(
      session,
      orderBy: (t) => t.filename,
      orderDescending: false,
    );
  }
}
