import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin HTTP wrapper over the Landfall Agent API.
///
/// All methods throw [LandfallApiException] on non-200 responses or network
/// errors so callers never need to inspect raw HTTP status codes.
abstract interface class LandfallApi {
  Future<Map<String, dynamic>> pushCard({
    required String source,
    required String title,
    String? body,
    String? dataJson,
    String? layout,
    String? priority,
    String? expiresAt,
    bool? persistent,
    String? externalId,
  });

  Future<Map<String, dynamic>> updateCard({
    required String externalId,
    required String source,
    required String title,
    String? body,
    String? layout,
    String? priority,
  });

  Future<bool> dismissCard(String externalId);

  Future<List<Map<String, dynamic>>> listCards();
}

class LandfallClient implements LandfallApi {
  LandfallClient({
    required this.baseUrl,
    required this.apiKey,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final http.Client _http;

  @override
  Future<Map<String, dynamic>> pushCard({
    required String source,
    required String title,
    String? body,
    String? dataJson,
    String? layout,
    String? priority,
    String? expiresAt,
    bool? persistent,
    String? externalId,
  }) async {
    final result = await _post('/agent/pushCard', {
      'apiKey': apiKey,
      'request': {
        '__className__': 'CardPushRequest',
        'source': source,
        'title': title,
        if (body != null) 'body': body,
        if (dataJson != null) 'dataJson': dataJson,
        if (layout != null) 'layout': layout,
        if (priority != null) 'priority': priority,
        if (expiresAt != null) 'expiresAt': expiresAt,
        if (persistent != null) 'persistent': persistent,
        if (externalId != null) 'externalId': externalId,
      },
    });
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateCard({
    required String externalId,
    required String source,
    required String title,
    String? body,
    String? layout,
    String? priority,
  }) async {
    final result = await _post('/agent/updateCard', {
      'apiKey': apiKey,
      'externalId': externalId,
      'request': {
        '__className__': 'CardPushRequest',
        'source': source,
        'title': title,
        if (body != null) 'body': body,
        if (layout != null) 'layout': layout,
        if (priority != null) 'priority': priority,
      },
    });
    return result as Map<String, dynamic>;
  }

  @override
  Future<bool> dismissCard(String externalId) async {
    final result = await _post('/agent/dismissCard', {
      'apiKey': apiKey,
      'externalId': externalId,
    });
    if (result is bool) return result;
    return false;
  }

  @override
  Future<List<Map<String, dynamic>>> listCards() async {
    final result = await _post('/agent/listCards', {'apiKey': apiKey});
    if (result is List) {
      return result.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } on Exception catch (e) {
      throw LandfallApiException('Network error: $e');
    }

    if (response.statusCode != 200) {
      String message;
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        message = decoded['message'] as String? ?? response.body;
      } catch (_) {
        message = response.body;
      }
      throw LandfallApiException(message);
    }

    return jsonDecode(response.body);
  }

  void dispose() => _http.close();
}

class LandfallApiException implements Exception {
  LandfallApiException(this.message);
  final String message;

  @override
  String toString() => 'LandfallApiException: $message';
}
