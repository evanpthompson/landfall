import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/clock/widgets/clock_card.dart';
import 'package:display/src/features/weather/widgets/current_weather_card.dart';
import 'package:display/src/features/calendar/widgets/calendar_card.dart';

Widget _wrapWithTheme(Widget child, LandfallThemeTokens tokens) {
  return MaterialApp(
    theme: LandfallTheme.dark,
    home: LandfallActiveTheme(
      tokens: tokens,
      child: Scaffold(body: child),
    ),
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: child),
    );

LandfallThemeTokens _customTokens({
  String cardFill = '#FF0000',
  String cardBorderColor = '#00FF00',
  String colorAccent = '#0000FF',
  String colorTextPrimary = '#FFFFFF',
  String colorTextSecondary = '#AAAAAA',
  String colorTextTertiary = '#666666',
}) =>
    LandfallThemeTokens.defaults().copyWith(
      cardFill: cardFill,
      cardBorderColor: cardBorderColor,
      colorAccent: colorAccent,
      colorTextPrimary: colorTextPrimary,
      colorTextSecondary: colorTextSecondary,
      colorTextTertiary: colorTextTertiary,
    );

void main() {
  group('LandfallActiveTheme token consumption', () {
    group('ClockCard', () {
      testWidgets('uses cardFill from tokens for decoration', (tester) async {
        final tokens = _customTokens(cardFill: '#FF0000');
        final entity = ClockEntity(DateTime(2026, 5, 1, 12, 0, 0));
        await tester.pumpWidget(
          _wrapWithTheme(ClockCard(entity: entity), tokens),
        );

        final box = tester.widget<DecoratedBox>(
          find.ancestor(
            of: find.text('12:00'),
            matching: find.byType(DecoratedBox),
          ).first,
        );
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFFFF0000)));
      });

      testWidgets('uses cardBorderColor from tokens', (tester) async {
        final tokens = _customTokens(cardBorderColor: '#00FF00');
        final entity = ClockEntity(DateTime(2026, 5, 1, 12, 0, 0));
        await tester.pumpWidget(
          _wrapWithTheme(ClockCard(entity: entity), tokens),
        );

        final box = tester.widget<DecoratedBox>(
          find.ancestor(
            of: find.text('12:00'),
            matching: find.byType(DecoratedBox),
          ).first,
        );
        final decoration = box.decoration as BoxDecoration;
        final border = decoration.border! as Border;
        expect(border.top.color, equals(const Color(0xFF00FF00)));
      });

      testWidgets('falls back to defaults when no ancestor theme', (tester) async {
        final entity = ClockEntity(DateTime(2026, 5, 1, 12, 0, 0));
        await tester.pumpWidget(_wrap(ClockCard(entity: entity)));

        final defaults = LandfallThemeTokens.defaults();
        final box = tester.widget<DecoratedBox>(
          find.ancestor(
            of: find.text('12:00'),
            matching: find.byType(DecoratedBox),
          ).first,
        );
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.color, equals(tokenColor(defaults.cardFill)));
      });
    });

    group('CurrentWeatherCard', () {
      testWidgets('uses cardFill from tokens', (tester) async {
        final tokens = _customTokens(cardFill: '#0000FF');
        final entity = WeatherEntity(
          locationName: 'Test City',
          tempC: 20,
          feelsLikeC: 18,
          humidity: 60,
          windSpeedMs: 5,
          condition: 'Clear',
          iconCode: '01d',
          fetchedAt: DateTime(2026, 5, 1),
        );
        await tester.pumpWidget(
          _wrapWithTheme(CurrentWeatherCard(entity: entity), tokens),
        );

        final box = tester.widget<DecoratedBox>(
          find.ancestor(
            of: find.text('Test City'),
            matching: find.byType(DecoratedBox),
          ).first,
        );
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF0000FF)));
      });
    });

    group('CalendarCard', () {
      testWidgets('uses cardFill from tokens', (tester) async {
        final tokens = _customTokens(cardFill: '#123456');
        await tester.pumpWidget(
          _wrapWithTheme(
            SizedBox(
              width: 400,
              height: 300,
              child: CalendarCard(events: const []),
            ),
            tokens,
          ),
        );

        final box = tester.widget<DecoratedBox>(
          find.ancestor(
            of: find.text('CALENDAR — NEXT 2 WEEKS'),
            matching: find.byType(DecoratedBox),
          ).first,
        );
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF123456)));
      });
    });

    group('tokenColor', () {
      test('nearest ancestor wins over outer ancestor', () {
        final outerTokens = LandfallThemeTokens.defaults().copyWith(cardFill: '#AABBCC');
        final innerTokens = LandfallThemeTokens.defaults().copyWith(cardFill: '#112233');

        expect(tokenColor(outerTokens.cardFill), equals(const Color(0xFFAABBCC)));
        expect(tokenColor(innerTokens.cardFill), equals(const Color(0xFF112233)));
      });
    });
  });
}
