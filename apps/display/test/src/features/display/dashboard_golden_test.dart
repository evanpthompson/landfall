// Renders the shipped weekday dashboard at its target resolution so the whole
// surface can be reviewed as one picture, not card by card. The repo standard
// is a 1920x1080 golden per public widget; this is the same idea one level up,
// and it is what catches "each card is fine but the wall looks wrong".
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/calendar/widgets/calendar_card.dart';
import 'package:display/src/features/clock/widgets/clock_card.dart';
import 'package:display/src/features/weather/widgets/weather_card.dart';

const _kGap = 12.0;

final _now = DateTime(2026, 9, 19, 14, 32);

WeatherEntity _weather() => WeatherEntity(
      locationName: 'Overland Park',
      tempC: 24.4,
      feelsLikeC: 25.6,
      condition: 'Partly cloudy',
      iconCode: '02d',
      humidity: 46,
      windSpeedMs: 4.1,
      fetchedAt: _now,
    );

List<ForecastDayEntity> _forecast() => [
      ForecastDayEntity(
        date: _now.add(const Duration(days: 1)),
        maxTempC: 26.1,
        minTempC: 15.0,
        condition: 'Sunny',
        iconCode: '01d',
      ),
      ForecastDayEntity(
        date: _now.add(const Duration(days: 2)),
        maxTempC: 22.2,
        minTempC: 13.3,
        condition: 'Rain',
        iconCode: '10d',
      ),
      ForecastDayEntity(
        date: _now.add(const Duration(days: 3)),
        maxTempC: 19.4,
        minTempC: 11.1,
        condition: 'Cloudy',
        iconCode: '03d',
      ),
      ForecastDayEntity(
        date: _now.add(const Duration(days: 4)),
        maxTempC: 23.9,
        minTempC: 14.4,
        condition: 'Sunny',
        iconCode: '01d',
      ),
      ForecastDayEntity(
        date: _now.add(const Duration(days: 5)),
        maxTempC: 25.0,
        minTempC: 16.1,
        condition: 'Partly cloudy',
        iconCode: '02d',
      ),
    ];

CalendarEventEntity _event(
  int id,
  String title,
  DateTime start,
  Duration length, {
  String calendar = 'Work',
}) =>
    CalendarEventEntity(
      id: id,
      credentialId: 1,
      calendarId: 'primary',
      calendarName: calendar,
      externalEventId: 'evt-$id',
      title: title,
      startTime: start,
      endTime: start.add(length),
      isAllDay: false,
    );

List<CalendarEventEntity> _events() => [
      _event(1, 'Sprint planning', DateTime(2026, 9, 19, 15),
          const Duration(minutes: 45)),
      _event(2, '1:1 with Sarah', DateTime(2026, 9, 19, 16, 30),
          const Duration(minutes: 30)),
      _event(3, 'Dinner with Mara', DateTime(2026, 9, 19, 19),
          const Duration(hours: 2), calendar: 'Family'),
      _event(4, 'Dentist', DateTime(2026, 9, 21, 9),
          const Duration(hours: 1), calendar: 'Family'),
      _event(5, 'Quarterly review', DateTime(2026, 9, 23, 13),
          const Duration(hours: 2)),
      _event(6, 'Flight to Denver', DateTime(2026, 9, 26, 6, 40),
          const Duration(hours: 3), calendar: 'Travel'),
    ];

Widget _cardFor(CardConfig config) => switch (config.source) {
      'system.clock' => ClockCard(
          entity: ClockEntity(_now),
          displayConfig: config.displayConfig,
        ),
      'system.weather' => WeatherCard(
          current: _weather(),
          forecast: _forecast(),
          displayConfig: config.displayConfig,
        ),
      'system.calendar' => CalendarCard(
          events: _events(),
          displayConfig: config.displayConfig,
        ),
      _ => _StubTile(label: config.source),
    };

class _StubTile extends StatelessWidget {
  const _StubTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokenColor(tokens.cardFill),
        borderRadius: BorderRadius.circular(tokens.cardRadius.toDouble()),
        border: Border.all(
          color: tokenColor(tokens.cardBorderColor),
          width: tokens.cardBorderWidth,
        ),
      ),
      child: Center(
        child: Text(
          label.split('.').last.toUpperCase(),
          style: LandfallTypography.cardLabel
              .copyWith(color: tokenColor(tokens.colorTextTertiary)),
        ),
      ),
    );
  }
}

Widget _dashboard(DashboardLayout layout) {
  final tokens = LandfallThemeTokens.defaults();
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: LandfallTheme.dark,
    home: LandfallActiveTheme(
      tokens: tokens,
      child: Scaffold(
        backgroundColor: tokenColor(tokens.backgroundValue),
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellW = constraints.maxWidth / layout.columns;
                  final cellH = constraints.maxHeight / layout.rows;
                  return Stack(
                    children: layout.visibleCards.map((config) {
                      final slot = config.slot;
                      return Positioned(
                        left: slot.column * cellW + _kGap,
                        top: slot.row * cellH + _kGap,
                        width: slot.columnSpan * cellW - _kGap * 2,
                        height: slot.rowSpan * cellH - _kGap * 2,
                        child: _cardFor(config),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const Expanded(flex: 1, child: _StubTile(label: 'agent.feed')),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('weekday dashboard at 1920x1080', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_dashboard(DashboardLayout.weekdayLayout()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/dashboard_weekday_1920x1080.png'),
    );
  });
}
