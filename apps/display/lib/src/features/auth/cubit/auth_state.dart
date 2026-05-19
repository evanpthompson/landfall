part of 'auth_cubit.dart';

sealed class AuthState {
  const AuthState();
}

/// No credentials on disk — show login screen.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Sending the OTP code to the server.
final class AuthSendingCode extends AuthState {
  const AuthSendingCode();
}

/// OTP code was sent; waiting for the user to enter it.
final class AuthCodeSent extends AuthState {
  const AuthCodeSent({required this.email});
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthCodeSent && email == other.email;

  @override
  int get hashCode => email.hashCode;
}

/// Verifying the submitted code against the server.
final class AuthVerifying extends AuthState {
  const AuthVerifying({required this.email});
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthVerifying && email == other.email;

  @override
  int get hashCode => email.hashCode;
}

/// Valid JWT stored — show display screen.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.accessToken});
  final String accessToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated && accessToken == other.accessToken;

  @override
  int get hashCode => accessToken.hashCode;
}

/// A transient error message to show on the login screen.
final class AuthError extends AuthState {
  const AuthError({required this.message, required this.previous});
  final String message;
  final AuthState previous;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          message == other.message &&
          previous == other.previous;

  @override
  int get hashCode => Object.hash(message, previous);
}

/// Device authorization flow started — TV is showing [userCode] + [verificationUri].
///
/// TV polls until the user completes sign-in on their phone.
final class AuthDevicePending extends AuthState {
  const AuthDevicePending({
    required this.userCode,
    required this.deviceCode,
    required this.verificationUri,
  });

  final String userCode;
  final String deviceCode;
  final String verificationUri;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthDevicePending &&
          userCode == other.userCode &&
          deviceCode == other.deviceCode &&
          verificationUri == other.verificationUri;

  @override
  int get hashCode => Object.hash(userCode, deviceCode, verificationUri);
}
