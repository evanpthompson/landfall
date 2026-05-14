import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/web/routes/build_manifest_route.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given BuildManifestRoute', (sessionBuilder, endpoints) {
    late Directory tempDir;
    late String manifestPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('build_manifest_test_');
      manifestPath = '${tempDir.path}/build-manifest.json';
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    Future<Response> get(BuildManifestRoute route) async {
      final session = sessionBuilder.build();
      final req = RequestInternal.create(
        Method.get,
        Uri.parse('http://localhost/health/build'),
        Object(),
      );
      final r = await route.handleCall(session, req) as Response;
      await session.close();
      return r;
    }

    group('when manifest file is absent', () {
      test('returns 200 with present:false', () async {
        final route = BuildManifestRoute(manifestPath: manifestPath);
        final res = await get(route);
        expect(res.statusCode, equals(200));
        final body = jsonDecode(await res.readAsString());
        expect(body['present'], isFalse);
      });
    });

    group('when manifest file is present', () {
      setUp(() async {
        await File(manifestPath).writeAsString(jsonEncode({
          'build': {
            'timestamp': '2026-05-14T15:23:00-05:00',
            'git_sha': 'deadbeef',
            'git_dirty': false,
          },
          'components': {
            'companion_web': {
              'bootstrap_sha256': 'abc123',
              'use_local_canvaskit': true,
            },
          },
        }));
      });

      test('returns 200 with the parsed manifest', () async {
        final route = BuildManifestRoute(manifestPath: manifestPath);
        final res = await get(route);
        expect(res.statusCode, equals(200));
        final body = jsonDecode(await res.readAsString()) as Map;
        expect(body['build']['git_sha'], equals('deadbeef'));
        expect(body['components']['companion_web']['use_local_canvaskit'],
            isTrue);
      });

      test('content-type is application/json', () async {
        final route = BuildManifestRoute(manifestPath: manifestPath);
        final res = await get(route);
        final mt = res.body.bodyType?.mimeType;
        expect(mt?.primaryType, equals('application'));
        expect(mt?.subType, equals('json'));
      });
    });

    group('when manifest file is malformed', () {
      setUp(() async {
        await File(manifestPath).writeAsString('not valid json {{{');
      });

      test('returns 500', () async {
        final route = BuildManifestRoute(manifestPath: manifestPath);
        final res = await get(route);
        expect(res.statusCode, equals(500));
      });
    });
  });
}
