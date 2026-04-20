part of 'auth_cubit.dart';

sealed class AuthState {
  const AuthState();
}

/// No credentials on disk — show login screen.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// OTP code was sent; waiting for the user to enter it.
final class AuthCodeSent extends AuthState {
  const AuthCodeSent({required this.email});
  final String email;
}

/// Verifying the submitted code against the server.
final class AuthVerifying extends AuthState {
  const AuthVerifying({required this.email});
  final String email;
}

/// Sending the OTP code to the server.
final class AuthSendingCode extends AuthState {
  const AuthSendingCode();
}

/// Valid JWT stored — show display screen.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.accessToken});
  final String accessToken;
}

/// A transient error message to show on the login screen.
final class AuthError extends AuthState {
  const AuthError({required this.message, required this.previous});
  final String message;
  final AuthState previous;
}
