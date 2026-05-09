import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

import '../generated/protocol.dart';
import 'otp_email_sender.dart';

/// Manages OTP email challenges.
///
/// Flow:
///   1. [sendCode] — generate a 6-digit code, hash it, store the request.
///      The plaintext code is NOT written to server logs; wire an email
///      provider via the [onSendCode] endpoint override for production.
///   2. [verifyCode] — validate the hash against the most recent unused,
///      unexpired request for the email. On success, find-or-create the auth
///      user, issue a JWT, and mark the request as used.
///
/// Rate limiting (in-memory, single-instance):
///   - Verify failures: max 5 per email within a 15-minute window.
///   - Code generation: max [maxSendRequestsPerIp] per IP within 15 minutes.
///
/// Fail-closed: any mismatch, expiry, reuse, or rate-limit throws [LandfallException].
class OtpService {
  OtpService({OtpEmailSender emailSender = const OtpEmailSender()})
      : _emailSender = emailSender;

  static const _codeLifetime = Duration(minutes: 10);
  static const _method = 'otp-email';
  static const _maxVerifyFailures = 5;
  static const _window = Duration(minutes: 15);

  /// Maximum number of code-generation requests allowed per IP per [_window].
  static const maxSendRequestsPerIp = 10;

  // ── In-memory rate-limit state ─────────────────────────────────────────────
  // Maps email/IP → (count, windowStart). Keyed by email or IP string.
  // These are server-level singletons that persist across sessions.
  static final _verifyFailures = <String, _RateWindow>{};
  static final _genRequests = <String, _RateWindow>{};

  final OtpEmailSender _emailSender;

  /// Clears all in-memory rate-limit counters. For testing only.
  static void resetRateLimits() {
    _verifyFailures.clear();
    _genRequests.clear();
  }

  /// Returns the sanitised log message for a code-send event.
  /// The OTP code itself is deliberately absent from this message.
  static String buildSanitizedLogMessage(String email, Duration lifetime) =>
      '[OTP] Code sent to $email (expires in ${lifetime.inMinutes} min)';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Generates and persists a one-time code for [email].
  ///
  /// [clientIp] is used for per-IP generation throttling. Pass null (or omit)
  /// to skip IP-based throttling (e.g. for internal/test calls).
  Future<void> sendCode(
    Session session,
    String email, {
    String? clientIp,
  }) async {
    // Per-IP generation throttle.
    if (clientIp != null && clientIp.isNotEmpty) {
      final window = _genRequests[clientIp];
      if (window != null && !window.isExpired) {
        if (window.count >= maxSendRequestsPerIp) {
          throw LandfallException(
            message: 'Too many code requests. Try again later.',
          );
        }
        window.count++;
      } else {
        _genRequests[clientIp] = _RateWindow();
      }
    }

    final normalizedEmail = email.toLowerCase().trim();
    final code = _generateCode();
    final hash = _hashCode(code);
    final now = DateTime.now().toUtc();

    await OtpRequest.db.insertRow(
      session,
      OtpRequest(
        email: normalizedEmail,
        codeHash: hash,
        createdAt: now,
        expiresAt: now.add(_codeLifetime),
        usedAt: null,
      ),
    );

    await _emailSender.sendCode(
      session,
      email: normalizedEmail,
      code: code,
      lifetime: _codeLifetime,
    );
    session.log(buildSanitizedLogMessage(normalizedEmail, _codeLifetime));
  }

  /// Verifies [code] for [email] and returns an [AuthSuccess] with a JWT.
  ///
  /// Throws [LandfallException] if the code is wrong, expired, already used,
  /// or if the per-email failure cap has been reached.
  Future<AuthSuccess> verifyCode(
    Session session,
    String email,
    String code,
  ) async {
    final normalizedEmail = email.toLowerCase().trim();

    // Per-email attempt cap.
    final failWindow = _verifyFailures[normalizedEmail];
    if (failWindow != null && !failWindow.isExpired) {
      if (failWindow.count >= _maxVerifyFailures) {
        throw LandfallException(
          message: 'Too many failed attempts. Try again later.',
        );
      }
    }

    final hash = _hashCode(code);
    final now = DateTime.now().toUtc();

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
      // Increment failure counter — same error for wrong code or no pending request.
      final w = _verifyFailures[normalizedEmail];
      if (w == null || w.isExpired) {
        _verifyFailures[normalizedEmail] = _RateWindow();
      } else {
        w.count++;
      }
      throw LandfallException(message: 'Invalid or expired code.');
    }

    // Success — reset failure counter and mark request as used.
    _verifyFailures.remove(normalizedEmail);

    final request = requests.first;
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

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<UuidValue> _findOrCreateAuthUser(
    Session session,
    String email,
  ) async {
    final existing = await OtpAccount.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );

    if (existing != null) return existing.authUserId;

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

/// Tracks a rolling rate-limit window: how many events occurred and when
/// the window started.
class _RateWindow {
  _RateWindow() : _start = DateTime.now().toUtc(), count = 1;

  final DateTime _start;
  int count;

  bool get isExpired =>
      DateTime.now().toUtc().difference(_start) > OtpService._window;
}
