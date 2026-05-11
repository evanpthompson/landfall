import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/photo/local_directory_photo_repository.dart';
import 'package:display/src/data/photo/network_photo_repository.dart';
import 'photo_state.dart';

export 'photo_state.dart';

/// Manages the photo slideshow state for [PhotoFrameCard].
///
/// Call [loadPhotos] on startup and every 30 minutes to pick up newly synced
/// photos. Call [advance] on each slideshow tick (every 45 seconds by default)
/// to move to the next photo. Both calls are driven externally by timers in
/// [DisplayScreen] to keep the cubit side-effect-free.
///
/// Call [setSource] to switch to a different photo source at runtime.
class PhotoCubit extends Cubit<PhotoState> {
  PhotoCubit(PhotoRepository repository)
      : _repository = repository,
        _serverpodRepository = repository,
        _activeSource = const PhotoSourceServerpod(),
        super(const PhotoLoading());

  PhotoRepository _repository;

  /// The original serverpod repository, kept so switching back to it works.
  final PhotoRepository _serverpodRepository;

  /// The currently configured source.
  PhotoSource _activeSource;
  PhotoSource get activeSource => _activeSource;

  /// Switches to a new photo source and reloads.
  Future<void> setSource(PhotoSource source) async {
    _activeSource = source;
    _repository = _repositoryForSource(source);
    emit(const PhotoLoading());
    await loadPhotos();
  }

  PhotoRepository _repositoryForSource(PhotoSource source) =>
      switch (source) {
        PhotoSourceServerpod() => _serverpodRepository,
        PhotoSourceLocalDirectory(:final path) =>
          LocalDirectoryPhotoRepository(path),
        PhotoSourceNetwork(:final urls) => NetworkPhotoRepository(urls),
        PhotoSourceS3() => NetworkPhotoRepository(const []),
      };

  Future<void> loadPhotos() async {
    try {
      final photos = await _repository.getPhotos();
      if (photos.isEmpty) {
        emit(const PhotoEmpty());
      } else {
        final shuffled = List.of(photos)..shuffle(Random());
        emit(PhotoLoaded(photos: shuffled, currentIndex: 0));
      }
    } catch (e, stackTrace) {
      dev.log(
        'loadPhotos error: $e',
        name: 'landfall.photo',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PhotoError(e.toString()));
    }
  }

  /// Advances to the next photo, wrapping around at the end of the list.
  ///
  /// No-ops if not currently in [PhotoLoaded] state.
  void advance() {
    final current = state;
    if (current is PhotoLoaded) {
      emit(current.withNextIndex());
    }
  }
}
