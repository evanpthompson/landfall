import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Displays current weather conditions from a [WeatherEntity].
///
/// Shows temperature (°F), condition, feels-like, humidity, and wind speed.
/// Pure presentational — wrap with [BlocBuilder<WeatherCubit, WeatherState>].
class CurrentWeatherCard extends StatelessWidget {
  const CurrentWeatherCard({super.key, required this.entity});

  final WeatherEntity entity;

  @override
  Widget build(BuildContext context) {
    final tempF = _toF(entity.tempC);
    final feelsF = _toF(entity.feelsLikeC);
    final windMph = (entity.windSpeedMs * 2.237).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandfallColors.cardBorder, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(entity.locationName, style: LandfallTypography.widgetHeading),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$tempF°', style: LandfallTypography.weatherTemp),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _weatherIcon(entity.iconCode),
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ],
            ),
            Text(entity.condition, style: LandfallTypography.weatherCondition),
            const SizedBox(height: 8),
            _MetaRow(
              feelsLike: 'Feels like $feelsF°F',
              humidity: '${entity.humidity}% humidity',
              wind: '$windMph mph',
            ),
          ],
        ),
      ),
    );
  }

  static int _toF(double c) => (c * 9 / 5 + 32).round();

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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.feelsLike,
    required this.humidity,
    required this.wind,
  });

  final String feelsLike;
  final String humidity;
  final String wind;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: Text(feelsLike, style: LandfallTypography.caption, overflow: TextOverflow.ellipsis)),
        _dot,
        Flexible(child: Text(humidity, style: LandfallTypography.caption, overflow: TextOverflow.ellipsis)),
        _dot,
        Flexible(child: Text(wind, style: LandfallTypography.caption, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  static const _dot = Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text('·', style: TextStyle(color: LandfallColors.textTertiary)),
  );
}
