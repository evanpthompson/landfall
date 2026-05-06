import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:display/src/data/photo/fallback_photo_repository.dart';

class _MockRepo extends Mock implements PhotoRepository {}

PhotoEntity _photo(int id) => PhotoEntity(
      id: id,
      filename: '$id.jpg',
      mimeType: 'image/jpeg',
      fetchedAt: DateTime(2026, 5, 1),
      imageUrl: 'https://example.com/$id.jpg',
    );

void main() {
  group('FallbackPhotoRepository', () {
    test('returns photos from primary when available', () async {
      final primary = _MockRepo();
      final secondary = _MockRepo();
      when(() => primary.getPhotos()).thenAnswer((_) async => [_photo(1)]);

      final repo = FallbackPhotoRepository([primary, secondary]);
      final result = await repo.getPhotos();

      expect(result.length, equals(1));
      verifyNever(() => secondary.getPhotos());
    });

    test('falls through to secondary when primary returns empty', () async {
      final primary = _MockRepo();
      final secondary = _MockRepo();
      when(() => primary.getPhotos()).thenAnswer((_) async => []);
      when(() => secondary.getPhotos()).thenAnswer((_) async => [_photo(2)]);

      final repo = FallbackPhotoRepository([primary, secondary]);
      final result = await repo.getPhotos();

      expect(result.length, equals(1));
      expect(result.first.id, equals(2));
    });

    test('returns empty when all sources return empty', () async {
      final primary = _MockRepo();
      final secondary = _MockRepo();
      when(() => primary.getPhotos()).thenAnswer((_) async => []);
      when(() => secondary.getPhotos()).thenAnswer((_) async => []);

      final repo = FallbackPhotoRepository([primary, secondary]);
      final result = await repo.getPhotos();

      expect(result, isEmpty);
    });

    test('falls through when primary throws', () async {
      final primary = _MockRepo();
      final secondary = _MockRepo();
      when(() => primary.getPhotos()).thenThrow(Exception('network error'));
      when(() => secondary.getPhotos()).thenAnswer((_) async => [_photo(3)]);

      final repo = FallbackPhotoRepository([primary, secondary]);
      final result = await repo.getPhotos();

      expect(result.length, equals(1));
      expect(result.first.id, equals(3));
    });

    test('empty repository list returns empty', () async {
      final repo = FallbackPhotoRepository([]);
      final result = await repo.getPhotos();
      expect(result, isEmpty);
    });
  });
}
