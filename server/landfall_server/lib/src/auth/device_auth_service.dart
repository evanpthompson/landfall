import 'dart:math';

/// RFC 8628-style device authorization service.
///
/// Holds device auth state in-memory — correct for a single-instance
/// self-hosted server. State is lost on restart; sessions expire in 15 min.
///
/// Flow:
///   1. TV calls [startFlow] → receives [DeviceAuthStartResult] with
///      a short user code to display and a device code for polling.
///   2. User opens [verificationUri] on phone, enters email + OTP +
///      the displayed user code. Server calls [completeFlow] on success.
///   3. TV polls [pollFlow] with device code → receives access token.
class DeviceAuthService {
  static const _codeLifetime = Duration(minutes: 15);
  static const _pollingInterval = 5; // seconds
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no O/0/I/1

  static final _requests = <String, _DeviceEntry>{}; // deviceCode → entry
  static final _byUserCode = <String, String>{}; // userCode → deviceCode

  static final _rng = Random.secure();

  /// Starts a new device authorization flow.
  ///
  /// [verificationUri] is the URL the user should visit on their phone.
  /// [lifetime] is exposed for testing only — defaults to 15 minutes.
  static DeviceAuthStartResult startFlow({
    required String verificationUri,
    Duration lifetime = _codeLifetime,
  }) {
    _evictExpired();

    final userCode = _generateUserCode();
    final deviceCode = _generateDeviceCode();
    final expiresAt = DateTime.now().toUtc().add(lifetime);

    final entry = _DeviceEntry(
      userCode: userCode,
      deviceCode: deviceCode,
      expiresAt: expiresAt,
    );
    _requests[deviceCode] = entry;
    _byUserCode[userCode] = deviceCode;

    return DeviceAuthStartResult(
      userCode: userCode,
      deviceCode: deviceCode,
      verificationUri: verificationUri,
      expiresIn: lifetime.inSeconds,
      interval: _pollingInterval,
    );
  }

  /// Polls for authorization status by device code.
  static DevicePollResult pollFlow(String deviceCode) {
    final entry = _requests[deviceCode];
    if (entry == null || entry.isExpired) {
      return const DevicePollResult(status: DevicePollStatus.expiredToken);
    }
    if (entry.authSuccessJson != null) {
      return DevicePollResult(
        status: DevicePollStatus.authorized,
        authSuccessJson: entry.authSuccessJson,
      );
    }
    return const DevicePollResult(status: DevicePollStatus.authorizationPending);
  }

  /// Returns true if [userCode] is known and not expired.
  static bool isValidUserCode(String userCode) =>
      _lookupEntry(userCode) != null;

  /// Stores the full [authSuccessJson] against the device entry for [userCode].
  ///
  /// Called by the server after the user successfully authenticates on phone.
  /// No-op if [userCode] is unknown or expired.
  static void completeFlow(String userCode, Map<String, dynamic> authSuccessJson) {
    _lookupEntry(userCode)?.authSuccessJson = authSuccessJson;
  }

  static _DeviceEntry? _lookupEntry(String userCode) {
    final deviceCode = _byUserCode[userCode];
    if (deviceCode == null) return null;
    final entry = _requests[deviceCode];
    if (entry == null || entry.isExpired) return null;
    return entry;
  }

  // ── Test helpers ───────────────────────────────────────────────────────────

  /// Clears all in-memory state. For testing only.
  static void resetForTest() {
    _requests.clear();
    _byUserCode.clear();
  }

  /// Pairs a device entry with a minimal fake auth response. For testing only.
  static void pairForTest(String userCode, String fakeToken) {
    completeFlow(userCode, {
      'authStrategy': 'otp',
      'token': fakeToken,
      'authUserId': '00000000-0000-0000-0000-000000000000',
      'scopeNames': ['user'],
    });
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static void _evictExpired() {
    _requests.removeWhere((_, e) => e.isExpired);
    _byUserCode.removeWhere((uc, dc) => !_requests.containsKey(dc));
  }

  static String _generateUserCode() {
    return List.generate(
      6,
      (_) => _alphabet[_rng.nextInt(_alphabet.length)],
    ).join();
  }

  static String _generateDeviceCode() {
    final bytes = List.generate(24, (_) => _rng.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}

class DeviceAuthStartResult {
  const DeviceAuthStartResult({
    required this.userCode,
    required this.deviceCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  final String userCode;
  final String deviceCode;
  final String verificationUri;
  final int expiresIn;
  final int interval;
}

enum DevicePollStatus { authorizationPending, authorized, expiredToken }

class DevicePollResult {
  const DevicePollResult({required this.status, this.authSuccessJson});

  final DevicePollStatus status;

  /// Full serialized `AuthSuccess` JSON, present only when [status] is [DevicePollStatus.authorized].
  final Map<String, dynamic>? authSuccessJson;

  /// Convenience accessor for the raw JWT token.
  String? get accessToken => authSuccessJson?['token'] as String?;
}

class _DeviceEntry {
  _DeviceEntry({
    required this.userCode,
    required this.deviceCode,
    required this.expiresAt,
  });

  final String userCode;
  final String deviceCode;
  final DateTime expiresAt;
  Map<String, dynamic>? authSuccessJson;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
}
