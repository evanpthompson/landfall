import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart' show AuthSuccess;

import 'otp_service.dart';

/// OTP email authentication endpoint.
///
/// Provides a passwordless login flow:
///   1. Client calls [sendCode] with the user's email address.
///   2. The server generates a 6-digit code, stores a SHA-256 hash, and logs
///      (or emails) the plaintext code.
///   3. Client calls [verifyCode] with the email and the code the user entered.
///   4. On success, the server returns an [AuthSuccess] containing a JWT.
///
/// Fail-closed: wrong code, expired code, or replay all throw [ServerpodUnauthenticatedException].
class OtpEndpoint extends Endpoint {
  final _service = OtpService();

  /// Sends a one-time code to [email].
  ///
  /// Always returns void — do not reveal whether the email is registered.
  Future<void> sendCode(Session session, String email) async {
    await _service.sendCode(session, email);
  }

  /// Verifies [code] for [email] and returns an [AuthSuccess] with a JWT.
  ///
  /// Throws [ServerpodUnauthenticatedException] on any failure.
  Future<AuthSuccess> verifyCode(
    Session session,
    String email,
    String code,
  ) async {
    return _service.verifyCode(session, email, code);
  }
}
