import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/features/companion/renderer/sprite_sheet_renderer.dart';

void main() {
  group('SpritePainter.computeDestRect', () {
    test('aspect-fits to canvas when no maxSize is given', () {
      final dst = SpritePainter.computeDestRect(
        canvasSize: const Size(800, 400),
        frameWidth: 192,
        frameHeight: 208,
      );
      // Height is the binding dimension (192/208 < 800/400).
      expect(dst.height, closeTo(400, 0.01));
      expect(dst.width, closeTo(400 * 192 / 208, 0.01));
      // Centred horizontally.
      expect(dst.left, closeTo((800 - dst.width) / 2, 0.01));
      expect(dst.top, closeTo(0, 0.01));
    });

    test('clamps to maxSize and centres within canvas when slot is bigger',
        () {
      final dst = SpritePainter.computeDestRect(
        canvasSize: const Size(960, 540),
        frameWidth: 192,
        frameHeight: 208,
        maxSize: const Size(353, 384),
      );
      // Effective box 353×384; 353/192 < 384/208 so width is the binding
      // axis. Sprite is 353 wide and (353 * 208/192) tall.
      expect(dst.width, closeTo(353, 0.01));
      expect(dst.height, closeTo(353 * 208 / 192, 0.01));
      // Both dimensions must stay inside the maxSize box.
      expect(dst.width, lessThanOrEqualTo(353 + 0.01));
      expect(dst.height, lessThanOrEqualTo(384 + 0.01));
      // Centred within the full 960×540 canvas (not the 353×384 max box).
      expect(dst.left, closeTo((960 - dst.width) / 2, 0.01));
      expect(dst.top, closeTo((540 - dst.height) / 2, 0.01));
    });

    test('ignores maxSize when the canvas is smaller than it', () {
      final dst = SpritePainter.computeDestRect(
        canvasSize: const Size(300, 200),
        frameWidth: 192,
        frameHeight: 208,
        maxSize: const Size(800, 800),
      );
      // Should aspect-fit to the 300×200 canvas, not balloon to 800.
      expect(dst.width, lessThanOrEqualTo(300));
      expect(dst.height, lessThanOrEqualTo(200));
    });

    test('clamps independently on each axis when canvas is wider than tall',
        () {
      // 1920×1080 canvas, 353×384 max — width is canvas-bound to 353 but
      // height-bound aspect-fit might be shorter. Verify the dst never
      // exceeds the maxSize box on either axis.
      final dst = SpritePainter.computeDestRect(
        canvasSize: const Size(1920, 1080),
        frameWidth: 192,
        frameHeight: 208,
        maxSize: const Size(353, 384),
      );
      expect(dst.width, lessThanOrEqualTo(353 + 0.01));
      expect(dst.height, lessThanOrEqualTo(384 + 0.01));
    });
  });
}
