import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_client/landfall_client.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    show AuthSuccess, ClientAuthSessionManager;

import '../data/device_auth_client.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required Client client,
    required ClientAuthSessionManager sessionManager,
    DeviceAuthClient? deviceAuthClient,
  })  : _client = client,
        _sessionManager = sessionManager,
        _deviceAuth = deviceAuthClient,
        super(const AuthUnauthenticated()) {
    _init();
  }

  /// Minimal constructor for testing device-auth flows without a real server.
  AuthCubit.withDeviceAuth({
    required DeviceAuthClient deviceAuthClient,
  })  : _client = null,
        _sessionManager = null,
        _deviceAuth = deviceAuthClient,
        super(const AuthUnauthenticated());

  final Client? _client;
  final ClientAuthSessionManager? _sessionManager;
  final DeviceAuthClient? _deviceAuth;

  Future<void> _init() async {
    try {
      await _sessionManager?.restore();
      if (_sessionManager?.isAuthenticated == true) {
        emit(AuthAuthenticated(
          accessToken: _sessionManager!.authInfo!.token,
        ));
      }
    } catch (_) {
      // Storage unavailable — stay unauthenticated.
    }
  }

  Future<void> sendCode(String email) async {
    emit(const AuthSendingCode());
    try {
      await _client!.otp.sendCode(email);
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
      final authSuccess = await _client!.otp.verifyCode(email, code);
      await _sessionManager!.updateSignedInUser(authSuccess);
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

  /// Returns the current access token directly from the session manager.
  ///
  /// Always reflects the latest token even after a silent auto-refresh, unlike
  /// [AuthAuthenticated.accessToken] which is set only at sign-in time.
  String? get currentAccessToken => _sessionManager?.authInfo?.token;

  Future<void> resendCode(String email) => sendCode(email);

  Future<void> signOut() async {
    try {
      await _sessionManager?.signOutDevice();
    } catch (_) {
      await _sessionManager?.updateSignedInUser(null);
    }
    emit(const AuthUnauthenticated());
  }

  // ── Device authorization (RFC 8628) ─────────────────────────────────────────

  /// Starts the device authorization flow. Emits [AuthDevicePending] on success.
  Future<void> startDeviceFlow() async {
    try {
      final start = await _deviceAuth!.startFlow();
      emit(AuthDevicePending(
        userCode: start.userCode,
        deviceCode: start.deviceCode,
        verificationUri: start.verificationUri,
      ));
    } catch (_) {
      emit(const AuthError(
        message: 'Could not start sign-in. Check your connection.',
        previous: AuthUnauthenticated(),
      ));
    }
  }

  /// Polls the server for device authorization status.
  ///
  /// Called by the UI on a timer. Emits [AuthAuthenticated] on success,
  /// [AuthError] if the code expired, no-op if still pending.
  Future<void> pollDeviceFlow(String deviceCode) async {
    try {
      final result = await _deviceAuth!.poll(deviceCode);
      switch (result.status) {
        case DevicePollStatus.authorized:
          final json = result.authSuccessJson;
          final sessionMgr = _sessionManager;
          if (sessionMgr != null && json != null) {
            try {
              final authSuccess = AuthSuccess.fromJson(json);
              await sessionMgr.updateSignedInUser(authSuccess);
            } catch (_) {
              // Fall through — still emit AuthAuthenticated for in-memory access.
            }
          }
          emit(AuthAuthenticated(accessToken: result.accessToken ?? ''));
        case DevicePollStatus.expiredToken:
          emit(const AuthError(
            message: 'The sign-in code has expired. Please try again.',
            previous: AuthUnauthenticated(),
          ));
        case DevicePollStatus.authorizationPending:
          // Still waiting — no state change.
          break;
      }
    } catch (_) {
      // Network error during poll — stay in pending state, retry next tick.
    }
  }
}
