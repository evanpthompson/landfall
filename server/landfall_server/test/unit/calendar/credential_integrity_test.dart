import 'package:test/test.dart';

import 'package:landfall_server/src/calendar/credential_integrity.dart';

void main() {
  group('isDeserializableUuid', () {
    test('rejects the all-zero sentinel that crashed the calendar refresh', () {
      // Logged 2026-05-03: one row holding this value made every read of
      // calendar_linked_credentials throw FormatException, so getLinkedCredentials
      // returned 500 and CalendarRefreshCall aborted for every account.
      expect(isDeserializableUuid('00000000-0000-0000-0000-000000000001'),
          isFalse);
    });

    test('accepts the canonical v4-shaped id authUserIdFromIdentifier emits',
        () {
      expect(isDeserializableUuid('00000000-0000-4000-8000-000000000001'),
          isTrue);
    });

    test('accepts a real v7 id from Serverpod auth', () {
      expect(isDeserializableUuid('019e330e-abf0-7666-a2d0-ece4ee3a1287'),
          isTrue);
    });

    test('is case-insensitive', () {
      expect(isDeserializableUuid('019E330E-ABF0-7666-A2D0-ECE4EE3A1287'),
          isTrue);
    });

    test('rejects a bad variant nibble', () {
      expect(isDeserializableUuid('019e330e-abf0-7666-02d0-ece4ee3a1287'),
          isFalse);
    });

    test('rejects malformed input', () {
      expect(isDeserializableUuid(''), isFalse);
      expect(isDeserializableUuid('not-a-uuid'), isFalse);
      expect(isDeserializableUuid('019e330e-abf0-7666-a2d0'), isFalse);
    });
  });

  group('partitionCredentialRows', () {
    test('splits readable ids from unreadable ones', () {
      final result = partitionCredentialRows([
        [1, '00000000-0000-4000-8000-000000000001'],
        [2, '00000000-0000-0000-0000-000000000001'],
        [3, '019e330e-abf0-7666-a2d0-ece4ee3a1287'],
      ]);

      expect(result.readable, [1, 3]);
      expect(result.unreadable, [2]);
    });

    test('returns empty lists for no rows', () {
      final result = partitionCredentialRows([]);
      expect(result.readable, isEmpty);
      expect(result.unreadable, isEmpty);
    });

    test('treats a null id or null uuid as unreadable rather than throwing',
        () {
      final result = partitionCredentialRows([
        [null, '00000000-0000-4000-8000-000000000001'],
        [4, null],
      ]);

      expect(result.readable, isEmpty);
      expect(result.unreadable, [4]);
    });
  });

  group('credentialIdQuery', () {
    test('filters on isActive by default', () {
      expect(
        credentialIdQuery(activeOnly: true),
        'SELECT id, "authUserId"::text FROM calendar_linked_credentials '
        'WHERE "isActive" = true',
      );
    });

    test('reads every row when the caller needs disabled ones too', () {
      // The token-encryption migration must see inactive rows, or their
      // tokens stay in plaintext.
      expect(
        credentialIdQuery(activeOnly: false),
        'SELECT id, "authUserId"::text FROM calendar_linked_credentials',
      );
    });
  });
}
