import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/weather/widgets/weather_card.dart';

import '../../../../support/legibility.dart';

final _now = DateTime(2026, 9, 19, 14, 32);

WeatherEntity _current() => WeatherEntity(
      locationName: 'Overland Park',
      tempC: 24.4,
      feelsLikeC: 25.6,
      condition: 'Partly cloudy',
      iconCode: '02d',
      humidity: 46,
      windSpeedMs: 4.1,
      fetchedAt: _now,
    );

List<ForecastDayEntity> _forecast() => List.generate(
      5,
      (i) => ForecastDayEntity(
        date: _now.add(Duration(days: i + 1)),
        minTempC: 12.0 + i,
        maxTempC: 24.0 + i,
        condition: 'Partly cloudy',
        iconCode: '02d',
      ),
    );

void main() {
  testWidgets('weather card is legible at its real slot', (tester) async {
    await expectLegibleAtSlot(
      tester,
      WeatherCard(current: _current(), forecast: _forecast()),
      CardSlot.weather,
    );
  });

  testWidgets('still legible in Celsius, which runs to more characters',
      (tester) async {
    await expectLegibleAtSlot(
      tester,
      WeatherCard(
        current: _current(),
        forecast: _forecast(),
        displayConfig: const {'unit': 'c'},
      ),
      CardSlot.weather,
    );
  });

  testWidgets('still legible with the stale footnote showing', (tester) async {
    await expectLegibleAtSlot(
      tester,
      WeatherCard(
        current: _current(),
        forecast: _forecast(),
        staleSince: _now.subtract(const Duration(hours: 3)),
      ),
      CardSlot.weather,
    );
  });

  testWidgets('the temperature is the largest thing on the card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(wrapInSlot(
      WeatherCard(current: _current(), forecast: _forecast()),
      CardSlot.weather,
    ));
    await tester.pump();

    final sizes = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.style?.fontSize ?? 0)
        .toList();
    expect(
      sizes.reduce((a, b) => a > b ? a : b),
      greaterThanOrEqualTo(LandfallTypography.weatherTemp.fontSize!),
    );
  });
}
