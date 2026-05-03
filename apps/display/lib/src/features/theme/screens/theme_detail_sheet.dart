import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart' hide Card;
import 'package:ui_kit/ui_kit.dart';

import '../widgets/theme_card.dart' show ThemeSwatch;

/// Modal bottom sheet showing full details for a marketplace theme.
///
/// Shows the color swatch, name, author, description, price, and an action
/// button (Apply for owned/free themes, Purchase for paid unowned themes).
class ThemeDetailSheet extends StatelessWidget {
  const ThemeDetailSheet({
    super.key,
    required this.entry,
    this.onApply,
    this.onPurchase,
  });

  final MarketplaceThemeInfo entry;
  final VoidCallback? onApply;
  final VoidCallback? onPurchase;

  static Future<void> show(
    BuildContext context, {
    required MarketplaceThemeInfo entry,
    VoidCallback? onApply,
    VoidCallback? onPurchase,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: LandfallColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ThemeDetailSheet(
        entry: entry,
        onApply: onApply,
        onPurchase: onPurchase,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = entry.theme;
    final canApply = entry.isOwned || entry.isFree;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemeSwatch(tokens: theme.tokens),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: const TextStyle(
                        color: LandfallColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (theme.author != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        theme.author!,
                        style: const TextStyle(
                          color: LandfallColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _PriceChip(entry: entry),
            ],
          ),
          if (theme.description != null) ...[
            const SizedBox(height: 12),
            Text(
              theme.description!,
              style: const TextStyle(
                color: LandfallColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: canApply
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onApply?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LandfallColors.accent,
                      foregroundColor: LandfallColors.background,
                    ),
                    child: const Text('Apply'),
                  )
                : ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onPurchase?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LandfallColors.surface,
                      foregroundColor: LandfallColors.accent,
                      side: const BorderSide(color: LandfallColors.accent),
                    ),
                    child: const Text('Purchase'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.entry});

  final MarketplaceThemeInfo entry;

  @override
  Widget build(BuildContext context) {
    if (entry.isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: LandfallColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: LandfallColors.accent.withValues(alpha: 0.4)),
        ),
        child: const Text(
          'Owned',
          style: TextStyle(
            color: LandfallColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: LandfallColors.cardBorder),
      ),
      child: Text(
        entry.displayPrice,
        style: const TextStyle(
          color: LandfallColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
