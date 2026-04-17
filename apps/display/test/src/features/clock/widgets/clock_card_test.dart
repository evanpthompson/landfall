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

    testWidgets('renders all weekday names correctly', (tester) async {
      // April 14 2026 = Tuesday, verify by checking Wednesday the 15th
      final entity = ClockEntity(DateTime(2026, 4, 15, 12, 0, 0));
      await tester.pumpWidget(_wrap(ClockCard(entity: entity)));
      expect(find.text('Wednesday, April 15'), findsOneWidget);
    });
  });
}
