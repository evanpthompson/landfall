import 'package:landfall_shared/landfall_shared.dart';

sealed class PhotoState {
  const PhotoState();
}

final class PhotoLoading extends PhotoState {
  const PhotoLoading();
}

final class PhotoEmpty extends PhotoState {
  const PhotoEmpty();
}

final class PhotoLoaded extends PhotoState {
  const PhotoLoaded({required this.photos, required this.currentIndex});
  final List<PhotoEntity> photos;
  final int currentIndex;

  PhotoEntity get current => photos[currentIndex];

  PhotoLoaded withNextIndex() => PhotoLoaded(
        photos: photos,
        currentIndex: (currentIndex + 1) % photos.length,
      );
}

final class PhotoError extends PhotoState {
  const PhotoError(this.message);
  final String message;
}
