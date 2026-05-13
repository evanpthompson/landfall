// BUG-05 regression: every system card must survive a slot that is 50% of
// its design footprint without throwing a Flutter overflow exception.
//
// These tests do not assert visual fidelity — they only assert that
// `tester.takeException()` is null after the card lays out at a small size.
// Visual regressions are covered by goldens elsewhere.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/calendar/widgets/calendar_card.dart';
import 'package:display/src/features/clock/widgets/clock_card.dart';
import 'package:display/src/features/weather/widgets/current_weather_card.dart';
import 'package:display/src/features/weather/widgets/forecast_strip_card.dart';

// PhotoFrameCard is covered separately in photo_frame_card_test.dart; it
// requires both PhotoCubit and AuthCubit and its content is a single Image
// widget, so the resize-overflow class of bug does not apply.

Widget _slot({
  required double width,
  required double height,
  required Widget child,
}) =>
    MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  group('System cards do not overflow at 50% slot dimensions', () {
    testWidgets('ClockCard at 300×150', (tester) async {
      final entity = ClockEntity(DateTime(2026, 4, 17, 23, 59, 59));
      await tester.pumpWidget(
        _slot(width: 300, height: 150, child: ClockCard(entity: entity)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('CurrentWeatherCard at 240×180', (tester) async {
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
      await tester.pumpWidget(
        _slot(width: 240, height: 180, child: CurrentWeatherCard(entity: entity)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ForecastStripCard at 320×110', (tester) async {
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
      await tester.pumpWidget(
        _slot(
          width: 320,
          height: 110,
          child: ForecastStripCard(forecast: forecast),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('CalendarCard (daily) at 240×200', (tester) async {
      final events = <CalendarEventEntity>[
        CalendarEventEntity(
          id: 1,
          credentialId: 1,
          calendarId: 'c',
          calendarName: 'Personal',
          externalEventId: 'evt-1',
          title: 'A meeting with a long title to encourage truncation',
          startTime: DateTime(2026, 4, 17, 9, 30),
          endTime: DateTime(2026, 4, 17, 10, 30),
          isAllDay: false,
        ),
      ];
      await tester.pumpWidget(
        _slot(width: 240, height: 200, child: CalendarCard(events: events)),
      );
      expect(tester.takeException(), isNull);
    });

  });
}
