import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:landfall_agent_sdk/landfall_agent_sdk.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> _cardRowJson({
  String externalId = 'test-slot',
  String source = 'agent.test',
  String title = 'Test card',
  String? body,
  String layout = 'medium',
  String priority = 'normal',
  String? expiresAt,
  bool persistent = false,
  String? dismissedAt,
  String createdAt = '2026-04-27T01:00:00.000Z',
}) {
  final m = <String, dynamic>{
    'id': 1,
    'externalId': externalId,
    'source': source,
    'title': title,
    'layout': layout,
    'priority': priority,
    'persistent': persistent,
    'createdAt': createdAt,
  };
  if (body != null) m['body'] = body;
  if (expiresAt != null) m['expiresAt'] = expiresAt;
  if (dismissedAt != null) m['dismissedAt'] = dismissedAt;
  return m;
}

http.Client _mockClient({
  required String expectedPath,
  required dynamic responseBody,
  int statusCode = 200,
  void Function(Map<String, dynamic> requestBody)? onRequest,
}) {
  return MockClient((request) async {
    expect(request.method, equals('POST'));
    expect(request.url.path, equals(expectedPath));
    expect(
      request.headers['content-type'],
      contains('application/json'),
    );
    if (onRequest != null) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      onRequest(body);
    }
    return http.Response(
      jsonEncode(responseBody),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  });
}

http.Client _errorClient({int statusCode = 400, String message = 'Bad request'}) {
  return MockClient((_) async => http.Response(
        jsonEncode({'message': message}),
        statusCode,
        headers: {'content-type': 'application/json'},
      ));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const serverUrl = 'http://localhost:8080';
  const apiKey = 'lf_testkey000000000000000000000000';

  group('LandfallClient.push', () {
    test('sends POST to /agent/pushCard with correct body', () async {
      final mock = _mockClient(
        expectedPath: '/agent/pushCard',
        responseBody: _cardRowJson(externalId: 'slot-1', title: 'My card'),
        onRequest: (body) {
          expect(body['apiKey'], equals(apiKey));
          final req = body['request'] as Map<String, dynamic>;
          expect(req['__className__'], equals('CardPushRequest'));
          expect(req['title'], equals('My card'));
          expect(req['source'], equals('agent.test'));
          expect(req['layout'], equals('medium'));
          expect(req['priority'], equals('normal'));
        },
      );

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );

      final draft = CardDraft.build()
          .title('My card')
          .source('agent.test')();

      final result = await client.push(draft);
      expect(result.cardId, equals('slot-1'));
      expect(result.title, equals('My card'));
      client.close();
    });

    test('includes externalId in request when cardId set', () async {
      final mock = _mockClient(
        expectedPath: '/agent/pushCard',
        responseBody: _cardRowJson(externalId: 'stable-slot'),
        onRequest: (body) {
          final req = body['request'] as Map<String, dynamic>;
          expect(req['externalId'], equals('stable-slot'));
        },
      );

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );

      await client.push(
        CardDraft.build().title('T').source('agent.t').cardId('stable-slot')(),
      );
      client.close();
    });

    test('includes expiresAt as ISO 8601 string', () async {
      final ts = DateTime.utc(2026, 6, 1, 18, 0, 0);
      final mock = _mockClient(
        expectedPath: '/agent/pushCard',
        responseBody: _cardRowJson(),
        onRequest: (body) {
          final req = body['request'] as Map<String, dynamic>;
          expect(req['expiresAt'], equals('2026-06-01T18:00:00.000Z'));
        },
      );

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );
      await client.push(
        CardDraft.build().title('T').source('agent.t').expiresAt(ts)(),
      );
      client.close();
    });

    test('throws LandfallClientException on non-200', () async {
      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: _errorClient(statusCode: 400, message: 'Invalid title'),
      );

      await expectLater(
        () => client.push(CardDraft.build().title('T').source('a.t')()),
        throwsA(
          isA<LandfallClientException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', contains('Invalid title')),
        ),
      );
      client.close();
    });

    test('throws LandfallClientException with statusCode on server error', () async {
      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: _errorClient(statusCode: 500, message: 'Internal error'),
      );

      await expectLater(
        () => client.push(CardDraft.build().title('T').source('a.t')()),
        throwsA(isA<LandfallClientException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
      client.close();
    });
  });

  group('LandfallClient.update', () {
    test('sends POST to /agent/updateCard with externalId and request', () async {
      final mock = _mockClient(
        expectedPath: '/agent/updateCard',
        responseBody: _cardRowJson(externalId: 'slot-1', title: 'Updated'),
        onRequest: (body) {
          expect(body['apiKey'], equals(apiKey));
          expect(body['externalId'], equals('slot-1'));
          final req = body['request'] as Map<String, dynamic>;
          expect(req['title'], equals('Updated'));
        },
      );

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );

      final result = await client.update(
        'slot-1',
        CardDraft.build().title('Updated').source('agent.t')(),
      );
      expect(result.title, equals('Updated'));
      client.close();
    });
  });

  group('LandfallClient.dismiss', () {
    test('sends POST to /agent/dismissCard and returns true on success', () async {
      final mock = _mockClient(
        expectedPath: '/agent/dismissCard',
        responseBody: true,
        onRequest: (body) {
          expect(body['apiKey'], equals(apiKey));
          expect(body['externalId'], equals('bye-slot'));
        },
      );

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );

      final result = await client.dismiss('bye-slot');
      expect(result, isTrue);
      client.close();
    });

    test('returns false when server returns false', () async {
      final mock = MockClient((_) async => http.Response(
            'false',
            200,
            headers: {'content-type': 'application/json'},
          ));

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );

      final result = await client.dismiss('no-such-id');
      expect(result, isFalse);
      client.close();
    });
  });

  group('LandfallClient.pushTicker', () {
    test('sends POST to /agent/pushTicker with source and message', () async {
      final mock = _mockClient(
        expectedPath: '/agent/pushTicker',
        responseBody: _cardRowJson(
          layout: 'ticker',
          title: 'Processing your request...',
        ),
        onRequest: (body) {
          expect(body['apiKey'], equals(apiKey));
          expect(body['source'], equals('agent.test'));
          expect(body['message'], equals('Processing your request...'));
        },
      );

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );

      final id = await client.pushTicker(
        'Processing your request...',
        source: 'agent.test',
      );
      expect(id, isA<String>());
      expect(id, isNotEmpty);
      client.close();
    });

    test('includes expiresAt when ttl is provided', () async {
      final mock = _mockClient(
        expectedPath: '/agent/pushTicker',
        responseBody: _cardRowJson(layout: 'ticker', title: 'msg'),
        onRequest: (body) {
          expect(body.containsKey('expiresAt'), isTrue);
        },
      );

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );
      await client.pushTicker('msg', source: 'agent.t', ttl: const Duration(minutes: 2));
      client.close();
    });
  });

  group('LandfallClient.listCards', () {
    test('sends POST to /agent/listCards and returns parsed PushedCards', () async {
      final mock = MockClient((_) async => http.Response(
            jsonEncode([
              _cardRowJson(externalId: 'a', title: 'Card A'),
              _cardRowJson(externalId: 'b', title: 'Card B'),
            ]),
            200,
            headers: {'content-type': 'application/json'},
          ));

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );

      final cards = await client.listCards();
      expect(cards, hasLength(2));
      expect(cards[0].title, equals('Card A'));
      expect(cards[1].title, equals('Card B'));
      client.close();
    });

    test('returns empty list when no cards', () async {
      final mock = MockClient((_) async => http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          ));

      final client = LandfallClient(
        serverUrl: serverUrl,
        apiKey: apiKey,
        httpClient: mock,
      );
      final cards = await client.listCards();
      expect(cards, isEmpty);
      client.close();
    });
  });

  group('LandfallClient URL construction', () {
    test('strips trailing slash from serverUrl', () async {
      final mock = _mockClient(
        expectedPath: '/agent/pushCard',
        responseBody: _cardRowJson(),
      );
      final client = LandfallClient(
        serverUrl: 'http://localhost:8080/',
        apiKey: apiKey,
        httpClient: mock,
      );
      await client.push(CardDraft.build().title('T').source('a.t')());
      client.close();
    });
  });
}
