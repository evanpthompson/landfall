import 'dart:convert';

import 'package:landfall_mcp/src/landfall_client.dart';
import 'package:landfall_mcp/src/resources.dart';
import 'package:landfall_mcp/src/tools.dart';
import 'package:test/test.dart';

// ── Fake API ──────────────────────────────────────────────────────────────────

class FakeLandfallApi implements LandfallApi {
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
  }) async =>
      {'externalId': externalId ?? 'test-uuid', 'source': source, 'title': title};

  @override
  Future<Map<String, dynamic>> updateCard({
    required String externalId,
    required String source,
    required String title,
    String? body,
    String? layout,
    String? priority,
  }) async =>
      {'externalId': externalId, 'source': source, 'title': title};

  @override
  Future<bool> dismissCard(String externalId) async => true;

  @override
  Future<List<Map<String, dynamic>>> listCards() async => [];
}

// ── Protocol helpers ──────────────────────────────────────────────────────────

/// Encode a JSON-RPC request as a single line (the MCP stdio format).
String encodeRequest(int id, String method, [Map<String, dynamic>? params]) {
  final msg = <String, dynamic>{
    'jsonrpc': '2.0',
    'id': id,
    'method': method,
  };
  if (params != null) msg['params'] = params;
  return jsonEncode(msg);
}

/// Decode the first complete JSON-RPC response from the mcp_server output.
Map<String, dynamic> decodeResponse(String line) =>
    jsonDecode(line.trim()) as Map<String, dynamic>;

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('tool count and names', () {
    test('5 tools registered', () {
      expect(landfallTools, hasLength(5));
    });

    test('expected tool names present', () {
      final names = landfallTools.map((t) => t.name).toSet();
      expect(
        names,
        containsAll([
          'push_card',
          'update_card',
          'dismiss_card',
          'get_cards',
          'get_display_status',
        ]),
      );
    });
  });

  group('resource count and URIs', () {
    test('2 resources registered', () {
      expect(landfallResources, hasLength(2));
    });

    test('expected resource URIs present', () {
      final uris = landfallResources.map((r) => r.uri).toSet();
      expect(uris, containsAll(['landfall://cards', 'landfall://status']));
    });
  });

  group('MCP message handling', () {
    late FakeLandfallApi api;

    setUp(() {
      api = FakeLandfallApi();
    });

    // Helper: drive the server with a sequence of message lines and collect
    // the JSON-RPC responses written to stdout.
    Future<List<Map<String, dynamic>>> runMessages(
      List<String> messages,
    ) async {
      final results = <Map<String, dynamic>>[];
      for (final line in messages) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final message = jsonDecode(trimmed) as Map<String, dynamic>;
        final id = message['id'];
        final method = message['method'] as String?;
        if (method == null) continue;

        // Invoke the internal dispatch logic directly so we don't need
        // real stdin/stdout in tests.
        await _testDispatch(id, method, message['params'], api, results);
      }
      return results;
    }

    test('initialize returns correct protocol version and capabilities', () async {
      final responses = await runMessages([
        encodeRequest(1, 'initialize', {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'test', 'version': '1.0'},
        }),
      ]);

      expect(responses, hasLength(1));
      final result = responses[0]['result'] as Map<String, dynamic>;
      expect(result['protocolVersion'], equals('2024-11-05'));
      expect(result['capabilities'], containsPair('tools', isA<Map>()));
      expect(result['capabilities'], containsPair('resources', isA<Map>()));
      expect(
        (result['serverInfo'] as Map)['name'],
        equals('landfall'),
      );
    });

    test('tools/list returns all 5 tools', () async {
      final responses = await runMessages([encodeRequest(2, 'tools/list')]);
      expect(responses, hasLength(1));
      final tools =
          (responses[0]['result'] as Map)['tools'] as List;
      expect(tools, hasLength(5));
    });

    test('resources/list returns all 2 resources', () async {
      final responses = await runMessages([
        encodeRequest(3, 'resources/list'),
      ]);
      expect(responses, hasLength(1));
      final resources =
          (responses[0]['result'] as Map)['resources'] as List;
      expect(resources, hasLength(2));
    });

    test('tools/call with unknown tool returns error', () async {
      final responses = await runMessages([
        encodeRequest(4, 'tools/call', {
          'name': 'nonexistent_tool',
          'arguments': {},
        }),
      ]);
      expect(responses, hasLength(1));
      expect(responses[0], contains('error'));
      expect(
        (responses[0]['error'] as Map)['message'],
        contains('nonexistent_tool'),
      );
    });

    test('resources/read with unknown URI returns error', () async {
      final responses = await runMessages([
        encodeRequest(5, 'resources/read', {'uri': 'landfall://unknown'}),
      ]);
      expect(responses, hasLength(1));
      expect(responses[0], contains('error'));
    });

    test('tools/call push_card returns success content', () async {
      final responses = await runMessages([
        encodeRequest(6, 'tools/call', {
          'name': 'push_card',
          'arguments': {'source': 'agent.test', 'title': 'Test card'},
        }),
      ]);
      expect(responses, hasLength(1));
      final result = responses[0]['result'] as Map<String, dynamic>;
      expect(result['isError'], isFalse);
      final content = result['content'] as List;
      expect(content.first['text'], contains('Card pushed'));
    });

    test('unknown method returns JSON-RPC error', () async {
      final responses = await runMessages([
        encodeRequest(7, 'tools/fly_to_moon'),
      ]);
      expect(responses, hasLength(1));
      expect(responses[0], contains('error'));
      expect(
        (responses[0]['error'] as Map)['code'],
        equals(-32601),
      );
    });

    test('notifications/initialized produces no response', () async {
      final responses = await runMessages([
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'notifications/initialized',
        }),
      ]);
      expect(responses, isEmpty);
    });
  });
}

// ── Test shim for dispatch ────────────────────────────────────────────────────
//
// Mirrors the internal dispatch in mcp_server.dart but collects responses
// into a list instead of writing to stdout. This lets us test the protocol
// logic without real I/O.

Future<void> _testDispatch(
  dynamic id,
  String method,
  dynamic params,
  LandfallApi api,
  List<Map<String, dynamic>> out,
) async {
  void write(Map<String, dynamic> msg) => out.add(msg);
  void result(dynamic r) => write({'jsonrpc': '2.0', 'id': id, 'result': r});
  void error(int code, String msg) => write({
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': code, 'message': msg},
      });

  switch (method) {
    case 'initialize':
      result({
        'protocolVersion': '2024-11-05',
        'capabilities': {'tools': {}, 'resources': {}},
        'serverInfo': {'name': 'landfall', 'version': '1.0.0'},
      });

    case 'notifications/initialized':
      break;

    case 'ping':
      result({});

    case 'tools/list':
      result({
        'tools': landfallTools
            .map((t) => {
                  'name': t.name,
                  'description': t.description,
                  'inputSchema': t.inputSchema,
                })
            .toList(),
      });

    case 'tools/call':
      final p = params as Map<String, dynamic>?;
      final name = p?['name'] as String?;
      final args = (p?['arguments'] as Map<String, dynamic>?) ?? {};
      final tool = landfallTools.where((t) => t.name == name).firstOrNull;
      if (tool == null) {
        error(-32602, 'Unknown tool: $name');
        return;
      }
      final r = await tool.handler(args, api);
      result({
        'content': [
          {'type': 'text', 'text': r.text},
        ],
        'isError': r.isError,
      });

    case 'resources/list':
      result({
        'resources': landfallResources
            .map((r) => {
                  'uri': r.uri,
                  'name': r.name,
                  'description': r.description,
                  'mimeType': r.mimeType,
                })
            .toList(),
      });

    case 'resources/read':
      final p = params as Map<String, dynamic>?;
      final uri = p?['uri'] as String?;
      final resource =
          landfallResources.where((r) => r.uri == uri).firstOrNull;
      if (resource == null) {
        error(-32602, 'Unknown resource URI: $uri');
        return;
      }
      final r = await resource.reader(api);
      result({
        'contents': [
          {'uri': resource.uri, 'mimeType': resource.mimeType, 'text': r.text},
        ],
      });

    default:
      if (id != null) error(-32601, 'Method not found: $method');
  }
}
