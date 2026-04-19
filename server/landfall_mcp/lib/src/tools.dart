import 'package:landfall_mcp/src/landfall_client.dart';

/// A single MCP tool call result.
class ToolResult {
  const ToolResult({required this.text, this.isError = false});
  final String text;
  final bool isError;
}

/// Definitions for all Landfall MCP tools.
///
/// Each [ToolDefinition] describes the tool to the MCP client (name,
/// description, input schema). The [handler] is invoked when the client
/// calls the tool.
class ToolDefinition {
  const ToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.handler,
  });

  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Future<ToolResult> Function(
    Map<String, dynamic> args,
    LandfallApi api,
  ) handler;
}

/// All tools exposed by the Landfall MCP server.
final List<ToolDefinition> landfallTools = [
  const ToolDefinition(
    name:'push_card',
    description:
        'Push a card to the Landfall display. '
        'If externalId matches an existing card it is updated in-place and '
        'its TTL is reset. Use a stable externalId (e.g. "agent.claude.summary") '
        'to own a consistent slot on the display.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'source': {
          'type': 'string',
          'description':
              'Origin identifier in <namespace>.<name> format. '
              'Use "agent.<yourname>" for custom integrations.',
        },
        'title': {
          'type': 'string',
          'description': 'Primary display text. Max 200 characters.',
        },
        'body': {
          'type': 'string',
          'description': 'Secondary display text. Max 2000 characters.',
        },
        'layout': {
          'type': 'string',
          'enum': ['small', 'medium', 'large', 'full'],
          'description': 'Size hint. Default: medium.',
        },
        'priority': {
          'type': 'string',
          'enum': ['ephemeral', 'normal', 'persistent'],
          'description':
              'Controls default TTL. ephemeral=2h, normal=24h, '
              'persistent=never. Default: normal.',
        },
        'expiresAt': {
          'type': 'string',
          'description': 'Explicit ISO 8601 UTC expiry timestamp.',
        },
        'persistent': {
          'type': 'boolean',
          'description':
              'Never auto-expire. Takes precedence over priority and expiresAt.',
        },
        'externalId': {
          'type': 'string',
          'description':
              'Stable ID for in-place updates. Re-pushing with the same '
              'ID replaces the card rather than creating a duplicate.',
        },
      },
      'required': ['source', 'title'],
    },
    handler: _pushCard,
  ),
  const ToolDefinition(
    name:'update_card',
    description:
        'Update an existing card by externalId. '
        'Throws if no card with that ID exists. '
        'Use push_card instead if you want upsert behaviour.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'externalId': {
          'type': 'string',
          'description': 'The externalId of the card to update.',
        },
        'source': {'type': 'string', 'description': 'New source value.'},
        'title': {'type': 'string', 'description': 'New title.'},
        'body': {'type': 'string', 'description': 'New body text.'},
        'layout': {
          'type': 'string',
          'enum': ['small', 'medium', 'large', 'full'],
        },
        'priority': {
          'type': 'string',
          'enum': ['ephemeral', 'normal', 'persistent'],
        },
      },
      'required': ['externalId', 'source', 'title'],
    },
    handler: _updateCard,
  ),
  const ToolDefinition(
    name:'dismiss_card',
    description:
        'Dismiss a card by externalId. '
        'The card is removed from the active display but retained in history.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'externalId': {
          'type': 'string',
          'description': 'The externalId of the card to dismiss.',
        },
      },
      'required': ['externalId'],
    },
    handler: _dismissCard,
  ),
  const ToolDefinition(
    name:'get_cards',
    description:
        'List all active (non-dismissed, non-expired) cards on the display, '
        'newest first.',
    inputSchema: {
      'type': 'object',
      'properties': {},
    },
    handler: _getCards,
  ),
  const ToolDefinition(
    name:'get_display_status',
    description:
        'Return a summary of the display: server connectivity, active card '
        'count, and a brief inventory of what is currently showing.',
    inputSchema: {
      'type': 'object',
      'properties': {},
    },
    handler: _getDisplayStatus,
  ),
];

// ── Handlers ─────────────────────────────────────────────────────────────────

Future<ToolResult> _pushCard(
  Map<String, dynamic> args,
  LandfallApi api,
) async {
  try {
    final card = await api.pushCard(
      source: args['source'] as String,
      title: args['title'] as String,
      body: args['body'] as String?,
      layout: args['layout'] as String?,
      priority: args['priority'] as String?,
      expiresAt: args['expiresAt'] as String?,
      persistent: args['persistent'] as bool?,
      externalId: args['externalId'] as String?,
    );
    final id = card['externalId'] as String? ?? card['id']?.toString() ?? '?';
    return ToolResult(text: 'Card pushed. externalId: $id');
  } on LandfallApiException catch (e) {
    return ToolResult(text: e.message, isError: true);
  }
}

Future<ToolResult> _updateCard(
  Map<String, dynamic> args,
  LandfallApi api,
) async {
  try {
    final card = await api.updateCard(
      externalId: args['externalId'] as String,
      source: args['source'] as String,
      title: args['title'] as String,
      body: args['body'] as String?,
      layout: args['layout'] as String?,
      priority: args['priority'] as String?,
    );
    final id = card['externalId'] as String? ?? card['id']?.toString() ?? '?';
    return ToolResult(text: 'Card updated. externalId: $id');
  } on LandfallApiException catch (e) {
    return ToolResult(text: e.message, isError: true);
  }
}

Future<ToolResult> _dismissCard(
  Map<String, dynamic> args,
  LandfallApi api,
) async {
  try {
    final externalId = args['externalId'] as String;
    final found = await api.dismissCard(externalId);
    if (!found) {
      return ToolResult(
        text: 'No active card found with externalId "$externalId".',
        isError: true,
      );
    }
    return ToolResult(text: 'Card dismissed. externalId: $externalId');
  } on LandfallApiException catch (e) {
    return ToolResult(text: e.message, isError: true);
  }
}

Future<ToolResult> _getCards(
  Map<String, dynamic> args,
  LandfallApi api,
) async {
  try {
    final cards = await api.listCards();
    if (cards.isEmpty) {
      return const ToolResult(text: 'No active cards on the display.');
    }
    final lines = cards.map((c) {
      final id = c['externalId'] ?? c['id'];
      final source = c['source'] ?? '?';
      final title = c['title'] ?? '?';
      final layout = c['layout'] ?? 'medium';
      final priority = c['priority'] ?? 'normal';
      return '• [$source] "$title" (layout: $layout, priority: $priority, id: $id)';
    });
    return ToolResult(text: '${cards.length} active card(s):\n${lines.join('\n')}');
  } on LandfallApiException catch (e) {
    return ToolResult(text: e.message, isError: true);
  }
}

Future<ToolResult> _getDisplayStatus(
  Map<String, dynamic> args,
  LandfallApi api,
) async {
  try {
    final cards = await api.listCards();
    final count = cards.length;

    final sources = <String>{};
    for (final c in cards) {
      final s = c['source'] as String?;
      if (s != null) sources.add(s.split('.').first);
    }

    final sourceList = sources.isEmpty ? 'none' : sources.join(', ');
    return ToolResult(
      text: 'Landfall display is reachable. '
          '$count active card(s). '
          'Active source namespaces: $sourceList.',
    );
  } on LandfallApiException catch (e) {
    return ToolResult(
      text: 'Display unreachable: ${e.message}',
      isError: true,
    );
  }
}
