import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';

class _MockPhotoRepository extends Mock implements PhotoRepository {}

class _MockDisplaySettingsRepository extends Mock
    implements DisplaySettingsRepository {}

PhotoEntity _photo(int id, String url) => PhotoEntity(
      id: id,
      filename: '$id.jpg',
      mimeType: 'image/jpeg',
      fetchedAt: DateTime(2026, 5, 1),
      imageUrl: url,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const DisplaySettings());
  });

  late _MockPhotoRepository repository;
  late _MockDisplaySettingsRepository settingsRepository;

  setUp(() {
    repository = _MockPhotoRepository();
    settingsRepository = _MockDisplaySettingsRepository();
    when(() => settingsRepository.getSettings())
        .thenAnswer((_) async => const DisplaySettings());
    when(() => settingsRepository.saveSettings(any()))
        .thenAnswer((_) async {});
  });

  group('PhotoCubit', () {
    blocTest<PhotoCubit, PhotoState>(
      'loadPhotos emits PhotoLoaded when photos available',
      build: () {
        when(() => repository.getPhotos()).thenAnswer(
          (_) async => [_photo(1, 'https://a.com/1.jpg')],
        );
        return PhotoCubit(repository, settingsRepository);
      },
      act: (c) => c.loadPhotos(),
      expect: () => [
        isA<PhotoLoaded>().having((s) => s.photos.length, 'length', 1),
      ],
    );

    blocTest<PhotoCubit, PhotoState>(
      'loadPhotos emits PhotoEmpty when list is empty',
      build: () {
        when(() => repository.getPhotos()).thenAnswer((_) async => []);
        return PhotoCubit(repository, settingsRepository);
      },
      act: (c) => c.loadPhotos(),
      expect: () => [isA<PhotoEmpty>()],
    );

    blocTest<PhotoCubit, PhotoState>(
      'loadPhotos emits PhotoError on exception',
      build: () {
        when(() => repository.getPhotos()).thenThrow(Exception('network error'));
        return PhotoCubit(repository, settingsRepository);
      },
      act: (c) => c.loadPhotos(),
      expect: () => [isA<PhotoError>()],
    );

    blocTest<PhotoCubit, PhotoState>(
      'advance moves to next photo',
      build: () => PhotoCubit(repository, settingsRepository),
      seed: () => PhotoLoaded(
        photos: [_photo(1, 'https://a.com/1.jpg'), _photo(2, 'https://a.com/2.jpg')],
        currentIndex: 0,
      ),
      act: (c) => c.advance(),
      expect: () => [
        isA<PhotoLoaded>().having((s) => s.currentIndex, 'index', 1),
      ],
    );

    blocTest<PhotoCubit, PhotoState>(
      'advance wraps around to index 0 after the last photo',
      build: () => PhotoCubit(repository, settingsRepository),
      seed: () => PhotoLoaded(
        photos: [_photo(1, 'https://a.com/1.jpg'), _photo(2, 'https://a.com/2.jpg')],
        currentIndex: 1,
      ),
      act: (c) => c.advance(),
      expect: () => [
        isA<PhotoLoaded>().having((s) => s.currentIndex, 'index', 0),
      ],
    );

    blocTest<PhotoCubit, PhotoState>(
      'advance on PhotoLoading state emits no new state',
      build: () => PhotoCubit(repository, settingsRepository),
      seed: () => const PhotoLoading(),
      act: (c) => c.advance(),
      expect: () => [],
    );

    blocTest<PhotoCubit, PhotoState>(
      'advance on PhotoEmpty state emits no new state',
      build: () => PhotoCubit(repository, settingsRepository),
      seed: () => const PhotoEmpty(),
      act: (c) => c.advance(),
      expect: () => [],
    );

    blocTest<PhotoCubit, PhotoState>(
      'advance on PhotoError state emits no new state',
      build: () => PhotoCubit(repository, settingsRepository),
      seed: () => const PhotoError('some error'),
      act: (c) => c.advance(),
      expect: () => [],
    );

    blocTest<PhotoCubit, PhotoState>(
      'loadPhotos shuffles photos and resets to index 0',
      build: () {
        when(() => repository.getPhotos()).thenAnswer(
          (_) async => [_photo(1, 'https://a.com/1.jpg'), _photo(2, 'https://a.com/2.jpg')],
        );
        return PhotoCubit(repository, settingsRepository);
      },
      seed: () => PhotoLoaded(
        photos: [_photo(1, 'https://a.com/1.jpg'), _photo(2, 'https://a.com/2.jpg')],
        currentIndex: 1,
      ),
      act: (c) => c.loadPhotos(),
      expect: () => [
        isA<PhotoLoaded>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having((s) => s.photos.length, 'length', 2),
      ],
    );

    blocTest<PhotoCubit, PhotoState>(
      'setSource switches repository and reloads',
      build: () {
        when(() => repository.getPhotos()).thenAnswer(
          (_) async => [_photo(1, 'https://b.com/photo.jpg')],
        );
        return PhotoCubit(repository, settingsRepository);
      },
      act: (c) async {
        await c.setSource(const PhotoSourceNetwork(urls: ['https://b.com/photo.jpg']));
      },
      expect: () => [
        isA<PhotoLoading>(),
        isA<PhotoLoaded>().having(
          (s) => s.photos.first.imageUrl,
          'imageUrl',
          'https://b.com/photo.jpg',
        ),
      ],
    );

    blocTest<PhotoCubit, PhotoState>(
      'setSource with local directory source loads local files',
      build: () {
        when(() => repository.getPhotos()).thenAnswer((_) async => []);
        return PhotoCubit(repository, settingsRepository);
      },
      act: (c) async {
        await c.setSource(const PhotoSourceLocalDirectory(path: '/tmp/photos'));
      },
      expect: () => [isA<PhotoLoading>(), isA<PhotoEmpty>()],
    );
  });
}
