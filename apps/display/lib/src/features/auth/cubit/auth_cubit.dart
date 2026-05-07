import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_client/landfall_client.dart';

import '../../../data/auth/auth_key_provider.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required Client client,
    required AuthKeyProvider keyProvider,
  })  : _client = client,
        _keyProvider = keyProvider,
        super(const AuthUnauthenticated()) {
    _init();
  }

  final Client _client;
  final AuthKeyProvider _keyProvider;

  Future<void> _init() async {
    try {
      final token = await _keyProvider.readToken();
      if (token != null && token.isNotEmpty) {
        emit(AuthAuthenticated(accessToken: token));
      }
    } catch (_) {
      // Keychain unavailable (e.g. ad-hoc signing in dev) — start unauthenticated.
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
      final result = await _client.otp.verifyCode(email, code);
      // Best-effort persistence — if the Keychain is unavailable (e.g. ad-hoc
      // signing in dev), the JWT lives in memory for this session only.
      try {
        await _keyProvider.saveToken(result.token);
      } catch (_) {}
      emit(AuthAuthenticated(accessToken: result.token));
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
      await _keyProvider.deleteToken();
    } catch (_) {}
    emit(const AuthUnauthenticated());
  }
}
