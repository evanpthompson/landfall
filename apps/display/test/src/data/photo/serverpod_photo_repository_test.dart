import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:display/src/data/photo/serverpod_photo_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockClient extends Mock implements Client {}

class _MockEndpointPhoto extends Mock implements EndpointPhoto {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Photo _serverPhoto({
  required int id,
  String? providerFileId,
  required String filename,
}) {
  return Photo(
    id: id,
    credentialId: 1,
    providerFileId: providerFileId ?? 'drive_$id',
    filename: filename,
    mimeType: 'image/jpeg',
    fetchedAt: DateTime.utc(2026, 5, 1),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockClient client;
  late _MockEndpointPhoto photoEndpoint;

  setUp(() {
    client = _MockClient();
    photoEndpoint = _MockEndpointPhoto();
    when(() => client.photo).thenReturn(photoEndpoint);
  });

  group('ServerpodPhotoRepository', () {
    group('getPhotos — URL construction', () {
      test('constructs imageUrl as webServerUrl/photos/{id} (trailing slash)', () async {
        when(() => photoEndpoint.getPhotos()).thenAnswer(
          (_) async => [_serverPhoto(id: 42, filename: 'sunset.jpg')],
        );

        final repo = ServerpodPhotoRepository(client, 'http://localhost:8082/');
        final photos = await repo.getPhotos();

        expect(photos, hasLength(1));
        expect(
          photos.first.imageUrl,
          equals('http://localhost:8082/photos/42'),
        );
      });

      test('constructs imageUrl correctly when webServerUrl has no trailing slash', () async {
        when(() => photoEndpoint.getPhotos()).thenAnswer(
          (_) async => [_serverPhoto(id: 7, filename: 'beach.jpg')],
        );

        final repo = ServerpodPhotoRepository(client, 'http://localhost:8082');
        final photos = await repo.getPhotos();

        expect(photos, hasLength(1));
        expect(
          photos.first.imageUrl,
          equals('http://localhost:8082/photos/7'),
        );
      });

      test('constructs imageUrl for each photo in the list', () async {
        when(() => photoEndpoint.getPhotos()).thenAnswer(
          (_) async => [
            _serverPhoto(id: 1, filename: 'a.jpg'),
            _serverPhoto(id: 2, filename: 'b.jpg'),
            _serverPhoto(id: 3, filename: 'c.jpg'),
          ],
        );

        final repo = ServerpodPhotoRepository(client, 'http://localhost:8082/');
        final photos = await repo.getPhotos();

        expect(photos, hasLength(3));
        expect(photos[0].imageUrl, equals('http://localhost:8082/photos/1'));
        expect(photos[1].imageUrl, equals('http://localhost:8082/photos/2'));
        expect(photos[2].imageUrl, equals('http://localhost:8082/photos/3'));
      });

      test('maps filename and mimeType correctly', () async {
        when(() => photoEndpoint.getPhotos()).thenAnswer(
          (_) async => [
            _serverPhoto(id: 5, filename: 'mountain.png'),
          ],
        );

        final repo = ServerpodPhotoRepository(client, 'http://localhost:8082/');
        final photos = await repo.getPhotos();

        expect(photos.first.filename, equals('mountain.png'));
        expect(photos.first.mimeType, equals('image/jpeg'));
        expect(photos.first.id, equals(5));
      });

      test('returns empty list when server returns no photos', () async {
        when(() => photoEndpoint.getPhotos()).thenAnswer((_) async => []);

        final repo = ServerpodPhotoRepository(client, 'http://localhost:8082/');
        final photos = await repo.getPhotos();

        expect(photos, isEmpty);
      });
    });

    group('getPhotos — error handling', () {
      test('returns [] and does not throw when getPhotos throws', () async {
        when(() => photoEndpoint.getPhotos())
            .thenThrow(Exception('network error'));

        final repo = ServerpodPhotoRepository(client, 'http://localhost:8082/');

        // Must not throw — error is swallowed and logged.
        final photos = await repo.getPhotos();

        expect(photos, isEmpty);
      });

      test('returns [] when server throws a StateError', () async {
        when(() => photoEndpoint.getPhotos())
            .thenThrow(StateError('connection refused'));

        final repo = ServerpodPhotoRepository(client, 'http://localhost:8082/');
        final photos = await repo.getPhotos();

        expect(photos, isEmpty);
      });

      test('subsequent call after error succeeds normally', () async {
        var callCount = 0;
        when(() => photoEndpoint.getPhotos()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) throw Exception('transient failure');
          return [_serverPhoto(id: 10, filename: 'recovery.jpg')];
        });

        final repo = ServerpodPhotoRepository(client, 'http://localhost:8082/');

        final first = await repo.getPhotos();
        expect(first, isEmpty, reason: 'First call (error) must return []');

        final second = await repo.getPhotos();
        expect(second, hasLength(1),
            reason: 'Second call (success) must return photos');
        expect(second.first.imageUrl, equals('http://localhost:8082/photos/10'));
      });
    });
  });
}
