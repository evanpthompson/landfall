import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/features/companion/widgets/companion_mobile_screen.dart';

Widget _wrap(
  String displayId,
  Future<void> Function(String) onAction, {
  CompanionInfo? info,
}) =>
    MaterialApp(
      home: CompanionMobileScreen(
        displayId: displayId,
        onAction: onAction,
        info: info,
      ),
    );

const _testInfo = CompanionInfo(
  name: 'Lumen',
  rarityLabel: 'Uncommon',
  rarityColor: Color(0xFF66BB6A),
  traits: ['curious', 'gentle'],
  evolutionStage: 0,
  assetCredit: '@changhaoliao via petdex',
);

void main() {
  group('CompanionMobileScreen', () {
    testWidgets('renders Pet, Play, and Feed action buttons', (tester) async {
      await tester.pumpWidget(_wrap('test-display', (_) async {}));
      await tester.pump();

      expect(find.text('Pet'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
    });

    testWidgets('tapping Pet calls onAction with "pet"', (tester) async {
      String? captured;
      await tester.pumpWidget(_wrap('test-display', (k) async => captured = k));
      await tester.pump();

      await tester.tap(find.text('Pet'));
      await tester.pump();

      expect(captured, equals('pet'));
    });

    testWidgets('tapping Play calls onAction with "play"', (tester) async {
      String? captured;
      await tester.pumpWidget(_wrap('test-display', (k) async => captured = k));
      await tester.pump();

      await tester.tap(find.text('Play'));
      await tester.pump();

      expect(captured, equals('play'));
    });

    testWidgets('tapping Feed calls onAction with "feed"', (tester) async {
      String? captured;
      await tester.pumpWidget(_wrap('test-display', (k) async => captured = k));
      await tester.pump();

      await tester.tap(find.text('Feed'));
      await tester.pump();

      expect(captured, equals('feed'));
    });

    testWidgets('shows feedback overlay after button tap', (tester) async {
      await tester.pumpWidget(_wrap('test-display', (_) async {}));
      await tester.pump();

      await tester.tap(find.text('Pet'));
      await tester.pump();

      // Feedback icon appears immediately after tap.
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('feedback disappears after delay', (tester) async {
      await tester.pumpWidget(_wrap('test-display', (_) async {}));
      await tester.pump();

      await tester.tap(find.text('Pet'));
      await tester.pump();
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Advance past the 800ms feedback window. pumpAndSettle is not usable
      // here because the loading spinner animates indefinitely.
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('Info tab shows loading indicator when info is null',
        (tester) async {
      await tester.pumpWidget(_wrap('test-display', (_) async {}));
      await tester.pump();

      await tester.tap(find.text('Info'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('Info tab shows name and rarity when info is provided',
        (tester) async {
      await tester.pumpWidget(
        _wrap('test-display', (_) async {}, info: _testInfo),
      );
      await tester.pump();

      await tester.tap(find.text('Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Lumen'), findsOneWidget);
      expect(find.text('Uncommon'), findsOneWidget);
    });

    testWidgets('Info tab shows traits when info is provided', (tester) async {
      await tester.pumpWidget(
        _wrap('test-display', (_) async {}, info: _testInfo),
      );
      await tester.pump();

      await tester.tap(find.text('Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Curious'), findsOneWidget);
      expect(find.text('Gentle'), findsOneWidget);
    });

    testWidgets('Info tab shows asset credit when provided', (tester) async {
      await tester.pumpWidget(
        _wrap('test-display', (_) async {}, info: _testInfo),
      );
      await tester.pump();

      await tester.tap(find.text('Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('@changhaoliao via petdex'), findsOneWidget);
    });

    testWidgets('golden — renders at phone resolution', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap('test-display', (_) async {}));
      await tester.pump();

      await expectLater(
        find.byType(CompanionMobileScreen),
        matchesGoldenFile('goldens/companion_mobile_screen.png'),
      );
    });
  });
}
