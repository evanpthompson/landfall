import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';

import '../provider/companion_provider.dart';

/// Companion sprite ceiling per `docs/companion_card_design.md` — 192×208
/// source frame at ×1.5–2× upscale → ~353×384 logical px on 1080p. Every
/// surface that renders the companion (dashboard, mobile companion page,
/// future variants) caps to this so the creature never over-magnifies and
/// always leaves room for the QR + meta around it.
const Size kCompanionSpriteMaxSize = Size(353, 384);

class SpriteSheetCompanionRenderer {
  SpriteSheetCompanionRenderer({
    required this.provider,
    required TickerProvider vsync,
  }) {
    _controller = AnimationController(vsync: vsync, duration: const Duration(seconds: 1));
    // Idle animation starts as soon as the image loads.
  }

  final SpriteSheetProvider provider;
  late final AnimationController _controller;

  ui.Image? _image;
  CompanionAnimationState _currentState = CompanionAnimationState.idle;
  bool _disposed = false;

  Future<void> load(AssetBundle bundle, String assetKey) async {
    final data = await bundle.load(assetKey);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!_disposed) {
      _image = frame.image;
      _applyState(CompanionAnimationState.idle);
    }
  }

  void triggerState(CompanionAnimationState requested) {
    if (_disposed) return;
    final resolved = provider.resolve(requested);
    _applyState(resolved);
  }

  void _applyState(CompanionAnimationState state) {
    final spec = provider.specFor(state) ??
        provider.specFor(CompanionAnimationState.idle)!;
    _currentState = state;

    final duration = Duration(
      milliseconds: ((1000.0 / spec.fps) * spec.frameCount).round(),
    );
    _controller.stop();
    _controller.duration = duration;

    if (spec.loops) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0).then((_) {
        if (!_disposed) _applyState(CompanionAnimationState.idle);
      });
    }
  }

  // Returns an animating Widget. Pass [maxSize] to cap the sprite at design
  // spec dimensions inside larger card slots — the sprite then aspect-fits to
  // min(slot, maxSize) and centres within the slot. Omitting maxSize keeps
  // the previous behaviour of filling the slot.
  Widget buildView({Size? maxSize}) =>
      _SpriteView(renderer: this, maxSize: maxSize);

  void dispose() {
    _disposed = true;
    _controller.dispose();
    _image?.dispose();
  }

  // Internal accessors for _SpriteView.
  ui.Image? get _currentImage => _image;
  AnimationController get _animationController => _controller;
  CompanionAnimationState get _state => _currentState;
}

// ---------------------------------------------------------------------------

class _SpriteView extends StatelessWidget {
  const _SpriteView({required this.renderer, this.maxSize});

  final SpriteSheetCompanionRenderer renderer;
  final Size? maxSize;

  @override
  Widget build(BuildContext context) {
    final image = renderer._currentImage;
    if (image == null) {
      return const SizedBox.expand();
    }
    return AnimatedBuilder(
      animation: renderer._animationController,
      builder: (_, _) {
        final spec = renderer.provider.specFor(renderer._state) ??
            renderer.provider.specFor(CompanionAnimationState.idle)!;
        final t = renderer._animationController.value;
        final frame = (t * spec.frameCount).floor().clamp(0, spec.frameCount - 1);
        return CustomPaint(
          painter: SpritePainter(
            image: image,
            stateRow: spec.row,
            frame: frame,
            frameWidth: renderer.provider.frameWidth,
            frameHeight: renderer.provider.frameHeight,
            maxSize: maxSize,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class SpritePainter extends CustomPainter {
  const SpritePainter({
    required this.image,
    required this.stateRow,
    required this.frame,
    required this.frameWidth,
    required this.frameHeight,
    this.maxSize,
  });

  final ui.Image image;
  final int stateRow;
  final int frame;
  final double frameWidth;
  final double frameHeight;

  /// Caps the painted sprite at this size. When set, the sprite aspect-fits
  /// to `min(canvasSize, maxSize)` and is centred in the canvas — leaving
  /// empty space around the sprite that the parent widget can use.
  final Size? maxSize;

  /// Aspect-fits the source frame inside `min(canvasSize, maxSize)` and
  /// centres the result within `canvasSize`. Pure function — exposed for
  /// unit tests; the painter's `paint()` delegates here.
  static Rect computeDestRect({
    required Size canvasSize,
    required double frameWidth,
    required double frameHeight,
    Size? maxSize,
  }) {
    final effectiveW = maxSize == null
        ? canvasSize.width
        : (canvasSize.width < maxSize.width ? canvasSize.width : maxSize.width);
    final effectiveH = maxSize == null
        ? canvasSize.height
        : (canvasSize.height < maxSize.height ? canvasSize.height : maxSize.height);
    final scaleX = effectiveW / frameWidth;
    final scaleY = effectiveH / frameHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dstW = frameWidth * scale;
    final dstH = frameHeight * scale;
    final dx = (canvasSize.width - dstW) / 2;
    final dy = (canvasSize.height - dstH) / 2;
    return Rect.fromLTWH(dx, dy, dstW, dstH);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      frame * frameWidth,
      stateRow * frameHeight,
      frameWidth,
      frameHeight,
    );
    final dst = computeDestRect(
      canvasSize: size,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      maxSize: maxSize,
    );

    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(SpritePainter old) =>
      old.frame != frame ||
      old.stateRow != stateRow ||
      old.image != image ||
      old.maxSize != maxSize;
}
