import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../../agent/api_key_service.dart';
import '../../../generated/protocol.dart';

/// Extracts and validates the Bearer token from the Authorization header.
///
/// Returns the authenticated [ApiKey], or null if the header is missing or
/// the key is invalid/revoked.
Future<ApiKey?> authenticateRequest(Session session, Request request) async {
  final auth = request.headers.authorization;
  if (auth == null) return null;

  String token;
  if (auth is BearerAuthorizationHeader) {
    token = auth.token;
  } else {
    // Fall back to parsing the raw header value manually.
    final raw = auth.headerValue;
    token = raw.startsWith('Bearer ') ? raw.substring(7).trim() : raw.trim();
  }

  try {
    return await ApiKeyService.instance.authenticate(session, token);
  } catch (_) {
    return null;
  }
}

/// Returns a 401 Unauthorized JSON response.
Response unauthorized([String message = 'Invalid or missing API key.']) =>
    Response(
      401,
      body: Body.fromString(
        jsonEncode({'error': message}),
        mimeType: MimeType.json,
      ),
    );

/// Returns a 400 Bad Request JSON response.
Response badRequest(String message) => Response(
      400,
      body: Body.fromString(
        jsonEncode({'error': message}),
        mimeType: MimeType.json,
      ),
    );

/// Returns a 404 Not Found JSON response.
Response notFound([String message = 'Not found.']) => Response(
      404,
      body: Body.fromString(
        jsonEncode({'error': message}),
        mimeType: MimeType.json,
      ),
    );

/// Returns a 429 Too Many Requests JSON response.
Response rateLimitExceeded(String message) => Response(
      429,
      body: Body.fromString(
        jsonEncode({'error': message}),
        mimeType: MimeType.json,
      ),
    );

/// Returns a 200 OK JSON response.
Response ok(Object data) => Response(
      200,
      body: Body.fromString(
        jsonEncode(data),
        mimeType: MimeType.json,
      ),
    );

/// Returns a 201 Created JSON response.
Response created(Object data) => Response(
      201,
      body: Body.fromString(
        jsonEncode(data),
        mimeType: MimeType.json,
      ),
    );

/// Returns a 204 No Content response.
Response noContent() => Response(204);

/// Reads the request body and parses it as a JSON object.
///
/// Returns null if the body is empty or not valid JSON.
Future<Map<String, dynamic>?> readJsonBody(Request request) async {
  if (request.isEmpty) return null;
  final raw = await request.readAsString();
  if (raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Converts a [CardRow] to a client-facing JSON map.
Map<String, dynamic> cardToJson(CardRow card) {
  Object? decodeOrNull(String? s) {
    if (s == null) return null;
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }

  return {
    'id': card.externalId,
    'source': card.source,
    'title': card.title,
    if (card.body != null) 'body': card.body,
    if (card.dataJson != null) 'data': decodeOrNull(card.dataJson),
    if (card.actionsJson != null) 'actions': decodeOrNull(card.actionsJson),
    'layout': card.layout,
    'priority': card.priority,
    if (card.expiresAt != null) 'expiresAt': card.expiresAt!.toIso8601String(),
    'persistent': card.persistent,
    'createdAt': card.createdAt.toIso8601String(),
  };
}
