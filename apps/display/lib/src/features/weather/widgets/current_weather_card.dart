import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Displays current weather conditions from a [WeatherEntity].
///
/// Responds to [displayConfig] keys:
/// - `unit`: `'f'` (default) or `'c'`
/// - `compact`: bool (default `false`) — hides feels-like/humidity/wind row
class CurrentWeatherCard extends StatelessWidget {
  const CurrentWeatherCard({
    super.key,
    required this.entity,
    this.displayConfig = const {},
  });

  final WeatherEntity entity;
  final Map<String, dynamic> displayConfig;

  @override
  Widget build(BuildContext context) {
    final useCelsius = displayConfig['unit'] == 'c';
    final compact = displayConfig['compact'] == true;

    final temp = useCelsius
        ? entity.tempC.round()
        : _toF(entity.tempC);
    final feelsLike = useCelsius
        ? entity.feelsLikeC.round()
        : _toF(entity.feelsLikeC);
    final unitLabel = useCelsius ? 'C' : 'F';
    final windMph = (entity.windSpeedMs * 2.237).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LandfallColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandfallColors.cardBorder, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entity.locationName, style: LandfallTypography.widgetHeading),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$temp°', style: LandfallTypography.weatherTemp),
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
              if (!compact) ...[
                const SizedBox(height: 8),
                _MetaRow(
                  feelsLike: 'Feels like $feelsLike°$unitLabel',
                  humidity: '${entity.humidity}% humidity',
                  wind: '$windMph mph',
                ),
              ],
            ],
          ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(feelsLike, style: LandfallTypography.caption),
        _dot,
        Text(humidity, style: LandfallTypography.caption),
        _dot,
        Text(wind, style: LandfallTypography.caption),
      ],
    );
  }

  static const _dot = Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text('·', style: TextStyle(color: LandfallColors.textTertiary)),
  );
}
