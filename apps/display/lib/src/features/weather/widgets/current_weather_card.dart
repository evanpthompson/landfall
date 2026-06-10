import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'weather_card.dart';

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
    final tokens = LandfallActiveTheme.of(context);
    final useCelsius = displayConfig['unit'] == 'c';
    final compact = displayConfig['compact'] == true;

    final temp = useCelsius ? entity.tempC.round() : _toF(entity.tempC);
    final feelsLike =
        useCelsius ? entity.feelsLikeC.round() : _toF(entity.feelsLikeC);
    final unitLabel = useCelsius ? 'C' : 'F';
    final windMph = (entity.windSpeedMs * 2.237).round();

    final textPrimary = tokenColor(tokens.colorTextPrimary);
    final textSecondary = tokenColor(tokens.colorTextSecondary);
    final textTertiary = tokenColor(tokens.colorTextTertiary);

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entity.locationName,
                  style: LandfallTypography.widgetHeading
                      .copyWith(color: textTertiary)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$temp°',
                      style: LandfallTypography.weatherTemp
                          .copyWith(color: textPrimary)),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WeatherCard.weatherIcon(
                      entity.iconCode,
                      size: 36,
                      fallbackColor: textSecondary,
                    ),
                  ),
                ],
              ),
              Text(entity.condition,
                  style: LandfallTypography.weatherCondition
                      .copyWith(color: textSecondary)),
              if (!compact) ...[
                const SizedBox(height: 8),
                _MetaRow(
                  feelsLike: 'Feels like $feelsLike°$unitLabel',
                  humidity: '${entity.humidity}% humidity',
                  wind: '$windMph mph',
                  textTertiary: textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static int _toF(double c) => (c * 9 / 5 + 32).round();
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.textTertiary,
  });

  final String feelsLike;
  final String humidity;
  final String wind;
  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    final style = LandfallTypography.caption.copyWith(color: textTertiary);
    final dot = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('·', style: TextStyle(color: textTertiary)),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(feelsLike, style: style),
        dot,
        Text(humidity, style: style),
        dot,
        Text(wind, style: style),
      ],
    );
  }
}
