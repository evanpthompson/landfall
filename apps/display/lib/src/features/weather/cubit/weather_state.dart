import 'package:landfall_shared/landfall_shared.dart';

sealed class WeatherState {
  const WeatherState();
}

final class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

final class WeatherLoaded extends WeatherState {
  const WeatherLoaded({required this.current, required this.forecast});

  final WeatherEntity current;
  final List<ForecastDayEntity> forecast;
}

final class WeatherError extends WeatherState {
  const WeatherError(this.message);

  final String message;
}
