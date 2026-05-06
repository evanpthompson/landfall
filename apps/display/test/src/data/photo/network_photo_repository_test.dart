import 'package:flutter_test/flutter_test.dart';
import 'package:display/src/data/photo/network_photo_repository.dart';

void main() {
  group('NetworkPhotoRepository', () {
    test('returns one PhotoEntity per URL', () async {
      const urls = [
        'https://example.com/a.jpg',
        'https://example.com/b.png',
        'https://example.com/c.webp',
      ];
      final repo = NetworkPhotoRepository(urls);
      final photos = await repo.getPhotos();

      expect(photos.length, equals(3));
      expect(photos[0].imageUrl, equals(urls[0]));
      expect(photos[1].imageUrl, equals(urls[1]));
      expect(photos[2].imageUrl, equals(urls[2]));
    });

    test('returns empty list when URLs list is empty', () async {
      final repo = NetworkPhotoRepository(const []);
      final photos = await repo.getPhotos();
      expect(photos, isEmpty);
    });

    test('each entity has unique id based on URL index', () async {
      final repo = NetworkPhotoRepository(const [
        'https://a.com/1.jpg',
        'https://a.com/2.jpg',
      ]);
      final photos = await repo.getPhotos();
      expect(photos[0].id, isNot(equals(photos[1].id)));
    });

    test('filename is extracted from URL', () async {
      final repo = NetworkPhotoRepository(const ['https://cdn.example.com/photo.jpg']);
      final photos = await repo.getPhotos();
      expect(photos.first.filename, equals('photo.jpg'));
    });
  });
}
