import 'package:landfall_shared/landfall_shared.dart';

sealed class WeatherState {
  const WeatherState();
}

final class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

final class WeatherLoaded extends WeatherState {
  const WeatherLoaded({
    required this.current,
    required this.forecast,
    required this.fetchedAt,
    this.isStale = false,
  });

  final WeatherEntity current;
  final List<ForecastDayEntity> forecast;

  /// When this reading was last fetched successfully.
  final DateTime fetchedAt;

  /// True when a later refresh failed and this reading is being kept on
  /// screen anyway — yesterday's weather shown as if it were now is the
  /// "weather froze" report.
  final bool isStale;

  WeatherLoaded copyWith({bool? isStale}) => WeatherLoaded(
        current: current,
        forecast: forecast,
        fetchedAt: fetchedAt,
        isStale: isStale ?? this.isStale,
      );
}

final class WeatherError extends WeatherState {
  const WeatherError(this.message);

  final String message;
}
