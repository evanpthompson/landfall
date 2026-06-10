import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/features/companion/companion_url.dart';

void main() {
  group('buildCompanionUrl', () {
    test('returns empty string for empty base', () {
      expect(buildCompanionUrl('', 'abc'), '');
    });

    test('joins base and display id with a single slash', () {
      expect(
        buildCompanionUrl('http://host:8082/', 'abc'),
        'http://host:8082/c/abc',
      );
      expect(
        buildCompanionUrl('http://host:8082', 'abc'),
        'http://host:8082/c/abc',
      );
    });
  });

  group('companionWebServerUrl', () {
    test('maps API port to web-server port (+2)', () {
      expect(
        companionWebServerUrl('http://host:8080/'),
        'http://host:8082/',
      );
    });

    test('returns input unchanged when unparseable / no port', () {
      expect(companionWebServerUrl('not a url'), 'not a url');
    });
  });

  group('companionWebOriginFromPage', () {
    test('keeps explicit non-default port (direct web-port access)', () {
      // Companion served directly from the Serverpod web server on :8082 —
      // OAuth routes live on this same origin.
      expect(
        companionWebOriginFromPage(Uri.parse('http://192.168.1.204:8082/c/abc')),
        'http://192.168.1.204:8082/',
      );
    });

    test('drops default http port (Caddy same-origin)', () {
      expect(
        companionWebOriginFromPage(Uri.parse('http://landfall.local/c/abc')),
        'http://landfall.local/',
      );
    });

    test('drops default https port (Caddy same-origin)', () {
      expect(
        companionWebOriginFromPage(
          Uri.parse('https://makefastlandfall.com/c/abc'),
        ),
        'https://makefastlandfall.com/',
      );
    });
  });
}
