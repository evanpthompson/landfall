import 'dart:io';
import 'package:landfall_shared/landfall_shared.dart';

/// A [PhotoRepository] that reads image files from a local directory path.
///
/// Supports `.jpg`, `.jpeg`, `.png`, `.webp` extensions.
/// Returns `file://` URLs for use with [Image.file] in the display widget.
class LocalDirectoryPhotoRepository implements PhotoRepository {
  const LocalDirectoryPhotoRepository(this.path);

  final String path;

  static const _extensions = {'.jpg', '.jpeg', '.png', '.webp'};

  @override
  Future<List<PhotoEntity>> getPhotos() async {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => _extensions.contains(_ext(f.path)))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    return [
      for (var i = 0; i < files.length; i++)
        PhotoEntity(
          id: i,
          filename: _basename(files[i].path),
          mimeType: _mimeType(files[i].path),
          fetchedAt: DateTime.now(),
          imageUrl: 'file://${files[i].path}',
        ),
    ];
  }

  static String _ext(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot).toLowerCase();
  }

  static String _basename(String path) {
    final sep = path.lastIndexOf('/');
    return sep == -1 ? path : path.substring(sep + 1);
  }

  static String _mimeType(String path) {
    return switch (_ext(path)) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
