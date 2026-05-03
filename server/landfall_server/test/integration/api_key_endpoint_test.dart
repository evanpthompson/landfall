import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

const _validToken = 'test-management-token';
const _wrongToken = 'wrong-token';

void main() {
  withServerpod('Given ApiKeyEndpoint', (sessionBuilder, endpoints) {
    group('generateKey', () {
      test('returns a key record and a plaintext key', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Test Key',
          _validToken,
        );

        expect(response.key.id, isNotNull);
        expect(response.key.name, equals('Test Key'));
        expect(response.plainTextKey, startsWith('lf_'));
        expect(response.plainTextKey.length, equals(35));
      });

      test('prefix stored on key matches plaintext prefix', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Prefix Test',
          _validToken,
        );

        expect(
          response.key.prefix,
          equals(response.plainTextKey.substring(0, 11)),
        );
      });

      test('plaintext key is not stored in keyHash', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Hash Test',
          _validToken,
        );

        expect(response.key.keyHash, isNot(equals(response.plainTextKey)));
        expect(response.key.keyHash.length, equals(64)); // SHA-256 hex
      });

      test('key starts with correct defaults', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Defaults Test',
          _validToken,
        );

        expect(response.key.dailyLimit, equals(500));
        expect(response.key.usageCount, equals(0));
        expect(response.key.revokedAt, isNull);
        expect(response.key.lastUsedAt, isNull);
      });

      test('rejects empty name', () async {
        expect(
          () => endpoints.apiKey.generateKey(sessionBuilder, '', _validToken),
          throwsA(isA<Exception>()),
        );
      });

      test('rejects name longer than 80 chars', () async {
        expect(
          () => endpoints.apiKey.generateKey(
            sessionBuilder,
            'a' * 81,
            _validToken,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('rejects wrong setupToken', () async {
        expect(
          () => endpoints.apiKey.generateKey(
            sessionBuilder,
            'Test Key',
            _wrongToken,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('rejects empty setupToken', () async {
        expect(
          () => endpoints.apiKey.generateKey(sessionBuilder, 'Test Key', ''),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('listKeys', () {
      test('returns empty list when no keys exist', () async {
        final keys = await endpoints.apiKey.listKeys(
          sessionBuilder,
          _validToken,
        );
        expect(keys, isEmpty);
      });

      test('returns generated keys', () async {
        await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Key A',
          _validToken,
        );
        await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Key B',
          _validToken,
        );

        final keys = await endpoints.apiKey.listKeys(
          sessionBuilder,
          _validToken,
        );
        expect(keys.length, equals(2));
      });

      test('revoked keys are excluded', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'To Revoke',
          _validToken,
        );
        await endpoints.apiKey.generateKey(
          sessionBuilder,
          'To Keep',
          _validToken,
        );
        await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
          _validToken,
        );

        final keys = await endpoints.apiKey.listKeys(
          sessionBuilder,
          _validToken,
        );
        expect(keys.length, equals(1));
        expect(keys.first.name, equals('To Keep'));
      });

      test('rejects wrong setupToken', () async {
        expect(
          () => endpoints.apiKey.listKeys(sessionBuilder, _wrongToken),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('revokeKey', () {
      test('returns true when key exists and is revoked', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'To Revoke',
          _validToken,
        );
        final result = await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
          _validToken,
        );
        expect(result, isTrue);
      });

      test('returns false for unknown id', () async {
        final result = await endpoints.apiKey.revokeKey(
          sessionBuilder,
          99999,
          _validToken,
        );
        expect(result, isFalse);
      });

      test('returns false when already revoked', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Double Revoke',
          _validToken,
        );
        await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
          _validToken,
        );
        final result = await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
          _validToken,
        );
        expect(result, isFalse);
      });

      test('rejects wrong setupToken', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Key',
          _validToken,
        );
        expect(
          () => endpoints.apiKey.revokeKey(
            sessionBuilder,
            response.key.id!,
            _wrongToken,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    // A09:2025 — Security Logging. These tests verify that audit logging calls
    // do not suppress exceptions or alter the visible return values of key
    // management operations.
    group('A09 audit logging — exception paths still throw', () {
      test('wrong setupToken on generateKey still throws after logging', () async {
        expect(
          () => endpoints.apiKey.generateKey(
            sessionBuilder,
            'Audit Test',
            _wrongToken,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('wrong setupToken on listKeys still throws after logging', () async {
        expect(
          () => endpoints.apiKey.listKeys(sessionBuilder, _wrongToken),
          throwsA(isA<Exception>()),
        );
      });

      test('wrong setupToken on revokeKey still throws after logging', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Audit Revoke',
          _validToken,
        );
        expect(
          () => endpoints.apiKey.revokeKey(
            sessionBuilder,
            response.key.id!,
            _wrongToken,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('generateKey succeeds and returns key after logging', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Audit Success',
          _validToken,
        );
        expect(response.key.id, isNotNull);
        expect(response.key.prefix, startsWith('lf_'));
      });

      test('revokeKey succeeds and returns true after logging', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Audit Revoke Success',
          _validToken,
        );
        final result = await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
          _validToken,
        );
        expect(result, isTrue);
      });
    });
  });
}
