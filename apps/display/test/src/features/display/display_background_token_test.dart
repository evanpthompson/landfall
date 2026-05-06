import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/clock/widgets/clock_card.dart';

void main() {
  group('DisplayScreen background token', () {
    testWidgets('Scaffold backgroundColor uses tokens.backgroundValue', (tester) async {
      const customBg = '#330011';
      final tokens = LandfallThemeTokens.defaults().copyWith(backgroundValue: customBg);

      await tester.pumpWidget(
        MaterialApp(
          home: LandfallActiveTheme(
            tokens: tokens,
            child: Builder(
              builder: (context) {
                final t = LandfallActiveTheme.of(context);
                return Scaffold(
                  backgroundColor: tokenColor(t.backgroundValue),
                  body: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF330011)));
    });

    testWidgets('ClockCard renders within a token-themed Scaffold', (tester) async {
      final tokens = LandfallThemeTokens.defaults().copyWith(
        backgroundValue: '#000000',
        cardFill: '#111111',
      );
      final entity = ClockEntity(DateTime(2026, 5, 1, 10, 30, 0));

      await tester.pumpWidget(
        MaterialApp(
          home: LandfallActiveTheme(
            tokens: tokens,
            child: Scaffold(
              backgroundColor: tokenColor(tokens.backgroundValue),
              body: ClockCard(entity: entity),
            ),
          ),
        ),
      );

      expect(find.text('10:30'), findsOneWidget);
    });
  });
}
