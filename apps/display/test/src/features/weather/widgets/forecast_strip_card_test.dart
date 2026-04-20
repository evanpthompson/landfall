import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/weather/widgets/forecast_strip_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: SizedBox(width: 800, height: 150, child: child)),
    );

ForecastDayEntity _day({
  required DateTime date,
  double minTempC = 10.0,
  double maxTempC = 20.0,
  String condition = 'Clear sky',
  String iconCode = '01d',
}) =>
    ForecastDayEntity(
      date: date,
      minTempC: minTempC,
      maxTempC: maxTempC,
      condition: condition,
      iconCode: iconCode,
    );

void main() {
  group('ForecastStripCard', () {
    final days = [
      _day(date: DateTime.utc(2026, 4, 20), minTempC: 10, maxTempC: 22), // MON
      _day(date: DateTime.utc(2026, 4, 21), minTempC: 12, maxTempC: 19), // TUE
      _day(date: DateTime.utc(2026, 4, 22), minTempC: 8, maxTempC: 17),  // WED
      _day(date: DateTime.utc(2026, 4, 23), minTempC: 11, maxTempC: 21), // THU
      _day(date: DateTime.utc(2026, 4, 24), minTempC: 14, maxTempC: 24), // FRI
    ];

    testWidgets('renders a column per forecast day', (tester) async {
      await tester.pumpWidget(_wrap(ForecastStripCard(forecast: days)));
      // MON – FRI short day labels
      expect(find.text('MON'), findsOneWidget);
      expect(find.text('TUE'), findsOneWidget);
      expect(find.text('WED'), findsOneWidget);
      expect(find.text('THU'), findsOneWidget);
      expect(find.text('FRI'), findsOneWidget);
    });

    testWidgets('renders high temp in Fahrenheit', (tester) async {
      // 22°C = 71.6 → 72°F
      await tester.pumpWidget(_wrap(ForecastStripCard(forecast: [days.first])));
      expect(find.text('72°'), findsOneWidget);
    });

    testWidgets('renders low temp in Fahrenheit', (tester) async {
      // 10°C = 50°F
      await tester.pumpWidget(_wrap(ForecastStripCard(forecast: [days.first])));
      expect(find.text('50°'), findsOneWidget);
    });

    testWidgets('renders weather emoji for each day', (tester) async {
      await tester.pumpWidget(_wrap(ForecastStripCard(forecast: days)));
      // 5 sunny icons
      expect(find.text('☀️'), findsNWidgets(5));
    });

    testWidgets('renders empty SizedBox when forecast is empty', (tester) async {
      await tester.pumpWidget(_wrap(const ForecastStripCard(forecast: [])));
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(DecoratedBox), findsNothing);
    });

    testWidgets('renders mixed icon types correctly', (tester) async {
      final mixed = [
        _day(date: DateTime.utc(2026, 4, 20), iconCode: '01d'), // ☀️
        _day(date: DateTime.utc(2026, 4, 21), iconCode: '13n'), // ❄️
        _day(date: DateTime.utc(2026, 4, 22), iconCode: '11d'), // ⛈
      ];
      await tester.pumpWidget(_wrap(ForecastStripCard(forecast: mixed)));
      expect(find.text('☀️'), findsOneWidget);
      expect(find.text('❄️'), findsOneWidget);
      expect(find.text('⛈'), findsOneWidget);
    });
  });
}
