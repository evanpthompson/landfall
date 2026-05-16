import 'package:test/test.dart';

import 'package:landfall_server/src/web/routes/companion/companion_page_route.dart';

void main() {
  group('CompanionPageRoute.injectDisplayId', () {
    test('injects script tag immediately after <head>', () {
      const html =
          '<html><head><title>Companion</title></head><body></body></html>';
      final result = CompanionPageRoute.injectDisplayId(html, 'display-abc');
      expect(
        result,
        contains('<head><script>window.LANDFALL_DISPLAY_ID = "display-abc";</script>'),
      );
    });

    test('leaves the rest of the HTML intact', () {
      const html = '<html><head></head><body>hello</body></html>';
      final result = CompanionPageRoute.injectDisplayId(html, 'any-id');
      expect(result, contains('<body>hello</body>'));
    });

    test('escapes backslashes in display ID', () {
      const html = '<html><head></head><body></body></html>';
      final result = CompanionPageRoute.injectDisplayId(html, r'some\path');
      expect(result, contains(r'some\\path'));
    });

    test('escapes double quotes in display ID', () {
      const html = '<html><head></head><body></body></html>';
      final result = CompanionPageRoute.injectDisplayId(html, 'uuid-"q"');
      expect(result, contains(r'\"q\"'));
      expect(result, isNot(contains('"q"')));
    });

    test('returns html unchanged when no <head> tag present', () {
      const html = '<html><body>no head</body></html>';
      final result = CompanionPageRoute.injectDisplayId(html, 'any-id');
      expect(result, equals(html));
    });

    test('patches Flutter base href from / to /c/{uuid}/', () {
      const html =
          '<html><head><base href="/"><title>T</title></head><body></body></html>';
      final result =
          CompanionPageRoute.injectDisplayId(html, 'test-uuid-123');
      expect(result, contains('<base href="/c/test-uuid-123/">'));
      expect(result, isNot(contains('<base href="/">')));
    });

    test('leaves base href unchanged when it is not the Flutter default /', () {
      const html =
          '<html><head><base href="/app/"><title>T</title></head><body></body></html>';
      final result =
          CompanionPageRoute.injectDisplayId(html, 'test-uuid-456');
      expect(result, contains('<base href="/app/">'));
    });
  });
}
