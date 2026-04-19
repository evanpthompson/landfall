import 'package:landfall_mcp/src/landfall_client.dart';
import 'package:landfall_mcp/src/resources.dart';
import 'package:test/test.dart';

class FakeLandfallApi implements LandfallApi {
  List<Map<String, dynamic>> cards = [];
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
  }) async => {};

  @override
  Future<Map<String, dynamic>> updateCard({
    required String externalId,
    required String source,
    required String title,
    String? body,
    String? layout,
    String? priority,
  }) async => {};

  @override
  Future<bool> dismissCard(String externalId) async => true;

  @override
  Future<List<Map<String, dynamic>>> listCards() async {
    if (throwOn != null) throw throwOn!;
    return cards;
  }
}

ResourceDefinition resourceAt(String uri) =>
    landfallResources.firstWhere((r) => r.uri == uri);

void main() {
  late FakeLandfallApi api;

  setUp(() => api = FakeLandfallApi());

  group('resource definitions', () {
    test('exposes landfall://cards and landfall://status', () {
      final uris = landfallResources.map((r) => r.uri).toSet();
      expect(uris, containsAll(['landfall://cards', 'landfall://status']));
    });

    test('all resources have non-empty names, descriptions, and mimeTypes', () {
      for (final r in landfallResources) {
        expect(r.name, isNotEmpty);
        expect(r.description, isNotEmpty);
        expect(r.mimeType, isNotEmpty);
      }
    });
  });

  group('landfall://cards resource', () {
    test('returns empty message when no cards', () async {
      api.cards = [];
      final result = await resourceAt('landfall://cards').reader(api);
      expect(result.isError, isFalse);
      expect(result.text, contains('No active cards'));
    });

    test('includes source, title, externalId for each card', () async {
      api.cards = [
        {
          'externalId': 'agent.claude.summary',
          'source': 'agent.claude',
          'title': 'Daily summary',
          'body': 'All tasks complete.',
          'layout': 'large',
          'priority': 'normal',
        },
      ];
      final result = await resourceAt('landfall://cards').reader(api);
      expect(result.isError, isFalse);
      expect(result.text, contains('agent.claude.summary'));
      expect(result.text, contains('agent.claude'));
      expect(result.text, contains('Daily summary'));
      expect(result.text, contains('All tasks complete.'));
    });

    test('returns isError on API failure', () async {
      api.throwOn = LandfallApiException('Network error');
      final result = await resourceAt('landfall://cards').reader(api);
      expect(result.isError, isTrue);
      expect(result.text, contains('Error reading cards'));
    });
  });

  group('landfall://status resource', () {
    test('reports reachable with card count and sources', () async {
      api.cards = [
        {'source': 'agent.claude', 'title': 'A'},
        {'source': 'system.weather', 'title': 'B'},
      ];
      final result = await resourceAt('landfall://status').reader(api);
      expect(result.isError, isFalse);
      expect(result.text, contains('status: reachable'));
      expect(result.text, contains('active_cards: 2'));
      expect(result.text, contains('agent.claude'));
      expect(result.text, contains('system.weather'));
    });

    test('reports reachable with no sources when empty', () async {
      api.cards = [];
      final result = await resourceAt('landfall://status').reader(api);
      expect(result.isError, isFalse);
      expect(result.text, contains('active_cards: 0'));
      expect(result.text, contains('sources: none'));
    });

    test('reports unreachable on API failure', () async {
      api.throwOn = LandfallApiException('Connection refused');
      final result = await resourceAt('landfall://status').reader(api);
      expect(result.isError, isTrue);
      expect(result.text, contains('status: unreachable'));
    });
  });
}
