import 'package:landfall_shared/src/models/weather/weather_entity.dart';
import 'package:landfall_shared/src/models/weather/forecast_day_entity.dart';

abstract class WeatherRepository {
  Future<WeatherEntity?> getCurrentWeather();
  Future<List<ForecastDayEntity>> getForecast();
}
