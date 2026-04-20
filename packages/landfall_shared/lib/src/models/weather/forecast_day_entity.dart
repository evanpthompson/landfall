/// Forecast conditions for a single calendar day.
class ForecastDayEntity {
  const ForecastDayEntity({
    required this.date,
    required this.minTempC,
    required this.maxTempC,
    required this.condition,
    required this.iconCode,
  });

  /// The calendar date this forecast applies to (time is midnight UTC).
  final DateTime date;

  final double minTempC;
  final double maxTempC;
  final String condition;

  /// OpenWeatherMap icon code, e.g. "01d", "09n".
  final String iconCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastDayEntity &&
          date == other.date &&
          minTempC == other.minTempC &&
          maxTempC == other.maxTempC &&
          condition == other.condition &&
          iconCode == other.iconCode;

  @override
  int get hashCode =>
      Object.hash(date, minTempC, maxTempC, condition, iconCode);

  @override
  String toString() =>
      'ForecastDayEntity(${date.toIso8601String().substring(0, 10)}, '
      '${minTempC.toStringAsFixed(1)}–${maxTempC.toStringAsFixed(1)}°C, $condition)';
}
