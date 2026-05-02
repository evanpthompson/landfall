import 'package:flutter/material.dart' hide Card;
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'card_action_button.dart';

/// Renders any [Card] from the agent push API.
///
/// When [tokens] are supplied, card surface and typography colours are driven
/// by the active theme. When null, falls back to [LandfallColors] defaults so
/// the widget is safe to use without a [ThemeCubit] in the tree.
class GenericAgentCard extends StatelessWidget {
  const GenericAgentCard({
    super.key,
    required this.card,
    this.tokens,
  });

  final Card card;

  /// Active theme token set. When provided, overrides hardcoded colours.
  final LandfallThemeTokens? tokens;

  @override
  Widget build(BuildContext context) {
    final hasActions = card.actions != null && card.actions!.isNotEmpty;

    final bgColor = _hex(tokens?.cardFill) ?? LandfallColors.surface;
    final borderColor =
        _hex(tokens?.cardBorderColor) ?? LandfallColors.cardBorder;
    final borderWidth = tokens?.cardBorderWidth ?? 1.5;
    final radius = tokens?.cardRadius.toDouble() ?? 8.0;
    final titleColor =
        _hex(tokens?.colorTextPrimary) ?? LandfallColors.textPrimary;
    final secondaryColor =
        _hex(tokens?.colorTextSecondary) ?? LandfallColors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.source,
              style: LandfallTypography.cardSource.copyWith(color: secondaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              card.title,
              style: LandfallTypography.cardTitle.copyWith(color: titleColor),
            ),
            if (card.body != null) ...[
              const SizedBox(height: 6),
              Text(
                card.body!,
                style:
                    LandfallTypography.cardBody.copyWith(color: secondaryColor),
              ),
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

  static Color? _hex(String? hex) {
    if (hex == null) return null;
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse(
      clean.length == 6 ? 'FF$clean' : clean,
      radix: 16,
    );
    return value == null ? null : Color(value);
  }
}
