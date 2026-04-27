import 'package:landfall_shared/landfall_shared.dart';

sealed class LicenseState {
  const LicenseState();
}

final class LicenseLoading extends LicenseState {
  const LicenseLoading();
  @override
  bool operator ==(Object other) => other is LicenseLoading;
  @override
  int get hashCode => runtimeType.hashCode;
}

final class LicenseActivating extends LicenseState {
  const LicenseActivating();
  @override
  bool operator ==(Object other) => other is LicenseActivating;
  @override
  int get hashCode => runtimeType.hashCode;
}

final class LicenseLoaded extends LicenseState {
  const LicenseLoaded(this.status);
  final LicenseStatus status;
  @override
  bool operator ==(Object other) =>
      other is LicenseLoaded &&
      other.status.tier == status.tier &&
      other.status.maskedKey == status.maskedKey;
  @override
  int get hashCode => Object.hash(status.tier, status.maskedKey);
}

final class LicenseError extends LicenseState {
  const LicenseError(this.message);
  final String message;
  @override
  bool operator ==(Object other) =>
      other is LicenseError && other.message == message;
  @override
  int get hashCode => message.hashCode;
}
