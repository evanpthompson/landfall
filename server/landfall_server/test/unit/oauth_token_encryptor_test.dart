import 'package:test/test.dart';

import 'package:landfall_server/src/web/routes/oauth_token_encryptor.dart';

const _testKey =
    'aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899';

void main() {
  group('OAuthTokenEncryptor', () {
    late OAuthTokenEncryptor encryptor;

    setUp(() {
      encryptor = OAuthTokenEncryptor.fromHex(_testKey);
    });

    test('encrypts to a non-empty string different from plaintext', () {
      const plain = 'ya29.a0AfH6SMBlah';
      final cipher = encryptor.encrypt(plain);
      expect(cipher, isNotEmpty);
      expect(cipher, isNot(equals(plain)));
    });

    test('decrypts back to original plaintext', () {
      const plain = 'ya29.a0AfH6SMBlah';
      final cipher = encryptor.encrypt(plain);
      expect(encryptor.decrypt(cipher), equals(plain));
    });

    test('each encryption produces a different ciphertext (random IV)', () {
      const plain = 'same-token';
      final c1 = encryptor.encrypt(plain);
      final c2 = encryptor.encrypt(plain);
      expect(c1, isNot(equals(c2)));
    });

    test('decrypt roundtrips for a refresh token', () {
      const refresh = '1//0grefreshtoken_value';
      expect(encryptor.decrypt(encryptor.encrypt(refresh)), equals(refresh));
    });

    test('decrypt roundtrips for long token', () {
      final long = 'x' * 512;
      expect(encryptor.decrypt(encryptor.encrypt(long)), equals(long));
    });

    test('wrong key fails decryption', () {
      const plain = 'super-secret-token';
      final cipher = encryptor.encrypt(plain);
      const wrongKey =
          '0011223344556677889900112233445566778899001122334455667788990011';
      final badEncryptor = OAuthTokenEncryptor.fromHex(wrongKey);
      expect(() => badEncryptor.decrypt(cipher), throwsA(anything));
    });

    test('tampered ciphertext fails decryption', () {
      const plain = 'some-token';
      final cipher = encryptor.encrypt(plain);
      // Flip the last byte of the base64 string
      final tampered = '${cipher.substring(0, cipher.length - 1)}X';
      expect(() => encryptor.decrypt(tampered), throwsA(anything));
    });
  });

  group('OAuthTokenEncryptor.isEncrypted', () {
    test('returns true for enc:v1: prefixed string', () {
      expect(OAuthTokenEncryptor.isEncrypted('enc:v1:abc'), isTrue);
    });

    test('returns false for plaintext token', () {
      expect(OAuthTokenEncryptor.isEncrypted('ya29.abc'), isFalse);
    });
  });

  group('OAuthTokenEncryptor.encryptIfKey', () {
    test('returns encrypted string when key is provided', () {
      const plain = 'token';
      final result = OAuthTokenEncryptor.encryptIfKey(plain, _testKey);
      expect(OAuthTokenEncryptor.isEncrypted(result), isTrue);
    });

    test('returns plaintext when key is null', () {
      const plain = 'token';
      final result = OAuthTokenEncryptor.encryptIfKey(plain, null);
      expect(result, equals(plain));
    });
  });

  group('OAuthTokenEncryptor.decryptIfEncrypted', () {
    test('decrypts enc:v1: prefixed value when key is provided', () {
      const plain = 'my-token';
      final encrypted = OAuthTokenEncryptor.encryptIfKey(plain, _testKey);
      final result = OAuthTokenEncryptor.decryptIfEncrypted(encrypted, _testKey);
      expect(result, equals(plain));
    });

    test('returns value as-is when no prefix and key is null', () {
      const plain = 'ya29.plain';
      expect(OAuthTokenEncryptor.decryptIfEncrypted(plain, null), equals(plain));
    });

    test('returns value as-is when no prefix even if key is provided', () {
      const plain = 'ya29.plain';
      expect(
        OAuthTokenEncryptor.decryptIfEncrypted(plain, _testKey),
        equals(plain),
      );
    });
  });
}
