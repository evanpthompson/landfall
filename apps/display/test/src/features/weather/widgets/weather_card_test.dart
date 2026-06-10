import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/weather/widgets/weather_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(
        body: SizedBox(width: 900, height: 400, child: child),
      ),
    );

// Finds an Image whose AssetImage points at [assetName].
Finder _assetIcon(String assetName) => find.byWidgetPredicate(
      (w) => w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == assetName,
    );

WeatherEntity _current({
  String locationName = 'Olathe',
  double tempC = 19.4,
  double feelsLikeC = 18.0,
  String condition = 'Overcast clouds',
  String iconCode = '04d',
  int humidity = 52,
  double windSpeedMs = 3.13,
}) =>
    WeatherEntity(
      locationName: locationName,
      tempC: tempC,
      feelsLikeC: feelsLikeC,
      condition: condition,
      iconCode: iconCode,
      humidity: humidity,
      windSpeedMs: windSpeedMs,
      fetchedAt: DateTime(2026, 5, 9, 12, 0),
    );

ForecastDayEntity _day(int weekday, {String iconCode = '01d'}) =>
    ForecastDayEntity(
      date: DateTime(2026, 5, 11 + weekday - 1),
      minTempC: 12.0,
      maxTempC: 22.0,
      condition: 'Clear',
      iconCode: iconCode,
    );

List<ForecastDayEntity> _forecast() => [
      _day(0, iconCode: '04d'),
      _day(1, iconCode: '01d'),
      _day(2, iconCode: '10d'),
      _day(3, iconCode: '01d'),
      _day(4, iconCode: '02d'),
    ];

void main() {
  group('WeatherCard', () {
    testWidgets('renders location name', (tester) async {
      await tester.pumpWidget(
        _wrap(WeatherCard(current: _current(), forecast: _forecast())),
      );
      expect(find.textContaining('Olathe'), findsOneWidget);
    });

    testWidgets('renders temperature in Fahrenheit by default', (tester) async {
      // 19.4°C = 66.92°F → rounds to 67
      await tester.pumpWidget(
        _wrap(WeatherCard(current: _current(tempC: 19.4), forecast: _forecast())),
      );
      expect(find.text('67°'), findsOneWidget);
    });

    testWidgets('renders condition text', (tester) async {
      await tester.pumpWidget(
        _wrap(WeatherCard(current: _current(), forecast: _forecast())),
      );
      expect(find.textContaining('Overcast clouds'), findsOneWidget);
    });

    testWidgets('renders current conditions icon', (tester) async {
      // iconCode '04d' → overcast-day Meteocons asset
      await tester.pumpWidget(
        _wrap(WeatherCard(
          current: _current(iconCode: '04d'),
          forecast: _forecast(),
        )),
      );
      expect(_assetIcon('assets/weather/overcast-day.png'), findsWidgets);
    });

    testWidgets('renders TODAY label for first forecast column', (tester) async {
      await tester.pumpWidget(
        _wrap(WeatherCard(current: _current(), forecast: _forecast())),
      );
      expect(find.text('TODAY'), findsOneWidget);
    });

    testWidgets('renders forecast high temp in Fahrenheit', (tester) async {
      // maxTempC 22.0 = 71.6°F → 72°
      await tester.pumpWidget(
        _wrap(WeatherCard(current: _current(), forecast: _forecast())),
      );
      expect(find.text('72°'), findsWidgets);
    });

    testWidgets('shows no forecast when list is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(WeatherCard(current: _current(), forecast: const [])),
      );
      expect(find.text('TODAY'), findsNothing);
    });

    testWidgets('does not overflow in a 400x300 slot', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: LandfallTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: WeatherCard(current: _current(), forecast: _forecast()),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
