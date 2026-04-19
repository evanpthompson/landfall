import 'package:landfall_mcp/src/landfall_client.dart';

/// A single MCP resource read result.
class ResourceResult {
  const ResourceResult({required this.text, this.isError = false});
  final String text;
  final bool isError;
}

/// Describes a readable MCP resource.
class ResourceDefinition {
  const ResourceDefinition({
    required this.uri,
    required this.name,
    required this.description,
    required this.mimeType,
    required this.reader,
  });

  final String uri;
  final String name;
  final String description;
  final String mimeType;
  final Future<ResourceResult> Function(LandfallApi api) reader;
}

/// All resources exposed by the Landfall MCP server.
final List<ResourceDefinition> landfallResources = [
  const ResourceDefinition(
    uri: 'landfall://cards',
    name: 'Active Cards',
    description: 'All active (non-dismissed, non-expired) cards currently '
        'showing on the Landfall display.',
    mimeType: 'text/plain',
    reader: _readCards,
  ),
  const ResourceDefinition(
    uri: 'landfall://status',
    name: 'Display Status',
    description: 'Landfall server connectivity and a summary of what is '
        'currently on the display.',
    mimeType: 'text/plain',
    reader: _readStatus,
  ),
];

// ── Readers ───────────────────────────────────────────────────────────────────

Future<ResourceResult> _readCards(LandfallApi api) async {
  try {
    final cards = await api.listCards();
    if (cards.isEmpty) {
      return const ResourceResult(text: 'No active cards.');
    }
    final lines = cards.map((c) {
      final id = c['externalId'] ?? c['id'];
      final source = c['source'] ?? '?';
      final title = c['title'] ?? '?';
      final body = c['body'] as String?;
      final layout = c['layout'] ?? 'medium';
      final priority = c['priority'] ?? 'normal';
      final buf = StringBuffer('externalId: $id\nsource: $source\ntitle: $title');
      if (body != null && body.isNotEmpty) buf.write('\nbody: $body');
      buf.write('\nlayout: $layout | priority: $priority');
      return buf.toString();
    });
    return ResourceResult(
      text: '${cards.length} active card(s)\n\n${lines.join('\n\n---\n\n')}',
    );
  } on LandfallApiException catch (e) {
    return ResourceResult(text: 'Error reading cards: ${e.message}', isError: true);
  }
}

Future<ResourceResult> _readStatus(LandfallApi api) async {
  try {
    final cards = await api.listCards();
    final count = cards.length;
    final sources = cards
        .map((c) => c['source'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final buf = StringBuffer('status: reachable\nactive_cards: $count\n');
    if (sources.isNotEmpty) {
      buf.write('sources:\n');
      for (final s in sources) {
        buf.write('  - $s\n');
      }
    } else {
      buf.write('sources: none\n');
    }
    return ResourceResult(text: buf.toString().trimRight());
  } on LandfallApiException catch (e) {
    return ResourceResult(
      text: 'status: unreachable\nerror: ${e.message}',
      isError: true,
    );
  }
}
