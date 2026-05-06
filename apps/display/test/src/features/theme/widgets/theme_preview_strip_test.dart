import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/theme/widgets/theme_preview_strip.dart';

LandfallThemeTokens _tokens({
  String accent = '#4F8EF7',
  String cardFill = '#1A1A1F',
  String bg = '#0D0D0F',
}) =>
    LandfallThemeTokens.defaults().copyWith(
      colorAccent: accent,
      cardFill: cardFill,
      backgroundValue: bg,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: child),
    );

void main() {
  group('ThemePreviewStrip', () {
    testWidgets('renders token swatch row', (tester) async {
      await tester.pumpWidget(
        _wrap(ThemePreviewStrip(tokens: _tokens())),
      );
      expect(find.byKey(const Key('preview_swatch_row')), findsOneWidget);
    });

    testWidgets('renders mini clock tile', (tester) async {
      await tester.pumpWidget(
        _wrap(ThemePreviewStrip(tokens: _tokens())),
      );
      expect(find.byKey(const Key('preview_clock_tile')), findsOneWidget);
    });

    testWidgets('renders mini weather tile', (tester) async {
      await tester.pumpWidget(
        _wrap(ThemePreviewStrip(tokens: _tokens())),
      );
      expect(find.byKey(const Key('preview_weather_tile')), findsOneWidget);
    });

    testWidgets('uses candidate tokens not ambient theme', (tester) async {
      final candidateTokens = _tokens(cardFill: '#FF0000');
      await tester.pumpWidget(
        // Outer LandfallActiveTheme has a different cardFill
        MaterialApp(
          home: LandfallActiveTheme(
            tokens: _tokens(cardFill: '#AABBCC'),
            child: Scaffold(
              body: ThemePreviewStrip(tokens: candidateTokens),
            ),
          ),
        ),
      );

      // The preview_clock_tile DecoratedBox should use the candidate token
      // cardFill (#FF0000), not the outer ambient theme's (#AABBCC).
      final clockTile = tester.widget<DecoratedBox>(
        find.byKey(const Key('preview_clock_tile')),
      );
      final decoration = clockTile.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFFFF0000)));
    });

    testWidgets('different accent produces different swatch colour', (tester) async {
      final tokensA = _tokens(accent: '#FF0000');
      final tokensB = _tokens(accent: '#00FF00');

      await tester.pumpWidget(_wrap(ThemePreviewStrip(tokens: tokensA)));
      final containerA = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('preview_accent_swatch')),
          matching: find.byType(Container),
        ),
      );
      final colorA = (containerA.decoration as BoxDecoration?)?.color;

      await tester.pumpWidget(_wrap(ThemePreviewStrip(tokens: tokensB)));
      final containerB = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('preview_accent_swatch')),
          matching: find.byType(Container),
        ),
      );
      final colorB = (containerB.decoration as BoxDecoration?)?.color;

      expect(colorA, isNot(equals(colorB)));
    });
  });
}
