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
    if (entry.accessToken != null) {
      return DevicePollResult(
        status: DevicePollStatus.authorized,
        accessToken: entry.accessToken,
      );
    }
    return const DevicePollResult(status: DevicePollStatus.authorizationPending);
  }

  /// Returns true if [userCode] is known and not expired.
  static bool isValidUserCode(String userCode) =>
      _lookupEntry(userCode) != null;

  /// Stores [accessToken] against the device entry for [userCode].
  ///
  /// Called by the server after the user successfully authenticates on phone.
  /// No-op if [userCode] is unknown or expired.
  static void completeFlow(String userCode, String accessToken) {
    _lookupEntry(userCode)?.accessToken = accessToken;
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

  /// Pairs a device entry with a fake token. For testing only.
  static void pairForTest(String userCode, String accessToken) {
    completeFlow(userCode, accessToken);
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
  const DevicePollResult({required this.status, this.accessToken});

  final DevicePollStatus status;
  final String? accessToken;
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
  String? accessToken;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
}
