import 'package:display/src/data/server/server_health_checker.dart';
import 'package:display/src/data/server/server_url_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Helpers that build a ServerUrlValidator with controlled HTTP responses.

ServerUrlValidator _validatorWithResponses({
  http.Response Function(http.Request)? respond,
  String? bakedWebUrl,
}) {
  final client = MockClient((req) async => respond?.call(req) ?? http.Response('ok', 200));
  return ServerUrlValidator(
    HttpServerHealthChecker(httpClient: client),
    webServerUrlOverride: bakedWebUrl,
  );
}

void main() {
  group('ServerUrlValidator — no baked web URL (single-origin / Caddy)', () {
    test('accepts a URL that is both reachable and serves web routes', () async {
      final v = _validatorWithResponses(
        respond: (req) => http.Response('{}', 200),
      );
      final result = await v.validate('http://server.example.com/');
      expect(result.isOk, isTrue);
      expect(result.normalizedUrl, 'http://server.example.com/');
    });

    test('rejects an unreachable URL', () async {
      final v = ServerUrlValidator(
        HttpServerHealthChecker(
          httpClient: MockClient((_) async => throw const _NoConnection()),
        ),
      );
      final result = await v.validate('http://dead.host/');
      expect(result.isOk, isFalse);
      expect(result.error, contains('Could not reach'));
    });

    test('rejects a URL that is reachable but serves only API (no /config)', () async {
      // Simulates entering the bare Serverpod API port (:8080) when no web URL
      // is baked in. The API port is up but does not serve /config.
      final v = _validatorWithResponses(
        respond: (req) => req.url.path == '/config'
            ? http.Response('Not found', 404)
            : http.Response('ok', 200),
      );
      final result = await v.validate('http://192.168.1.167:8080/');
      expect(result.isOk, isFalse);
      expect(result.error, contains("can't handle sign-in"));
    });

    test('normalizes URL by adding trailing slash', () async {
      final v = _validatorWithResponses(
        respond: (_) => http.Response('{}', 200),
      );
      final result = await v.validate('http://server.example.com');
      expect(result.isOk, isTrue);
      expect(result.normalizedUrl, 'http://server.example.com/');
    });
  });

  group('ServerUrlValidator — baked web URL (split-port dev / Pi direct)', () {
    // When LANDFALL_WEB_SERVER_URL is baked in the build, the validator checks
    // reachability of the entered API URL and web-route availability on the
    // baked web URL. This lets the user (or build script) enter the :8080 API
    // URL while sign-in flows route to the separately baked :8082 web URL.

    test('accepts the API URL when the baked web URL serves /config', () async {
      // Simulates LANDFALL_DEFAULT_SERVER_URL=:8080 LANDFALL_WEB_SERVER_URL=:8082.
      // The user enters the API URL; web check hits the baked :8082 URL.
      final v = _validatorWithResponses(
        bakedWebUrl: 'http://192.168.1.167:8082/',
        respond: (req) => http.Response('{}', 200),
      );
      final result = await v.validate('http://192.168.1.167:8080/');
      expect(result.isOk, isTrue);
      expect(result.normalizedUrl, 'http://192.168.1.167:8080/');
    });

    test('reachability check uses the entered API URL, not the baked web URL', () async {
      final requested = <Uri>[];
      final v = ServerUrlValidator(
        HttpServerHealthChecker(
          httpClient: MockClient((req) async {
            requested.add(req.url);
            return http.Response('{}', 200);
          }),
        ),
        webServerUrlOverride: 'http://192.168.1.167:8082/',
      );
      await v.validate('http://192.168.1.167:8080/');

      // First request must be to the entered API URL (reachability probe).
      expect(requested.first.host, '192.168.1.167');
      expect(requested.first.port, 8080);
    });

    test('web-route check uses the baked web URL, not the entered API URL', () async {
      final requested = <Uri>[];
      final v = ServerUrlValidator(
        HttpServerHealthChecker(
          httpClient: MockClient((req) async {
            requested.add(req.url);
            return http.Response('{}', 200);
          }),
        ),
        webServerUrlOverride: 'http://192.168.1.167:8082/',
      );
      await v.validate('http://192.168.1.167:8080/');

      // The /config probe must hit the baked :8082 port, not the entered :8080.
      final configReq = requested.firstWhere((u) => u.path == '/config');
      expect(configReq.port, 8082);
    });

    test('fails when the API URL is unreachable even with a valid baked web URL', () async {
      int callCount = 0;
      final v = ServerUrlValidator(
        HttpServerHealthChecker(
          httpClient: MockClient((req) async {
            callCount++;
            // First call (reachability of entered URL) throws; web URL would succeed.
            if (callCount == 1) throw const _NoConnection();
            return http.Response('{}', 200);
          }),
        ),
        webServerUrlOverride: 'http://192.168.1.167:8082/',
      );
      final result = await v.validate('http://192.168.1.167:8080/');
      expect(result.isOk, isFalse);
      expect(result.error, contains('Could not reach'));
    });
  });
}

class _NoConnection implements Exception {
  const _NoConnection();
}
