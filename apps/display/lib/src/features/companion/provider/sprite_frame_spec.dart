import 'package:flutter/foundation.dart';

@immutable
class SpriteFrameSpec {
  const SpriteFrameSpec({
    required this.row,
    required this.frameCount,
    required this.fps,
    this.loops = true,
  });

  final int row;
  final int frameCount;
  final int fps;
  final bool loops;

  @override
  bool operator ==(Object other) =>
      other is SpriteFrameSpec &&
      row == other.row &&
      frameCount == other.frameCount &&
      fps == other.fps &&
      loops == other.loops;

  @override
  int get hashCode => Object.hash(row, frameCount, fps, loops);
}
