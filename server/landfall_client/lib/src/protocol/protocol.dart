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
import 'auth/otp_account.dart' as _i5;
import 'auth/otp_request.dart' as _i6;
import 'calendar/calendar_event.dart' as _i7;
import 'cards/card_push_request.dart' as _i8;
import 'cards/card_row.dart' as _i9;
import 'greetings/greeting.dart' as _i10;
import 'layout/layout_config.dart' as _i11;
import 'license/integration_pack.dart' as _i12;
import 'license/license_key.dart' as _i13;
import 'license/license_status_response.dart' as _i14;
import 'license/owned_pack.dart' as _i15;
import 'license/pack_info_response.dart' as _i16;
import 'photo/photo.dart' as _i17;
import 'settings/linked_credential_summary.dart' as _i18;
import 'weather/weather_current.dart' as _i19;
import 'weather/weather_forecast.dart' as _i20;
import 'package:landfall_client/src/protocol/cards/card_row.dart' as _i21;
import 'package:landfall_client/src/protocol/agent/api_key.dart' as _i22;
import 'dart:typed_data' as _i23;
import 'package:landfall_client/src/protocol/calendar/calendar_event.dart'
    as _i24;
import 'package:landfall_client/src/protocol/layout/layout_config.dart' as _i25;
import 'package:landfall_client/src/protocol/license/pack_info_response.dart'
    as _i26;
import 'package:landfall_client/src/protocol/photo/photo.dart' as _i27;
import 'package:landfall_client/src/protocol/settings/linked_credential_summary.dart'
    as _i28;
import 'package:landfall_client/src/protocol/weather/weather_forecast.dart'
    as _i29;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i30;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i31;
export 'agent/api_key.dart';
export 'agent/api_key_create_response.dart';
export 'agent/landfall_exception.dart';
export 'auth/otp_account.dart';
export 'auth/otp_request.dart';
export 'calendar/calendar_event.dart';
export 'cards/card_push_request.dart';
export 'cards/card_row.dart';
export 'greetings/greeting.dart';
export 'layout/layout_config.dart';
export 'license/integration_pack.dart';
export 'license/license_key.dart';
export 'license/license_status_response.dart';
export 'license/owned_pack.dart';
export 'license/pack_info_response.dart';
export 'photo/photo.dart';
export 'settings/linked_credential_summary.dart';
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
    if (t == _i5.OtpAccount) {
      return _i5.OtpAccount.fromJson(data) as T;
    }
    if (t == _i6.OtpRequest) {
      return _i6.OtpRequest.fromJson(data) as T;
    }
    if (t == _i7.CalendarEvent) {
      return _i7.CalendarEvent.fromJson(data) as T;
    }
    if (t == _i8.CardPushRequest) {
      return _i8.CardPushRequest.fromJson(data) as T;
    }
    if (t == _i9.CardRow) {
      return _i9.CardRow.fromJson(data) as T;
    }
    if (t == _i10.Greeting) {
      return _i10.Greeting.fromJson(data) as T;
    }
    if (t == _i11.LayoutConfig) {
      return _i11.LayoutConfig.fromJson(data) as T;
    }
    if (t == _i12.IntegrationPack) {
      return _i12.IntegrationPack.fromJson(data) as T;
    }
    if (t == _i13.LicenseKey) {
      return _i13.LicenseKey.fromJson(data) as T;
    }
    if (t == _i14.LicenseStatusResponse) {
      return _i14.LicenseStatusResponse.fromJson(data) as T;
    }
    if (t == _i15.OwnedPack) {
      return _i15.OwnedPack.fromJson(data) as T;
    }
    if (t == _i16.PackInfoResponse) {
      return _i16.PackInfoResponse.fromJson(data) as T;
    }
    if (t == _i17.Photo) {
      return _i17.Photo.fromJson(data) as T;
    }
    if (t == _i18.LinkedCredentialSummary) {
      return _i18.LinkedCredentialSummary.fromJson(data) as T;
    }
    if (t == _i19.WeatherCurrent) {
      return _i19.WeatherCurrent.fromJson(data) as T;
    }
    if (t == _i20.WeatherForecast) {
      return _i20.WeatherForecast.fromJson(data) as T;
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
    if (t == _i1.getType<_i5.OtpAccount?>()) {
      return (data != null ? _i5.OtpAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.OtpRequest?>()) {
      return (data != null ? _i6.OtpRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.CalendarEvent?>()) {
      return (data != null ? _i7.CalendarEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.CardPushRequest?>()) {
      return (data != null ? _i8.CardPushRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.CardRow?>()) {
      return (data != null ? _i9.CardRow.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.Greeting?>()) {
      return (data != null ? _i10.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.LayoutConfig?>()) {
      return (data != null ? _i11.LayoutConfig.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.IntegrationPack?>()) {
      return (data != null ? _i12.IntegrationPack.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.LicenseKey?>()) {
      return (data != null ? _i13.LicenseKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.LicenseStatusResponse?>()) {
      return (data != null ? _i14.LicenseStatusResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.OwnedPack?>()) {
      return (data != null ? _i15.OwnedPack.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.PackInfoResponse?>()) {
      return (data != null ? _i16.PackInfoResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.Photo?>()) {
      return (data != null ? _i17.Photo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.LinkedCredentialSummary?>()) {
      return (data != null ? _i18.LinkedCredentialSummary.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.WeatherCurrent?>()) {
      return (data != null ? _i19.WeatherCurrent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.WeatherForecast?>()) {
      return (data != null ? _i20.WeatherForecast.fromJson(data) : null) as T;
    }
    if (t == List<_i21.CardRow>) {
      return (data as List).map((e) => deserialize<_i21.CardRow>(e)).toList()
          as T;
    }
    if (t == List<_i22.ApiKey>) {
      return (data as List).map((e) => deserialize<_i22.ApiKey>(e)).toList()
          as T;
    }
    if (t == _i1.getType<({_i23.ByteData challenge, _i1.UuidValue id})>()) {
      return (
            challenge: deserialize<_i23.ByteData>(
              ((data as Map)['n'] as Map)['challenge'],
            ),
            id: deserialize<_i1.UuidValue>(data['n']['id']),
          )
          as T;
    }
    if (t == List<_i24.CalendarEvent>) {
      return (data as List)
              .map((e) => deserialize<_i24.CalendarEvent>(e))
              .toList()
          as T;
    }
    if (t == List<_i25.LayoutConfig>) {
      return (data as List)
              .map((e) => deserialize<_i25.LayoutConfig>(e))
              .toList()
          as T;
    }
    if (t == List<_i26.PackInfoResponse>) {
      return (data as List)
              .map((e) => deserialize<_i26.PackInfoResponse>(e))
              .toList()
          as T;
    }
    if (t == List<_i27.Photo>) {
      return (data as List).map((e) => deserialize<_i27.Photo>(e)).toList()
          as T;
    }
    if (t == List<_i28.LinkedCredentialSummary>) {
      return (data as List)
              .map((e) => deserialize<_i28.LinkedCredentialSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i29.WeatherForecast>) {
      return (data as List)
              .map((e) => deserialize<_i29.WeatherForecast>(e))
              .toList()
          as T;
    }
    try {
      return _i30.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i31.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.ApiKey => 'ApiKey',
      _i3.ApiKeyCreateResponse => 'ApiKeyCreateResponse',
      _i4.LandfallException => 'LandfallException',
      _i5.OtpAccount => 'OtpAccount',
      _i6.OtpRequest => 'OtpRequest',
      _i7.CalendarEvent => 'CalendarEvent',
      _i8.CardPushRequest => 'CardPushRequest',
      _i9.CardRow => 'CardRow',
      _i10.Greeting => 'Greeting',
      _i11.LayoutConfig => 'LayoutConfig',
      _i12.IntegrationPack => 'IntegrationPack',
      _i13.LicenseKey => 'LicenseKey',
      _i14.LicenseStatusResponse => 'LicenseStatusResponse',
      _i15.OwnedPack => 'OwnedPack',
      _i16.PackInfoResponse => 'PackInfoResponse',
      _i17.Photo => 'Photo',
      _i18.LinkedCredentialSummary => 'LinkedCredentialSummary',
      _i19.WeatherCurrent => 'WeatherCurrent',
      _i20.WeatherForecast => 'WeatherForecast',
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
      case _i5.OtpAccount():
        return 'OtpAccount';
      case _i6.OtpRequest():
        return 'OtpRequest';
      case _i7.CalendarEvent():
        return 'CalendarEvent';
      case _i8.CardPushRequest():
        return 'CardPushRequest';
      case _i9.CardRow():
        return 'CardRow';
      case _i10.Greeting():
        return 'Greeting';
      case _i11.LayoutConfig():
        return 'LayoutConfig';
      case _i12.IntegrationPack():
        return 'IntegrationPack';
      case _i13.LicenseKey():
        return 'LicenseKey';
      case _i14.LicenseStatusResponse():
        return 'LicenseStatusResponse';
      case _i15.OwnedPack():
        return 'OwnedPack';
      case _i16.PackInfoResponse():
        return 'PackInfoResponse';
      case _i17.Photo():
        return 'Photo';
      case _i18.LinkedCredentialSummary():
        return 'LinkedCredentialSummary';
      case _i19.WeatherCurrent():
        return 'WeatherCurrent';
      case _i20.WeatherForecast():
        return 'WeatherForecast';
    }
    className = _i30.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i31.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'OtpAccount') {
      return deserialize<_i5.OtpAccount>(data['data']);
    }
    if (dataClassName == 'OtpRequest') {
      return deserialize<_i6.OtpRequest>(data['data']);
    }
    if (dataClassName == 'CalendarEvent') {
      return deserialize<_i7.CalendarEvent>(data['data']);
    }
    if (dataClassName == 'CardPushRequest') {
      return deserialize<_i8.CardPushRequest>(data['data']);
    }
    if (dataClassName == 'CardRow') {
      return deserialize<_i9.CardRow>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i10.Greeting>(data['data']);
    }
    if (dataClassName == 'LayoutConfig') {
      return deserialize<_i11.LayoutConfig>(data['data']);
    }
    if (dataClassName == 'IntegrationPack') {
      return deserialize<_i12.IntegrationPack>(data['data']);
    }
    if (dataClassName == 'LicenseKey') {
      return deserialize<_i13.LicenseKey>(data['data']);
    }
    if (dataClassName == 'LicenseStatusResponse') {
      return deserialize<_i14.LicenseStatusResponse>(data['data']);
    }
    if (dataClassName == 'OwnedPack') {
      return deserialize<_i15.OwnedPack>(data['data']);
    }
    if (dataClassName == 'PackInfoResponse') {
      return deserialize<_i16.PackInfoResponse>(data['data']);
    }
    if (dataClassName == 'Photo') {
      return deserialize<_i17.Photo>(data['data']);
    }
    if (dataClassName == 'LinkedCredentialSummary') {
      return deserialize<_i18.LinkedCredentialSummary>(data['data']);
    }
    if (dataClassName == 'WeatherCurrent') {
      return deserialize<_i19.WeatherCurrent>(data['data']);
    }
    if (dataClassName == 'WeatherForecast') {
      return deserialize<_i20.WeatherForecast>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i30.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i31.Protocol().deserializeByClassName(data);
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
    if (record is ({_i23.ByteData challenge, _i1.UuidValue id})) {
      return {
        "n": {
          "challenge": record.challenge.toJson(),
          "id": record.id.toJson(),
        },
      };
    }
    try {
      return _i30.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i31.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }

  /// Maps container types (like [List], [Map], [Set]) containing
  /// [Record]s or non-String-keyed [Map]s to their JSON representation.
  ///
  /// It should not be called for [SerializableModel] types. These
  /// handle the "[Record] in container" mapping internally already.
  ///
  /// It is only supposed to be called from generated protocol code.
  ///
  /// Returns either a `List<dynamic>` (for List, Sets, and Maps with
  /// non-String keys) or a `Map<String, dynamic>` in case the input was
  /// a `Map<String, …>`.
  Object? mapContainerToJson(Object obj) {
    if (obj is! Iterable && obj is! Map) {
      throw ArgumentError.value(
        obj,
        'obj',
        'The object to serialize should be of type List, Map, or Set',
      );
    }

    dynamic mapIfNeeded(Object? obj) {
      return switch (obj) {
        Record record => mapRecordToJson(record),
        Iterable iterable => mapContainerToJson(iterable),
        Map map => mapContainerToJson(map),
        Object? value => value,
      };
    }

    switch (obj) {
      case Map<String, dynamic>():
        return {
          for (var entry in obj.entries) entry.key: mapIfNeeded(entry.value),
        };
      case Map():
        return [
          for (var entry in obj.entries)
            {
              'k': mapIfNeeded(entry.key),
              'v': mapIfNeeded(entry.value),
            },
        ];

      case Iterable():
        return [
          for (var e in obj) mapIfNeeded(e),
        ];
    }

    return obj;
  }
}
