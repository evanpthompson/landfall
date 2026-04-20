import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

import '../generated/protocol.dart';

/// Manages OTP email challenges.
///
/// Flow:
///   1. [sendCode] — generate a 6-digit code, hash it, store the request, log
///      the code (a real deployment wires an email client here).
///   2. [verifyCode] — validate the hash against the most recent unused,
///      unexpired request for the email. On success, find-or-create the auth
///      user, issue a JWT, and mark the request as used.
///
/// Fail-closed: any mismatch, expiry, or reuse throws [LandfallException].
class OtpService {
  static const _codeLifetime = Duration(minutes: 10);
  static const _method = 'otp-email';

  /// Generates and persists a one-time code for [email].
  ///
  /// The plaintext code is logged via [Session.log] so it is visible in the
  /// server console during development. Wire an email provider here for
  /// production.
  Future<void> sendCode(Session session, String email) async {
    final code = _generateCode();
    final hash = _hashCode(code);
    final now = DateTime.now().toUtc();

    await OtpRequest.db.insertRow(
      session,
      OtpRequest(
        email: email.toLowerCase().trim(),
        codeHash: hash,
        createdAt: now,
        expiresAt: now.add(_codeLifetime),
        usedAt: null,
      ),
    );

    // In production, send `code` via your email provider.
    session.log(
      '[OTP] Code for $email: $code  (expires in ${_codeLifetime.inMinutes} min)',
    );
  }

  /// Verifies [code] for [email] and returns an [AuthSuccess] with a JWT.
  ///
  /// Throws [LandfallException] if the code is wrong, expired, or already used.
  Future<AuthSuccess> verifyCode(
    Session session,
    String email,
    String code,
  ) async {
    final normalizedEmail = email.toLowerCase().trim();
    final hash = _hashCode(code);
    final now = DateTime.now().toUtc();

    // Find the most recent unused, unexpired request for this email.
    final requests = await OtpRequest.db.find(
      session,
      where: (t) =>
          t.email.equals(normalizedEmail) &
          (t.expiresAt > now) &
          t.usedAt.equals(null),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 1,
    );

    if (requests.isEmpty || requests.first.codeHash != hash) {
      // Same error for wrong code or no pending request — fail closed.
      throw LandfallException(message: 'Invalid or expired code.');
    }

    final request = requests.first;

    // Mark used atomically — prevents replay.
    await OtpRequest.db.updateRow(
      session,
      request.copyWith(usedAt: now),
    );

    final authUserId = await _findOrCreateAuthUser(session, normalizedEmail);

    return AuthServices.instance.tokenManager.issueToken(
      session,
      authUserId: authUserId,
      method: _method,
    );
  }

  /// Returns the [UuidValue] auth user ID for [email], creating one if needed.
  Future<UuidValue> _findOrCreateAuthUser(
    Session session,
    String email,
  ) async {
    final existing = await OtpAccount.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );

    if (existing != null) {
      return existing.authUserId;
    }

    final newUser = await const AuthUsers().create(session);

    await OtpAccount.db.insertRow(
      session,
      OtpAccount(email: email, authUserId: newUser.id),
    );

    return newUser.id;
  }

  static String _generateCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  static String _hashCode(String code) {
    final bytes = utf8.encode(code);
    return sha256.convert(bytes).toString();
  }
}
