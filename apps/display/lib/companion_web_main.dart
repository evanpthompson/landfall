import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:landfall_client/landfall_client.dart';

import 'src/features/companion/widgets/companion_mobile_screen.dart';

// Reads the display ID injected by CompanionPageRoute into the page HTML.
// The server injects: window.LANDFALL_DISPLAY_ID = "{uuid}";
@JS('LANDFALL_DISPLAY_ID')
external JSString? get _rawDisplayId;

void main() {
  final displayId = _rawDisplayId?.toDart ?? '';

  // Same-origin server: strip the /companion/{uuid} path and use just the origin.
  final uri = Uri.base;
  final serverUrl = '${uri.scheme}://${uri.host}:${uri.port}/';

  final client = Client(serverUrl);

  runApp(_CompanionWebApp(displayId: displayId, client: client));
}

class _CompanionWebApp extends StatelessWidget {
  const _CompanionWebApp({required this.displayId, required this.client});

  final String displayId;
  final Client client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Landfall Companion',
      theme: ThemeData.dark(useMaterial3: true),
      home: CompanionMobileScreen(
        displayId: displayId,
        onAction: (kind) => client.companion.pushAction(displayId, kind),
      ),
    );
  }
}
