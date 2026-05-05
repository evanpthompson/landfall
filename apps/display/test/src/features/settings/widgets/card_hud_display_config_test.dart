import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/settings/widgets/layout_editor.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DashboardLayout _layoutWithSource(String source) => DashboardLayout(
      id: 'test',
      name: 'Test',
      columns: 12,
      rows: 8,
      cards: [
        CardConfig(
          id: 'card_a',
          source: source,
          slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
        ),
      ],
    );

Widget _wrapLayout(
  DashboardLayout layout, {
  ValueChanged<DashboardLayout>? onChanged,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 800,
          child: LayoutEditor(
            layout: layout,
            onLayoutChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );

Future<void> _openHud(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Card HUD — display config sections', () {
    // ── Clock ────────────────────────────────────────────────────────────────

    group('system.clock section', () {
      testWidgets('shows hour-format chips when source is system.clock',
          (tester) async {
        await tester.pumpWidget(
            _wrapLayout(_layoutWithSource('system.clock')));
        await _openHud(tester);

        expect(find.byKey(const ValueKey('hud_clock_hour_format_24')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('hud_clock_hour_format_12')),
            findsOneWidget);
      });

      testWidgets('shows seconds switch when source is system.clock',
          (tester) async {
        await tester.pumpWidget(
            _wrapLayout(_layoutWithSource('system.clock')));
        await _openHud(tester);

        expect(
            find.byKey(const ValueKey('hud_clock_show_seconds')), findsOneWidget);
      });

      testWidgets('shows date-line switch when source is system.clock',
          (tester) async {
        await tester.pumpWidget(
            _wrapLayout(_layoutWithSource('system.clock')));
        await _openHud(tester);

        expect(
            find.byKey(const ValueKey('hud_clock_show_date')), findsOneWidget);
      });

      testWidgets('tapping 12h chip emits displayConfig hourFormat=12',
          (tester) async {
        DashboardLayout? emitted;
        await tester.pumpWidget(_wrapLayout(
          _layoutWithSource('system.clock'),
          onChanged: (l) => emitted = l,
        ));
        await _openHud(tester);

        await tester
            .tap(find.byKey(const ValueKey('hud_clock_hour_format_12')));
        await tester.pumpAndSettle();

        expect(emitted, isNotNull);
        final config = emitted!.cards.first;
        expect(config.displayConfig['hourFormat'], equals('12'));
      });

      testWidgets('tapping 24h chip emits displayConfig hourFormat=24',
          (tester) async {
        // Start with 12h already set
        final layout = DashboardLayout(
          id: 'test',
          name: 'Test',
          columns: 12,
          rows: 8,
          cards: [
            CardConfig(
              id: 'card_a',
              source: 'system.clock',
              slot:
                  DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
              displayConfig: const {'hourFormat': '12'},
            ),
          ],
        );
        DashboardLayout? emitted;
        await tester.pumpWidget(
            _wrapLayout(layout, onChanged: (l) => emitted = l));
        await _openHud(tester);

        await tester
            .tap(find.byKey(const ValueKey('hud_clock_hour_format_24')));
        await tester.pumpAndSettle();

        expect(emitted!.cards.first.displayConfig['hourFormat'], equals('24'));
      });

      testWidgets('toggling seconds switch updates showSeconds in displayConfig',
          (tester) async {
        DashboardLayout? emitted;
        await tester.pumpWidget(_wrapLayout(
          _layoutWithSource('system.clock'),
          onChanged: (l) => emitted = l,
        ));
        await _openHud(tester);

        await tester
            .tap(find.byKey(const ValueKey('hud_clock_show_seconds')));
        await tester.pumpAndSettle();

        expect(emitted, isNotNull);
        expect(emitted!.cards.first.displayConfig['showSeconds'], isFalse);
      });

      testWidgets('toggling date switch updates showDate in displayConfig',
          (tester) async {
        DashboardLayout? emitted;
        await tester.pumpWidget(_wrapLayout(
          _layoutWithSource('system.clock'),
          onChanged: (l) => emitted = l,
        ));
        await _openHud(tester);

        await tester
            .ensureVisible(find.byKey(const ValueKey('hud_clock_show_date')));
        await tester.tap(find.byKey(const ValueKey('hud_clock_show_date')));
        await tester.pumpAndSettle();

        expect(emitted, isNotNull);
        expect(emitted!.cards.first.displayConfig['showDate'], isFalse);
      });

      testWidgets('clock section does not appear for non-clock sources',
          (tester) async {
        await tester.pumpWidget(
            _wrapLayout(_layoutWithSource('system.weather')));
        await _openHud(tester);

        expect(find.byKey(const ValueKey('hud_clock_hour_format_12')),
            findsNothing);
      });
    });

    // ── Weather ──────────────────────────────────────────────────────────────

    group('system.weather section', () {
      testWidgets('shows unit chips when source is system.weather',
          (tester) async {
        await tester.pumpWidget(
            _wrapLayout(_layoutWithSource('system.weather')));
        await _openHud(tester);

        expect(find.byKey(const ValueKey('hud_weather_unit_f')), findsOneWidget);
        expect(find.byKey(const ValueKey('hud_weather_unit_c')), findsOneWidget);
      });

      testWidgets('shows compact switch when source is system.weather',
          (tester) async {
        await tester.pumpWidget(
            _wrapLayout(_layoutWithSource('system.weather')));
        await _openHud(tester);

        expect(
            find.byKey(const ValueKey('hud_weather_compact')), findsOneWidget);
      });

      testWidgets('tapping °C chip emits displayConfig unit=c', (tester) async {
        DashboardLayout? emitted;
        await tester.pumpWidget(_wrapLayout(
          _layoutWithSource('system.weather'),
          onChanged: (l) => emitted = l,
        ));
        await _openHud(tester);

        await tester.tap(find.byKey(const ValueKey('hud_weather_unit_c')));
        await tester.pumpAndSettle();

        expect(emitted!.cards.first.displayConfig['unit'], equals('c'));
      });

      testWidgets('tapping °F chip emits displayConfig unit=f', (tester) async {
        DashboardLayout? emitted;
        await tester.pumpWidget(_wrapLayout(
          _layoutWithSource('system.weather'),
          onChanged: (l) => emitted = l,
        ));
        await _openHud(tester);

        await tester.tap(find.byKey(const ValueKey('hud_weather_unit_f')));
        await tester.pumpAndSettle();

        expect(emitted!.cards.first.displayConfig['unit'], equals('f'));
      });

      testWidgets('toggling compact switch updates compact in displayConfig',
          (tester) async {
        DashboardLayout? emitted;
        await tester.pumpWidget(_wrapLayout(
          _layoutWithSource('system.weather'),
          onChanged: (l) => emitted = l,
        ));
        await _openHud(tester);

        await tester.tap(find.byKey(const ValueKey('hud_weather_compact')));
        await tester.pumpAndSettle();

        expect(emitted!.cards.first.displayConfig['compact'], isTrue);
      });

      testWidgets('weather section does not appear for non-weather sources',
          (tester) async {
        await tester.pumpWidget(
            _wrapLayout(_layoutWithSource('system.clock')));
        await _openHud(tester);

        expect(
            find.byKey(const ValueKey('hud_weather_unit_c')), findsNothing);
      });
    });

    // ── Forecast ─────────────────────────────────────────────────────────────

    group('system.weather.forecast section', () {
      testWidgets('shows days chips when source is system.weather.forecast',
          (tester) async {
        await tester.pumpWidget(
            _wrapLayout(_layoutWithSource('system.weather.forecast')));
        await _openHud(tester);

        expect(
            find.byKey(const ValueKey('hud_forecast_days_1')), findsOneWidget);
        expect(
            find.byKey(const ValueKey('hud_forecast_days_3')), findsOneWidget);
        expect(
            find.byKey(const ValueKey('hud_forecast_days_5')), findsOneWidget);
      });

      testWidgets('tapping 1 chip emits displayConfig days=1', (tester) async {
        DashboardLayout? emitted;
        await tester.pumpWidget(_wrapLayout(
          _layoutWithSource('system.weather.forecast'),
          onChanged: (l) => emitted = l,
        ));
        await _openHud(tester);

        await tester.tap(find.byKey(const ValueKey('hud_forecast_days_1')));
        await tester.pumpAndSettle();

        expect(emitted!.cards.first.displayConfig['days'], equals(1));
      });

      testWidgets('tapping 3 chip emits displayConfig days=3', (tester) async {
        DashboardLayout? emitted;
        await tester.pumpWidget(_wrapLayout(
          _layoutWithSource('system.weather.forecast'),
          onChanged: (l) => emitted = l,
        ));
        await _openHud(tester);

        await tester.tap(find.byKey(const ValueKey('hud_forecast_days_3')));
        await tester.pumpAndSettle();

        expect(emitted!.cards.first.displayConfig['days'], equals(3));
      });

      testWidgets('tapping 5 chip emits displayConfig days=5', (tester) async {
        DashboardLayout? emitted;
        await tester.pumpWidget(_wrapLayout(
          _layoutWithSource('system.weather.forecast'),
          onChanged: (l) => emitted = l,
        ));
        await _openHud(tester);

        await tester.tap(find.byKey(const ValueKey('hud_forecast_days_5')));
        await tester.pumpAndSettle();

        expect(emitted!.cards.first.displayConfig['days'], equals(5));
      });

      testWidgets('forecast section does not appear for non-forecast sources',
          (tester) async {
        await tester.pumpWidget(
            _wrapLayout(_layoutWithSource('system.clock')));
        await _openHud(tester);

        expect(
            find.byKey(const ValueKey('hud_forecast_days_1')), findsNothing);
      });
    });
  });
}
