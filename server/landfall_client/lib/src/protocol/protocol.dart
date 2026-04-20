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
import 'agent/api_key.dart' as _i2;
import 'agent/api_key_create_response.dart' as _i3;
import 'agent/landfall_exception.dart' as _i4;
import 'cards/card_push_request.dart' as _i5;
import 'cards/card_row.dart' as _i6;
import 'greetings/greeting.dart' as _i7;
import 'weather/weather_current.dart' as _i8;
import 'weather/weather_forecast.dart' as _i9;
import 'package:landfall_client/src/protocol/cards/card_row.dart' as _i10;
import 'package:landfall_client/src/protocol/agent/api_key.dart' as _i11;
import 'package:landfall_client/src/protocol/weather/weather_forecast.dart'
    as _i12;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i13;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i14;
export 'agent/api_key.dart';
export 'agent/api_key_create_response.dart';
export 'agent/landfall_exception.dart';
export 'cards/card_push_request.dart';
export 'cards/card_row.dart';
export 'greetings/greeting.dart';
export 'weather/weather_current.dart';
export 'weather/weather_forecast.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.ApiKey) {
      return _i2.ApiKey.fromJson(data) as T;
    }
    if (t == _i3.ApiKeyCreateResponse) {
      return _i3.ApiKeyCreateResponse.fromJson(data) as T;
    }
    if (t == _i4.LandfallException) {
      return _i4.LandfallException.fromJson(data) as T;
    }
    if (t == _i5.CardPushRequest) {
      return _i5.CardPushRequest.fromJson(data) as T;
    }
    if (t == _i6.CardRow) {
      return _i6.CardRow.fromJson(data) as T;
    }
    if (t == _i7.Greeting) {
      return _i7.Greeting.fromJson(data) as T;
    }
    if (t == _i8.WeatherCurrent) {
      return _i8.WeatherCurrent.fromJson(data) as T;
    }
    if (t == _i9.WeatherForecast) {
      return _i9.WeatherForecast.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.ApiKey?>()) {
      return (data != null ? _i2.ApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.ApiKeyCreateResponse?>()) {
      return (data != null ? _i3.ApiKeyCreateResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.LandfallException?>()) {
      return (data != null ? _i4.LandfallException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.CardPushRequest?>()) {
      return (data != null ? _i5.CardPushRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.CardRow?>()) {
      return (data != null ? _i6.CardRow.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Greeting?>()) {
      return (data != null ? _i7.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.WeatherCurrent?>()) {
      return (data != null ? _i8.WeatherCurrent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.WeatherForecast?>()) {
      return (data != null ? _i9.WeatherForecast.fromJson(data) : null) as T;
    }
    if (t == List<_i10.CardRow>) {
      return (data as List).map((e) => deserialize<_i10.CardRow>(e)).toList()
          as T;
    }
    if (t == List<_i11.ApiKey>) {
      return (data as List).map((e) => deserialize<_i11.ApiKey>(e)).toList()
          as T;
    }
    if (t == List<_i12.WeatherForecast>) {
      return (data as List)
              .map((e) => deserialize<_i12.WeatherForecast>(e))
              .toList()
          as T;
    }
    try {
      return _i13.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i14.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.ApiKey => 'ApiKey',
      _i3.ApiKeyCreateResponse => 'ApiKeyCreateResponse',
      _i4.LandfallException => 'LandfallException',
      _i5.CardPushRequest => 'CardPushRequest',
      _i6.CardRow => 'CardRow',
      _i7.Greeting => 'Greeting',
      _i8.WeatherCurrent => 'WeatherCurrent',
      _i9.WeatherForecast => 'WeatherForecast',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('landfall.', '');
    }

    switch (data) {
      case _i2.ApiKey():
        return 'ApiKey';
      case _i3.ApiKeyCreateResponse():
        return 'ApiKeyCreateResponse';
      case _i4.LandfallException():
        return 'LandfallException';
      case _i5.CardPushRequest():
        return 'CardPushRequest';
      case _i6.CardRow():
        return 'CardRow';
      case _i7.Greeting():
        return 'Greeting';
      case _i8.WeatherCurrent():
        return 'WeatherCurrent';
      case _i9.WeatherForecast():
        return 'WeatherForecast';
    }
    className = _i13.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i14.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ApiKey') {
      return deserialize<_i2.ApiKey>(data['data']);
    }
    if (dataClassName == 'ApiKeyCreateResponse') {
      return deserialize<_i3.ApiKeyCreateResponse>(data['data']);
    }
    if (dataClassName == 'LandfallException') {
      return deserialize<_i4.LandfallException>(data['data']);
    }
    if (dataClassName == 'CardPushRequest') {
      return deserialize<_i5.CardPushRequest>(data['data']);
    }
    if (dataClassName == 'CardRow') {
      return deserialize<_i6.CardRow>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i7.Greeting>(data['data']);
    }
    if (dataClassName == 'WeatherCurrent') {
      return deserialize<_i8.WeatherCurrent>(data['data']);
    }
    if (dataClassName == 'WeatherForecast') {
      return deserialize<_i9.WeatherForecast>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i13.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i14.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i13.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i14.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
