import 'package:flutter/material.dart' hide Card;
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'card_action_button.dart';

/// Renders any [Card] from the agent push API.
///
/// This is the fallback renderer — every card that does not have a dedicated
/// display template (weather, calendar, etc.) is rendered here. It shows the
/// source label, title, optional body, and any [CardAction] buttons.
///
/// This is a pure presentational widget. Wire it with
/// [BlocBuilder<CardCubit, CardState>] in the parent screen.
class GenericAgentCard extends StatelessWidget {
  const GenericAgentCard({super.key, required this.card});

  final Card card;

  @override
  Widget build(BuildContext context) {
    final hasActions =
        card.actions != null && card.actions!.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LandfallColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.source, style: LandfallTypography.cardSource),
            const SizedBox(height: 8),
            Text(card.title, style: LandfallTypography.cardTitle),
            if (card.body != null) ...[
              const SizedBox(height: 6),
              Text(card.body!, style: LandfallTypography.cardBody),
            ],
            if (hasActions) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: card.actions!
                    .map((a) => CardActionButton(card: card, action: a))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
