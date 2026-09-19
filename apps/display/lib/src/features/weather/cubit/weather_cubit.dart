import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/companion/companion_event_bus.dart';
import 'package:display/src/features/weather/cubit/weather_state.dart';

/// Fetches current weather and forecast from [WeatherRepository].
///
/// Call [loadWeather] once on startup and periodically (every 10 min) to
/// keep data fresh. The cubit reads from the server-side cache; the
/// repository handles local Drift caching and offline fallback transparently.
class WeatherCubit extends Cubit<WeatherState> {
  WeatherCubit(this._repository, {CompanionEventBus? bus, DateTime Function()? now})
      : _bus = bus,
        _now = now ?? DateTime.now,
        super(const WeatherLoading());

  final WeatherRepository _repository;
  final CompanionEventBus? _bus;
  final DateTime Function() _now;

  String? _lastCondition;

  Future<void> loadWeather() async {
    final previous = state;
    if (previous is! WeatherLoaded) {
      emit(const WeatherLoading());
    }
    try {
      final results = await Future.wait([
        _repository.getCurrentWeather(),
        _repository.getForecast(),
      ]);
      final current = results[0] as WeatherEntity?;
      final forecast = results[1] as List<ForecastDayEntity>;
      if (current == null) {
        if (previous is! WeatherLoaded) {
          emit(const WeatherError('No weather data available yet.'));
          return;
        }
        emit(previous.copyWith(isStale: true));
        return;
      }
      _emitBusTrigger(current.condition);
      _lastCondition = current.condition;
      emit(WeatherLoaded(
        current: current,
        forecast: forecast,
        fetchedAt: _now(),
      ));
    } catch (e) {
      // Stale weather beats no weather on a wall display, but it is labelled
      // rather than passed off as the current reading.
      if (previous is! WeatherLoaded) {
        emit(WeatherError(e.toString()));
        return;
      }
      emit(previous.copyWith(isStale: true));
    }
  }

  void _emitBusTrigger(String condition) {
    final bus = _bus;
    if (bus == null) return;
    if (condition == _lastCondition) return;
    final lower = condition.toLowerCase();
    if (_isRain(lower)) {
      bus.emit(CompanionTrigger.weatherChangedToRain);
    } else if (_isSun(lower)) {
      bus.emit(CompanionTrigger.weatherChangedToSun);
    }
  }

  static bool _isRain(String lower) =>
      lower.contains('rain') ||
      lower.contains('drizzle') ||
      lower.contains('shower') ||
      lower.contains('storm');

  static bool _isSun(String lower) =>
      lower.contains('sun') ||
      lower.contains('clear') ||
      lower.contains('fair');
}
