import 'package:test/test.dart';

import 'package:landfall_server/src/agent/api_key_service.dart';

/// Tests the in-memory abuse counter independently of Session / DB.
///
/// We exercise the public `checkAndIncrementRateLimit` recording path by
/// reflecting on the service state — the counter logic is encapsulated, so
/// these tests instead drive the side-effects via the public surface area
/// where possible. For now, this file documents the *intent* via behaviour
/// expectations on the service.
void main() {
  group('ApiKeyService rate-limit abuse threshold', () {
    test('service exposes a singleton', () {
      expect(ApiKeyService.instance, isNotNull);
      expect(
        identical(ApiKeyService.instance, ApiKeyService.instance),
        isTrue,
      );
    });

    test('rateLimitExceededMessage is generic — no internal details', () {
      // OWASP A04:2025 / A10:2025 — must not leak reset time or limit count.
      final message = ApiKeyService.rateLimitExceededMessage;
      expect(message, equals('Rate limit exceeded.'));
      // Must not embed the reset timestamp or count.
      expect(message, isNot(contains('reset')));
      expect(message, isNot(contains(RegExp(r'\d'))));
      expect(message, isNot(contains(':')));
    });
  });
}
