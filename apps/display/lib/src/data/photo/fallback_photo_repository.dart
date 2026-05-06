import 'package:landfall_shared/landfall_shared.dart';

/// A [PhotoRepository] that tries each source in priority order.
///
/// Returns the first non-empty result. Falls through to the next source if
/// the current one returns an empty list or throws.
class FallbackPhotoRepository implements PhotoRepository {
  const FallbackPhotoRepository(this.sources);

  final List<PhotoRepository> sources;

  @override
  Future<List<PhotoEntity>> getPhotos() async {
    for (final source in sources) {
      try {
        final photos = await source.getPhotos();
        if (photos.isNotEmpty) return photos;
      } catch (_) {
        // Try next source
      }
    }
    return [];
  }
}
