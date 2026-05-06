import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:display/src/data/photo/local_directory_photo_repository.dart';

void main() {
  group('LocalDirectoryPhotoRepository', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('photo_repo_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('returns PhotoEntity for each image file', () async {
      for (final name in ['a.jpg', 'b.jpeg', 'c.png', 'd.webp']) {
        await File('${tempDir.path}/$name').create();
      }
      final repo = LocalDirectoryPhotoRepository(tempDir.path);
      final photos = await repo.getPhotos();

      expect(photos.length, equals(4));
      expect(photos.every((p) => p.imageUrl.startsWith('file://')), isTrue);
    });

    test('ignores non-image files', () async {
      await File('${tempDir.path}/photo.jpg').create();
      await File('${tempDir.path}/readme.txt').create();
      await File('${tempDir.path}/data.json').create();

      final repo = LocalDirectoryPhotoRepository(tempDir.path);
      final photos = await repo.getPhotos();

      expect(photos.length, equals(1));
      expect(photos.first.filename, equals('photo.jpg'));
    });

    test('returns empty list for empty directory', () async {
      final repo = LocalDirectoryPhotoRepository(tempDir.path);
      final photos = await repo.getPhotos();
      expect(photos, isEmpty);
    });

    test('returns empty list when directory does not exist', () async {
      final repo = LocalDirectoryPhotoRepository('/nonexistent/path');
      final photos = await repo.getPhotos();
      expect(photos, isEmpty);
    });

    test('imageUrl uses file:// scheme', () async {
      await File('${tempDir.path}/test.jpg').create();
      final repo = LocalDirectoryPhotoRepository(tempDir.path);
      final photos = await repo.getPhotos();
      expect(photos.first.imageUrl, startsWith('file://'));
    });
  });
}
