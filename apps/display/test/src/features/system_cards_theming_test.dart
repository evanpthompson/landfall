// BUG-06 regression: every system card must read its border, fill, and text
// colors from `LandfallActiveTheme.of(context)` rather than hardcoded
// `LandfallColors` constants. A custom token set wrapped around the card
// tree must take effect.
//
// We assert by injecting a recognizable border color (#ABCDEF) via a custom
// `LandfallActiveTheme` and finding a DecoratedBox whose Border carries that
// exact color. If a card ever reverts to a hardcoded constant, this test
// fails.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/calendar/widgets/calendar_card.dart';
import 'package:display/src/features/clock/widgets/clock_card.dart';
import 'package:display/src/features/weather/widgets/current_weather_card.dart';
import 'package:display/src/features/weather/widgets/forecast_strip_card.dart';

const _customBorderHex = '#ABCDEF';
const _expectedBorderColor = Color(0xFFABCDEF);

LandfallThemeTokens _tokensWithBorder() =>
    LandfallThemeTokens.defaults().copyWith(cardBorderColor: _customBorderHex);

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            height: 400,
            child: LandfallActiveTheme(
              tokens: _tokensWithBorder(),
              child: child,
            ),
          ),
        ),
      ),
    );

bool _hasExpectedBorder(WidgetTester tester) {
  final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
  for (final box in decoratedBoxes) {
    final decoration = box.decoration;
    if (decoration is! BoxDecoration) continue;
    final border = decoration.border;
    if (border is Border && border.top.color == _expectedBorderColor) {
      return true;
    }
  }
  return false;
}

void main() {
  group('System cards consume LandfallActiveTheme tokens', () {
    testWidgets('ClockCard reflects custom cardBorderColor', (tester) async {
      final entity = ClockEntity(DateTime(2026, 4, 17, 9, 30, 45));
      await tester.pumpWidget(_wrap(ClockCard(entity: entity)));
      expect(
        _hasExpectedBorder(tester),
        isTrue,
        reason: 'ClockCard must read cardBorderColor from LandfallActiveTheme',
      );
    });

    testWidgets('CurrentWeatherCard reflects custom cardBorderColor',
        (tester) async {
      final entity = WeatherEntity(
        locationName: 'Olathe, KS',
        tempC: 22.3,
        feelsLikeC: 22.0,
        humidity: 55,
        windSpeedMs: 4.2,
        condition: 'Partly cloudy',
        iconCode: '02d',
        fetchedAt: DateTime(2026, 4, 17, 12, 0),
      );
      await tester.pumpWidget(_wrap(CurrentWeatherCard(entity: entity)));
      expect(
        _hasExpectedBorder(tester),
        isTrue,
        reason: 'CurrentWeatherCard must read cardBorderColor from LandfallActiveTheme',
      );
    });

    testWidgets('ForecastStripCard reflects custom cardBorderColor',
        (tester) async {
      final today = DateTime(2026, 4, 17);
      final forecast = List.generate(
        5,
        (i) => ForecastDayEntity(
          date: today.add(Duration(days: i)),
          maxTempC: 24.0,
          minTempC: 12.0,
          iconCode: '01d',
          condition: 'Clear',
        ),
      );
      await tester.pumpWidget(_wrap(ForecastStripCard(forecast: forecast)));
      expect(
        _hasExpectedBorder(tester),
        isTrue,
        reason: 'ForecastStripCard must read cardBorderColor from LandfallActiveTheme',
      );
    });

    testWidgets('CalendarCard reflects custom cardBorderColor', (tester) async {
      final events = <CalendarEventEntity>[
        CalendarEventEntity(
          id: 1,
          credentialId: 1,
          calendarId: 'c',
          calendarName: 'Personal',
          externalEventId: 'evt-1',
          title: 'A meeting',
          startTime: DateTime(2026, 4, 17, 9, 30),
          endTime: DateTime(2026, 4, 17, 10, 30),
          isAllDay: false,
        ),
      ];
      await tester.pumpWidget(_wrap(CalendarCard(events: events)));
      expect(
        _hasExpectedBorder(tester),
        isTrue,
        reason: 'CalendarCard must read cardBorderColor from LandfallActiveTheme',
      );
    });
  });
}
