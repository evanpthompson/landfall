import 'dart:convert';

import 'package:http/http.dart' as http;

import 'card_draft.dart';
import 'landfall_exception.dart';
import 'pushed_card.dart';

/// Authenticated HTTP client for pushing cards to a Landfall display.
///
/// ```dart
/// final client = LandfallClient(
///   serverUrl: 'https://my.landfall.dev',
///   apiKey: 'lf_...',
/// );
///
/// await client.push(
///   CardDraft.build()
///     .title('Flight DEN→LAX dropped to \$287')
///     .body('Round trip, June 14. Price valid ~4 hours.')
///     .priority(CardPriority.ephemeral)
///     .expires(const Duration(hours: 4)),
/// );
///
/// client.close();
/// ```
class LandfallClient {
  LandfallClient({
    required String serverUrl,
    required this.apiKey,
    http.Client? httpClient,
  })  : _base = serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl,
        _http = httpClient ?? http.Client();

  final String _base;
  final String apiKey;
  final http.Client _http;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Pushes [draft] to the display and returns the created or updated card.
  ///
  /// If [CardDraftBuilder.cardId] was set and a card with that ID already
  /// exists, the existing card is updated in-place and un-dismissed.
  Future<PushedCard> push(CardDraft draft) async {
    final json = await _post('/agent/pushCard', {
      'apiKey': apiKey,
      'request': draft.toRequestJson(),
    });
    return PushedCard.fromJson(json as Map<String, dynamic>);
  }

  /// Replaces an existing card by [cardId].
  ///
  /// Throws [LandfallClientException] if no card with [cardId] exists.
  Future<PushedCard> update(String cardId, CardDraft draft) async {
    final json = await _post('/agent/updateCard', {
      'apiKey': apiKey,
      'externalId': cardId,
      'request': draft.toRequestJson(),
    });
    return PushedCard.fromJson(json as Map<String, dynamic>);
  }

  /// Dismisses a card by [cardId]. Returns true if dismissed, false if not found.
  Future<bool> dismiss(String cardId) async {
    final result = await _post('/agent/dismissCard', {
      'apiKey': apiKey,
      'externalId': cardId,
    });
    return result as bool;
  }

  /// Pushes a ticker heartbeat to the ghost ticker strip at the bottom of the display.
  ///
  /// Returns the [externalId] of the created ticker card.
  ///
  /// The ticker strip is a scrolling overlay — messages appear for 30 seconds
  /// by default (override with [ttl]). Use it to signal agent activity before
  /// the main result card is ready.
  ///
  /// [source] defaults to `'agent.sdk'`. Set it to your agent's identifier
  /// so the ticker is attributable on the display.
  Future<String> pushTicker(
    String message, {
    String source = 'agent.sdk',
    Duration? ttl,
  }) async {
    final body = <String, dynamic>{
      'apiKey': apiKey,
      'source': source,
      'message': message,
    };
    if (ttl != null) {
      body['expiresAt'] =
          DateTime.now().toUtc().add(ttl).toIso8601String();
    }

    final json = await _post('/agent/pushTicker', body);

    final card = json as Map<String, dynamic>;
    return card['externalId'] as String;
  }

  /// Returns all active (non-dismissed, non-expired) cards, newest first.
  Future<List<PushedCard>> listCards() async {
    final json = await _post('/agent/listCards', {'apiKey': apiKey});
    final list = json as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(PushedCard.fromJson)
        .toList();
  }

  /// Releases the underlying HTTP client.
  void close() => _http.close();

  // ---------------------------------------------------------------------------
  // HTTP internals
  // ---------------------------------------------------------------------------

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_base$path');
    final response = await _http.post(
      url,
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message = 'Request failed';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['message'] as String? ??
            decoded['data']?['message'] as String? ??
            response.body;
      }
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : 'Request failed';
    }

    throw LandfallClientException(message, statusCode: response.statusCode);
  }
}
