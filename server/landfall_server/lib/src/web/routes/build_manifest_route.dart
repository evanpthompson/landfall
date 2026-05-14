import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

/// Serves the build manifest baked into the image at build time.
///
/// The build manifest is the receipt for what actually shipped: git SHA,
/// dirty-tree flag, host Flutter version, component SHA256s, integration
/// status, and Pi config. It is emitted by `deploy/pi-gen/build.sh` and
/// baked into the server tarball at `/etc/landfall/build-manifest.json`.
///
/// `curl http://<pi>:8080/health/build` returns the manifest. This collapses
/// "which build is running on this Pi" from a multi-step investigation
/// (ssh in, find the .img name, hash files) to a single HTTP call.
///
/// When the manifest file is absent (e.g. running outside the image),
/// returns `{"present": false}` with 200 so the route is always available.
class BuildManifestRoute extends Route {
  BuildManifestRoute({String? manifestPath})
      : _manifestPath = manifestPath ?? '/etc/landfall/build-manifest.json',
        super(methods: {Method.get});

  final String _manifestPath;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final file = File(_manifestPath);
    if (!file.existsSync()) {
      return Response(
        200,
        body: Body.fromString(
          jsonEncode({'present': false}),
          mimeType: MimeType.json,
        ),
      );
    }
    try {
      final contents = await file.readAsString();
      jsonDecode(contents); // validate
      return Response(
        200,
        body: Body.fromString(contents, mimeType: MimeType.json),
      );
    } on FormatException {
      return Response(
        500,
        body: Body.fromString(
          jsonEncode({'error': 'manifest is not valid JSON'}),
          mimeType: MimeType.json,
        ),
      );
    }
  }
}
