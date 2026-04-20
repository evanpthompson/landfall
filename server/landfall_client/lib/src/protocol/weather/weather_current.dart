/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// Current weather conditions cached from OpenWeatherMap.
/// A single row is maintained per location — the service upserts on each refresh.
abstract class WeatherCurrent implements _i1.SerializableModel {
  WeatherCurrent._({
    this.id,
    required this.locationName,
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.iconCode,
    required this.humidity,
    required this.windSpeedMs,
    required this.fetchedAt,
  });

  factory WeatherCurrent({
    int? id,
    required String locationName,
    required double tempC,
    required double feelsLikeC,
    required String condition,
    required String iconCode,
    required int humidity,
    required double windSpeedMs,
    required DateTime fetchedAt,
  }) = _WeatherCurrentImpl;

  factory WeatherCurrent.fromJson(Map<String, dynamic> jsonSerialization) {
    return WeatherCurrent(
      id: jsonSerialization['id'] as int?,
      locationName: jsonSerialization['locationName'] as String,
      tempC: (jsonSerialization['tempC'] as num).toDouble(),
      feelsLikeC: (jsonSerialization['feelsLikeC'] as num).toDouble(),
      condition: jsonSerialization['condition'] as String,
      iconCode: jsonSerialization['iconCode'] as String,
      humidity: jsonSerialization['humidity'] as int,
      windSpeedMs: (jsonSerialization['windSpeedMs'] as num).toDouble(),
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Human-readable location name, e.g. "Chicago".
  String locationName;

  /// Current temperature in Celsius.
  double tempC;

  /// "Feels like" temperature in Celsius.
  double feelsLikeC;

  /// Short text description, e.g. "Clear sky".
  String condition;

  /// OpenWeatherMap icon code, e.g. "01d". Used to resolve icon assets.
  String iconCode;

  /// Relative humidity, 0–100.
  int humidity;

  /// Wind speed in m/s.
  double windSpeedMs;

  /// When this row was last fetched from the upstream API.
  DateTime fetchedAt;

  /// Returns a shallow copy of this [WeatherCurrent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WeatherCurrent copyWith({
    int? id,
    String? locationName,
    double? tempC,
    double? feelsLikeC,
    String? condition,
    String? iconCode,
    int? humidity,
    double? windSpeedMs,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WeatherCurrent',
      if (id != null) 'id': id,
      'locationName': locationName,
      'tempC': tempC,
      'feelsLikeC': feelsLikeC,
      'condition': condition,
      'iconCode': iconCode,
      'humidity': humidity,
      'windSpeedMs': windSpeedMs,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WeatherCurrentImpl extends WeatherCurrent {
  _WeatherCurrentImpl({
    int? id,
    required String locationName,
    required double tempC,
    required double feelsLikeC,
    required String condition,
    required String iconCode,
    required int humidity,
    required double windSpeedMs,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         locationName: locationName,
         tempC: tempC,
         feelsLikeC: feelsLikeC,
         condition: condition,
         iconCode: iconCode,
         humidity: humidity,
         windSpeedMs: windSpeedMs,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [WeatherCurrent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WeatherCurrent copyWith({
    Object? id = _Undefined,
    String? locationName,
    double? tempC,
    double? feelsLikeC,
    String? condition,
    String? iconCode,
    int? humidity,
    double? windSpeedMs,
    DateTime? fetchedAt,
  }) {
    return WeatherCurrent(
      id: id is int? ? id : this.id,
      locationName: locationName ?? this.locationName,
      tempC: tempC ?? this.tempC,
      feelsLikeC: feelsLikeC ?? this.feelsLikeC,
      condition: condition ?? this.condition,
      iconCode: iconCode ?? this.iconCode,
      humidity: humidity ?? this.humidity,
      windSpeedMs: windSpeedMs ?? this.windSpeedMs,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
