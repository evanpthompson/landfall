import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/weather/cubit/weather_state.dart';

/// Fetches current weather and forecast from [WeatherRepository].
///
/// Call [loadWeather] once on startup and periodically (every 10 min) to
/// keep data fresh. The cubit reads from the server-side cache; the
/// repository handles local Drift caching and offline fallback transparently.
class WeatherCubit extends Cubit<WeatherState> {
  WeatherCubit(this._repository) : super(const WeatherLoading());

  final WeatherRepository _repository;

  Future<void> loadWeather() async {
    emit(const WeatherLoading());
    try {
      final results = await Future.wait([
        _repository.getCurrentWeather(),
        _repository.getForecast(),
      ]);
      final current = results[0] as WeatherEntity?;
      final forecast = results[1] as List<ForecastDayEntity>;
      if (current == null) {
        emit(const WeatherError('No weather data available yet.'));
        return;
      }
      emit(WeatherLoaded(current: current, forecast: forecast));
    } catch (e) {
      emit(WeatherError(e.toString()));
    }
  }
}
