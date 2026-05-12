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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SourceBadge(source: card.source, borderColor: borderColor),
            const SizedBox(height: 10),
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

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source, required this.borderColor});

  final String source;
  final Color borderColor;

  static Color _badgeColor(String source) {
    if (source.startsWith('agent.')) {
      final name = source.substring(6).toLowerCase();
      return switch (name) {
        'claude' => const Color(0xFF3DD68C),
        'ci' || 'github' => const Color(0xFFF5A623),
        'slack' => const Color(0xFF4A154B),
        _ => const Color(0xFF6C9EFF),
      };
    }
    return const Color(0xFF6C9EFF);
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(source);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        source,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }
}
