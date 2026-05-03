import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/clock/widgets/clock_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: child),
    );

void main() {
  group('ClockCard', () {
    testWidgets('renders hours and minutes', (tester) async {
      final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 45));
      await tester.pumpWidget(_wrap(ClockCard(entity: entity)));

      expect(find.text('09:30'), findsOneWidget);
    });

    testWidgets('renders seconds with leading colon', (tester) async {
      final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 45));
      await tester.pumpWidget(_wrap(ClockCard(entity: entity)));

      expect(find.text(':45'), findsOneWidget);
    });

    testWidgets('renders the date line', (tester) async {
      final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 45));
      await tester.pumpWidget(_wrap(ClockCard(entity: entity)));

      expect(find.text('Friday, April 17'), findsOneWidget);
    });

    testWidgets('updates when given a new entity', (tester) async {
      final t0 = DateTime(2026, 4, 17, 9, 30, 0);
      final t1 = DateTime(2026, 4, 17, 9, 30, 1);

      await tester.pumpWidget(_wrap(ClockCard(entity: ClockEntity(t0))));
      expect(find.text('09:30'), findsOneWidget);
      expect(find.text(':00'), findsOneWidget);

      await tester.pumpWidget(_wrap(ClockCard(entity: ClockEntity(t1))));
      expect(find.text(':01'), findsOneWidget);
    });

    testWidgets('renders midnight correctly', (tester) async {
      final entity = ClockEntity(DateTime(2026, 4, 17, 0, 0, 0));
      await tester.pumpWidget(_wrap(ClockCard(entity: entity)));

      expect(find.text('00:00'), findsOneWidget);
      expect(find.text(':00'), findsOneWidget);
    });

    // BUG-03: FittedBox scale must not jitter when the date label length changes.
    testWidgets(
        'ClockCard renders at consistent scale across different date lengths',
        (tester) async {
      const slotSize = Size(480, 270);

      // Short date: "Monday, January 1"
      await tester.pumpWidget(MaterialApp(
        theme: LandfallTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: slotSize.width,
            height: slotSize.height,
            child: ClockCard(entity: ClockEntity(DateTime(2026, 1, 5, 12, 0))),
          ),
        ),
      ));
      // Find the FittedBox that wraps the time row only (not the whole column).
      // After the fix it wraps only the Row, so there's a FittedBox in the tree.
      final fittedBoxFinder = find.byType(FittedBox);
      expect(fittedBoxFinder, findsWidgets);

      // Record the render object's scale for the short date.
      final shortDateBox =
          tester.renderObject(fittedBoxFinder.first) as RenderBox;
      final shortSize = shortDateBox.size;

      // Long date: "Wednesday, September 22"
      await tester.pumpWidget(MaterialApp(
        theme: LandfallTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: slotSize.width,
            height: slotSize.height,
            child: ClockCard(
                entity: ClockEntity(DateTime(2026, 9, 23, 12, 0))),
          ),
        ),
      ));
      await tester.pump();

      final longDateBox =
          tester.renderObject(fittedBoxFinder.first) as RenderBox;
      final longSize = longDateBox.size;

      // The FittedBox that wraps only the time row should be the same width
      // regardless of date label length (within 10% tolerance).
      expect(
        (shortSize.width - longSize.width).abs(),
        lessThan(slotSize.width * 0.10),
        reason: 'time row FittedBox width must not shift when date label changes',
      );
    });

    testWidgets('renders all weekday names correctly', (tester) async {
      // April 14 2026 = Tuesday, verify by checking Wednesday the 15th
      final entity = ClockEntity(DateTime(2026, 4, 15, 12, 0, 0));
      await tester.pumpWidget(_wrap(ClockCard(entity: entity)));
      expect(find.text('Wednesday, April 15'), findsOneWidget);
    });
  });
}
