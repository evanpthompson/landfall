import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'weather_card.dart';

/// A horizontal forecast strip.
///
/// Each column shows: short day name, weather emoji, high/low in °F.
/// Pure presentational — wrap with [BlocBuilder<WeatherCubit, WeatherState>].
///
/// Responds to [displayConfig] key:
/// - `days`: `1`, `3`, or `5` (default `5`) — number of day columns to show
class ForecastStripCard extends StatelessWidget {
  const ForecastStripCard({
    super.key,
    required this.forecast,
    this.displayConfig = const {},
  });

  final List<ForecastDayEntity> forecast;
  final Map<String, dynamic> displayConfig;

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    final tokens = LandfallActiveTheme.of(context);
    final days = (displayConfig['days'] as int?) ?? 5;
    final visible = forecast.take(days).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokenColor(tokens.cardFill),
        borderRadius: BorderRadius.circular(tokens.cardRadius.toDouble()),
        border: Border.all(
          color: tokenColor(tokens.cardBorderColor),
          width: tokens.cardBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: visible
              .map((day) => Expanded(child: _DayColumn(day: day, tokens: tokens)))
              .toList(),
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.day, required this.tokens});

  final ForecastDayEntity day;
  final LandfallThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final hi = _toF(day.maxTempC);
    final lo = _toF(day.minTempC);
    final textTertiary = tokenColor(tokens.colorTextTertiary);
    final textSecondary = tokenColor(tokens.colorTextSecondary);
    final textPrimary = tokenColor(tokens.colorTextPrimary);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_shortDay(day.date),
              style: LandfallTypography.widgetHeading
                  .copyWith(color: textTertiary)),
          const SizedBox(height: 4),
          Icon(WeatherCard.weatherIconData(day.iconCode), size: 24, color: textSecondary),
          const SizedBox(height: 4),
          Text('$hi°',
              style: LandfallTypography.cardBody.copyWith(color: textPrimary)),
          Text('$lo°',
              style: LandfallTypography.caption.copyWith(color: textSecondary)),
        ],
      ),
    );
  }

  static int _toF(double c) => (c * 9 / 5 + 32).round();

  static String _shortDay(DateTime dt) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[dt.weekday - 1];
  }

}
