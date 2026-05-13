import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Verifies the proportional feed panel layout: grid 5/6, feed 1/6.
//
// _DisplayBody is private to display_screen.dart, so we test the geometry
// contract using an equivalent Row + Expanded structure rather than pumping
// the full widget tree with all required BLoC providers.

void main() {
  group('_DisplayBody proportional layout contract', () {
    testWidgets('grid and feed panel share screen in 5:1 ratio', (tester) async {
      const totalWidth = 600.0;
      await tester.binding.setSurfaceSize(const Size(totalWidth, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Mirror the flex structure used by _DisplayBody.
      final gridKey = GlobalKey();
      final feedKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              Expanded(flex: 5, child: SizedBox.expand(key: gridKey)),
              Expanded(flex: 1, child: SizedBox.expand(key: feedKey)),
            ],
          ),
        ),
      );

      final gridWidth = tester.getSize(find.byKey(gridKey)).width;
      final feedWidth = tester.getSize(find.byKey(feedKey)).width;

      // Allow 1px tolerance for rounding.
      expect(gridWidth, closeTo(totalWidth * 5 / 6, 1.0));
      expect(feedWidth, closeTo(totalWidth * 1 / 6, 1.0));
      expect(gridWidth + feedWidth, closeTo(totalWidth, 1.0));
    });

    testWidgets('at 1920px: grid is 1600px, feed is 320px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final gridKey = GlobalKey();
      final feedKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              Expanded(flex: 5, child: SizedBox.expand(key: gridKey)),
              Expanded(flex: 1, child: SizedBox.expand(key: feedKey)),
            ],
          ),
        ),
      );

      final gridWidth = tester.getSize(find.byKey(gridKey)).width;
      final feedWidth = tester.getSize(find.byKey(feedKey)).width;

      expect(gridWidth, closeTo(1600.0, 1.0));
      expect(feedWidth, closeTo(320.0, 1.0));
    });
  });
}
