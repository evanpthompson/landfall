import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

/// Serves the companion interaction web page and its Flutter web assets.
///
/// URL layout:
///   GET /c/{uuid}              → index.html with injected display ID
///   GET /c/{uuid}/index.html   → same as above
///   GET /c/{uuid}/**           → static asset from the Flutter web build
///
/// The path prefix /c/ (not /companion/) is intentional — Serverpod routes
/// URL-path-based endpoint calls as /endpoint/method, so /companion/** would
/// be shadowed by the companion endpoint before the web route could handle it.
///
/// The Flutter web build is expected at [webDir] (default: web/app).
/// When the build is absent every request returns 404 so the TV still functions
/// while the web page is not yet deployed.
class CompanionPageRoute extends Route {
  CompanionPageRoute({String? webDir})
      : _webDir = webDir ?? 'web/app',
        super(methods: {Method.get});

  final String _webDir;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final segments = request.url.pathSegments;
    // Expect at least ['c', '{uuid}'].
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

  /// Injects `window.LANDFALL_DISPLAY_ID` and fixes the Flutter base href.
  ///
  /// Flutter web builds with `<base href="/">` which resolves all relative
  /// asset URLs (flutter_bootstrap.js, main.dart.js, etc.) to the server
  /// root — outside the /c/** route. Patching it to `/c/{uuid}/` keeps all
  /// relative fetches inside the companion route.
  ///
  /// The [displayId] is JS-escaped so backslashes and double quotes are safe.
  static String injectDisplayId(String html, String displayId) {
    final escaped = displayId
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"');
    return html
        .replaceFirst(
          '<head>',
          '<head><script>window.LANDFALL_DISPLAY_ID = "$escaped";</script>',
        )
        .replaceFirst('<base href="/">', '<base href="/c/$displayId/">');
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
