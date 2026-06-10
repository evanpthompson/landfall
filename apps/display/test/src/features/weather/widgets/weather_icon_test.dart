import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/features/weather/widgets/weather_card.dart';

void main() {
  group('WeatherCard.meteoconAssetFor', () {
    test('maps clear day/night', () {
      expect(WeatherCard.meteoconAssetFor('01d'),
          'assets/weather/clear-day.png');
      expect(WeatherCard.meteoconAssetFor('01n'),
          'assets/weather/clear-night.png');
    });

    test('maps partly-cloudy day/night', () {
      expect(WeatherCard.meteoconAssetFor('02d'),
          'assets/weather/partly-cloudy-day.png');
      expect(WeatherCard.meteoconAssetFor('02n'),
          'assets/weather/partly-cloudy-night.png');
    });

    test('maps scattered clouds to cloudy (day-agnostic)', () {
      expect(WeatherCard.meteoconAssetFor('03d'), 'assets/weather/cloudy.png');
      expect(WeatherCard.meteoconAssetFor('03n'), 'assets/weather/cloudy.png');
    });

    test('maps overcast day/night', () {
      expect(WeatherCard.meteoconAssetFor('04d'),
          'assets/weather/overcast-day.png');
      expect(WeatherCard.meteoconAssetFor('04n'),
          'assets/weather/overcast-night.png');
    });

    test('maps precipitation and atmosphere codes', () {
      expect(WeatherCard.meteoconAssetFor('09d'), 'assets/weather/drizzle.png');
      expect(WeatherCard.meteoconAssetFor('10d'), 'assets/weather/rain.png');
      expect(WeatherCard.meteoconAssetFor('11d'),
          'assets/weather/thunderstorms.png');
      expect(WeatherCard.meteoconAssetFor('13n'), 'assets/weather/snow.png');
      expect(WeatherCard.meteoconAssetFor('50d'), 'assets/weather/mist.png');
    });

    test('returns null for unknown / empty codes', () {
      expect(WeatherCard.meteoconAssetFor('xx'), isNull);
      expect(WeatherCard.meteoconAssetFor(''), isNull);
    });
  });

  group('WeatherCard.weatherIcon', () {
    testWidgets('renders a Meteocons Image for a known code', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WeatherCard.weatherIcon('01d', size: 40),
        ),
      ));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName,
          'assets/weather/clear-day.png');
    });

    testWidgets('falls back to a tinted glyph for an unknown code',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WeatherCard.weatherIcon('zz', size: 40, fallbackColor: Colors.red),
        ),
      ));

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.device_thermostat), findsOneWidget);
    });
  });
}
