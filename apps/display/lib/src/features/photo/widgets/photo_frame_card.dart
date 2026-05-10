import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import '../cubit/photo_cubit.dart';
import 'photo_transition.dart';

/// Displays a rotating photo slideshow from the configured Drive folder.
///
/// Reads [LandfallThemeTokens.photoTransition] from the active theme to select
/// the transition style. The Ken Burns (drift) effect animates the displayed
/// image while it is on screen; other styles animate the switch itself.
///
/// Preloads the next two photos into Flutter's image cache so transitions are
/// instantaneous even over the local network.
class PhotoFrameCard extends StatelessWidget {
  const PhotoFrameCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    final style = PhotoTransitionStyle.fromString(tokens.photoTransition);

    return BlocBuilder<PhotoCubit, PhotoState>(
      builder: (context, state) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: switch (state) {
            PhotoLoaded() => _PhotoDisplay(state: state, style: style),
            PhotoLoading() => const _Placeholder(label: null),
            PhotoEmpty() => const _Placeholder(label: 'No photos configured'),
            PhotoError() => const _Placeholder(label: 'Photos unavailable'),
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Photo display — handles preloading, transition selection, Ken Burns
// ---------------------------------------------------------------------------

class _PhotoDisplay extends StatefulWidget {
  const _PhotoDisplay({required this.state, required this.style});

  final PhotoLoaded state;
  final PhotoTransitionStyle style;

  @override
  State<_PhotoDisplay> createState() => _PhotoDisplayState();
}

class _PhotoDisplayState extends State<_PhotoDisplay> {
  /// The concrete style active for the *current* photo.
  late PhotoTransitionStyle _activeStyle;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.state.current;
    final cubit = context.read<PhotoCubit>();

    _preloadNext(context, widget.state);

    final duration = _transitionDuration(widget.state);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: PhotoTransitions.builderFor(_activeStyle),
      child: _imageFor(photo, cubit),
    );
  }

  // Preload the next two photos so the transition is instant.
  void _preloadNext(BuildContext context, PhotoLoaded state) {
    for (var i = 1; i <= 2; i++) {
      final idx = (state.currentIndex + i) % state.photos.length;
      final p = state.photos[idx];
      if (p.imageUrl.startsWith('file://')) {
        final path = p.imageUrl.replaceFirst('file://', '');
        precacheImage(FileImage(File(path)), context, onError: (_, _) {});
      } else {
        precacheImage(NetworkImage(p.imageUrl), context, onError: (_, _) {});
      }
    }
  }

  Duration _transitionDuration(PhotoLoaded state) {
    // Could read animationSpeed from tokens here in future; hardcoded for now.
    return const Duration(milliseconds: 1200);
  }

  Widget _imageFor(PhotoEntity photo, PhotoCubit cubit) {
    void onError(Object error) {
      dev.log(
        'Failed to load photo: ${photo.imageUrl}',
        name: 'landfall.photo',
        error: error,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => cubit.advance());
    }

    final imageWidget = _rawImage(photo, onError);

    // Wrap in Ken Burns for the drift style.
    if (_activeStyle == PhotoTransitionStyle.drift) {
      return KenBurnsWidget(
        key: ValueKey('kb_${photo.id}'),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _rawImage(PhotoEntity photo, void Function(Object) onError) {
    if (photo.imageUrl.startsWith('file://')) {
      final path = photo.imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(path),
        key: ValueKey(photo.imageUrl),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, error, st) {
          onError(error);
          return const _Placeholder(label: null);
        },
      );
    }
    return Image.network(
      photo.imageUrl,
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
