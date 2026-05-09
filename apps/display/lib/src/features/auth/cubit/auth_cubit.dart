import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required Client client,
    required ClientAuthSessionManager sessionManager,
  })  : _client = client,
        _sessionManager = sessionManager,
        super(const AuthUnauthenticated()) {
    _init();
  }

  final Client _client;
  final ClientAuthSessionManager _sessionManager;

  Future<void> _init() async {
    try {
      // Restore stored AuthSuccess (access token + refresh token) from disk.
      // Do not call initialize() — that would sign out the user if the server
      // is temporarily unreachable at startup.
      await _sessionManager.restore();
      if (_sessionManager.isAuthenticated) {
        emit(AuthAuthenticated(
          accessToken: _sessionManager.authInfo!.token,
        ));
      }
    } catch (_) {
      // Storage unavailable — stay unauthenticated.
    }
  }

  Future<void> sendCode(String email) async {
    emit(const AuthSendingCode());
    try {
      await _client.otp.sendCode(email);
      emit(AuthCodeSent(email: email));
    } catch (_) {
      emit(
        const AuthError(
          message: 'Could not send code. Check your connection and try again.',
          previous: AuthUnauthenticated(),
        ),
      );
    }
  }

  Future<void> verifyCode(String email, String code) async {
    emit(AuthVerifying(email: email));
    try {
      final authSuccess = await _client.otp.verifyCode(email, code);
      // Persist the full AuthSuccess — both access token AND refresh token —
      // so ClientAuthSessionManager can auto-renew before the 10-min expiry.
      await _sessionManager.updateSignedInUser(authSuccess);
      emit(AuthAuthenticated(accessToken: authSuccess.token));
    } catch (_) {
      emit(
        AuthError(
          message: 'Invalid or expired code.',
          previous: AuthCodeSent(email: email),
        ),
      );
    }
  }

  Future<void> resendCode(String email) => sendCode(email);

  Future<void> signOut() async {
    try {
      await _sessionManager.signOutDevice();
    } catch (_) {
      await _sessionManager.updateSignedInUser(null);
    }
    emit(const AuthUnauthenticated());
  }
}
