import 'dart:convert';
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
/// Call [setSource] to switch to a different photo source at runtime. The
/// chosen source is persisted via [DisplaySettingsRepository] and restored
/// on the next app launch.
class PhotoCubit extends Cubit<PhotoState> {
  PhotoCubit(PhotoRepository repository, this._settingsRepository)
      : _repository = repository,
        _serverpodRepository = repository,
        _activeSource = const PhotoSourceServerpod(),
        super(const PhotoLoading());

  PhotoRepository _repository;

  /// The original serverpod repository, kept so switching back to it works.
  final PhotoRepository _serverpodRepository;

  final DisplaySettingsRepository _settingsRepository;

  /// The currently configured source.
  PhotoSource _activeSource;
  PhotoSource get activeSource => _activeSource;

  /// Loads the persisted source from settings, then loads photos.
  ///
  /// Call once at startup before the first [loadPhotos] tick.
  Future<void> initSource() async {
    try {
      final settings = await _settingsRepository.getSettings();
      if (settings.photoSourceJson != null) {
        final json = jsonDecode(settings.photoSourceJson!) as Map<String, dynamic>;
        final source = PhotoSource.fromJson(json);
        _activeSource = source;
        _repository = _repositoryForSource(source);
      }
    } catch (e) {
      dev.log('initSource: failed to restore source: $e', name: 'landfall.photo');
    }
    await loadPhotos();
  }

  /// Switches to a new photo source, persists it, and reloads.
  Future<void> setSource(PhotoSource source) async {
    _activeSource = source;
    _repository = _repositoryForSource(source);
    emit(const PhotoLoading());
    try {
      final settings = await _settingsRepository.getSettings();
      await _settingsRepository.saveSettings(
        settings.copyWith(photoSourceJson: jsonEncode(source.toJson())),
      );
    } catch (e) {
      dev.log('setSource: failed to persist source: $e', name: 'landfall.photo');
    }
    await loadPhotos();
  }

  /// Applies a photo source that arrived via remote settings sync.
  ///
  /// Called from the `settings.changed` action path so a source chosen in the
  /// web companion takes effect live, without restarting the app. Unlike
  /// [setSource] this does **not** persist — [DisplaySettingsSyncService] has
  /// already written the settings locally before invoking the apply callback.
  ///
  /// No-ops when [DisplaySettings.photoSourceJson] is null/blank/malformed, or
  /// when the encoded source already equals [activeSource] (avoids a redundant
  /// reload flash on unrelated settings changes such as a dim-level tweak).
  Future<void> applyRemoteSource(DisplaySettings settings) async {
    final json = settings.photoSourceJson;
    if (json == null || json.isEmpty) return;

    final PhotoSource source;
    try {
      source = PhotoSource.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      dev.log(
        'applyRemoteSource: failed to parse source: $e',
        name: 'landfall.photo',
      );
      return;
    }

    if (source == _activeSource) return;

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
