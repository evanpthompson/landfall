import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/widgets/stale_badge.dart';

/// Combined current-conditions + forecast card.
///
/// Displays location, temperature, icon, condition, meta row, then a
/// 5-day forecast strip below a divider.
///
/// Responds to [displayConfig] keys:
/// - `unit`: `'f'` (default) or `'c'`
/// - `compact`: bool — hides feels-like/humidity/wind row
/// - `days`: 1, 3, or 5 (default 5) — forecast columns to show
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.current,
    required this.forecast,
    this.displayConfig = const {},
    this.staleSince,
  });

  final WeatherEntity current;
  final List<ForecastDayEntity> forecast;
  final Map<String, dynamic> displayConfig;

  /// When set, the reading could not be refreshed and was last fetched at this
  /// time — the card says so instead of passing it off as current.
  final DateTime? staleSince;

  @override
  Widget build(BuildContext context) {
    final tokens = LandfallActiveTheme.of(context);
    final useCelsius = displayConfig['unit'] == 'c';
    final compact = displayConfig['compact'] == true;
    final days = (displayConfig['days'] as int?) ?? 5;

    final temp = useCelsius ? current.tempC.round() : _toF(current.tempC);
    final feelsLike =
        useCelsius ? current.feelsLikeC.round() : _toF(current.feelsLikeC);
    final unitLabel = useCelsius ? 'C' : 'F';
    final windMph = (current.windSpeedMs * 2.237).round();

    final textPrimary = tokenColor(tokens.colorTextPrimary);
    final textSecondary = tokenColor(tokens.colorTextSecondary);
    final textTertiary = tokenColor(tokens.colorTextTertiary);
    final borderColor = tokenColor(tokens.cardBorderColor);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokenColor(tokens.cardFill),
        borderRadius: BorderRadius.circular(tokens.cardRadius.toDouble()),
        border: Border.all(color: borderColor, width: tokens.cardBorderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('WEATHER',
                    style: LandfallTypography.cardLabel
                        .copyWith(color: textTertiary)),
                if (staleSince != null) ...[
                  const Spacer(),
                  StaleBadge(fetchedAt: staleSince!),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Current conditions — FittedBox scales down width if slot is narrow.
            Flexible(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$temp°',
                          style: LandfallTypography.weatherTemp
                              .copyWith(color: textPrimary),
                        ),
                        const SizedBox(width: 14),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: weatherIcon(
                            current.iconCode,
                            size: 40,
                            fallbackColor: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${current.condition} · ${current.locationName}',
                      style: LandfallTypography.weatherCondition
                          .copyWith(color: textSecondary),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      _MetaRow(
                        feelsLike: 'Feels like $feelsLike°$unitLabel',
                        humidity: '${current.humidity}% humidity',
                        wind: '$windMph mph',
                        textTertiary: textTertiary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (forecast.isNotEmpty) ...[
              Divider(color: borderColor, height: 16),
              Flexible(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: forecast
                      .take(days)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (e) => Expanded(
                          child: _ForecastColumn(
                            day: e.value,
                            isToday: e.key == 0,
                            tokens: tokens,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static int _toF(double c) => (c * 9 / 5 + 32).round();

  /// Maps an OpenWeatherMap icon [code] (e.g. `01d`, `10n`) to a full-colour
  /// Meteocons PNG asset path, honouring the day/night suffix. Returns null
  /// for unknown codes so callers can fall back to [weatherIconData].
  ///
  /// Assets: Meteocons by Bas Milius (MIT) — see assets/weather/LICENSE.
  static String? meteoconAssetFor(String code) {
    if (code.isEmpty) return null;
    final prefix = code.length >= 2 ? code.substring(0, 2) : code;
    final isNight = code.endsWith('n');
    final name = switch (prefix) {
      '01' => isNight ? 'clear-night' : 'clear-day',
      '02' => isNight ? 'partly-cloudy-night' : 'partly-cloudy-day',
      '03' => 'cloudy',
      '04' => isNight ? 'overcast-night' : 'overcast-day',
      '09' => 'drizzle',
      '10' => 'rain',
      '11' => 'thunderstorms',
      '13' => 'snow',
      '50' => 'mist',
      _ => null,
    };
    return name == null ? null : 'assets/weather/$name.png';
  }

  /// Full-colour weather icon for an OWM [code]. Renders the Meteocons asset
  /// when available, falling back to the monochrome [weatherIconData] glyph
  /// (tinted [fallbackColor]) for unknown codes.
  static Widget weatherIcon(
    String code, {
    required double size,
    Color? fallbackColor,
  }) {
    final asset = meteoconAssetFor(code);
    if (asset != null) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      );
    }
    return Icon(weatherIconData(code), size: size, color: fallbackColor);
  }

  static IconData weatherIconData(String code) {
    final prefix = code.length >= 2 ? code.substring(0, 2) : code;
    return switch (prefix) {
      '01' => Icons.wb_sunny,
      '02' => Icons.wb_cloudy,
      '03' => Icons.cloud,
      '04' => Icons.cloud,
      '09' => Icons.grain,
      '10' => Icons.umbrella,
      '11' => Icons.flash_on,
      '13' => Icons.ac_unit,
      '50' => Icons.blur_on,
      _ => Icons.device_thermostat,
    };
  }
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

class _ForecastColumn extends StatelessWidget {
  const _ForecastColumn({
    required this.day,
    required this.isToday,
    required this.tokens,
  });

  final ForecastDayEntity day;
  final bool isToday;
  final LandfallThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final hi = _toF(day.maxTempC);
    final lo = _toF(day.minTempC);
    final textTertiary = tokenColor(tokens.colorTextTertiary);
    final textSecondary = tokenColor(tokens.colorTextSecondary);
    final textPrimary = tokenColor(tokens.colorTextPrimary);
    final label = isToday ? 'TODAY' : _shortDay(day.date);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: LandfallTypography.widgetHeading
                .copyWith(color: textTertiary),
          ),
          const SizedBox(height: 4),
          WeatherCard.weatherIcon(
            day.iconCode,
            size: 22,
            fallbackColor: textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            '$hi°',
            style: LandfallTypography.cardBody.copyWith(color: textPrimary),
          ),
          Text(
            '$lo°',
            style:
                LandfallTypography.caption.copyWith(color: textSecondary),
          ),
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
