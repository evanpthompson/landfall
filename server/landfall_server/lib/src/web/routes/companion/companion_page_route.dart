import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

/// Serves the companion interaction web page and its Flutter web assets.
///
/// URL layout:
///   GET /companion/{uuid}              → index.html with injected display ID
///   GET /companion/{uuid}/index.html   → same as above
///   GET /companion/{uuid}/**           → static asset from the Flutter web build
///
/// The Flutter web build is expected at [webDir] (default: web/static/companion).
/// When the build is absent every request returns 404 so the TV still functions
/// while the web page is not yet deployed.
class CompanionPageRoute extends Route {
  CompanionPageRoute({String? webDir})
      : _webDir = webDir ?? 'web/static/companion',
        super(methods: {Method.get});

  final String _webDir;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final segments = request.url.pathSegments;
    // Expect at least ['companion', '{uuid}'].
    if (segments.length < 2) return Response(404);

    final subSegments = segments.length > 2 ? segments.sublist(2) : <String>[];

    // Reject path traversal.
    if (subSegments.any((s) => s == '..')) return Response(404);

    final subPath = subSegments.join('/');

    if (subPath.isEmpty || subPath == 'index.html') {
      return _serveIndex(segments[1]);
    }
    return _serveAsset(subPath);
  }

  Future<Result> _serveIndex(String displayId) async {
    final file = File('$_webDir/index.html');
    if (!file.existsSync()) {
      return Response(
        404,
        body: Body.fromString('Companion page not yet built.'),
      );
    }
    final html = injectDisplayId(await file.readAsString(), displayId);
    return Response(
      200,
      body: Body.fromString(html, mimeType: MimeType.html),
    );
  }

  Future<Result> _serveAsset(String subPath) async {
    final file = File('$_webDir/$subPath');
    if (!file.existsSync()) return Response(404);
    final bytes = await file.readAsBytes();
    return Response(
      200,
      body: Body.fromData(bytes, mimeType: _mimeFor(subPath)),
    );
  }

  /// Injects `window.LANDFALL_DISPLAY_ID` immediately after the `<head>` tag.
  /// The [displayId] is JS-escaped so backslashes and double quotes are safe.
  static String injectDisplayId(String html, String displayId) {
    final escaped = displayId
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"');
    return html.replaceFirst(
      '<head>',
      '<head><script>window.LANDFALL_DISPLAY_ID = "$escaped";</script>',
    );
  }

  static MimeType _mimeFor(String path) {
    if (path.endsWith('.html')) return MimeType.html;
    if (path.endsWith('.js')) return MimeType.javascript;
    if (path.endsWith('.css')) return MimeType.css;
    if (path.endsWith('.json')) return MimeType.json;
    if (path.endsWith('.png')) return MimeType('image', 'png');
    if (path.endsWith('.webp')) return MimeType('image', 'webp');
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      return MimeType('image', 'jpeg');
    }
    if (path.endsWith('.svg')) return MimeType('image', 'svg+xml');
    if (path.endsWith('.wasm')) return MimeType('application', 'wasm');
    if (path.endsWith('.ico')) return MimeType('image', 'x-icon');
    return MimeType.octetStream;
  }
}
