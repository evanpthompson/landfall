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

  /// How long to wait for the server to confirm a restored session before
  /// falling back to the stored credentials. Long enough for a cold Pi on a
  /// slow LAN, short enough that launch is not visibly blocked.
  static const _validationTimeout = Duration(seconds: 5);

  Future<void> _init() async {
    final sessionManager = _sessionManager;
    if (sessionManager == null) return;
    try {
      // Restore *and* validate. `isAuthenticated` alone only means a token file
      // exists — a token the server has since forgotten passes that check, and
      // the display then boots into an endless "Authentication required" error
      // with no way back to the login screen. `initialize` refreshes against
      // the server and signs the device out when the refresh token is dead, so
      // a rejected session lands on the login screen instead.
      await sessionManager.initialize(timeout: _validationTimeout);
    } catch (_) {
      // Server unreachable or slow: keep whatever `initialize` restored from
      // storage and let the first endpoint call decide. Being offline must not
      // sign a working display out.
    }
    final authInfo = sessionManager.authInfo;
    if (authInfo != null) {
      emit(AuthAuthenticated(accessToken: authInfo.token));
    }
  }

  /// Discards the stored session after the server rejected it mid-run.
  ///
  /// Returns the app to [AuthUnauthenticated] so the auth gate shows the login
  /// screen. Storage is cleared even when the sign-out call fails — keeping a
  /// credential the server refuses only reproduces the same dead end on the
  /// next launch.
  Future<void> sessionExpired() async {
    try {
      await _sessionManager?.signOutDevice();
    } catch (_) {
      try {
        await _sessionManager?.updateSignedInUser(null);
      } catch (_) {
        // Storage unavailable — the in-memory sign-out below still applies.
      }
    }
    emit(const AuthUnauthenticated());
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
          if (sessionMgr != null) {
            // Without a stored AuthSuccess the client has no credential to send,
            // so reporting success here would drop the display straight into
            // "Authentication required" on every call. Fail closed: stay on the
            // login screen and let the user try again.
            if (json == null) {
              emit(const AuthError(
                message: 'Sign-in did not complete. Please try again.',
                previous: AuthUnauthenticated(),
              ));
              return;
            }
            try {
              final authSuccess = AuthSuccess.fromJson(json);
              await sessionMgr.updateSignedInUser(authSuccess);
            } catch (_) {
              emit(const AuthError(
                message: 'Could not save the sign-in on this device. '
                    'Please try again.',
                previous: AuthUnauthenticated(),
              ));
              return;
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
