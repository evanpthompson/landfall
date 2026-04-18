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
      test('same input produces same hash', () {
        const key = 'lf_testkey1234';
        expect(service.hashKey(key), equals(service.hashKey(key)));
      });

      test('different inputs produce different hashes', () {
        expect(
          service.hashKey('lf_key1'),
          isNot(equals(service.hashKey('lf_key2'))),
        );
      });

      test('hash is 64-character hex string (SHA-256)', () {
        final hash = service.hashKey('lf_test');
        expect(hash.length, equals(64));
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(hash), isTrue);
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
