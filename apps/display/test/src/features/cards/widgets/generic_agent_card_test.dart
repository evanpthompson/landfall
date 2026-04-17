import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/cards/widgets/generic_agent_card.dart';

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
  });
}
