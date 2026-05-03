import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Landfall API key format: "lf_" + 32 random lowercase hex characters.
/// Example: lf_a3f8b2c1d4e5f6a7b8c9d0e1f2a3b4c5
const _keyPrefix = 'lf_';
const _keyRandomLength = 32;
const _displayPrefixLength = 11; // "lf_" + first 8 chars of random part
const _hmacSecretPasswordsKey = 'apiKeyHmacSecret';

class ApiKeyService {
  ApiKeyService._();

  static final ApiKeyService instance = ApiKeyService._();

  /// Generates a cryptographically random plaintext API key.
  String generatePlainTextKey() {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    final rng = Random.secure();
    final random = List.generate(
      _keyRandomLength,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    return '$_keyPrefix$random';
  }

  /// Returns the HMAC-SHA-256 hex digest of [plainTextKey] keyed with [secret].
  ///
  /// The secret must be non-empty — pass `session.passwords['apiKeyHmacSecret']`.
  /// Throws [LandfallException] if [secret] is empty so that misconfigured
  /// deployments fail loudly rather than silently downgrading to bare SHA-256.
  /// OWASP A04:2025.
  String hashKey(String plainTextKey, String secret) {
    if (secret.isEmpty) {
      throw LandfallException(
        message: 'apiKeyHmacSecret is not configured in passwords.yaml.',
      );
    }
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(plainTextKey)).toString();
  }

  /// Returns the display prefix of [plainTextKey] (e.g. "lf_a3f8b2c1").
  String prefixOf(String plainTextKey) {
    return plainTextKey.substring(0, _displayPrefixLength);
  }

  /// Creates and persists a new [ApiKey]. Returns the row and plaintext key.
  Future<({ApiKey key, String plainTextKey})> createKey(
    Session session,
    String name,
  ) async {
    final plain = generatePlainTextKey();
    final secret = session.passwords[_hmacSecretPasswordsKey] ?? '';
    final now = DateTime.now().toUtc();
    final row = ApiKey(
      name: name,
      keyHash: hashKey(plain, secret),
      prefix: prefixOf(plain),
      createdAt: now,
      usageResetAt: _nextMidnightUtc(now),
    );
    final saved = await ApiKey.db.insertRow(session, row);
    return (key: saved, plainTextKey: plain);
  }

  /// Looks up and validates an API key.
  ///
  /// [plainTextKey] is the full key as provided by the agent caller.
  /// Throws [LandfallException] if the key is invalid or revoked.
  /// Logs every failure at warning level for A09:2025 audit trail.
  Future<ApiKey> authenticate(Session session, String plainTextKey) async {
    if (plainTextKey.isEmpty) {
      final ip = session.request?.remoteInfo ?? 'unknown';
      session.log(
        'api_key.auth_failed prefix=(empty) ip=$ip',
        level: LogLevel.warning,
      );
      throw LandfallException(
        message: 'API key must not be empty.',
      );
    }

    final secret = session.passwords[_hmacSecretPasswordsKey] ?? '';
    final hash = hashKey(plainTextKey, secret);
    final row = await ApiKey.db.findFirstRow(
      session,
      where: (t) => t.keyHash.equals(hash),
    );

    if (row == null || row.revokedAt != null) {
      final displayPrefix = plainTextKey.length >= _displayPrefixLength
          ? plainTextKey.substring(0, _displayPrefixLength)
          : plainTextKey;
      final ip = session.request?.remoteInfo ?? 'unknown';
      session.log(
        'api_key.auth_failed prefix=$displayPrefix ip=$ip',
        level: LogLevel.warning,
      );
      throw LandfallException(message: 'Invalid or revoked API key.');
    }

    return row;
  }

  /// Checks the daily rate limit and increments [ApiKey.usageCount].
  ///
  /// Resets the counter if [ApiKey.usageResetAt] is in the past.
  /// Throws [LandfallException] if the daily limit is exceeded.
  Future<void> checkAndIncrementRateLimit(
    Session session,
    ApiKey key,
  ) async {
    final now = DateTime.now().toUtc();

    int count;
    DateTime resetAt;

    if (now.isAfter(key.usageResetAt)) {
      count = 1;
      resetAt = _nextMidnightUtc(now);
    } else {
      count = key.usageCount + 1;
      resetAt = key.usageResetAt;
    }

    if (count > key.dailyLimit) {
      throw LandfallException(
        message:
            'Rate limit exceeded. Limit: ${key.dailyLimit} pushes/day. '
            'Resets at ${key.usageResetAt.toIso8601String()}.',
      );
    }

    await ApiKey.db.updateRow(
      session,
      key.copyWith(
        usageCount: count,
        usageResetAt: resetAt,
        lastUsedAt: now,
      ),
    );
  }

  DateTime _nextMidnightUtc(DateTime from) {
    return DateTime.utc(from.year, from.month, from.day + 1);
  }
}
