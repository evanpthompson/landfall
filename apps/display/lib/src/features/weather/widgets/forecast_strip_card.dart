import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// A horizontal 5-day forecast strip.
///
/// Each column shows: short day name, weather emoji, high/low in °F.
/// Pure presentational — wrap with [BlocBuilder<WeatherCubit, WeatherState>].
class ForecastStripCard extends StatelessWidget {
  const ForecastStripCard({super.key, required this.forecast});

  final List<ForecastDayEntity> forecast;

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandfallColors.cardBorder, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: forecast
              .map((day) => Expanded(child: _DayColumn(day: day)))
              .toList(),
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.day});

  final ForecastDayEntity day;

  @override
  Widget build(BuildContext context) {
    final hi = _toF(day.maxTempC);
    final lo = _toF(day.minTempC);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_shortDay(day.date), style: LandfallTypography.widgetHeading),
          const SizedBox(height: 4),
          Text(_weatherIcon(day.iconCode), style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text('$hi°', style: LandfallTypography.cardBody),
          Text('$lo°', style: LandfallTypography.caption),
        ],
      ),
    );
  }

  static int _toF(double c) => (c * 9 / 5 + 32).round();

  static String _shortDay(DateTime dt) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[dt.weekday - 1];
  }

  static String _weatherIcon(String code) {
    final prefix = code.length >= 2 ? code.substring(0, 2) : code;
    return switch (prefix) {
      '01' => '☀️',
      '02' => '⛅',
      '03' => '🌥',
      '04' => '☁️',
      '09' => '🌧',
      '10' => '🌦',
      '11' => '⛈',
      '13' => '❄️',
      '50' => '🌫',
      _ => '🌡',
    };
  }
}
