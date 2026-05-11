import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/web/routes/companion/companion_page_route.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given CompanionPageRoute', (sessionBuilder, endpoints) {
    late Directory webDir;
    late CompanionPageRoute route;

    setUp(() async {
      webDir = await Directory.systemTemp.createTemp('companion_page_test_');
      route = CompanionPageRoute(webDir: webDir.path);
    });

    tearDown(() async {
      await webDir.delete(recursive: true);
    });

    group('when Flutter web build is absent', () {
      test('GET /companion/{uuid} returns 404', () async {
        final session = sessionBuilder.build();
        final req = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/companion/test-uuid'),
          Object(),
        );
        final result = await route.handleCall(session, req);
        expect((result as Response).statusCode, equals(404));
        await session.close();
      });

      test('GET /companion/{uuid}/main.dart.js returns 404', () async {
        final session = sessionBuilder.build();
        final req = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/companion/test-uuid/main.dart.js'),
          Object(),
        );
        final result = await route.handleCall(session, req);
        expect((result as Response).statusCode, equals(404));
        await session.close();
      });
    });

    group('when Flutter web build is present', () {
      setUp(() async {
        await File('${webDir.path}/index.html').writeAsString(
          '<html><head><title>Companion</title></head><body></body></html>',
        );
        await File('${webDir.path}/main.dart.js').writeAsString('console.log(1);');
        await Directory('${webDir.path}/assets').create();
        await File('${webDir.path}/assets/sprite.webp').writeAsBytes([0, 1, 2]);
      });

      test('GET /companion/{uuid} returns 200', () async {
        final session = sessionBuilder.build();
        final req = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/companion/display-abc'),
          Object(),
        );
        final result = await route.handleCall(session, req);
        expect((result as Response).statusCode, equals(200));
        await session.close();
      });

      test('GET /companion/{uuid}/index.html also returns 200', () async {
        final session = sessionBuilder.build();
        final req = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/companion/display-abc/index.html'),
          Object(),
        );
        final result = await route.handleCall(session, req);
        expect((result as Response).statusCode, equals(200));
        await session.close();
      });

      test('GET /companion/{uuid}/main.dart.js returns 200', () async {
        final session = sessionBuilder.build();
        final req = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/companion/display-abc/main.dart.js'),
          Object(),
        );
        final result = await route.handleCall(session, req);
        expect((result as Response).statusCode, equals(200));
        await session.close();
      });

      test('GET /companion/{uuid}/assets/sprite.webp returns 200', () async {
        final session = sessionBuilder.build();
        final req = RequestInternal.create(
          Method.get,
          Uri.parse(
            'http://localhost/companion/display-abc/assets/sprite.webp',
          ),
          Object(),
        );
        final result = await route.handleCall(session, req);
        expect((result as Response).statusCode, equals(200));
        await session.close();
      });

      test('GET /companion/{uuid}/nonexistent.js returns 404', () async {
        final session = sessionBuilder.build();
        final req = RequestInternal.create(
          Method.get,
          Uri.parse('http://localhost/companion/display-abc/nonexistent.js'),
          Object(),
        );
        final result = await route.handleCall(session, req);
        expect((result as Response).statusCode, equals(404));
        await session.close();
      });

      test('path traversal attempt returns 404', () async {
        final session = sessionBuilder.build();
        // Dart's Uri.parse normalises away the ..s so this tests the
        // segments-level check via a raw Uri.
        final req = RequestInternal.create(
          Method.get,
          Uri(
            scheme: 'http',
            host: 'localhost',
            pathSegments: ['companion', 'uuid', '..', 'etc', 'passwd'],
          ),
          Object(),
        );
        final result = await route.handleCall(session, req);
        expect((result as Response).statusCode, equals(404));
        await session.close();
      });
    });
  });
}
