import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart' hide Card;
import 'package:ui_kit/ui_kit.dart';

import 'theme_card.dart' show ThemeSwatch;

/// A card in the marketplace browser representing a single [MarketplaceThemeInfo].
///
/// Shows the color swatch, name, optional author, price or Owned badge, and
/// fires [onTap] when tapped to open the detail sheet.
class MarketplaceThemeCard extends StatelessWidget {
  const MarketplaceThemeCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final MarketplaceThemeInfo entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: LandfallColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: entry.isOwned
                ? LandfallColors.accent
                : LandfallColors.cardBorder,
            width: entry.isOwned ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemeSwatch(tokens: entry.theme.tokens),
              const SizedBox(height: 10),
              Text(
                entry.theme.name,
                style: TextStyle(
                  color: entry.isOwned
                      ? LandfallColors.accent
                      : LandfallColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.theme.author != null) ...[
                const SizedBox(height: 2),
                Text(
                  entry.theme.author!,
                  style: const TextStyle(
                    color: LandfallColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              _PriceBadge(entry: entry),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.entry});

  final MarketplaceThemeInfo entry;

  @override
  Widget build(BuildContext context) {
    if (entry.isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: LandfallColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: LandfallColors.accent.withValues(alpha: 0.4)),
        ),
        child: const Text(
          'Owned',
          style: TextStyle(
            color: LandfallColors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Text(
      entry.displayPrice,
      style: const TextStyle(
        color: LandfallColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
