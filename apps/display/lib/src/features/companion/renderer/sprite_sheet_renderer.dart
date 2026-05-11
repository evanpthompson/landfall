import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';

import '../provider/companion_provider.dart';

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

  // Returns an animating Widget. Call inside an AnimatedBuilder or let the
  // SpriteSheetAnimationView handle it.
  Widget buildView() => _SpriteView(renderer: this);

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
  const _SpriteView({required this.renderer});

  final SpriteSheetCompanionRenderer renderer;

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
          painter: _SpritePainter(
            image: image,
            stateRow: spec.row,
            frame: frame,
            frameWidth: renderer.provider.frameWidth,
            frameHeight: renderer.provider.frameHeight,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SpritePainter extends CustomPainter {
  const _SpritePainter({
    required this.image,
    required this.stateRow,
    required this.frame,
    required this.frameWidth,
    required this.frameHeight,
  });

  final ui.Image image;
  final int stateRow;
  final int frame;
  final double frameWidth;
  final double frameHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      frame * frameWidth,
      stateRow * frameHeight,
      frameWidth,
      frameHeight,
    );

    // Aspect-fit: scale uniformly so the frame fills as much of the card as
    // possible without cropping, then center the result.
    final scaleX = size.width / frameWidth;
    final scaleY = size.height / frameHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dstW = frameWidth * scale;
    final dstH = frameHeight * scale;
    final dx = (size.width - dstW) / 2;
    final dy = (size.height - dstH) / 2;
    final dst = Rect.fromLTWH(dx, dy, dstW, dstH);

    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.frame != frame || old.stateRow != stateRow || old.image != image;
}
