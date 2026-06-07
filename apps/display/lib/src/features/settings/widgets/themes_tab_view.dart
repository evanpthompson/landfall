import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/theme/cubit/theme_cubit.dart';
import 'package:display/src/features/theme/cubit/theme_state.dart';
import 'package:display/src/features/theme/screens/theme_browser_screen.dart';
import 'package:display/src/features/settings/widgets/section_header.dart';

class ThemesTabView extends StatelessWidget {
  const ThemesTabView({super.key, this.onAfterThemeApplied});

  /// Called after the user returns from [ThemeBrowserScreen].
  /// When provided (web context), the caller fires the push notification.
  final Future<void> Function()? onAfterThemeApplied;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionHeader('Active Theme'),
            const SizedBox(height: 12),
            _ActiveThemeTile(state: state),
            if (state is ThemeLoaded) ...[
              const SizedBox(height: 20),
              const SectionHeader('Token Colours'),
              const SizedBox(height: 12),
              _TokenSwatchPanel(tokens: state.active.tokens),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ThemeBrowserScreen(),
                      ),
                    )
                    .then((_) => onAfterThemeApplied?.call()),
                icon: const Icon(Icons.palette_outlined, size: 18),
                label: const Text('Browse Themes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LandfallColors.accent,
                  side: const BorderSide(color: LandfallColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveThemeTile extends StatelessWidget {
  const _ActiveThemeTile({required this.state});

  final ThemeState state;

  @override
  Widget build(BuildContext context) {
    if (state is! ThemeLoaded) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final theme = (state as ThemeLoaded).active;
    final accent = _parseHex(theme.tokens.colorAccent);
    final bg = _parseHex(theme.tokens.backgroundValue);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandfallColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    ColoredBox(color: bg, child: const SizedBox.expand()),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 6,
                      child: ColoredBox(color: accent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: const TextStyle(
                      color: LandfallColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (theme.author != null)
                    Text(
                      theme.author!,
                      style: const TextStyle(
                        color: LandfallColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: LandfallColors.accent,
              size: 18,
            ),
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

class _TokenSwatchPanel extends StatelessWidget {
  const _TokenSwatchPanel({required this.tokens});

  final LandfallThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final swatches = [
      ('Background', tokens.backgroundValue),
      ('Card Fill', tokens.cardFill),
      ('Card Border', tokens.cardBorderColor),
      ('Text Primary', tokens.colorTextPrimary),
      ('Text Secondary', tokens.colorTextSecondary),
      ('Text Tertiary', tokens.colorTextTertiary),
      ('Accent', tokens.colorAccent),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: swatches
          .map((entry) => _SwatchChip(label: entry.$1, colorStr: entry.$2))
          .toList(),
    );
  }
}

class _SwatchChip extends StatelessWidget {
  const _SwatchChip({required this.label, required this.colorStr});

  final String label;
  final String colorStr;

  @override
  Widget build(BuildContext context) {
    final color = tokenColor(colorStr);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: LandfallColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
