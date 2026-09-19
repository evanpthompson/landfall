import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:serverpod/serverpod.dart';

import '../../calendar/credential_integrity.dart';
import '../../generated/protocol.dart';

/// Prefix written before every encrypted value stored in the database.
const _encPrefix = 'enc:v1:';

/// AES-256-GCM symmetric encryption for OAuth tokens at rest.
///
/// Usage:
///   final enc = OAuthTokenEncryptor.fromHex(key);
///   final cipher = enc.encrypt(plaintext);   // stores as "enc:v1:&lt;base64url&gt;"
///   final plain  = enc.decrypt(cipher);      // strips prefix before decrypting
///
/// The 32-byte key is supplied as a 64-character lowercase hex string stored in
/// `passwords.yaml` under the key `oauthTokenEncryptionKey`.
///
/// If the key is absent from config the `encryptIfKey` / `decryptIfEncrypted`
/// helpers fall back to plaintext — acceptable for local dev, not for production.
class OAuthTokenEncryptor {
  OAuthTokenEncryptor.fromHex(String hexKey)
      : _keyBytes = _hexToBytes(hexKey);

  final Uint8List _keyBytes;

  static final _rng = Random.secure();

  /// Encrypts [plaintext] and returns `enc:v1:<base64url(iv||ciphertext+tag)>`.
  String encrypt(String plaintext) {
    final iv = Uint8List.fromList(
      List.generate(12, (_) => _rng.nextInt(256)),
    );
    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(_keyBytes), 128, iv, Uint8List(0)),
      );
    final ciphertext = gcm.process(
      Uint8List.fromList(utf8.encode(plaintext)),
    );
    final combined = Uint8List(12 + ciphertext.length);
    combined.setRange(0, 12, iv);
    combined.setRange(12, combined.length, ciphertext);
    return '$_encPrefix${base64Url.encode(combined)}';
  }

  /// Decrypts a value previously returned by [encrypt].
  ///
  /// Throws if the GCM tag does not verify (wrong key or tampered data).
  String decrypt(String encryptedWithPrefix) {
    final encoded = encryptedWithPrefix.startsWith(_encPrefix)
        ? encryptedWithPrefix.substring(_encPrefix.length)
        : encryptedWithPrefix;
    final combined = base64Url.decode(encoded);
    final iv = Uint8List.fromList(combined.sublist(0, 12));
    final ciphertext = Uint8List.fromList(combined.sublist(12));
    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(KeyParameter(_keyBytes), 128, iv, Uint8List(0)),
      );
    return utf8.decode(gcm.process(ciphertext));
  }

  // ── Static helpers ──────────────────────────────────────────────────────────

  /// Returns true when [value] was produced by [encrypt] (has the `enc:v1:` prefix).
  static bool isEncrypted(String value) => value.startsWith(_encPrefix);

  /// Encrypts [value] if [hexKey] is non-null; otherwise returns [value] as-is.
  static String encryptIfKey(String value, String? hexKey) {
    if (hexKey == null || hexKey.isEmpty) return value;
    return OAuthTokenEncryptor.fromHex(hexKey).encrypt(value);
  }

  /// Decrypts [value] if it has the `enc:v1:` prefix and [hexKey] is non-null;
  /// otherwise returns [value] as-is (backwards compatible with plaintext tokens).
  static String decryptIfEncrypted(String value, String? hexKey) {
    if (!isEncrypted(value)) return value;
    if (hexKey == null || hexKey.isEmpty) return value;
    return OAuthTokenEncryptor.fromHex(hexKey).decrypt(value);
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  static Uint8List _hexToBytes(String hex) {
    if (hex.length != 64) {
      throw ArgumentError(
        'oauthTokenEncryptionKey must be a 64-character hex string (32 bytes).',
      );
    }
    final result = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}

/// One-shot migration helper: reads all [LinkedCredential] rows and encrypts
/// any that still hold plaintext tokens.
///
/// Idempotent: rows whose `accessToken` already has the `enc:v1:` prefix are
/// skipped without modification.
class OAuthTokenMigration {
  const OAuthTokenMigration._();

  static Future<void> encryptAll(Session session, String hexKey) async {
    // Skips rows whose authUserId cannot be deserialized. Reading them
    // directly throws, which would abort the migration and leave every other
    // account's tokens in plaintext.
    final credentials = await findReadableCredentials(
      session,
      activeOnly: false,
    );

    final toUpdate = credentials
        .where((c) => !OAuthTokenEncryptor.isEncrypted(c.accessToken))
        .toList();

    if (toUpdate.isEmpty) return;

    final encryptor = OAuthTokenEncryptor.fromHex(hexKey);

    for (final cred in toUpdate) {
      await LinkedCredential.db.updateRow(
        session,
        cred.copyWith(
          accessToken: encryptor.encrypt(cred.accessToken),
          refreshToken: cred.refreshToken != null
              ? encryptor.encrypt(cred.refreshToken!)
              : null,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
  }
}
