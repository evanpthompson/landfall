import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/clock/widgets/clock_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: SizedBox(width: 480, height: 270, child: child)),
    );

void main() {
  group('ClockCard displayConfig', () {
    group('hourFormat', () {
      testWidgets('24h format renders zero-padded 24-hour time (default)',
          (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 0));
        await tester.pumpWidget(
          _wrap(ClockCard(entity: entity, displayConfig: const {})),
        );
        expect(find.text('09:30'), findsOneWidget);
      });

      testWidgets('12h format renders non-padded hour with AM suffix',
          (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 0));
        await tester.pumpWidget(
          _wrap(ClockCard(
            entity: entity,
            displayConfig: const {'hourFormat': '12'},
          )),
        );
        expect(find.text('9:30'), findsOneWidget);
        expect(find.text('AM'), findsOneWidget);
      });

      testWidgets('12h format renders PM for afternoon hours', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 13, 45, 0));
        await tester.pumpWidget(
          _wrap(ClockCard(
            entity: entity,
            displayConfig: const {'hourFormat': '12'},
          )),
        );
        expect(find.text('1:45'), findsOneWidget);
        expect(find.text('PM'), findsOneWidget);
      });

      testWidgets('12h format renders 12 noon as 12:00 PM', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 12, 0, 0));
        await tester.pumpWidget(
          _wrap(ClockCard(
            entity: entity,
            displayConfig: const {'hourFormat': '12'},
          )),
        );
        expect(find.text('12:00'), findsOneWidget);
        expect(find.text('PM'), findsOneWidget);
      });

      testWidgets('12h format renders midnight as 12:00 AM', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 0, 0, 0));
        await tester.pumpWidget(
          _wrap(ClockCard(
            entity: entity,
            displayConfig: const {'hourFormat': '12'},
          )),
        );
        expect(find.text('12:00'), findsOneWidget);
        expect(find.text('AM'), findsOneWidget);
      });
    });

    group('showSeconds', () {
      testWidgets('seconds visible by default', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 45));
        await tester.pumpWidget(
          _wrap(ClockCard(entity: entity, displayConfig: const {})),
        );
        expect(find.text(':45'), findsOneWidget);
      });

      testWidgets('showSeconds=false hides the seconds text', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 45));
        await tester.pumpWidget(
          _wrap(ClockCard(
            entity: entity,
            displayConfig: const {'showSeconds': false},
          )),
        );
        expect(find.text(':45'), findsNothing);
      });

      testWidgets('showSeconds=true explicitly shows seconds', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 7));
        await tester.pumpWidget(
          _wrap(ClockCard(
            entity: entity,
            displayConfig: const {'showSeconds': true},
          )),
        );
        expect(find.text(':07'), findsOneWidget);
      });
    });

    group('showDate', () {
      testWidgets('date line visible by default', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 0));
        await tester.pumpWidget(
          _wrap(ClockCard(entity: entity, displayConfig: const {})),
        );
        expect(find.text('Friday, April 17'), findsOneWidget);
      });

      testWidgets('showDate=false hides the date line', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 0));
        await tester.pumpWidget(
          _wrap(ClockCard(
            entity: entity,
            displayConfig: const {'showDate': false},
          )),
        );
        expect(find.text('Friday, April 17'), findsNothing);
      });

      testWidgets('showDate=true explicitly shows date', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 0));
        await tester.pumpWidget(
          _wrap(ClockCard(
            entity: entity,
            displayConfig: const {'showDate': true},
          )),
        );
        expect(find.text('Friday, April 17'), findsOneWidget);
      });
    });

    group('combined configs', () {
      testWidgets('12h + no seconds + no date', (tester) async {
        final entity = ClockEntity(DateTime(2026, 4, 17, 14, 5, 30));
        await tester.pumpWidget(
          _wrap(ClockCard(
            entity: entity,
            displayConfig: const {
              'hourFormat': '12',
              'showSeconds': false,
              'showDate': false,
            },
          )),
        );
        expect(find.text('2:05'), findsOneWidget);
        expect(find.text('PM'), findsOneWidget);
        expect(find.textContaining(':30'), findsNothing);
        expect(find.textContaining('April'), findsNothing);
      });
    });
  });
}
