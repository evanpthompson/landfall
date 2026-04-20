/// A snapshot of current weather conditions for a location.
class WeatherEntity {
  const WeatherEntity({
    required this.locationName,
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.iconCode,
    required this.humidity,
    required this.windSpeedMs,
    required this.fetchedAt,
  });

  final String locationName;
  final double tempC;
  final double feelsLikeC;
  final String condition;

  /// OpenWeatherMap icon code, e.g. "01d", "09n".
  /// Use to derive icon asset paths or API icon URLs.
  final String iconCode;

  /// Relative humidity, 0–100.
  final int humidity;

  final double windSpeedMs;
  final DateTime fetchedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherEntity &&
          locationName == other.locationName &&
          tempC == other.tempC &&
          feelsLikeC == other.feelsLikeC &&
          condition == other.condition &&
          iconCode == other.iconCode &&
          humidity == other.humidity &&
          windSpeedMs == other.windSpeedMs &&
          fetchedAt == other.fetchedAt;

  @override
  int get hashCode => Object.hash(
        locationName,
        tempC,
        feelsLikeC,
        condition,
        iconCode,
        humidity,
        windSpeedMs,
        fetchedAt,
      );

  @override
  String toString() =>
      'WeatherEntity($locationName, ${tempC.toStringAsFixed(1)}°C, $condition)';
}
