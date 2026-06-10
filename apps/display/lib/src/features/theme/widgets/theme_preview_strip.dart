import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// A compact preview strip that renders a mini representation of a theme's
/// token set without applying the theme globally.
///
/// Shows a swatch row, a mini clock tile, and a mini weather tile, all driven
/// by [tokens] injected via a local [LandfallActiveTheme] ancestor.
class ThemePreviewStrip extends StatelessWidget {
  const ThemePreviewStrip({super.key, required this.tokens});

  final LandfallThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return LandfallActiveTheme(
      tokens: tokens,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Swatch row
          SizedBox(
            key: const Key('preview_swatch_row'),
            height: 20,
            child: Row(
              children: [
                _Swatch(
                  key: const Key('preview_bg_swatch'),
                  colorStr: tokens.backgroundValue,
                  tooltip: 'Background',
                ),
                _Swatch(
                  colorStr: tokens.cardFill,
                  tooltip: 'Card',
                ),
                _Swatch(
                  key: const Key('preview_accent_swatch'),
                  colorStr: tokens.colorAccent,
                  tooltip: 'Accent',
                ),
                _Swatch(
                  colorStr: tokens.colorTextPrimary,
                  tooltip: 'Text',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _MiniClockTile(tokens: tokens)),
              const SizedBox(width: 8),
              Expanded(child: _MiniWeatherTile(tokens: tokens)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({super.key, required this.colorStr, required this.tooltip});

  final String colorStr;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            color: tokenColor(colorStr),
          ),
        ),
      ),
    );
  }
}

class _MiniClockTile extends StatelessWidget {
  const _MiniClockTile({required this.tokens});

  final LandfallThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final textPrimary = tokenColor(tokens.colorTextPrimary);
    final textSecondary = tokenColor(tokens.colorTextSecondary);

    return DecoratedBox(
      key: const Key('preview_clock_tile'),
      decoration: BoxDecoration(
        color: tokenColor(tokens.cardFill),
        borderRadius: BorderRadius.circular(tokens.cardRadius.toDouble()),
        border: Border.all(
          color: tokenColor(tokens.cardBorderColor),
          width: tokens.cardBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '12:00',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Tuesday, May 5',
                style: TextStyle(fontSize: 10, color: textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniWeatherTile extends StatelessWidget {
  const _MiniWeatherTile({required this.tokens});

  final LandfallThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final textPrimary = tokenColor(tokens.colorTextPrimary);
    final textSecondary = tokenColor(tokens.colorTextSecondary);
    final textTertiary = tokenColor(tokens.colorTextTertiary);

    return DecoratedBox(
      key: const Key('preview_weather_tile'),
      decoration: BoxDecoration(
        color: tokenColor(tokens.cardFill),
        borderRadius: BorderRadius.circular(tokens.cardRadius.toDouble()),
        border: Border.all(
          color: tokenColor(tokens.cardBorderColor),
          width: tokens.cardBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New York',
                  style: TextStyle(fontSize: 9, color: textTertiary)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '72°',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('☀️', style: TextStyle(fontSize: 16)),
                ],
              ),
              Text(
                'Clear',
                style: TextStyle(fontSize: 10, color: textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
