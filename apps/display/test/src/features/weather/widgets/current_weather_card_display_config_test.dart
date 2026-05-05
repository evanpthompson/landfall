import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/weather/widgets/current_weather_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: SizedBox(width: 600, height: 300, child: child)),
    );

WeatherEntity _entity({double tempC = 22.0, double feelsLikeC = 20.0}) =>
    WeatherEntity(
      locationName: 'Chicago',
      tempC: tempC,
      feelsLikeC: feelsLikeC,
      condition: 'Clear sky',
      iconCode: '01d',
      humidity: 55,
      windSpeedMs: 4.47,
      fetchedAt: DateTime(2026, 4, 19, 12, 0),
    );

void main() {
  group('CurrentWeatherCard displayConfig', () {
    group('unit', () {
      testWidgets('default unit is °F', (tester) async {
        // 22°C = 71.6 → 72°F
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(entity: _entity(), displayConfig: const {})),
        );
        expect(find.text('72°'), findsOneWidget);
      });

      testWidgets('unit=f renders Fahrenheit', (tester) async {
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(
            entity: _entity(tempC: 22.0),
            displayConfig: const {'unit': 'f'},
          )),
        );
        expect(find.text('72°'), findsOneWidget);
      });

      testWidgets('unit=c renders Celsius rounded', (tester) async {
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(
            entity: _entity(tempC: 22.0),
            displayConfig: const {'unit': 'c'},
          )),
        );
        expect(find.text('22°'), findsOneWidget);
      });

      testWidgets('unit=c renders negative Celsius', (tester) async {
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(
            entity: _entity(tempC: -5.0),
            displayConfig: const {'unit': 'c'},
          )),
        );
        expect(find.text('-5°'), findsOneWidget);
      });

      testWidgets('unit=c shows feels-like in Celsius', (tester) async {
        // feelsLikeC=15.0 → "Feels like 15°C"
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(
            entity: _entity(feelsLikeC: 15.0),
            displayConfig: const {'unit': 'c'},
          )),
        );
        expect(find.text('Feels like 15°C'), findsOneWidget);
      });

      testWidgets('unit=f shows feels-like in Fahrenheit', (tester) async {
        // feelsLikeC=20.0 → 68°F
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(
            entity: _entity(feelsLikeC: 20.0),
            displayConfig: const {'unit': 'f'},
          )),
        );
        expect(find.text('Feels like 68°F'), findsOneWidget);
      });
    });

    group('compact', () {
      testWidgets('meta row visible by default', (tester) async {
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(entity: _entity(), displayConfig: const {})),
        );
        expect(find.text('55% humidity'), findsOneWidget);
      });

      testWidgets('compact=false shows meta row', (tester) async {
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(
            entity: _entity(),
            displayConfig: const {'compact': false},
          )),
        );
        expect(find.text('55% humidity'), findsOneWidget);
      });

      testWidgets('compact=true hides meta row', (tester) async {
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(
            entity: _entity(),
            displayConfig: const {'compact': true},
          )),
        );
        expect(find.text('55% humidity'), findsNothing);
        expect(find.textContaining('Feels like'), findsNothing);
        expect(find.textContaining('mph'), findsNothing);
      });

      testWidgets('compact=true still shows temp and condition', (tester) async {
        await tester.pumpWidget(
          _wrap(CurrentWeatherCard(
            entity: _entity(tempC: 22.0),
            displayConfig: const {'compact': true},
          )),
        );
        expect(find.text('72°'), findsOneWidget);
        expect(find.text('Clear sky'), findsOneWidget);
      });
    });
  });
}
