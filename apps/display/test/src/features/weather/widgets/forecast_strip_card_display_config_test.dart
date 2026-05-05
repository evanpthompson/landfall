import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/weather/widgets/forecast_strip_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: SizedBox(width: 800, height: 150, child: child)),
    );

ForecastDayEntity _day(DateTime date) => ForecastDayEntity(
      date: date,
      minTempC: 10.0,
      maxTempC: 20.0,
      condition: 'Clear sky',
      iconCode: '01d',
    );

final _fiveDays = [
  _day(DateTime.utc(2026, 4, 20)), // MON
  _day(DateTime.utc(2026, 4, 21)), // TUE
  _day(DateTime.utc(2026, 4, 22)), // WED
  _day(DateTime.utc(2026, 4, 23)), // THU
  _day(DateTime.utc(2026, 4, 24)), // FRI
];

void main() {
  group('ForecastStripCard displayConfig', () {
    group('days', () {
      testWidgets('shows all 5 days by default', (tester) async {
        await tester.pumpWidget(
          _wrap(ForecastStripCard(
            forecast: _fiveDays,
            displayConfig: const {},
          )),
        );
        expect(find.text('MON'), findsOneWidget);
        expect(find.text('FRI'), findsOneWidget);
      });

      testWidgets('days=5 shows all 5 columns', (tester) async {
        await tester.pumpWidget(
          _wrap(ForecastStripCard(
            forecast: _fiveDays,
            displayConfig: const {'days': 5},
          )),
        );
        expect(find.text('MON'), findsOneWidget);
        expect(find.text('TUE'), findsOneWidget);
        expect(find.text('WED'), findsOneWidget);
        expect(find.text('THU'), findsOneWidget);
        expect(find.text('FRI'), findsOneWidget);
      });

      testWidgets('days=3 shows only first 3 columns', (tester) async {
        await tester.pumpWidget(
          _wrap(ForecastStripCard(
            forecast: _fiveDays,
            displayConfig: const {'days': 3},
          )),
        );
        expect(find.text('MON'), findsOneWidget);
        expect(find.text('TUE'), findsOneWidget);
        expect(find.text('WED'), findsOneWidget);
        expect(find.text('THU'), findsNothing);
        expect(find.text('FRI'), findsNothing);
      });

      testWidgets('days=1 shows only first column', (tester) async {
        await tester.pumpWidget(
          _wrap(ForecastStripCard(
            forecast: _fiveDays,
            displayConfig: const {'days': 1},
          )),
        );
        expect(find.text('MON'), findsOneWidget);
        expect(find.text('TUE'), findsNothing);
        expect(find.text('WED'), findsNothing);
      });

      testWidgets('days config does not exceed available forecast length',
          (tester) async {
        // Only 2 days in forecast, days=5 — must not crash
        final twodays = _fiveDays.take(2).toList();
        await tester.pumpWidget(
          _wrap(ForecastStripCard(
            forecast: twodays,
            displayConfig: const {'days': 5},
          )),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('MON'), findsOneWidget);
        expect(find.text('TUE'), findsOneWidget);
        expect(find.text('WED'), findsNothing);
      });
    });
  });
}
