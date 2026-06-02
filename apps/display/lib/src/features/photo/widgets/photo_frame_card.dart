import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import '../cubit/photo_cubit.dart';
import 'photo_transition.dart';

/// Hard ceiling on the longest decoded edge, in device pixels.
///
/// A 1080p (or even 4K) panel never needs more than this to show a photo
/// crisply, but a full-resolution phone photo (12 MP → 4032×3024) decodes to
/// a ~48 MB RGBA GPU texture. On the Raspberry Pi those textures come out of
/// the CMA pool, which has no IOMMU fallback — a handful of full-res photos
/// exhaust it and `dmabuf` export starts failing, which is what stops the
/// companion sprite (and everything else image-based) from rendering. Capping
/// the decode at this edge bounds each texture to ~14 MB worst case.
const int kMaxPhotoDecodeEdge = 1920;

/// The Ken Burns (drift) transition zooms in up to ~1.3×, so decode a little
/// above the slot size to keep the zoomed image from looking soft.
const double _kKenBurnsHeadroom = 1.3;

/// How long after a photo leaves the screen before its texture is evicted from
/// the image cache. Must outlast the cross-fade so we never drop a texture
/// that is still painting.
const Duration _kEvictionDelay = Duration(milliseconds: 2000);

/// Longest decoded edge (device px) for a photo filling a slot of
/// [slotLogicalSize] at [devicePixelRatio], clamped to `[1, kMaxPhotoDecodeEdge]`.
///
/// Unbounded constraints (a slot laid out with infinite width/height) fall
/// back to the cap rather than overflowing.
@visibleForTesting
int photoDecodeEdge(Size slotLogicalSize, double devicePixelRatio) {
  final longestLogical =
      math.max(slotLogicalSize.width, slotLogicalSize.height);
  // Unbounded constraints can't be sized to — fall back to the cap.
  if (!longestLogical.isFinite) return kMaxPhotoDecodeEdge;
  final px = (longestLogical * devicePixelRatio * _kKenBurnsHeadroom).ceil();
  // clamp's lower bound of 1 also normalises a zero- or negative-size slot.
  return px.clamp(1, kMaxPhotoDecodeEdge);
}

/// Builds the [ImageProvider] for [photo], downsampled to fit within an
/// [decodeEdge]×[decodeEdge] box (aspect ratio preserved, never upscaled).
///
/// `file://` URLs resolve to a [FileImage]; everything else to a
/// [NetworkImage]. The same call reconstructs the key used for eviction, so it
/// must be deterministic for a given photo + edge.
@visibleForTesting
ImageProvider photoProvider(PhotoEntity photo, int decodeEdge) {
  final ImageProvider base = photo.imageUrl.startsWith('file://')
      ? FileImage(File(photo.imageUrl.replaceFirst('file://', '')))
      : NetworkImage(photo.imageUrl);
  return ResizeImage(
    base,
    width: decodeEdge,
    height: decodeEdge,
    policy: ResizeImagePolicy.fit,
    allowUpscaling: false,
  );
}

/// Displays a rotating photo slideshow from the configured Drive folder.
///
/// Reads [LandfallThemeTokens.photoTransition] from the active theme to select
/// the transition style. The Ken Burns (drift) effect animates the displayed
/// image while it is on screen; other styles animate the switch itself.
///
/// Photos are decoded at slot resolution (see [photoDecodeEdge]) and evicted
/// from the image cache once they leave the screen, so the GPU texture
/// footprint stays bounded on memory-constrained devices like the Pi.
class PhotoFrameCard extends StatelessWidget {
  const PhotoFrameCard({super.key, this.evictProvider});

  /// Test seam for the cache eviction performed when a photo leaves the
  /// screen. Defaults to evicting from Flutter's global image cache.
  final void Function(ImageProvider provider)? evictProvider;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    final style = PhotoTransitionStyle.fromString(tokens.photoTransition);

    return BlocBuilder<PhotoCubit, PhotoState>(
      builder: (context, state) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(tokens.cardRadius.toDouble()),
          child: switch (state) {
            PhotoLoaded() => _PhotoDisplay(
                state: state,
                style: style,
                evictProvider: evictProvider ?? _defaultEvict,
              ),
            PhotoLoading() => const _Placeholder(label: null),
            PhotoEmpty() => const _Placeholder(label: 'No photos configured'),
            PhotoError() => const _Placeholder(label: 'Photos unavailable'),
          },
        );
      },
    );
  }

  static void _defaultEvict(ImageProvider provider) {
    PaintingBinding.instance.imageCache.evict(provider);
  }
}

// ---------------------------------------------------------------------------
// Photo display — handles preloading, transition selection, Ken Burns
// ---------------------------------------------------------------------------

class _PhotoDisplay extends StatefulWidget {
  const _PhotoDisplay({
    required this.state,
    required this.style,
    required this.evictProvider,
  });

  final PhotoLoaded state;
  final PhotoTransitionStyle style;
  final void Function(ImageProvider provider) evictProvider;

  @override
  State<_PhotoDisplay> createState() => _PhotoDisplayState();
}

class _PhotoDisplayState extends State<_PhotoDisplay> {
  /// The concrete style active for the *current* photo.
  late PhotoTransitionStyle _activeStyle;

  /// Decode edge from the most recent build. Captured so [didUpdateWidget] can
  /// reconstruct the outgoing photo's provider key for eviction without its
  /// own access to the layout constraints.
  int _lastEdge = kMaxPhotoDecodeEdge;

  /// Eviction timers awaiting the end of a transition. Held so they can be
  /// cancelled on dispose rather than firing against an unmounted state.
  final List<Timer> _pendingEvictions = [];

  @override
  void initState() {
    super.initState();
    _activeStyle = widget.style.resolve();
  }

  @override
  void didUpdateWidget(_PhotoDisplay old) {
    super.didUpdateWidget(old);
    final photoChanged = widget.state.current.id != old.state.current.id;
    if (photoChanged) {
      // Re-resolve style on each photo change so random picks vary.
      _activeStyle = widget.style.resolve();
      // The photo that just left the screen can be released once the
      // cross-fade finishes — it is no longer painted and not pre-cached.
      _scheduleEviction(old.state.current);
    }
  }

  @override
  void dispose() {
    for (final timer in _pendingEvictions) {
      timer.cancel();
    }
    _pendingEvictions.clear();
    super.dispose();
  }

  void _scheduleEviction(PhotoEntity outgoing) {
    final provider = photoProvider(outgoing, _lastEdge);
    late final Timer timer;
    timer = Timer(_kEvictionDelay, () {
      _pendingEvictions.remove(timer);
      if (!mounted) return;
      widget.evictProvider(provider);
    });
    _pendingEvictions.add(timer);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.state.current;
    final cubit = context.read<PhotoCubit>();
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final edge = photoDecodeEdge(constraints.biggest, dpr);
        _lastEdge = edge;

        _preloadNext(context, widget.state, edge);

        final duration = _transitionDuration(widget.state);

        return AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: PhotoTransitions.builderFor(_activeStyle),
          child: _imageFor(photo, cubit, edge),
        );
      },
    );
  }

  // Preload the next two photos so the transition is instant. Decoded at the
  // same bounded edge as the on-screen photo so pre-caching cannot blow past
  // the memory budget.
  void _preloadNext(BuildContext context, PhotoLoaded state, int edge) {
    for (var i = 1; i <= 2; i++) {
      final idx = (state.currentIndex + i) % state.photos.length;
      precacheImage(
        photoProvider(state.photos[idx], edge),
        context,
        onError: (_, _) {},
      );
    }
  }

  Duration _transitionDuration(PhotoLoaded state) {
    // Could read animationSpeed from tokens here in future; hardcoded for now.
    return const Duration(milliseconds: 1200);
  }

  Widget _imageFor(PhotoEntity photo, PhotoCubit cubit, int edge) {
    void onError(Object error) {
      dev.log(
        'Failed to load photo: ${photo.imageUrl}',
        name: 'landfall.photo',
        error: error,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => cubit.advance());
    }

    final imageWidget = _rawImage(photo, edge, onError);

    // Wrap in Ken Burns for the drift style.
    if (_activeStyle == PhotoTransitionStyle.drift) {
      return KenBurnsWidget(
        key: ValueKey('kb_${photo.id}'),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _rawImage(
    PhotoEntity photo,
    int edge,
    void Function(Object) onError,
  ) {
    return Image(
      image: photoProvider(photo, edge),
      key: ValueKey(photo.imageUrl),
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, error, st) {
        onError(error);
        return const _Placeholder(label: null);
      },
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const _Placeholder(label: null);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder
// ---------------------------------------------------------------------------

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String? label;

  static const _photoSlotColor = Color(0xFFBF5AF2);

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    return ColoredBox(
      color: tokenColor(tokens.cardFill),
      child: Center(
        child: label != null
            ? Text(
                label!,
                style: const TextStyle(
                  color: _photoSlotColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
