import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/cards/widgets/generic_agent_card.dart';

// ── token fixture ──────────────────────────────────────────────────────────────

LandfallThemeTokens _tokens({
  String cardFill = '#2d1b69',
  String cardBorderColor = '#7C3AED',
  String colorTextPrimary = '#f0e6ff',
  String colorTextSecondary = '#c4b5fd',
}) =>
    LandfallThemeTokens(
      backgroundType: 'solid',
      backgroundValue: '#0d0d0d',
      cardFill: cardFill,
      cardBorderColor: cardBorderColor,
      cardBorderWidth: 1.5,
      cardBorderStyle: 'solid',
      cardRadius: 10,
      cardBlur: 0,
      cardShadow: 'none',
      fontFamily: 'Inter',
      typographyScale: 'default',
      headingWeight: 600,
      bodyWeight: 400,
      letterSpacing: 'normal',
      timeDisplayFontFamily: 'Inter',
      timeDisplayWeight: 700,
      colorAccent: '#7C3AED',
      colorAccentMuted: '#5b21b6',
      colorTextPrimary: colorTextPrimary,
      colorTextSecondary: colorTextSecondary,
      colorTextTertiary: '#888888',
      colorDivider: '#333333',
      colorAgentBorder: '#7C3AED',
      colorSuccess: '#00ff00',
      colorWarning: '#ffff00',
      colorAlert: '#ff0000',
      animationTransition: 'fade',
      animationSpeed: 'normal',
      animationCardEntry: 'slide',
      animationTickerScroll: 'smooth',
      moodUrgentBorderColor: '#ff0000',
      moodUrgentFillColor: '#330000',
      moodUrgentPulse: true,
      moodUrgentScale: 1.02,
      moodUrgentAnimation: 'pulse',
      moodCelebratoryBorderColor: '#ffcc00',
      moodCelebratoryFillColor: '#332200',
      moodCelebratoryPulse: false,
      moodCelebratoryScale: 1.0,
      moodCelebratoryAnimation: 'confetti',
      moodSuccessBorderColor: '#00ff00',
      moodSuccessFillColor: '#003300',
      moodSuccessPulse: false,
      moodSuccessScale: 1.0,
      moodSuccessAnimation: 'none',
      moodMutedBorderColor: '#555555',
      moodMutedFillColor: '#1a1a1a',
      moodMutedPulse: false,
      moodMutedScale: 1.0,
      moodMutedAnimation: 'none',
      moodMutedOpacity: 0.5,
      photoTransition: 'drift',
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: SizedBox(width: 400, height: 200, child: child)),
    );

Card _card({
  String id = 'test-card-1',
  String source = 'agent.claude',
  String title = 'Flight DEN→LAX dropped to \$287',
  String? body,
}) {
  return Card(
    id: id,
    source: source,
    title: title,
    body: body,
    layout: CardLayout.medium,
    priority: CardPriority.normal,
    persistent: false,
    createdAt: DateTime(2026, 4, 17, 9, 0, 0),
  );
}

void main() {
  group('GenericAgentCard', () {
    testWidgets('renders the card title', (tester) async {
      await tester.pumpWidget(
        _wrap(GenericAgentCard(card: _card())),
      );
      expect(find.text('Flight DEN→LAX dropped to \$287'), findsOneWidget);
    });

    testWidgets('renders the source label', (tester) async {
      await tester.pumpWidget(
        _wrap(GenericAgentCard(card: _card(source: 'agent.claude'))),
      );
      expect(find.text('agent.claude'), findsOneWidget);
    });

    testWidgets('renders body text when present', (tester) async {
      await tester.pumpWidget(
        _wrap(GenericAgentCard(card: _card(body: 'Round trip, departing June 14.'))),
      );
      expect(find.text('Round trip, departing June 14.'), findsOneWidget);
    });

    testWidgets('does not render body area when body is null', (tester) async {
      await tester.pumpWidget(
        _wrap(GenericAgentCard(card: _card(body: null))),
      );
      // Only the title and source should be present, no extra text
      expect(find.text('Flight DEN→LAX dropped to \$287'), findsOneWidget);
      expect(find.text('agent.claude'), findsOneWidget);
      // Expect exactly these two Text widgets (no body text widget)
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('renders system source cards', (tester) async {
      await tester.pumpWidget(
        _wrap(GenericAgentCard(
          card: _card(source: 'system.weather', title: 'Clear skies'),
        )),
      );
      expect(find.text('system.weather'), findsOneWidget);
      expect(find.text('Clear skies'), findsOneWidget);
    });

    // ── token wiring ──────────────────────────────────────────────────────────

    testWidgets('applies title color from tokens', (tester) async {
      const primaryHex = '#f0e6ff';
      await tester.pumpWidget(
        _wrap(GenericAgentCard(
          card: _card(),
          tokens: _tokens(colorTextPrimary: primaryHex),
        )),
      );

      final titleWidget = tester.widget<Text>(
        find.text('Flight DEN→LAX dropped to \$287'),
      );
      expect(titleWidget.style?.color, const Color(0xFFf0e6ff));
    });

    testWidgets('applies source color from tokens', (tester) async {
      const secondaryHex = '#c4b5fd';
      await tester.pumpWidget(
        _wrap(GenericAgentCard(
          card: _card(),
          tokens: _tokens(colorTextSecondary: secondaryHex),
        )),
      );

      final sourceWidget = tester.widget<Text>(find.text('agent.claude'));
      expect(sourceWidget.style?.color, const Color(0xFFc4b5fd));
    });

    testWidgets('works correctly when tokens are null (fallback to defaults)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(GenericAgentCard(card: _card())),
      );
      expect(find.text('Flight DEN→LAX dropped to \$287'), findsOneWidget);
      expect(find.text('agent.claude'), findsOneWidget);
    });
  });
}
