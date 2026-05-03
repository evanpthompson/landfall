import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/agent/api_key_service.dart';

void main() {
  final service = ApiKeyService.instance;

  group('ApiKeyService', () {
    group('generatePlainTextKey', () {
      test('returns key with lf_ prefix', () {
        final key = service.generatePlainTextKey();
        expect(key, startsWith('lf_'));
      });

      test('key has correct total length (3 + 32 = 35)', () {
        final key = service.generatePlainTextKey();
        expect(key.length, equals(35));
      });

      test('generates unique keys', () {
        final keys = List.generate(100, (_) => service.generatePlainTextKey());
        expect(keys.toSet().length, equals(100));
      });

      test('key contains only valid characters after prefix', () {
        final key = service.generatePlainTextKey();
        final random = key.substring(3);
        expect(RegExp(r'^[0-9a-z]+$').hasMatch(random), isTrue);
      });
    });

    group('hashKey', () {
      const secret = 'test-hmac-secret';

      test('same input and secret produces same hash', () {
        const key = 'lf_testkey1234';
        expect(
          service.hashKey(key, secret),
          equals(service.hashKey(key, secret)),
        );
      });

      test('different inputs produce different hashes', () {
        expect(
          service.hashKey('lf_key1', secret),
          isNot(equals(service.hashKey('lf_key2', secret))),
        );
      });

      test('same key with different secrets produces different hashes', () {
        expect(
          service.hashKey('lf_key', 'secret-a'),
          isNot(equals(service.hashKey('lf_key', 'secret-b'))),
        );
      });

      test('hash is 64-character hex string (HMAC-SHA-256)', () {
        final hash = service.hashKey('lf_test', secret);
        expect(hash.length, equals(64));
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(hash), isTrue);
      });

      test('HMAC hash differs from plain SHA-256 of same input', () {
        // Confirms HMAC is being used, not bare SHA-256.
        final plainSha256 = sha256.convert(utf8.encode('lf_test')).toString();
        expect(service.hashKey('lf_test', secret), isNot(equals(plainSha256)));
      });

      test('throws when secret is empty', () {
        expect(
          () => service.hashKey('lf_test', ''),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('rateLimitExceededMessage', () {
      test('message is defined', () {
        expect(ApiKeyService.rateLimitExceededMessage, isNotEmpty);
      });

      test('message does not include an ISO 8601 timestamp', () {
        expect(
          ApiKeyService.rateLimitExceededMessage,
          isNot(matches(RegExp(r'\d{4}-\d{2}-\d{2}'))),
          reason: 'reset timestamp must not leak to callers (A10)',
        );
      });

      test('message does not include per-key limit details', () {
        expect(
          ApiKeyService.rateLimitExceededMessage,
          isNot(contains('pushes/day')),
          reason: 'internal rate-limit config must not leak to callers (A10)',
        );
      });
    });

    group('prefixOf', () {
      test('returns first 11 characters', () {
        final key = 'lf_abcdefghijklmnopqrstuvwxyz12345';
        expect(service.prefixOf(key), equals('lf_abcdefgh'));
      });

      test('prefix starts with lf_', () {
        final key = service.generatePlainTextKey();
        expect(service.prefixOf(key), startsWith('lf_'));
      });
    });
  });
}
