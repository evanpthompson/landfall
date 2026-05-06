import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/weather/widgets/current_weather_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: SizedBox(width: 600, height: 300, child: child)),
    );

WeatherEntity _entity({
  String locationName = 'Chicago',
  double tempC = 22.0,
  double feelsLikeC = 20.0,
  String condition = 'Clear sky',
  String iconCode = '01d',
  int humidity = 55,
  double windSpeedMs = 4.47, // ≈ 10 mph
}) =>
    WeatherEntity(
      locationName: locationName,
      tempC: tempC,
      feelsLikeC: feelsLikeC,
      condition: condition,
      iconCode: iconCode,
      humidity: humidity,
      windSpeedMs: windSpeedMs,
      fetchedAt: DateTime(2026, 4, 19, 12, 0),
    );

void main() {
  group('CurrentWeatherCard', () {
    testWidgets('renders location name', (tester) async {
      await tester.pumpWidget(_wrap(CurrentWeatherCard(entity: _entity())));
      expect(find.text('Chicago'), findsOneWidget);
    });

    testWidgets('renders temperature in Fahrenheit', (tester) async {
      // 22°C = 71.6°F → rounds to 72
      await tester.pumpWidget(
        _wrap(CurrentWeatherCard(entity: _entity(tempC: 22.0))),
      );
      expect(find.text('72°'), findsOneWidget);
    });

    testWidgets('renders condition text', (tester) async {
      await tester.pumpWidget(_wrap(CurrentWeatherCard(entity: _entity())));
      expect(find.text('Clear sky'), findsOneWidget);
    });

    testWidgets('renders feels-like in Fahrenheit', (tester) async {
      // 20°C = 68°F
      await tester.pumpWidget(
        _wrap(CurrentWeatherCard(entity: _entity(feelsLikeC: 20.0))),
      );
      expect(find.text('Feels like 68°F'), findsOneWidget);
    });

    testWidgets('renders humidity percentage', (tester) async {
      await tester.pumpWidget(
        _wrap(CurrentWeatherCard(entity: _entity(humidity: 55))),
      );
      expect(find.text('55% humidity'), findsOneWidget);
    });

    testWidgets('renders wind speed in mph', (tester) async {
      // 4.47 m/s × 2.237 = 9.99 ≈ 10 mph
      await tester.pumpWidget(
        _wrap(CurrentWeatherCard(entity: _entity(windSpeedMs: 4.47))),
      );
      expect(find.text('10 mph'), findsOneWidget);
    });

    testWidgets('renders sunny emoji for clear sky icon', (tester) async {
      await tester.pumpWidget(
        _wrap(CurrentWeatherCard(entity: _entity(iconCode: '01d'))),
      );
      expect(find.text('☀️'), findsOneWidget);
    });

    testWidgets('renders snow emoji for snow icon', (tester) async {
      await tester.pumpWidget(
        _wrap(CurrentWeatherCard(entity: _entity(iconCode: '13n'))),
      );
      expect(find.text('❄️'), findsOneWidget);
    });

    testWidgets('renders thunderstorm emoji for storm icon', (tester) async {
      await tester.pumpWidget(
        _wrap(CurrentWeatherCard(entity: _entity(iconCode: '11d'))),
      );
      expect(find.text('⛈'), findsOneWidget);
    });

    testWidgets('freezing temp converts correctly', (tester) async {
      // 0°C = 32°F
      await tester.pumpWidget(
        _wrap(CurrentWeatherCard(entity: _entity(tempC: 0.0))),
      );
      expect(find.text('32°'), findsOneWidget);
    });

    // BUG-05: card content must scale down at small slot sizes without overflow.
    testWidgets('does not overflow in a 240x180 slot', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: LandfallTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 180,
            child: CurrentWeatherCard(entity: _entity()),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
