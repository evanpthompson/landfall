import 'package:landfall_mcp/src/landfall_client.dart';
import 'package:landfall_mcp/src/tools.dart';
import 'package:test/test.dart';

// ── Fake API ──────────────────────────────────────────────────────────────────

class FakeLandfallApi implements LandfallApi {
  List<Map<String, dynamic>> cards = [];
  bool dismissResult = true;
  LandfallApiException? throwOn;

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
    if (throwOn != null) throw throwOn!;
    return {
      'externalId': externalId ?? 'generated-uuid',
      'source': source,
      'title': title,
    };
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
    if (throwOn != null) throw throwOn!;
    return {'externalId': externalId, 'source': source, 'title': title};
  }

  @override
  Future<bool> dismissCard(String externalId) async {
    if (throwOn != null) throw throwOn!;
    return dismissResult;
  }

  @override
  Future<List<Map<String, dynamic>>> listCards() async {
    if (throwOn != null) throw throwOn!;
    return cards;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ToolDefinition toolNamed(String name) =>
    landfallTools.firstWhere((t) => t.name == name);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeLandfallApi api;

  setUp(() => api = FakeLandfallApi());

  group('tool definitions', () {
    test('exposes exactly 5 tools', () {
      expect(landfallTools, hasLength(5));
    });

    test('all tools have non-empty names and descriptions', () {
      for (final t in landfallTools) {
        expect(t.name, isNotEmpty, reason: 'tool name must not be empty');
        expect(
          t.description,
          isNotEmpty,
          reason: '${t.name}: description must not be empty',
        );
      }
    });

    test('push_card requires source and title', () {
      final schema = toolNamed('push_card').inputSchema;
      expect(schema['required'], containsAll(['source', 'title']));
    });

    test('update_card requires externalId, source, title', () {
      final schema = toolNamed('update_card').inputSchema;
      expect(
        schema['required'],
        containsAll(['externalId', 'source', 'title']),
      );
    });

    test('dismiss_card requires externalId', () {
      final schema = toolNamed('dismiss_card').inputSchema;
      expect(schema['required'], contains('externalId'));
    });

    test('get_cards has no required fields', () {
      final schema = toolNamed('get_cards').inputSchema;
      expect(schema['required'], isNot(contains(anything)));
    });

    test('get_display_status has no required fields', () {
      final schema = toolNamed('get_display_status').inputSchema;
      expect(schema['required'], isNot(contains(anything)));
    });
  });

  group('push_card handler', () {
    test('returns externalId on success', () async {
      final result = await toolNamed('push_card').handler(
        {'source': 'agent.test', 'title': 'Hello'},
        api,
      );
      expect(result.isError, isFalse);
      expect(result.text, contains('generated-uuid'));
    });

    test('uses provided externalId in success message', () async {
      final result = await toolNamed('push_card').handler(
        {
          'source': 'agent.test',
          'title': 'Hello',
          'externalId': 'agent.test.slot',
        },
        api,
      );
      expect(result.text, contains('agent.test.slot'));
    });

    test('returns isError on API failure', () async {
      api.throwOn = LandfallApiException('Invalid card payload: source invalid.');
      final result = await toolNamed('push_card').handler(
        {'source': 'bad source', 'title': 'Hello'},
        api,
      );
      expect(result.isError, isTrue);
      expect(result.text, contains('source invalid'));
    });
  });

  group('update_card handler', () {
    test('returns externalId on success', () async {
      final result = await toolNamed('update_card').handler(
        {
          'externalId': 'agent.test.slot',
          'source': 'agent.test',
          'title': 'Updated',
        },
        api,
      );
      expect(result.isError, isFalse);
      expect(result.text, contains('agent.test.slot'));
    });

    test('returns isError on API failure', () async {
      api.throwOn = LandfallApiException('No card found with externalId "x".');
      final result = await toolNamed('update_card').handler(
        {'externalId': 'x', 'source': 'agent.test', 'title': 'Hi'},
        api,
      );
      expect(result.isError, isTrue);
      expect(result.text, contains('No card found'));
    });
  });

  group('dismiss_card handler', () {
    test('returns success message when card exists', () async {
      api.dismissResult = true;
      final result = await toolNamed('dismiss_card').handler(
        {'externalId': 'agent.test.slot'},
        api,
      );
      expect(result.isError, isFalse);
      expect(result.text, contains('agent.test.slot'));
    });

    test('returns isError when card not found', () async {
      api.dismissResult = false;
      final result = await toolNamed('dismiss_card').handler(
        {'externalId': 'missing'},
        api,
      );
      expect(result.isError, isTrue);
      expect(result.text, contains('missing'));
    });

    test('returns isError on API failure', () async {
      api.throwOn = LandfallApiException('Invalid or revoked API key.');
      final result = await toolNamed('dismiss_card').handler(
        {'externalId': 'any'},
        api,
      );
      expect(result.isError, isTrue);
    });
  });

  group('get_cards handler', () {
    test('returns empty message when no cards', () async {
      api.cards = [];
      final result = await toolNamed('get_cards').handler({}, api);
      expect(result.isError, isFalse);
      expect(result.text, contains('No active cards'));
    });

    test('lists all cards with source, title, id', () async {
      api.cards = [
        {
          'externalId': 'agent.claude.summary',
          'source': 'agent.claude',
          'title': 'Summary',
          'layout': 'large',
          'priority': 'normal',
        },
        {
          'externalId': 'system.clock',
          'source': 'system.clock',
          'title': 'Clock',
          'layout': 'small',
          'priority': 'persistent',
        },
      ];
      final result = await toolNamed('get_cards').handler({}, api);
      expect(result.isError, isFalse);
      expect(result.text, contains('2 active card'));
      expect(result.text, contains('agent.claude'));
      expect(result.text, contains('Summary'));
      expect(result.text, contains('system.clock'));
    });

    test('returns isError on API failure', () async {
      api.throwOn = LandfallApiException('Network error');
      final result = await toolNamed('get_cards').handler({}, api);
      expect(result.isError, isTrue);
    });
  });

  group('get_display_status handler', () {
    test('reports reachable with card count', () async {
      api.cards = [
        {'source': 'agent.claude', 'title': 'Hi'},
        {'source': 'system.weather', 'title': 'Sunny'},
      ];
      final result = await toolNamed('get_display_status').handler({}, api);
      expect(result.isError, isFalse);
      expect(result.text, contains('reachable'));
      expect(result.text, contains('2 active card'));
    });

    test('reports reachable with no cards', () async {
      api.cards = [];
      final result = await toolNamed('get_display_status').handler({}, api);
      expect(result.isError, isFalse);
      expect(result.text, contains('reachable'));
      expect(result.text, contains('0 active card'));
    });

    test('reports unreachable on API failure', () async {
      api.throwOn = LandfallApiException('Connection refused');
      final result = await toolNamed('get_display_status').handler({}, api);
      expect(result.isError, isTrue);
      expect(result.text, contains('unreachable'));
    });
  });
}
