import 'package:display/src/data/server/server_health_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('isReachable', () {
    test('true when the URL answers a non-5xx status', () async {
      final checker = HttpServerHealthChecker(
        httpClient: MockClient((_) async => http.Response('ok', 200)),
      );
      expect(await checker.isReachable('http://host:8080/'), isTrue);
    });

    test('true on a 4xx (server is up, just no route)', () async {
      final checker = HttpServerHealthChecker(
        httpClient: MockClient((_) async => http.Response('nope', 404)),
      );
      expect(await checker.isReachable('http://host:8080/'), isTrue);
    });

    test('false on a 5xx', () async {
      final checker = HttpServerHealthChecker(
        httpClient: MockClient((_) async => http.Response('boom', 503)),
      );
      expect(await checker.isReachable('http://host/'), isFalse);
    });

    test('false when the host cannot be reached', () async {
      final checker = HttpServerHealthChecker(
        httpClient: MockClient((_) async => throw const _NoConnection()),
      );
      expect(await checker.isReachable('http://nope/'), isFalse);
    });
  });

  group('servesWebRoutes', () {
    test('probes the web-only /config route', () async {
      late Uri requested;
      final checker = HttpServerHealthChecker(
        httpClient: MockClient((req) async {
          requested = req.url;
          return http.Response('{"timezone":"America/Chicago"}', 200);
        }),
      );

      await checker.servesWebRoutes('http://host:8082/');

      expect(requested.path, '/config');
    });

    test('true when /config answers 2xx (web/Caddy origin)', () async {
      final checker = HttpServerHealthChecker(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      expect(await checker.servesWebRoutes('http://host/'), isTrue);
    });

    test('false when /config 404s (bare API port)', () async {
      final checker = HttpServerHealthChecker(
        httpClient: MockClient((_) async => http.Response('Not found', 404)),
      );
      expect(await checker.servesWebRoutes('http://host:8080/'), isFalse);
    });

    test('normalizes a URL without a trailing slash', () async {
      late Uri requested;
      final checker = HttpServerHealthChecker(
        httpClient: MockClient((req) async {
          requested = req.url;
          return http.Response('{}', 200);
        }),
      );

      await checker.servesWebRoutes('http://host');

      expect(requested.toString(), 'http://host/config');
    });
  });
}

class _NoConnection implements Exception {
  const _NoConnection();
}
