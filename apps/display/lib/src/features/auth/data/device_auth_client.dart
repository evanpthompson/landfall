import 'dart:convert';

import 'package:http/http.dart' as http;

/// Wraps the two device-auth REST endpoints on the Landfall server.
///
/// POST /auth/device/start → [DeviceAuthStartResponse]
/// POST /auth/device/poll  → [DevicePollResponse]
abstract interface class DeviceAuthClient {
  Future<DeviceAuthStartResponse> startFlow();
  Future<DevicePollResponse> poll(String deviceCode);
}

class HttpDeviceAuthClient implements DeviceAuthClient {
  HttpDeviceAuthClient({required String serverUrl, http.Client? httpClient})
      : _base = serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl,
        _http = httpClient ?? http.Client();

  final String _base;
  final http.Client _http;

  @override
  Future<DeviceAuthStartResponse> startFlow() async {
    final res = await _http.post(
      Uri.parse('$_base/auth/device/start'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw Exception('Device auth start failed: ${res.statusCode}');
    }
    return DeviceAuthStartResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<DevicePollResponse> poll(String deviceCode) async {
    final res = await _http.post(
      Uri.parse('$_base/auth/device/poll'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceCode': deviceCode}),
    );
    if (res.statusCode != 200) {
      throw Exception('Device auth poll failed: ${res.statusCode}');
    }
    return DevicePollResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}

class DeviceAuthStartResponse {
  const DeviceAuthStartResponse({
    required this.userCode,
    required this.deviceCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  factory DeviceAuthStartResponse.fromJson(Map<String, dynamic> json) =>
      DeviceAuthStartResponse(
        userCode: json['userCode'] as String,
        deviceCode: json['deviceCode'] as String,
        verificationUri: json['verificationUri'] as String,
        expiresIn: json['expiresIn'] as int,
        interval: json['interval'] as int,
      );

  final String userCode;
  final String deviceCode;
  final String verificationUri;
  final int expiresIn;
  final int interval;
}

enum DevicePollStatus { authorizationPending, authorized, expiredToken }

class DevicePollResponse {
  const DevicePollResponse({required this.status, this.accessToken});

  factory DevicePollResponse.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status'] as String) {
      'authorized' => DevicePollStatus.authorized,
      'expired_token' => DevicePollStatus.expiredToken,
      _ => DevicePollStatus.authorizationPending,
    };
    return DevicePollResponse(
      status: status,
      accessToken: json['accessToken'] as String?,
    );
  }

  final DevicePollStatus status;
  final String? accessToken;
}
