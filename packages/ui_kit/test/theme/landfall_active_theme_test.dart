import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('LandfallActiveTheme.of', () {
    testWidgets('returns injected tokens when ancestor present', (tester) async {
      final tokens = LandfallThemeTokens.defaults().copyWith(
        colorAccent: '#FF0000',
      );
      late LandfallThemeTokens captured;

      await tester.pumpWidget(MaterialApp(
        home: LandfallActiveTheme(
          tokens: tokens,
          child: Builder(builder: (context) {
            captured = LandfallActiveTheme.of(context);
            return const SizedBox.shrink();
          }),
        ),
      ));

      expect(captured.colorAccent, equals('#FF0000'));
    });

    testWidgets('falls back to defaults when no ancestor present',
        (tester) async {
      late LandfallThemeTokens captured;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          captured = LandfallActiveTheme.of(context);
          return const SizedBox.shrink();
        }),
      ));

      expect(captured, equals(LandfallThemeTokens.defaults()));
    });

    testWidgets('nearest ancestor wins when nested', (tester) async {
      final outer = LandfallThemeTokens.defaults().copyWith(colorAccent: '#0000FF');
      final inner = LandfallThemeTokens.defaults().copyWith(colorAccent: '#00FF00');
      late LandfallThemeTokens captured;

      await tester.pumpWidget(MaterialApp(
        home: LandfallActiveTheme(
          tokens: outer,
          child: LandfallActiveTheme(
            tokens: inner,
            child: Builder(builder: (context) {
              captured = LandfallActiveTheme.of(context);
              return const SizedBox.shrink();
            }),
          ),
        ),
      ));

      expect(captured.colorAccent, equals('#00FF00'));
    });
  });

  group('tokenColor', () {
    test('parses #RRGGBB', () {
      expect(tokenColor('#F2F2F7'), equals(const Color(0xFFF2F2F7)));
    });

    test('parses #RRGGBBAA', () {
      expect(tokenColor('#FF000080'), equals(const Color(0x80FF0000)));
    });

    test('parses rgba(r,g,b,a)', () {
      final c = tokenColor('rgba(79,142,247,0.2)');
      expect(c.r8, equals(79));
      expect(c.g8, equals(142));
      expect(c.b8, equals(247));
      expect((c.a * 255).round(), closeTo(51, 1)); // 0.2 * 255 ≈ 51
    });

    test('returns black for unrecognised format', () {
      expect(tokenColor('unknown'), equals(const Color(0xFF000000)));
    });
  });
}

extension _ColorComponents on Color {
  int get r8 => (r * 255).round();
  int get g8 => (g * 255).round();
  int get b8 => (b * 255).round();
}
