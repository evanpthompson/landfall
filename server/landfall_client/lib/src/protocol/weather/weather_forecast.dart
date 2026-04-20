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

/// One row per forecast day cached from OpenWeatherMap.
/// Five rows (today+4) are replaced wholesale on each refresh.
abstract class WeatherForecast implements _i1.SerializableModel {
  WeatherForecast._({
    this.id,
    required this.locationName,
    required this.forecastDate,
    required this.minTempC,
    required this.maxTempC,
    required this.condition,
    required this.iconCode,
    required this.fetchedAt,
  });

  factory WeatherForecast({
    int? id,
    required String locationName,
    required DateTime forecastDate,
    required double minTempC,
    required double maxTempC,
    required String condition,
    required String iconCode,
    required DateTime fetchedAt,
  }) = _WeatherForecastImpl;

  factory WeatherForecast.fromJson(Map<String, dynamic> jsonSerialization) {
    return WeatherForecast(
      id: jsonSerialization['id'] as int?,
      locationName: jsonSerialization['locationName'] as String,
      forecastDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['forecastDate'],
      ),
      minTempC: (jsonSerialization['minTempC'] as num).toDouble(),
      maxTempC: (jsonSerialization['maxTempC'] as num).toDouble(),
      condition: jsonSerialization['condition'] as String,
      iconCode: jsonSerialization['iconCode'] as String,
      fetchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Location this forecast belongs to.
  String locationName;

  /// Midnight UTC for the forecast date.
  DateTime forecastDate;

  /// Low temperature in Celsius.
  double minTempC;

  /// High temperature in Celsius.
  double maxTempC;

  /// Short text description, e.g. "Light rain".
  String condition;

  /// OpenWeatherMap icon code for the representative period of the day.
  String iconCode;

  /// When this row was last fetched from the upstream API.
  DateTime fetchedAt;

  /// Returns a shallow copy of this [WeatherForecast]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WeatherForecast copyWith({
    int? id,
    String? locationName,
    DateTime? forecastDate,
    double? minTempC,
    double? maxTempC,
    String? condition,
    String? iconCode,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WeatherForecast',
      if (id != null) 'id': id,
      'locationName': locationName,
      'forecastDate': forecastDate.toJson(),
      'minTempC': minTempC,
      'maxTempC': maxTempC,
      'condition': condition,
      'iconCode': iconCode,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WeatherForecastImpl extends WeatherForecast {
  _WeatherForecastImpl({
    int? id,
    required String locationName,
    required DateTime forecastDate,
    required double minTempC,
    required double maxTempC,
    required String condition,
    required String iconCode,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         locationName: locationName,
         forecastDate: forecastDate,
         minTempC: minTempC,
         maxTempC: maxTempC,
         condition: condition,
         iconCode: iconCode,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [WeatherForecast]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WeatherForecast copyWith({
    Object? id = _Undefined,
    String? locationName,
    DateTime? forecastDate,
    double? minTempC,
    double? maxTempC,
    String? condition,
    String? iconCode,
    DateTime? fetchedAt,
  }) {
    return WeatherForecast(
      id: id is int? ? id : this.id,
      locationName: locationName ?? this.locationName,
      forecastDate: forecastDate ?? this.forecastDate,
      minTempC: minTempC ?? this.minTempC,
      maxTempC: maxTempC ?? this.maxTempC,
      condition: condition ?? this.condition,
      iconCode: iconCode ?? this.iconCode,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
