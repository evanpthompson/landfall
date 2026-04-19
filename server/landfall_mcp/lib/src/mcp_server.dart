import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:landfall_mcp/src/landfall_client.dart';
import 'package:landfall_mcp/src/resources.dart';
import 'package:landfall_mcp/src/tools.dart';

const _protocolVersion = '2024-11-05';

/// Runs the MCP server, reading JSON-RPC messages from [stdin] and writing
/// responses to [stdout].
///
/// Messages are newline-delimited JSON (one object per line). Logging goes
/// to [stderr] so it never pollutes the MCP stream.
///
/// The server exits when stdin closes.
Future<void> runMcpServer(LandfallApi api) async {
  stderr.writeln('[landfall-mcp] server starting');

  final lines = stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  await for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    Map<String, dynamic> message;
    try {
      message = jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      _writeError(null, -32700, 'Parse error');
      continue;
    }

    final id = message['id'];
    final method = message['method'] as String?;

    if (method == null) continue; // notification with no method — ignore

    await _dispatch(id, method, message['params'], api);
  }

  stderr.writeln('[landfall-mcp] stdin closed, exiting');
}

// ── Dispatch ─────────────────────────────────────────────────────────────────

Future<void> _dispatch(
  dynamic id,
  String method,
  dynamic params,
  LandfallApi api,
) async {
  switch (method) {
    case 'initialize':
      _writeResult(id, {
        'protocolVersion': _protocolVersion,
        'capabilities': {
          'tools': {},
          'resources': {},
        },
        'serverInfo': {'name': 'landfall', 'version': '1.0.0'},
      });

    case 'notifications/initialized':
      // Client acknowledgement — no response needed.
      break;

    case 'ping':
      _writeResult(id, {});

    case 'tools/list':
      _writeResult(id, {
        'tools': landfallTools
            .map(
              (t) => {
                'name': t.name,
                'description': t.description,
                'inputSchema': t.inputSchema,
              },
            )
            .toList(),
      });

    case 'tools/call':
      await _handleToolCall(id, params as Map<String, dynamic>?, api);

    case 'resources/list':
      _writeResult(id, {
        'resources': landfallResources
            .map(
              (r) => {
                'uri': r.uri,
                'name': r.name,
                'description': r.description,
                'mimeType': r.mimeType,
              },
            )
            .toList(),
      });

    case 'resources/read':
      await _handleResourceRead(id, params as Map<String, dynamic>?, api);

    default:
      if (id != null) {
        _writeError(id, -32601, 'Method not found: $method');
      }
  }
}

// ── Tool call ─────────────────────────────────────────────────────────────────

Future<void> _handleToolCall(
  dynamic id,
  Map<String, dynamic>? params,
  LandfallApi api,
) async {
  final name = params?['name'] as String?;
  final args = (params?['arguments'] as Map<String, dynamic>?) ?? {};

  final tool = landfallTools.where((t) => t.name == name).firstOrNull;
  if (tool == null) {
    _writeError(id, -32602, 'Unknown tool: $name');
    return;
  }

  final result = await tool.handler(args, api);
  _writeResult(id, {
    'content': [
      {'type': 'text', 'text': result.text},
    ],
    'isError': result.isError,
  });
}

// ── Resource read ─────────────────────────────────────────────────────────────

Future<void> _handleResourceRead(
  dynamic id,
  Map<String, dynamic>? params,
  LandfallApi api,
) async {
  final uri = params?['uri'] as String?;

  final resource =
      landfallResources.where((r) => r.uri == uri).firstOrNull;
  if (resource == null) {
    _writeError(id, -32602, 'Unknown resource URI: $uri');
    return;
  }

  final result = await resource.reader(api);
  _writeResult(id, {
    'contents': [
      {
        'uri': resource.uri,
        'mimeType': resource.mimeType,
        'text': result.text,
      },
    ],
  });
}

// ── Wire helpers ──────────────────────────────────────────────────────────────

void _writeResult(dynamic id, Map<String, dynamic> result) {
  _write({'jsonrpc': '2.0', 'id': id, 'result': result});
}

void _writeError(dynamic id, int code, String message) {
  _write({
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  });
}

void _write(Map<String, dynamic> message) {
  stdout.writeln(jsonEncode(message));
}
