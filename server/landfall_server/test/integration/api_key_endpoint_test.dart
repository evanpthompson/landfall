import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ApiKeyEndpoint', (sessionBuilder, endpoints) {
    group('generateKey', () {
      test('returns a key record and a plaintext key', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Test Key',
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
        );

        expect(response.key.keyHash, isNot(equals(response.plainTextKey)));
        expect(response.key.keyHash.length, equals(64)); // SHA-256 hex
      });

      test('key starts with correct defaults', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Defaults Test',
        );

        expect(response.key.dailyLimit, equals(500));
        expect(response.key.usageCount, equals(0));
        expect(response.key.revokedAt, isNull);
        expect(response.key.lastUsedAt, isNull);
      });

      test('rejects empty name', () async {
        expect(
          () => endpoints.apiKey.generateKey(sessionBuilder, ''),
          throwsA(isA<Exception>()),
        );
      });

      test('rejects name longer than 80 chars', () async {
        expect(
          () => endpoints.apiKey.generateKey(
            sessionBuilder,
            'a' * 81,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('listKeys', () {
      test('returns empty list when no keys exist', () async {
        final keys = await endpoints.apiKey.listKeys(sessionBuilder);
        expect(keys, isEmpty);
      });

      test('returns generated keys', () async {
        await endpoints.apiKey.generateKey(sessionBuilder, 'Key A');
        await endpoints.apiKey.generateKey(sessionBuilder, 'Key B');

        final keys = await endpoints.apiKey.listKeys(sessionBuilder);
        expect(keys.length, equals(2));
      });

      test('revoked keys are excluded', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'To Revoke',
        );
        await endpoints.apiKey.generateKey(sessionBuilder, 'To Keep');
        await endpoints.apiKey.revokeKey(sessionBuilder, response.key.id!);

        final keys = await endpoints.apiKey.listKeys(sessionBuilder);
        expect(keys.length, equals(1));
        expect(keys.first.name, equals('To Keep'));
      });
    });

    group('revokeKey', () {
      test('returns true when key exists and is revoked', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'To Revoke',
        );
        final result = await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
        );
        expect(result, isTrue);
      });

      test('returns false for unknown id', () async {
        final result = await endpoints.apiKey.revokeKey(sessionBuilder, 99999);
        expect(result, isFalse);
      });

      test('returns false when already revoked', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Double Revoke',
        );
        await endpoints.apiKey.revokeKey(sessionBuilder, response.key.id!);
        final result = await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
        );
        expect(result, isFalse);
      });
    });
  });
}
