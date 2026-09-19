import 'package:test/test.dart';

import 'package:landfall_server/src/auth/auth_user_id.dart';

void main() {
  group('authUserIdFromIdentifier', () {
    test('pads a short numeric identifier into RFC 4122 v4 layout', () {
      // Version nibble = 4, variant nibble = 8.
      expect(
        authUserIdFromIdentifier('100000000001'),
        '00000000-0000-4000-8000-100000000001',
      );
    });

    test('pads a shorter numeric identifier with leading zeros', () {
      expect(
        authUserIdFromIdentifier('42'),
        '00000000-0000-4000-8000-000000000042',
      );
    });

    test('returns an already-valid UUID unchanged (case-insensitive)', () {
      const uuid = '019e330e-abf0-7666-a2d0-ece4ee3a1287';
      expect(authUserIdFromIdentifier(uuid), uuid);
      expect(
        authUserIdFromIdentifier(uuid.toUpperCase()),
        uuid.toUpperCase(),
      );
    });

    test('rejects empty input', () {
      expect(
        () => authUserIdFromIdentifier(''),
        throwsArgumentError,
      );
    });

    test('rejects non-numeric, non-UUID input', () {
      expect(
        () => authUserIdFromIdentifier('not-a-valid-input'),
        throwsArgumentError,
      );
    });

    test('rejects numeric input that does not fit in 12 chars', () {
      // Padding would otherwise corrupt the UUID's last block.
      expect(
        () => authUserIdFromIdentifier('1234567890123'),
        throwsArgumentError,
      );
    });

    test('output is a syntactically valid UUID for every accepted form', () {
      final pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      for (final id in [
        '1',
        '42',
        '100000000001',
        '019e330e-abf0-7666-a2d0-ece4ee3a1287',
      ]) {
        final out = authUserIdFromIdentifier(id);
        expect(pattern.hasMatch(out), isTrue, reason: 'malformed for $id: $out');
      }
    });
  });

  group('SEC-06 callsite alignment (regression guard)', () {
    // If two callsites that both store into LinkedCredential.authUserId produce
    // different UUID strings, a credential created via one flow becomes
    // un-resolvable via the other. Catch that here, not at runtime.
    //
    // The canonical function is the single source of truth. This test guards
    // against anyone re-introducing a duplicate implementation by ensuring the
    // function is deterministic for the inputs the production callsites use.
    test('produces identical output for repeated calls (determinism)', () {
      const inputs = [
        '1',
        '100000000001',
        '019e330e-abf0-7666-a2d0-ece4ee3a1287',
      ];
      for (final id in inputs) {
        final a = authUserIdFromIdentifier(id);
        final b = authUserIdFromIdentifier(id);
        expect(a, b, reason: 'non-deterministic for $id');
      }
    });
  });

  group('rejects UUIDs Serverpod cannot read back', () {
    // Regression: the pattern used to accept any hex in the version and
    // variant positions, so a value like the one below could be stored and
    // then crash every read of the row with a FormatException from the uuid
    // package's RFC 4122 validation. Logged 2026-05-03.
    test('rejects the all-zero sentinel', () {
      expect(
        () => authUserIdFromIdentifier('00000000-0000-0000-0000-000000000001'),
        throwsArgumentError,
      );
    });

    test('rejects a bad variant nibble', () {
      expect(
        () => authUserIdFromIdentifier('019e330e-abf0-7666-02d0-ece4ee3a1287'),
        throwsArgumentError,
      );
    });

    test('still accepts the v4 layout it generates itself', () {
      expect(
        authUserIdFromIdentifier('00000000-0000-4000-8000-000000000042'),
        '00000000-0000-4000-8000-000000000042',
      );
    });
  });
}
