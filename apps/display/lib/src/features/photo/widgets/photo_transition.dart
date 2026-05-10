import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Style enum
// ---------------------------------------------------------------------------

enum PhotoTransitionStyle {
  fade,
  zoom,
  slide,
  drift,   // Ken Burns: slow pan/zoom while displayed, crossfade on switch
  random;  // Picks randomly from the four concrete styles above

  static final _rng = Random();
  static const _concrete = [fade, zoom, slide, drift];

  /// Returns a concrete (non-random) style. If `this` is [random], picks one.
  PhotoTransitionStyle resolve() =>
      this == random ? _concrete[_rng.nextInt(_concrete.length)] : this;

  static PhotoTransitionStyle fromString(String? s) => switch (s) {
        'zoom' => zoom,
        'slide' => slide,
        'drift' => drift,
        'random' => random,
        _ => fade,
      };
}

// ---------------------------------------------------------------------------
// Transition builder
// ---------------------------------------------------------------------------

class PhotoTransitions {
  const PhotoTransitions._();

  /// Returns the [AnimatedSwitcher] transitionBuilder for [style].
  /// [style] must be concrete (not [PhotoTransitionStyle.random]).
  static AnimatedSwitcherTransitionBuilder builderFor(
          PhotoTransitionStyle style) =>
      switch (style) {
        PhotoTransitionStyle.fade ||
        PhotoTransitionStyle.drift ||
        PhotoTransitionStyle.random =>
          _fade,
        PhotoTransitionStyle.zoom => _zoom,
        PhotoTransitionStyle.slide => _slide,
      };

  static Widget _fade(Widget child, Animation<double> animation) =>
      FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );

  static Widget _zoom(Widget child, Animation<double> animation) {
    final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }

  static Widget _slide(Widget child, Animation<double> animation) {
    final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ken Burns widget  (drift style)
// ---------------------------------------------------------------------------

/// Wraps a child in a slow, randomly-seeded pan-and-zoom animation for the
/// duration of a photo's display interval.
///
/// Each instance picks random start/end scale and translation values so no
/// two photos move the same way.
class KenBurnsWidget extends StatefulWidget {
  const KenBurnsWidget({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 50),
  });

  final Widget child;

  /// How long the motion lasts. Set slightly longer than the slideshow
  /// interval so the photo is still moving when it fades out.
  final Duration duration;

  @override
  State<KenBurnsWidget> createState() => _KenBurnsWidgetState();
}

class _KenBurnsWidgetState extends State<KenBurnsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final _KenBurnsParams _params;

  @override
  void initState() {
    super.initState();
    _params = _KenBurnsParams.random();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        final scale = lerpDouble(_params.startScale, _params.endScale, t)!;
        final dx = lerpDouble(_params.startX, _params.endX, t)!;
        final dy = lerpDouble(_params.startY, _params.endY, t)!;
        return Transform(
          transform: Matrix4.identity()
            ..translateByDouble(dx, dy, 0, 1)
            ..scaleByDouble(scale, scale, 1, 1),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _KenBurnsParams {
  const _KenBurnsParams({
    required this.startScale,
    required this.endScale,
    required this.startX,
    required this.endX,
    required this.startY,
    required this.endY,
  });

  final double startScale;
  final double endScale;
  final double startX;
  final double endX;
  final double startY;
  final double endY;

  factory _KenBurnsParams.random() {
    final rng = Random();
    // Scale drifts gently: 1.00 → 1.07 or 1.07 → 1.00
    final zoomIn = rng.nextBool();
    final lo = 1.0 + rng.nextDouble() * 0.03;
    final hi = lo + 0.04 + rng.nextDouble() * 0.03;
    // Translate up to ±20px horizontally, ±14px vertically
    return _KenBurnsParams(
      startScale: zoomIn ? lo : hi,
      endScale: zoomIn ? hi : lo,
      startX: (rng.nextDouble() - 0.5) * 40,
      endX: (rng.nextDouble() - 0.5) * 40,
      startY: (rng.nextDouble() - 0.5) * 28,
      endY: (rng.nextDouble() - 0.5) * 28,
    );
  }
}
