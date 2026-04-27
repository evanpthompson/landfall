import 'license_tier.dart';

/// Current license state for a Landfall installation.
class LicenseStatus {
  const LicenseStatus({
    required this.tier,
    this.activatedAt,
    this.maskedKey,
  });

  final LicenseTier tier;

  /// When the license was activated. Null for free tier.
  final DateTime? activatedAt;

  /// Partially masked license key for display (e.g. "LF-PRO-****-1234").
  final String? maskedKey;

  bool get isPro => tier.isPro;
}
