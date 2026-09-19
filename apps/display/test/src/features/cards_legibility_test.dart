// The floor applied to the rest of the wall. See test/support/legibility.dart
// for what is being asserted and why these slot sizes.
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/cards/widgets/generic_agent_card.dart';
import 'package:display/src/features/clock/widgets/clock_card.dart';

import '../../support/legibility.dart';

final _now = DateTime(2026, 9, 19, 14, 32);

/// The agent feed is the remaining 1/6 of the width, less its padding. Height
/// is generous because the feed is a ListView: a card takes the height its
/// content needs rather than being squeezed into a fixed slot.
const _feedSlot = Size(296, 600);

Card _card({List<CardAction>? actions}) => Card(
      id: 'card-1',
      source: 'agent.claude',
      title: 'Meeting in 10 minutes',
      body: 'Sprint planning — Room 4B, with the design review straight after.',
      layout: CardLayout.medium,
      priority: CardPriority.normal,
      persistent: false,
      createdAt: _now,
      actions: actions,
    );

void main() {
  testWidgets('clock card is legible at its real slot', (tester) async {
    await expectLegibleAtSlot(
      tester,
      ClockCard(entity: ClockEntity(_now)),
      CardSlot.clock,
    );
  });

  testWidgets('clock card is legible with seconds and the date line on',
      (tester) async {
    await expectLegibleAtSlot(
      tester,
      ClockCard(
        entity: ClockEntity(_now),
        displayConfig: const {
          'hourFormat': '12',
          'showSeconds': true,
          'showDate': true,
        },
      ),
      CardSlot.clock,
    );
  });

  testWidgets('agent card is legible in the feed column', (tester) async {
    await expectLegibleAtSlot(tester, GenericAgentCard(card: _card()), _feedSlot);
  });

  testWidgets('agent card source stays readable — it is who is talking',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapInSlot(GenericAgentCard(card: _card()), _feedSlot),
    );
    await tester.pump();

    final source = tester.widgetList<Text>(find.text('agent.claude')).first;
    expect(source.style?.fontSize, greaterThanOrEqualTo(16));
  });
}
