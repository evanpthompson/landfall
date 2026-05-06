import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import '../cubit/photo_cubit.dart';

/// Displays a rotating photo slideshow from the configured Drive folder.
///
/// Uses [AnimatedSwitcher] for a crossfade transition between photos.
/// Shows a placeholder when no photos have been configured or synced yet.
///
/// Wrap with [BlocBuilder<PhotoCubit, PhotoState>] or use as a direct child
/// of a BlocBuilder — the internal builder handles all states.
class PhotoFrameCard extends StatelessWidget {
  const PhotoFrameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotoCubit, PhotoState>(
      builder: (context, state) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: switch (state) {
            PhotoLoaded() => _PhotoDisplay(state: state),
            PhotoLoading() => const _Placeholder(label: null),
            PhotoEmpty() => const _Placeholder(label: 'No photos configured'),
            PhotoError() => const _Placeholder(label: 'Photos unavailable'),
          },
        );
      },
    );
  }
}

class _PhotoDisplay extends StatelessWidget {
  const _PhotoDisplay({required this.state});

  final PhotoLoaded state;

  @override
  Widget build(BuildContext context) {
    final photo = state.current;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1200),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _imageFor(photo),
    );
  }

  Widget _imageFor(PhotoEntity photo) {
    final isLocal = photo.imageUrl.startsWith('file://');
    if (isLocal) {
      final path = photo.imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(path),
        key: ValueKey(photo.imageUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _Placeholder(label: 'Photo unavailable'),
      );
    }
    return Image.network(
      photo.imageUrl,
      key: ValueKey(photo.imageUrl),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => const _Placeholder(label: 'Photo unavailable'),
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _Placeholder(label: null);
      },
    );
  }
}

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
