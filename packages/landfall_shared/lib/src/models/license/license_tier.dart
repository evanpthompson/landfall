/// License tier for a Landfall installation.
///
/// Free is the default for all self-hosted instances.
/// Pro and Founding Member are activated via a one-time license key.
enum LicenseTier {
  free,
  pro,
  foundingMember;

  String get displayName => switch (this) {
        LicenseTier.free => 'Free',
        LicenseTier.pro => 'Pro',
        LicenseTier.foundingMember => 'Founding Member',
      };

  /// Card history retention window in days.
  int get historyRetentionDays => switch (this) {
        LicenseTier.free => 7,
        LicenseTier.pro => 90,
        LicenseTier.foundingMember => 365,
      };

  /// Maximum agent API pushes per day. 0 means no cap (unlimited).
  int get dailyApiLimit => switch (this) {
        LicenseTier.free => 500,
        LicenseTier.pro => 0,
        LicenseTier.foundingMember => 0,
      };

  bool get isPro => this == pro || this == foundingMember;

  static LicenseTier fromString(String value) {
    return LicenseTier.values.firstWhere(
      (t) => t.name == value,
      orElse: () => LicenseTier.free,
    );
  }
}
