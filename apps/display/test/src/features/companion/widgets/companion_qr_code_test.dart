import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/features/companion/widgets/companion_qr_code.dart';

void main() {
  group('CompanionQrCode', () {
    Future<Size> renderedSize(WidgetTester tester, {required Size parent}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: parent.width,
                height: parent.height,
                child: const CompanionQrCode(
                  url: 'https://example.com/c/abc',
                ),
              ),
            ),
          ),
        ),
      );
      // The outermost sized box of the QR is the white-padded Container.
      // Find the QrImageView's parent Container.
      final container = find.descendant(
        of: find.byType(CompanionQrCode),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == Colors.white,
        ),
      );
      expect(container, findsOneWidget);
      final renderObject = tester.renderObject<RenderBox>(container);
      return renderObject.size;
    }

    testWidgets('scales down to fit a small parent', (tester) async {
      final size = await renderedSize(
        tester,
        parent: const Size(80, 80),
      );
      expect(size.width, 80);
      expect(size.height, 80);
    });

    testWidgets('scales with the parent up to 270 spec ceiling',
        (tester) async {
      final size = await renderedSize(
        tester,
        parent: const Size(220, 220),
      );
      expect(size.width, 220);
      expect(size.height, 220);
    });

    testWidgets('caps at the 270 spec ceiling in a huge parent',
        (tester) async {
      final size = await renderedSize(
        tester,
        parent: const Size(1000, 1000),
      );
      expect(size.width, 270);
      expect(size.height, 270);
    });

    testWidgets('honours an explicit targetSize override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1000,
                height: 1000,
                child: const CompanionQrCode(
                  url: 'https://example.com/c/abc',
                  targetSize: 200,
                ),
              ),
            ),
          ),
        ),
      );
      final container = find.descendant(
        of: find.byType(CompanionQrCode),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == Colors.white,
        ),
      );
      expect(container, findsOneWidget);
      final size = tester.renderObject<RenderBox>(container).size;
      expect(size.width, 200);
    });
  });
}
