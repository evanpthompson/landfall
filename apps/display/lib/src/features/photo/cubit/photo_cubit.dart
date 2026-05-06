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
  PhotoCubit(this._repository) : super(const PhotoLoading());

  PhotoRepository _repository;

  /// Switches to a new photo source and reloads.
  Future<void> setSource(PhotoSource source) async {
    _repository = _repositoryForSource(source);
    emit(const PhotoLoading());
    await loadPhotos();
  }

  static PhotoRepository _repositoryForSource(PhotoSource source) =>
      switch (source) {
        PhotoSourceServerpod() => throw UnimplementedError(
            'PhotoSourceServerpod requires the original repository — '
            'pass it at construction time instead',
          ),
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
        final current = state;
        // Preserve the current index when reloading so the display doesn't
        // jump back to photo 0 on every 30-minute refresh.
        final index = (current is PhotoLoaded && current.currentIndex < photos.length)
            ? current.currentIndex
            : 0;
        emit(PhotoLoaded(photos: photos, currentIndex: index));
      }
    } catch (e) {
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
