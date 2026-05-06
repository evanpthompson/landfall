import 'package:landfall_shared/landfall_shared.dart';

/// A [PhotoRepository] that serves a fixed list of image URLs.
///
/// No server round-trip — returns [PhotoEntity] objects directly from [urls].
class NetworkPhotoRepository implements PhotoRepository {
  const NetworkPhotoRepository(this.urls);

  final List<String> urls;

  @override
  Future<List<PhotoEntity>> getPhotos() async {
    return [
      for (var i = 0; i < urls.length; i++)
        PhotoEntity(
          id: i,
          filename: _filename(urls[i]),
          mimeType: _mimeType(urls[i]),
          fetchedAt: DateTime.now(),
          imageUrl: urls[i],
        ),
    ];
  }

  static String _filename(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final segments = uri.pathSegments;
    return segments.isNotEmpty ? segments.last : url;
  }

  static String _mimeType(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
