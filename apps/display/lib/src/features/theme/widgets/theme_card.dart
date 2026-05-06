import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart' hide Card;
import 'package:ui_kit/ui_kit.dart';

import 'theme_preview_strip.dart';

/// A card in the theme browser representing a single [ThemeInfo].
///
/// Displays a color swatch sampled from the theme's accent and background
/// tokens, the theme name, optional author, a Built-in badge, and an
/// Apply button when the theme is not currently active.
class ThemeCard extends StatelessWidget {
  const ThemeCard({
    super.key,
    required this.theme,
    required this.isActive,
    required this.onApply,
  });

  final ThemeInfo theme;
  final bool isActive;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: LandfallColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isActive ? LandfallColors.accent : LandfallColors.cardBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThemePreviewStrip(tokens: theme.tokens),
            const SizedBox(height: 10),
            _Header(theme: theme, isActive: isActive),
            if (theme.author != null) ...[
              const SizedBox(height: 2),
              Text(
                theme.author!,
                style: const TextStyle(
                  color: LandfallColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            _Footer(
              isBuiltIn: theme.isBuiltIn,
              isActive: isActive,
              onApply: onApply,
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({super.key, required this.tokens});

  final LandfallThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final bg = _parseHex(tokens.backgroundValue);
    final accent = _parseHex(tokens.colorAccent);
    final card = _parseHex(tokens.cardFill);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ColoredBox(
                color: bg,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(width: 3, color: accent),
          ],
        ),
      ),
    );
  }

  static Color _parseHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse(
      clean.length == 6 ? 'FF$clean' : clean,
      radix: 16,
    );
    return Color(value ?? 0xFF1a1a1a);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme, required this.isActive});

  final ThemeInfo theme;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            theme.name,
            style: TextStyle(
              color: isActive ? LandfallColors.accent : LandfallColors.textPrimary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isActive)
          const Icon(Icons.check_circle, color: LandfallColors.accent, size: 16),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isBuiltIn,
    required this.isActive,
    required this.onApply,
  });

  final bool isBuiltIn;
  final bool isActive;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isBuiltIn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: LandfallColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: LandfallColors.cardBorder),
            ),
            child: const Text(
              'Built-in',
              style: TextStyle(
                color: LandfallColors.textSecondary,
                fontSize: 10,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        if (!isActive)
          SizedBox(
            height: 28,
            child: TextButton(
              onPressed: onApply,
              style: TextButton.styleFrom(
                foregroundColor: LandfallColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Apply'),
            ),
          ),
      ],
    );
  }
}
