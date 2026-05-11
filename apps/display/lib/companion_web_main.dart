// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:landfall_client/landfall_client.dart' as lf;

import 'src/features/companion/widgets/companion_mobile_screen.dart';

// Reads the display ID injected by CompanionPageRoute into the page HTML.
// The server injects: window.LANDFALL_DISPLAY_ID = "{uuid}";
@JS('LANDFALL_DISPLAY_ID')
external JSString? get _rawDisplayId;

void main() {
  final displayId = _rawDisplayId?.toDart ?? '';

  // The page is served from the Serverpod web server (API port + 2, e.g. 8082).
  // The API endpoint lives two ports lower (e.g. 8080). Subtract 2 to get it.
  final uri = Uri.base;
  final apiPort = uri.port - 2;
  final serverUrl = '${uri.scheme}://${uri.host}:$apiPort/';

  final client = lf.Client(serverUrl);

  runApp(_CompanionWebApp(displayId: displayId, client: client));
}

class _CompanionWebApp extends StatefulWidget {
  const _CompanionWebApp({required this.displayId, required this.client});

  final String displayId;
  final lf.Client client;

  @override
  State<_CompanionWebApp> createState() => _CompanionWebAppState();
}

class _CompanionWebAppState extends State<_CompanionWebApp> {
  CompanionInfo? _info;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final entity = await widget.client.companion
          .getOrCreateForDisplay(widget.displayId);
      if (mounted) setState(() => _info = _toInfo(entity));
    } catch (_) {
      // Info tab will stay in loading state — interaction still works.
    }
  }

  static CompanionInfo _toInfo(lf.CompanionEntity entity) {
    const rarityColors = <String, Color>{
      'common': Color(0xFF9E9E9E),
      'uncommon': Color(0xFF66BB6A),
      'rare': Color(0xFF42A5F5),
      'epic': Color(0xFFAB47BC),
      'legendary': Color(0xFFFFA726),
    };
    const rarityLabels = <String, String>{
      'common': 'Common',
      'uncommon': 'Uncommon',
      'rare': 'Rare',
      'epic': 'Epic',
      'legendary': 'Legendary',
    };

    final rarity = entity.rarityTier.toLowerCase();
    final traits = entity.traits
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return CompanionInfo(
      name: entity.name,
      rarityLabel: rarityLabels[rarity] ?? rarity,
      rarityColor: rarityColors[rarity] ?? const Color(0xFF9E9E9E),
      traits: traits,
      evolutionStage: entity.evolutionStage,
      assetCredit: entity.assetCredit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Landfall Companion',
      theme: ThemeData.dark(useMaterial3: true),
      home: Stack(
        children: [
          CompanionMobileScreen(
            displayId: widget.displayId,
            onAction: (kind) =>
                widget.client.companion.pushAction(widget.displayId, kind),
            info: _info,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.refresh),
                color: const Color(0x66FFFFFF),
                iconSize: 20,
                tooltip: 'Refresh',
                onPressed: () => html.window.location.reload(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
