import 'dart:io';

import 'package:landfall_mcp/src/landfall_client.dart';
import 'package:landfall_mcp/src/mcp_server.dart';

/// Entry point for the Landfall MCP server.
///
/// Configure via environment variables:
///   LANDFALL_URL      — base URL of your Landfall server (required)
///   LANDFALL_API_KEY  — API key for the agent endpoints (required)
///
/// Claude Desktop config example (~/.config/claude/claude_desktop_config.json):
///   {
///     "mcpServers": {
///       "landfall": {
///         "command": "/path/to/landfall_mcp",
///         "env": {
///           "LANDFALL_URL": "http://your-server:8080",
///           "LANDFALL_API_KEY": "lf_..."
///         }
///       }
///     }
///   }
void main() async {
  final url = Platform.environment['LANDFALL_URL'];
  final key = Platform.environment['LANDFALL_API_KEY'];

  if (url == null || url.isEmpty) {
    stderr.writeln('[landfall-mcp] LANDFALL_URL is not set. Exiting.');
    exit(1);
  }
  if (key == null || key.isEmpty) {
    stderr.writeln('[landfall-mcp] LANDFALL_API_KEY is not set. Exiting.');
    exit(1);
  }

  final api = LandfallClient(baseUrl: url, apiKey: key);

  try {
    await runMcpServer(api);
  } finally {
    api.dispose();
  }
}
