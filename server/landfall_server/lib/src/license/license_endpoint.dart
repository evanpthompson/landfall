import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Manages license key activation and status queries.
///
/// One license key can be activated per Serverpod auth user. The key is tied
/// to the account permanently — it survives app reinstalls because auth is
/// server-side.
class LicenseEndpoint extends Endpoint {
  /// Returns the current license status for the authenticated user.
  ///
  /// Returns free tier when the user has no activated license or is not signed in.
  Future<LicenseStatusResponse> getLicenseStatus(Session session) async {
    final userId = session.authenticated?.userIdentifier;
    if (userId == null) {
      return LicenseStatusResponse(tier: 'free');
    }

    final row = await LicenseKey.db.findFirstRow(
      session,
      where: (t) => t.activatedByUserId.equals(userId),
    );

    if (row == null) {
      return LicenseStatusResponse(tier: 'free');
    }

    return LicenseStatusResponse(
      tier: row.tier,
      activatedAt: row.activatedAt,
      maskedKey: _maskKey(row.key),
    );
  }

  /// Activates [key] for the authenticated user.
  ///
  /// Throws [LicenseException] if the key is not found or already activated
  /// by a different user.
  Future<LicenseStatusResponse> activateLicense(
    Session session,
    String key,
  ) async {
    final userId = session.authenticated?.userIdentifier;
    if (userId == null) {
      throw LicenseException('Authentication required to activate a license.');
    }

    final row = await LicenseKey.db.findFirstRow(
      session,
      where: (t) => t.key.equals(key),
    );

    if (row == null) {
      throw LicenseException('License key not found: $key');
    }

    if (row.activatedByUserId != null && row.activatedByUserId != userId) {
      throw LicenseException('This license key has already been activated.');
    }

    if (row.activatedByUserId == userId) {
      throw LicenseException(
        'This license key is already activated on your account.',
      );
    }

    final now = DateTime.now().toUtc();
    await LicenseKey.db.updateRow(
      session,
      row.copyWith(
        activatedByUserId: userId,
        activatedAt: now,
      ),
    );

    return LicenseStatusResponse(
      tier: row.tier,
      activatedAt: now,
      maskedKey: _maskKey(key),
    );
  }

  String _maskKey(String key) {
    final parts = key.split('-');
    if (parts.length < 4) return '****';
    final last = parts.last;
    return '${parts.first}-${parts[1]}-****-$last';
  }
}

class LicenseException implements Exception {
  const LicenseException(this.message);
  final String message;
  @override
  String toString() => 'LicenseException: $message';
}
