import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/web/routes/config_route.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ConfigRoute', (sessionBuilder, endpoints) {
    Future<Response> getConfig() async {
      final session = sessionBuilder.build();
      final req = RequestInternal.create(
        Method.get,
        Uri.parse('http://localhost:8082/config'),
        Object(),
      );
      final res = await ConfigRoute().handleCall(session, req) as Response;
      await session.close();
      return res;
    }

    test('returns 200 with a JSON timezone field', () async {
      final res = await getConfig();
      expect(res.statusCode, equals(200));
      final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
      expect(body.containsKey('timezone'), isTrue);
      expect(body['timezone'], isA<String>());
    });

    test('exposes the piTimezone configured in passwords.yaml', () async {
      // Pins the wiring: the shared `piTimezone` in passwords.yaml is surfaced
      // verbatim so the display can render the household wall-clock time.
      final res = await getConfig();
      final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
      expect(body['timezone'], equals('America/Chicago'));
    });
  });
}
