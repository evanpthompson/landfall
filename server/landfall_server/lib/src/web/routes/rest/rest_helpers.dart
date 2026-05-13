import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../../agent/api_key_service.dart';
import '../../../generated/protocol.dart';

/// CORS policy: the `/api/v1/*` surface is for agent-to-server integration,
/// not for browser-based clients. We do not emit `Access-Control-Allow-*`
/// headers, and we actively reject any request that carries a cross-origin
/// `Origin` header — such a request can only originate from a browser, which
/// should never call this API directly. OWASP A02:2025.
///
/// To opt a request out of the browser-origin check (e.g. for local browser
/// dev tools against a localhost server), the request must have an `Origin`
/// that resolves to a loopback host.
bool _isBrowserOriginForbidden(Request request) {
  final originHeader = request.headers['origin'];
  if (originHeader == null || originHeader.isEmpty) return false;
  final origin = originHeader.first;
  final uri = Uri.tryParse(origin);
  if (uri == null) return true;
  final host = uri.host.toLowerCase();
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    return false;
  }
  return true;
}

/// Extracts and validates the Bearer token from the Authorization header.
///
/// Returns the authenticated [ApiKey], or null if the header is missing or
/// the key is invalid/revoked. Also returns null when the request carries a
/// non-loopback `Origin` header — see the CORS policy above.
Future<ApiKey?> authenticateRequest(Session session, Request request) async {
  if (_isBrowserOriginForbidden(request)) {
    final ip = session.request?.remoteInfo ?? 'unknown';
    session.log(
      'rest.cross_origin_rejected ip=$ip',
      level: LogLevel.warning,
    );
    return null;
  }

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
