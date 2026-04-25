import 'package:landfall_shared/src/models/photo/photo_entity.dart';

export '../models/photo/photo_entity.dart';

abstract class PhotoRepository {
  /// Returns all available photos, ordered by filename.
  ///
  /// Returns an empty list if no photos have been synced yet or the server
  /// is unreachable.
  Future<List<PhotoEntity>> getPhotos();
}
